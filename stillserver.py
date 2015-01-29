#!/usr/bin/python

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

DEBUG = 0


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
        if s is serverSocket:
            client_socket, address = serverSocket.accept()
            read_list.append(client_socket)
            #print "Connection from", address
            write_list.append(client_socket)
    readable, writable, errored = select.select([], write_list, [], 0)
    if len(writable) > 0:
        if DEBUG:
            sys.stdout.write('w')
            sys.stdout.flush()
        req = urllib2.Request('http://10.1.1.104/SnapshotJPEG?Resolution=320x240&Quality=Standard')
        req.add_header("Authorization", authHeader)
        response = urllib2.urlopen(req)
        headers = ''.join(response.headers.headers)
        img = response.read()
    else:
        if DEBUG:
            sys.stdout.write('p')
            sys.stdout.flush()
        pass


    for s in writable:
        if DEBUG:
            sys.stdout.write('s')
            sys.stdout.flush()
        try:
            s.sendall("HTTP/1.0 200 OK\n");
            s.sendall(''.join((headers,"\n",img)))
            s.close()
            write_list.remove(s)
            read_list.remove(s)
            if DEBUG:
                sys.stdout.write('S')
                sys.stdout.flush()
        except:
            s.close()
            print "Connection closed", address
            write_list.remove(s)
            read_list.remove(s)
            

    
