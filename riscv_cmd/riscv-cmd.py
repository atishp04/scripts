
#!/usr/bin/env python

import cmd
import json
import getopt
import shlex
import sys
import time
import pexpect
from riscv_helper import *

class riscv_cmd(cmd.Cmd):
	"This is command line interpreter for riscv script"
	
	arg_options = {
		"do_login" : "",
		"do_flash" : "t:",
		}
	version = 0.1
	def cmdloop(self, intro=None):
		return cmd.Cmd.cmdloop(self, intro)
	
	def emptyline(self):
		print "*** Unknown Syntax ***. Enter help for all supported commands"

	def parse_args(self, func, args):
		
		argList = shlex.split(args)
		try:
	   		if func in riscv_cmd.arg_options:
				argoptions = riscv_cmd.arg_options[func]
				opts, remainder = getopt.getopt(argList,riscv_cmd.arg_options[func])
			else:
				return None, None
		except getopt.GetoptError:
			return None, None
		if (len(opts) > 0) and opts[0][0] == '-t':
			arg = opts[0][1].lower()
		return arg

	def do_help(self, arg):
		'List available commands with "help" or detailed help with "help cmd".'
		'This function overrides the base function to print help message accordingly'
		if arg:
		    # XXX check arg syntax
		    try:
			func = getattr(self, 'help_' + arg)
		    except AttributeError:
			try:
			    doc=getattr(self, 'do_' + arg).__doc__
			    if doc:
				self.stdout.write("%s\n"%str(doc))
				return
			except AttributeError:
			    pass
			self.stdout.write("%s\n"%str(self.nohelp % (arg,)))
			return
		    func()
		else:
			with open('help', 'r') as hfile:
				shelp = hfile.read()
		    		print "Current version : %.2f " %riscv_cmd.version
				print shelp
		    		hfile.close()

	def do_login(self, args):
		"login "
		connect_usb_serial()

	def do_flash(self, args):
		"flash -t [binary] - flash bl or fsbl"
		bimageType = self.parse_args(sys._getframe().f_code.co_name, args)
		print bimageType
		if bimageType == "bl":
			print const.CMD_BL_COPY
			exec_shell_cmd_stdout(const.CMD_BL_COPY)	
			print const.CMD_BL_INSTALL
			exec_shell_cmd_stdout(const.CMD_BL_INSTALL)	
		elif bimageType == "fsbl":
			print const.CMD_FSBL_COPY
			exec_shell_cmd_stdout(const.CMD_FSBL_COPY)	
			print const.CMD_FSBL_INSTALL
			exec_shell_cmd_stdout(const.CMD_FSBL_INSTALL)	
			
		else:
			print "Invalid binary image type"
			return False

	def do_quit(self,line):
		"quit - To quit/exit the riscv command console"
		print "Exiting the riscv command console"
		return True
	def do_exit(self, line):
		"exit - To exit/exit the riscv command console"
		print "Exiting the riscv command console"
		return True

if __name__ == '__main__':
	if len(sys.argv) > 1:
	        if sys.argv[1] == "-h" or sys.argv[1] == "help" or sys.argv[1] == "--h": 
			riscv_cmd().onecmd("help")
		else:
			print "Invalid options. riscv -h for more details"
			sys.exit(0)
	else:
		riscv_cmd().cmdloop()
