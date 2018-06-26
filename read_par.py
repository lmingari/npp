#!/usr/bin/python2

import subprocess
import sys
import time
import os

#--------------------------- BEGIN USER MODIFICATIONS ---------------------------
EXEC_STR       = ["ncl", "-Q"]                # -Q option turns off echo of NCL version and copyright info
NCL_SCRIPT     = ["read_npp.ncl"]             # NCL script for reading
POLL_INTERVAL  = 1                            # seconds between checking status of tasks
MAX_CONCURRENT = 4                            # run MAX_TASKS tasks at once
fnames         = ["npp_out.nc"]               # NPP output file list
varnames       = ["MDBZ",                     # NPP variable list
                  "PP", 
                  "SPD10",
                  "PSFC",
                  "Q2",
                  "REFL1KM",
                  "REFL4KM",
                  "T2",
                  ]

scripts = [['fname="{}"'.format(fname), 'varname="{}"'.format(varname)] for varname in varnames for fname in fnames]
#--------------------------- END USER MODIFICATIONS -----------------------------

def launchTask(script):
    task = subprocess.Popen(EXEC_STR + script + NCL_SCRIPT)
    return task
 
# ------------------------- main -----------------------------------------------

# fire off up-to MAX_CONCURRENT subprocesses...
tasks = list()
for i,script in enumerate(scripts):
    if i >= MAX_CONCURRENT:
        break
    tasks.append( launchTask(script) )

scripts = scripts[len(tasks):]  # remove those scripts we've just launched...

start_time = time.time()

while len(tasks) > 0:
    finishedList = []
    for task in tasks:
         retCode = task.poll()
         if retCode != None:
             finishedList.append(task)

             # more scripts to be run?
             if len(scripts) > 0:
                 tasks.append( launchTask(scripts[0]) )
                 del scripts[0]

    for task in finishedList:
        tasks.remove(task)

    if tasks:
      time.sleep(POLL_INTERVAL)
    else:
      break

elapsed_time = time.time() - start_time

print "task_parallelism.py: Done! Elapsed time: {}".format(elapsed_time)


