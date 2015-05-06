#!/usr/bin/env python

#
# Watch an Apache config file for changes and reload Apache.
#

import time, sys, os
from subprocess import call
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler

class MyHandler(PatternMatchingEventHandler):
    patterns = ["*/watch_this.conf"]

    def process(self, event):
        """
        event.event_type
            'modified' | 'created' | 'moved' | 'deleted'
        event.is_directory
            True | False
        event.src_path
            path/to/observed/file
        """
        # the file will be processed there
        call(["service", "httpd", "reload"])

    def on_modified(self, event):
        self.process(event)

    def on_created(self, event):
        self.process(event)

def createDaemon():
   """Detach a process from the controlling terminal and run it in the
   background as a daemon.
   From: http://code.activestate.com/recipes/278731-creating-a-daemon-the-python-way/
   """

   try:
      pid = os.fork()
   except OSError, e:
      raise Exception, "%s [%d]" % (e.strerror, e.errno)

   if (pid == 0):   # The first child.
      os.setsid()

      try:
         pid = os.fork()    # Fork a second child.
      except OSError, e:
         raise Exception, "%s [%d]" % (e.strerror, e.errno)

      if (pid == 0):    # The second child.
         os.chdir('/')
         # We probably don't want the file mode creation mask inherited from
         # the parent, so we give the child complete control over permissions.
         os.umask(0)
      else:
         os._exit(0)    # Exit parent (the first child) of the second child.
   else:
      os._exit(0)   # Exit parent of the first child.

   import resource		# Resource usage information.
   maxfd = resource.getrlimit(resource.RLIMIT_NOFILE)[1]
   if (maxfd == resource.RLIM_INFINITY):
      maxfd = MAXFD
  
   # Iterate through and close all file descriptors.
   for fd in range(0, maxfd):
      try:
         os.close(fd)
      except OSError:	# ERROR, fd wasn't open to begin with (ignored)
         pass

   os.open("/dev/null", os.O_RDWR)	# standard input (0)

   # Duplicate standard input to standard output and standard error.
   os.dup2(0, 1)			# standard output (1)
   os.dup2(0, 2)			# standard error (2)

   return(0)

def writePID():
    with open('/var/run/reload_apache_config.pid', 'w') as f:
        f.write(str(os.getpid()))


if __name__ == "__main__":

    createDaemon()
    writePID()

    args = sys.argv[1:]
    observer = Observer()
    observer.schedule(MyHandler(), path=args[0] if args else '.')
    observer.start()

    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
            observer.stop()

    observer.join()
