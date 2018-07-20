#!/usr/bin/python2

import subprocess
import time
from datetime import datetime,timedelta

#--------------------------- BEGIN USER MODIFICATIONS ---------------------------
POLL_INTERVAL  = 2                            # seconds between checking status of tasks
EXEC_STR       = ["ncl", "-Q"]                # -Q option turns off echo of NCL version and copyright info
NCL_WRITE_CMD  = {'analysis': 'write_npp_analysis.ncl',
                  'guess':    'write_npp_guess.ncl',
                  'forecast': 'write_npp_forecast.ncl'
                 }
NCL_READ_CMD   = {'read_single':   'read_npp_single.ncl',
                  'read_panelx60': 'read_npp_panelx60.ncl',
                  'read_panelx4':  'read_npp_panelx4.ncl'
                 }
#--------------------------- END USER MODIFICATIONS -----------------------------

def datetimeIterator(from_date=None, to_date=None, delta=timedelta(hours=1)):
  while to_date is None or from_date <= to_date:
    yield from_date
    from_date = from_date + delta
  return

def launchTask(script):
    task = subprocess.Popen(EXEC_STR + script)
    return task

def run_tasklist(scripts, MAX_CONCURRENT):
    # fire off up-to MAX_CONCURRENT subprocesses...
    tasks = list()
    for i,script in enumerate(scripts):
        if i >= MAX_CONCURRENT:
            break
        tasks.append( launchTask(script) )

    # remove those scripts we've just launched...
    scripts = scripts[len(tasks):]

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

def get_datetimes(config,block):
    year    = config.getint(block, "start_year")
    month   = config.getint(block, "start_month")
    day     = config.getint(block, "start_day")
    hour    = config.getint(block, "start_hour")
    minute  = config.getint(block, "start_min")
    t_start = datetime(year,month,day,hour,minute)

    year    = config.getint(block, "end_year")
    month   = config.getint(block, "end_month")
    day     = config.getint(block, "end_day")
    hour    = config.getint(block, "end_hour")
    minute  = config.getint(block, "end_min")
    t_end   = datetime(year,month,day,hour,minute)

    dmin    = config.getint(block, "interval_min")
    dt      = timedelta(minutes=dmin)

    return t_start, t_end, dt

def get_tasklist(config,block):
    t_start, t_end, dt = get_datetimes(config,block)

    scripts     = []
    fmt         = "y=%Y m=%m d=%d h=%H"
    args_common = t_start.strftime(fmt).split()
    args_list   = []

    if block=="write":
        args_list.append(args_common)
    else:
        varnames = config.get(block, "variables").split()
        zlevels  = [int(iz) for iz in config.get(block, "vertical_levels").split()]
        for varname in varnames:
            if varname in ["T","Q","SPD","HGT"]:
                for iz in zlevels:
                    new_args = ['varname="{}"'.format(varname),"iz={}".format(iz)]
                    args_list.append(args_common+new_args)
            else:
                new_args = ['varname="{}"'.format(varname)]
                args_list.append(args_common+new_args)

    for file_type in ["analysis","guess","forecast"]:
        if config.getboolean(block,file_type):
            if block=="write":
                NCL_CMD = [NCL_WRITE_CMD[file_type]]
            else:
                NCL_CMD = [NCL_READ_CMD[block]]
            for args in args_list:
                if file_type=="forecast":
                    for item in datetimeIterator(from_date=t_start, to_date=t_end, delta=dt):
                        hf = (item-t_start).total_seconds()/3600
                        hf = int(hf)
                        #Por ahora se asume valor entero
                        #En el futuro esto se modificara
                        scripts.append(args+["hf={}".format(hf)]+NCL_CMD)
                elif file_type=="guess":
                    scripts.append(args+["hf={}".format(-1)]+NCL_CMD)
                else:
                    scripts.append(args+NCL_CMD)
    return scripts
