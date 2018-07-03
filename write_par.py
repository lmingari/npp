#!/usr/bin/python2

import subprocess
import sys
import time
import os

from datetime import datetime, timedelta

#--------------------------- BEGIN USER MODIFICATIONS ---------------------------
EXEC_STR       = ["ncl", "-Q"]                # -Q option turns off echo of NCL version and copyright info
NCL_WRT_AN     = ["write_npp_analysis.ncl"]   # NCL script for writing analysis
NCL_WRT_GS     = ["write_npp_guess.ncl"]      # NCL script for writing guess
NCL_WRT_FC     = ["write_npp_forecast.ncl"]   # NCL script for writing forecast
POLL_INTERVAL  = 2                           # seconds between checking status of tasks
MAX_CONCURRENT = 4                            # run MAX_TASKS tasks at once

def datetimeIterator(from_date=None, to_date=None, delta=timedelta(hours=1)):
  while to_date is None or from_date <= to_date:
    yield from_date
    from_date = from_date + delta
  return

scripts=[]
fmt = "y=%Y m=%m d=%d h=%H"

t1 = datetime(2017,9,27,0)
t2 = datetime(2017,9,27,23)
#for item in datetimeIterator(from_date=t1, to_date=t2):
#  args = item.strftime(fmt).split()
#  scripts.append(args+NCL_WRT_AN)
#  scripts.append(args+NCL_WRT_GS)

fc_hours = range(0,19)
t1 = datetime(2017,9,26,18)
t2 = datetime(2017,9,26,18)
dt = timedelta(hours=3)
for item in datetimeIterator(from_date=t1, to_date=t2, delta=dt):
  args = item.strftime(fmt).split()
  for hf in fc_hours:
    scripts.append(args+["hf={}".format(hf)]+NCL_WRT_FC)

# --------------------------- END USER MODIFICATIONS -----------------------------

def launchTask(script):
    task = subprocess.Popen(EXEC_STR + script)
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
