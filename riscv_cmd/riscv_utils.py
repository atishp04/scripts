import re
import os
import subprocess
import csv
import json
import sys
from collections import defaultdict

class const(object):
	'''
	This is a constant class which defines all constants for riscv helper.
	'''
	class ConstError(TypeError): pass
	def __setattr__(self,name,value):
		if self.__dict__.has_key(name):
			raise self.ConstError, "Can't rebind const(%s)"%name
		self.__dict__[name]=value
	
	#path strings
	PATH_STRING_SERIAL_MAC = "/dev/tty.usb*"
	PATH_STRING_SERIAL_LINUX = "/dev/tty[A-Za-z]*"

	PATH_STRING_BUILD_SERVER = "jedi-01.sdcorp.global.sandisk.com"
	PATH_STRING_BL_IMAGE = "/tmp/bl.bin" 
	PATH_STRING_FSBL_IMAGE = "/home/atish/workspace/freedom-u540-c000-bootloader/fsbl.bin"	
	PATH_STRING_BL_PART_SDCARD = "/dev/disk2s1"
	PATH_STRING_FSBL_PART_SDCARD = "/dev/disk2s4"

	#PATH_STRING_BL_PART_SDCARD = "/dev/disk3s1"
	#PATH_STRING_FSBL_PART_SDCARD = "/dev/disk3s4"
	
	USERNAME_BUILD_SERVER = "atish"
	PASSWORD_BUILD_SERVER = ""

		
	#All error strings
	ERR_STRING_INVALID_OPTIONS = "Invalid options. help [cmd]"
	#All command strings
	CMD_GET_ALL_SCREENS = "sudo screen -ls"	
	CMD_QUIT_SCREEN_SESSION = "sudo screen -X -S %s quit"
	CMD_CONNECT_SCREEN_SESSION = "sudo screen -L %s %d"
	
	CMD_CONNECT_MINICOM_SESSION = "sudo minicom -D %s"
	#Copy the bbl image from remote server to local machine	
	CMD_BL_COPY = "scp " + USERNAME_BUILD_SERVER + "@" + PATH_STRING_BUILD_SERVER + ":" +PATH_STRING_BL_IMAGE + " /tmp" 
	
	CMD_FSBL_COPY = "scp " + USERNAME_BUILD_SERVER + "@" + PATH_STRING_BUILD_SERVER + ":" +PATH_STRING_FSBL_IMAGE + " /tmp" 
	CMD_BL_INSTALL = "sudo dd if=/tmp/bl.bin of=" + PATH_STRING_BL_PART_SDCARD + " bs=1024"	
	CMD_FSBL_INSTALL = "sudo dd if=/tmp/fsbl.bin of=" + PATH_STRING_FSBL_PART_SDCARD	
	
	
