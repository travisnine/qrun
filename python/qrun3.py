#!/usr/bin/python3

# import libs
import sys
import collections
import threading
import time
import subprocess

# parse params
if len(sys.argv) < 3:
    print("usage:",sys.argv[0],"program {}")
    sys.exit(1)

args = sys.argv[1:]
argReplace = []
idx = 0
for arg in args:
    if arg == "{}":
        argReplace.append(idx)
    idx += 1

print("args:",args)


# create queue and thread stuff
q = collections.deque()
qlock = threading.Lock()
qsem = threading.Semaphore(0)

# main processing thread
def qthread():
    curArgs = args # copy of args
    while True: # thread loop
        qsem.acquire() # wait for signal that an item is in the queue
        if len(q) < 1:
            # the queue is empty, but we got a signal, that means we are finished
            return
        nextItem = ""
        with qlock: # wait for my turn
            nextItem = q.popleft() # get the next item in the queue
        print("Processing:",nextItem)
        for idx in argReplace: # replace {} in args with current item
            curArgs[idx] = nextItem
        curProc = subprocess.Popen(curArgs) # start process
        curProc.communicate() # wait for process to finish

# start queue thread
qthreadobj = threading.Thread(target=qthread)
qthreadobj.start()

# main loop
while True:
    try:
        nextLine = input() # wait for a line of input on stdin
    except EOFError:
        print("EOF Reached")
        qsem.release() # signal thread without adding queue item
        qthreadobj.join() # wait for thread to finish
        break
    if nextLine != "": # skip blank lines
        with qlock: # wait for my turn
            q.append(nextLine) # add item to queue
        print("Added:",nextLine)
        qsem.release() # signal thread

sys.exit(0)
