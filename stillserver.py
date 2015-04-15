#!/usr/bin/python
#
# Single threaded sockets server:
# - Listen for connections
# - Grab image from HTTP source.
# - Send image to connected clients.
#
# Sending relies on socket.sendall(). This is a blocking process but we rely on TCP buffers 
# to accept the data immediately since our amount of data is small. It would probably be 
# better to loop over the connections and send a chunk of data until all has been sent.
#

import sys
import socket
import select
import urllib2
import base64
import time
import errno


cameraIP = "10.1.1.104"
cameraPort = 80

camUser = "camera"
camPass = "camera"
base64string = base64.encodestring(
                '%s:%s' % (camUser, camPass))[:-1]
authHeader =  "Basic %s" % base64string
requestString = "GET /SnapshotJPEG?Resolution=320x240&Quality=Standard\n\n"

DEBUG = 1

def debug(msg):
    if DEBUG:
        sys.stdout.write(msg)
        sys.stdout.flush()

def startServer(ip, port):
    _socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    _socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    _socket.bind((ip, port))
    _socket.listen(1)
    print "Listening on port %s:%d" % (ip, port)
    return(_socket)

serverSocket = startServer('0.0.0.0', 8888)

read_list = [serverSocket]
write_list = []

while True:
    readable, writable, errored = select.select(read_list, [], [])
    for s in readable:
        client_socket, address = serverSocket.accept()
        client_socket.shutdown(socket.SHUT_RD)
        debug("Connection: %s\n" % (address,))
        write_list.append(client_socket)
    readable, writable, errored = select.select([], write_list, [], 0)
    if len(writable) > 0:
        req = urllib2.Request('http://10.1.1.104/SnapshotJPEG?Resolution=320x240&Quality=Standard')
        req.add_header("Authorization", authHeader)
        response = urllib2.urlopen(req)
        headers = ''.join(response.headers.headers)
        img = response.read()
    else:
        continue

    for s in writable:
        try:
            s.sendall("HTTP/1.0 200 OK\n"+''.join((headers,"\n",img)))
            s.shutdown(socket.SHUT_RDWR)
            
            # Consume all received data so that when we close() it doesn't tear down the connection.
            # If there is buffered data to read, close() will kill the connection even if there is 
            # buffered data to send to the client.
            while client_socket.recv(1024, socket.MSG_DONTWAIT):
                pass
            s.close()
            
            write_list.remove(s)
        except Exception,e:
            print "Error: %s" % (e,)
            print "Connection closed: %s" % (s,)
            s.close()
            write_list.remove(s)
    
