#!/usr/bin/python2

from ConfigParser import SafeConfigParser
from Parallelization import get_tasklist, run_tasklist
from multiprocessing import cpu_count

#--------------------------- BEGIN USER MODIFICATIONS ---------------------------
MAX_CONCURRENT = 4             # run MAX_TASKS tasks at once
#--------------------------- END USER MODIFICATIONS ---------------------------

print "Python script to execute multiple independent NCL tasks in parallel"
print "***************"

print "Available cores: {}".format(cpu_count())
print "Using MAX_CONCURRENT={}".format(MAX_CONCURRENT)

config = SafeConfigParser()
config.read("npp.cfg")

#Write scripts
block   = "write"
scripts = get_tasklist(config,block)

if scripts:
  print "Running write scripts:"
  for item in scripts: print item
  run_tasklist(scripts, MAX_CONCURRENT)

#Read scripts
scripts = []

block   = "read_single"
scripts += get_tasklist(config,block)

block   = "read_panelx60"
scripts += get_tasklist(config,block)

block   = "read_panelx4"
scripts += get_tasklist(config,block)

block   = "read_probability"
scripts += get_tasklist(config,block)

if scripts:
  print "Running read scripts"
  for item in scripts: print item
  run_tasklist(scripts, MAX_CONCURRENT)

