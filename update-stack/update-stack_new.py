#!/usr/bin/env python3

import argparse
import botocore
import boto3
# import ConfigParser
import sys
# from distutils.util import strtobool
from datetime import date
from random import randrange

# new/change for python3:
import configparser
import json

__version__ = '0.2.0'


class DefaultHelpParser(argparse.ArgumentParser):
  def error(self, message):
    sys.stderr.write('error: %s\n' % message)
    self.print_help()
    sys.exit(2)

class SubcommandHelpFormatter(argparse.RawDescriptionHelpFormatter):
  def _format_action(self, action):
    parts = super(argparse.RawDescriptionHelpFormatter, self)._format_action(action)
    if action.nargs == argparse.PARSER:
      parts = "\n".join(parts.split("\n")[1:])
    return parts

def parse_args():
  parser = DefaultHelpParser(add_help=True, formatter_class=SubcommandHelpFormatter)
  parser.add_argument('--version', '-v', action='version', version=__version__)
  parser.add_argument('configuration', help='the configuration file to apply parameter values from')
  parser.add_argument('--change_set_only', '-ch', action='store_true', help='create change set instead of update stack')
#  subparsers = parser.add_subparsers(title='command', dest='command', metavar="<command>")
#  parser_status = subparsers.add_parser('status', help='show current status')
#  parser_status.add_argument('-e', '--environment', type=str, default='dev', help='environment name')
#  parser_status.add_argument('-c', '--component', type=str, default='rabdc', help='component name')

  return parser.parse_args()

# Definition of strtobool because it's deprecated since python 3.10 and will be removed from 3.12 
def strtobool(val):
    """Convert a string representation of truth to true (1) or false (0).
    True values are 'y', 'yes', 't', 'true', 'on', and '1'; false values
    are 'n', 'no', 'f', 'false', 'off', and '0'.  Raises ValueError if
    'val' is anything else.
    """
    val = val.lower()
    if val in ('y', 'yes', 't', 'true', 'on', '1'):
        return 1
    elif val in ('n', 'no', 'f', 'false', 'off', '0'):
        return 0
    else:
        raise ValueError("invalid truth value %r" % (val,))

def main(args):

  print("Reading configuration...")
  config = configparser.ConfigParser()
  config.read(args.configuration)
  stack_name = config.get('Stack', 'Name')
  region = config.get('Stack', 'Region')
  #print config.options('Parameters')

  print("Creating session...")
  session = boto3.Session(region_name=region)
  cf = session.client('cloudformation')

  print("Reading stack info...")
  response = cf.describe_stacks(StackName=stack_name)
  params = response['Stacks'][0]['Parameters']

  if config.has_section('Conditions'):
    for condition in config.options('Conditions'):
      value = config.get('Conditions', condition)
      for param in params:
        if param['ParameterKey'].lower() == condition:
          try:
            if strtobool(param['ParameterValue']) != strtobool(value):
              # print("Boolean condition '%s=%s' not met! Aborting." % ( condition, value ))
              print(f"Boolean condition '{condition}={value}' not met! Aborting.")
              sys.exit(2)
          except ValueError:
            if param['ParameterValue'] != value:
              # print("Condition '%s=%s' not met! Aborting." % ( condition, value ))
              print(f"Condition '{condition}={value}' not met! Aborting.")
              sys.exit(2)

  print("Preparing stack parameters...")
  for option in config.options('Parameters'):
    found = False
    for param in params:
      if param['ParameterKey'].lower() == option:
        # if any(x in option for x in ['AsgSize', 'NvsBibeAutoScalingDesiredCapacity', 'NvsBibeAutoScalingMaxSize', 'NvsBibeAutoScalingMinSize']):
        #   param['ParameterValue'] = config.getint('Parameters', option)
        # else:
        param['ParameterValue'] = config.get('Parameters', option)
        found = True
    if not found:
      # print("ERROR: Parameter %s (case ignored) not available for stack %s") % ( option, stack_name )
      print(f"ERROR: Parameter '{option}' (case ignored) not available for stack '{stack_name}'! Aborting!")
      exit(1)

  print("Updating stack...")
  try:
    if args.change_set_only:
      change_name=stack_name + date.today().isoformat() + "-"+ str(randrange(1000))
      response = cf.create_change_set(
        StackName=stack_name,
        UsePreviousTemplate=True,
        Parameters=params,
        Capabilities=['CAPABILITY_IAM'],
        ChangeSetName=change_name,
        ChangeSetType='UPDATE'
      )
      print(f"Change set created for Stack {stack_name}")
    else:
      response = cf.update_stack(
        StackName=stack_name,
        UsePreviousTemplate=True,
        Parameters=params,
        Capabilities=['CAPABILITY_IAM']
    )
      print(f"Update started for stack {stack_name}")
  except botocore.exceptions.ClientError as e:
    error = e.response.get("Error", {})
    code = error.get("Code", "")
    message = error.get("Message", "")
    if code == "ValidationError" and "No updates are to be performed" in message:
      print(f"No update needed for stack {stack_name}")
      sys.exit(3)
    print(f"AWS error during stack operation for {stack_name}: {code} - {message}")
    sys.exit(1)

  print(json.dumps(response, indent=4))


args = parse_args()
#globals()[args.command](args)
main(args)


