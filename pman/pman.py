#!/usr/bin/env python

import argparse
import boto3
import operator
import re
import sys
import yaml
# import csv
# import configparser

from os.path import basename
from datetime import datetime,timedelta
from botocore.exceptions import ClientError
from colorama import Fore, Style
# from cStringIO import StringIO
# from io import StringIO
# from pprint import pprint


selection = "dummy"

__version__ = '0.3.0'


class Item(object):

  def __init__(self, name):
    self.name = name

  def __iter__(self):
    for attr, value in self.__dict__.items():
      yield attr, value

  def info(self):
    return dict(self)


def sizeof_fmt(num, suffix='B'):
  for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
    if abs(num) < 1024.0:
      return "%3.1f %s%s" % (num, unit, suffix)
    num /= 1024.0
  return "%.1f %s%s" % (num, 'Yi', suffix)


class DefaultHelpParser(argparse.ArgumentParser):
  def error(self, message):
    sys.stderr.write('error: %s\n' % message)
    self.print_help()
    sys.exit(2)


def main():

  # init some vars
  now = datetime.now()
  activation_date = now
  date_format = "%Y-%m-%d %H:%M:%S"
  today = now.strftime("%Y-%m-%d")
  now_as_string = now.strftime("%H:%M")
  interactive = True

  parser = DefaultHelpParser(add_help=True)
  parser.add_argument('--datatype', '-dt', type=str, help='manage package of specific data type only')
  parser.add_argument('--date', '-d', type=str, default=today, help='activate package at YYYY-MM-DD (default: today)')
  parser.add_argument('--latest', '-l', action='store_true', help='use latest available version')
  parser.add_argument('--list', action='store_true', help='list currently installed version')
  parser.add_argument('--profile', '-p', type=str, help='aws profile to use')
  parser.add_argument('--time', '-t', type=str, default=now_as_string, help='activate package at HH:MM (default: now)')
  parser.add_argument('--version', '-v', action='version', version=__version__)
  parser.add_argument('configuration', help='the package configuration file')
  parser.add_argument('--pkgname', '-pn', type=str, help='data archive to be explicitly deployed')

  args = parser.parse_args()

  # check dataname args
  if args.pkgname != None:

     interactive = False
     if args.datatype == None:

        print("ERROR:  parameter --dataname(-dn) requires parameter --datatype(-dt)!")

        sys.exit(1)

  # check date syntax
  if args.date.startswith('+'):
    offset = int(args.date[1:])
    date = now + timedelta(days=offset)
    args.date = date.strftime("%Y-%m-%d")
  else:
    try:
      tmp = datetime.strptime(args.date, "%Y-%m-%d")
    except:
      print(f"Date '{args.date}' not in YYYY-mm-dd format! Aborting.")
      raise
      sys.exit(1)

  # check time syntax
  try:
    tmp = datetime.strptime(args.time, "%H:%M")
  except:
    print(f"Time '{args.time}' not in HH:MM format! Aborting.")
    sys.exit(1)

  # compute activation date from args or defaults
  if args.date == today and args.time == now_as_string:
    activation_date = now
  else:
    activation_date = datetime.strptime(args.date + " " + args.time + ":00", date_format)

  # detect environment
  config_basename = args.configuration[:-4]
  #( component, subsystem, environment ) = config_basename.split('-')

  # read configuration file with pools, patterns and locations
  config_yml = open(args.configuration, 'r')
  config = yaml.load(config_yml, Loader=yaml.SafeLoader)

  # init session (depends on profile)
  if args.profile == None:
    session = boto3.Session(region_name='eu-central-1')
  else:
    session = boto3.Session(profile_name=args.profile)
  s3 = session.resource('s3')

  # limit package types to be processed if specified on command line
  if args.datatype == None:
    # read all from *.csv
    package_list = config['packages']
  else:
    package_list = []
    # read datatype only from *.csv
    for pitem in config['packages']:
      if pitem['name'] == args.datatype:
        package_list.append(pitem)

    if not package_list:
      print(f"Package datatype '{args.datatype}' seems to be invalid, aborting")
      sys.exit(1)

  # retrieve version info and store in hash of arrays
  # get bucket attributes
  state_config = config['state']
  # get bucket name
  state_bucket_name = state_config['bucket']
  # get prefix
  state_prefix = state_config.get('prefix') or ""
  if state_prefix != "" and not state_prefix.endswith('/'):
    state_prefix += "/"
  # get config csv
  version_file = state_prefix + config_basename + '.csv'

  versions = {}
  # get all strings from csv
  try:
    versions_object = s3.Object(state_bucket_name, version_file).get()
  except ClientError as e:
    if e.response['Error']['Code'] == 'NoSuchKey':
      print("Warning: no version file, will create new one")
      versions_object = None
    else:
      raise e
  # get datatype from list
  if versions_object:
    for line in versions_object['Body'].read().decode('utf-8').splitlines():
      record = line.split(';')
      key = record[0]

      # skip version entry if datatype was removed from configuration
      # e.g. if connection-preview was disabled
      if args.datatype == None:
        if not next((item for item in package_list if item["name"] == key), False):
          continue

      # convert string to datetime
      if record[2] == "now":
        record[2] = now
      else:
        record[2] = datetime.strptime(record[2], date_format)

      if key in versions:
        versions[key].append(record[1:])
      else:
        versions[key] = []
        versions[key].append(record[1:])

  # process all given package items
  first = True
  # get all strings from *.yml
  for package_definition in package_list:
    p_bucket = package_definition.get('bucket')
    p_prefix = package_definition.get('prefix') or ""
    if p_prefix != "" and not p_prefix.endswith('/'):
        p_prefix += "/"
    pattern = p_prefix + package_definition.get('pattern', '.*')
    exclude = package_definition.get('exclude', None)
    search_pattern = package_definition.get('search_pattern', '^(.*)$')
    sort_expression = package_definition.get('sort_expression', r'\1')
    max_results = package_definition.get('max_results', 100)
    regexp = re.compile(pattern)

    # print extra line for repetive blocks
    if first:
      first = False
    else:
      print

    datatype = package_definition['name']

    if interactive:

       print("Package datatype: " + Fore.WHITE + Style.BRIGHT + datatype + Style.RESET_ALL)

    state = None
    version_recordset = None

    if datatype in versions:

      version_recordset = versions[package_definition['name']]

      # identify the currently relevant version entry
      for version_entry in version_recordset:
        # version_entry consists of filename;validFrom

        # skip future entries
        if version_entry[1] > now:
          continue

        # compare against previous timestamp and skip if older
        if state is not None:
          if version_entry[1] < state[1]:
            continue

        # if we made it until here then store current row
        state = version_entry

      if interactive:

         print("Currently installed: " + Fore.WHITE + Style.BRIGHT + state[0] + Style.RESET_ALL)
         print("Active since: " + Fore.WHITE + Style.BRIGHT + state[1].strftime("%d.%m.%Y %H:%M") + Style.RESET_ALL)
         print("Available:")

    # get matching files in bucket
    packages = []
    bucket = s3.Bucket(p_bucket)
    object_list = bucket.objects.filter(Prefix=p_prefix)

    for entry in object_list:
      if regexp.match(entry.key):
        item = Item(basename(entry.key))

        # skip file if name matches exclude pattern
        if exclude is not None and re.search(exclude, item.name) is not None:
            # print("{}{} matches exclude pattern {}. Ignoring!{}".format(Fore.RED, item.name, exclude, Style.RESET_ALL))
            print(f"{Fore.RED}{item.name} matches exclude pattern {exclude}. Ignoring!{Style.RESET_ALL}")
            continue

        # get file stats from s3
        s3_object = s3.Object(p_bucket, entry.key)
        item.mtime = int(s3_object.last_modified.strftime("%s"))
        item.size = s3_object.content_length
        item.selected = ( state != None and item.name == basename(state[0]) )

        # skip file if name does not match pattern (sort_value equals filename otherwise)
        test_value = re.sub(search_pattern, "1", item.name)
        if test_value != "1":
            # print("{}{} does not match {}. Ignoring!{}".format(Fore.RED, item.name, search_pattern, Style.RESET_ALL))
            print(f"{Fore.RED}{item.name} does not match {search_pattern}. Ignoring!{Style.RESET_ALL}")
            continue

        item.sort_value = s3_object.last_modified.strftime(re.sub(search_pattern, sort_expression, item.name))
        # item.description = "%s (%s, %s, %s)" % ( item.name, s3_object.last_modified.strftime('%d.%m.%Y %H:%M'), sizeof_fmt(item.size), item.sort_value )
        item.description = f"{item.name} ({s3_object.last_modified.strftime('%d.%m.%Y %H:%M')}, {sizeof_fmt(item.size)}, {item.sort_value})"

        packages.append(item)

    # sort items respecting sort_value
    cmp = operator.attrgetter('sort_value')
    packages.sort(key=cmp, reverse=False)

    # limit number of items to max_results
    packages = packages[-max_results:]
    response = len(packages)

    if interactive:

       # print available packages
       for idx, item in enumerate(packages):
         style = Style.RESET_ALL
         if item.selected:
           response = idx+1
           style = Fore.WHITE + Style.BRIGHT

        #  print style + " %4s %s" % ( "[" + `idx+1` + "]", item.description ) + Style.RESET_ALL
         print(f"{Style} [{idx + 1:4}] {item.description}{Style.RESET_ALL}")

       if args.latest:
         selection = packages[-1].name

       elif args.list:
         selection = None

       else:
         choice = input("Your choice [%d]: " % ( response ))

         if choice != "":
           try:
             response = int(choice)
           except ValueError:
             print("Non-numeric response, aborting")
             return 1

         try:
           selection = packages[response-1].name
         except IndexError:
           print("Invalid choice (out of range), aborting")
           return 1
         except:
           print("Unexpected error!")
           raise

    else:
       # non interactive
       try:
          
           for names in packages:

             if names.name == args.pkgname:

                selection = names.name
          
                print(names.name)

       except UnboundLocalError:

          print("Invalid package name, aborting")
          sys.exit(3)

    if not datatype in versions:
      versions[datatype] = []
      versions[datatype].append([ f"s3://{p_bucket}/{p_prefix}{selection}", activation_date ])

    else:
      version_recordset_copy = list(version_recordset)

      for version_entry in version_recordset_copy:

        # entries from the past become irrelevant if ...
        if version_entry[1] <= now:
          # ... the new target date is 'now'
          if activation_date == now:
            version_recordset.remove(version_entry)
          # ... the entry is older than the currently relevant entry
          else:
            if state is not None and version_entry[1] < state[1]:
              version_recordset.remove(version_entry)

        # if target date is in the future => remove entries postponed after target date
        if version_entry[1] > now and version_entry[1] > activation_date:
          version_recordset.remove(version_entry)

      # finally add new entry
      version_recordset.append([ f"s3://{p_bucket}/{p_prefix}{selection}", activation_date ])

  # END OF PACKAGE SELECTION

  if not args.list:

    data = ""
    for key, recordset in versions.items():
      for record in recordset:
        data += key + ";" + record[0] + ";" + record[1].strftime(date_format) + "\n"

    if versions_object:
      # make sure file was not changed in the meantime
      last_modified_orig = versions_object['LastModified']
      last_modified_now = s3.Object(state_bucket_name, version_file).get()['LastModified']

      if last_modified_orig != last_modified_now:
        print("FATAL: version file was changed in the meantime! Aborting.")
        sys.exit(3)

    print("Writing data to file:")
    print(data)
    s3.Object(state_bucket_name, version_file).put(Body=data)
    print("Done!")

  sys.exit(0)


if __name__ == '__main__':

    try:

        main()
  
    except UnboundLocalError:

        print("ERROR: Invalid package name,wrong regexp-filter in yaml-template or package not found in s3, aborting...")
        sys.exit(1)

    except Exception as e:

        print("ERROR in function main : " , e)
        sys.exit(1)
