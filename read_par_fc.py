#!/usr/bin/python2

import subprocess
import sys
import time
import os

from datetime import datetime, timedelta


#--------------------------- BEGIN USER MODIFICATIONS ---------------------------
EXEC_STR       = ["ncl", "-Q"]                # -Q option turns off echo of NCL version and copyright info
NCL_SCRIPT     = ["read_npp_panel_surface.ncl"]             # NCL script for reading
POLL_INTERVAL  = 2                            # seconds between checking status of tasks
MAX_CONCURRENT = 5                            # run MAX_TASKS tasks at once
varnames       = ["PP"]                     # NPP variable list
                 # "Q2",
                  # "PSFC",
                  # "REFL1KM",
                  # "REFL4KM",
                  # "T2",
                 # ]

def datetimeIterator(from_date=None, to_date=None, delta=timedelta(hours=1)):
  while to_date is None or from_date <= to_date:
    yield from_date
    from_date = from_date + delta
  return

scripts=[]
fmt = "NPP_%Y-%m-%d_%H_"

t1 = datetime(2017,9,25,0)
t2 = datetime(2017,9,27,0)
dt = timedelta(hours=3)
# t2 = datetime(2017,9,28,0)
for item in datetimeIterator(from_date=t1, to_date=t2, delta=dt):
#  for hf in range(19):	
  for hf in [18]:
    for varname in varnames:
      fc_fname = item.strftime(fmt) + 'FC{:02d}'.format(hf)
      script = ['fname="{}"'.format(fc_fname), 'varname="{}"'.format(varname)]
      scripts.append(script)

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

