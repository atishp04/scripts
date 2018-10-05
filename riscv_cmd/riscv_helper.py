import glob
import sys
import serial
import pexpect
import re
import os
import subprocess
import csv
import json
import sys
from collections import defaultdict
from pexpect_serial import SerialSpawn
from riscv_utils import *

baud = 115200
portcache = -1

def exec_shell_cmd_output(cmd):
	response = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
	return response.communicate()

def exec_shell_cmd_stdout(cmd):
	response = subprocess.Popen(cmd, stdout=sys.stdout, stderr=sys.stderr, shell=True)
	return response.communicate()
def exec_shell_cmd(cmd):
	DEVNULL = open(os.devnull, 'wb')
	response = subprocess.call(cmd, stdout=DEVNULL, stderr=DEVNULL, shell=True)
	DEVNULL.close()
	return response

def get_serial_ports():
    """ Lists serial port names

        :raises EnvironmentError:
            On unsupported or unknown platforms
        :returns:
            A list of the serial ports available on the system
    """
    if sys.platform.startswith('win'):
        ports = ['COM%s' % (i + 1) for i in range(256)]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        # this excludes your current terminal "/dev/tty"
        ports = glob.glob(const.PATH_STRING_SERIAL_LINUX)
    elif sys.platform.startswith('darwin'):
        ports = glob.glob(const.PATH_STRING_SERIAL_MAC)
    else:
        raise EnvironmentError('Unsupported platform')
    result = []
    for port in ports:
        try:
            s = serial.Serial(port, baud)
            s.close()
            result.append(port)
        except (OSError, serial.SerialException):
            print "Couldnot attach to serial %s" %port
    return result

def check_screen_session():
	output = exec_shell_cmd_output(const.CMD_GET_ALL_SCREENS)[0]
	outL = re.split(r'\t+',output)
	if (len(outL) > 1):
		for dsession in outL:
			if "tty" in dsession:
				print "Found an detached session %s" %dsession
				cmd = const.CMD_QUIT_SCREEN_SESSION %dsession
				exec_shell_cmd(cmd)
	else:
		print outL[0]
def connect_to_serial(port):
	cmd = const.CMD_CONNECT_SCREEN_SESSION %(port, baud)
	child = pexpect.spawn(cmd)
	try:
        	child.logfile = open(logfile, "a")
	except Exception, e:
		child.logfile = None
	child.interact()
	#Returned from interact. Now kill the screen session
	check_screen_session()
		

def connect_usb_serial(logfile=None):
	
	index = 0
	check_screen_session()
	sPortList = get_serial_ports()
	sPortListLen = len(sPortList)
	#TODO: Introduce an automatic mode where it will connect to the serial portcache by default	
	if sPortListLen == 0:
		print "No serial port Found. Exiting."	
		return True
	elif sPortListLen == 1:
		print "one serial port found"
		connect_to_serial(sPortList[0])	
	elif sPortListLen > 1:	
		print "Multiple serial port found"
	for index, port in enumerate(sPortList):
		print "%d. [%s]" %(index, port)
	index = raw_input("Enter serial index to access that serial port or 'a' to iterate through all\n")

	if index == 'a':
		for port in sPortList:
			connect_to_serial(port)
	else:
		portcache = index
		connect_to_serial(sPortList[int(index)])	
