#!/usr/bin/env python

import argparse
import boto3
import sys
import time
from botocore.config import Config
from tabulate import tabulate

__version__ = '0.2.4'

copy_tags = ['ApplicationName','CostReference', 'Environment' ]

config = Config(
  retries = dict(
    max_attempts = 15
  )
)

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
  #subparsers = parser.add_subparsers(title='command', dest='command', metavar="<command>")

  #parser_list = subparsers.add_parser('list', help='list image masters')

  #parser_start = subparsers.add_parser('start', help='start instances')
  #parser_start.add_argument('-y', '--assumeyes', action="store_true", help='answer yes for all questions')
  #parser_start.add_argument('name', help='instance name pattern to match')
  parser.add_argument('--im', default="", type=str, help='selected imageMaster for snapshot')
  parser.add_argument('--comment', default="", type=str, help='PE oder SERVER Version')
  parser.add_argument('--KM', default="", type=str, help='KM')
  return parser.parse_args()


def run(args):

  # get all instances with tag ImageMaster
  instances = []
  instances_table = []
  idx = 0
  imageCustomFilter=[{'Name': 'tag:Subsystem', 'Values': ['imageMaster']}]
  if args.im != "":
    imageCustomFilter.append({'Name': 'tag:Name', 'Values': [args.im]})
  instances_response = ec2.describe_instances(Filters=imageCustomFilter)
  for reservation in instances_response['Reservations']:
    for instance in reservation['Instances']:
      idx = idx + 1
      name = ""
      verfahren = ""
      ip = instance.get('PrivateIpAddress', 'n.a.')

      if 'Tags' in instance:
        for tag in instance['Tags']:
          if tag['Key'] == 'Name':
            name = tag['Value']
          if tag['Key'] == 'ApplicationName':
            verfahren = tag['Value']

      instance['Hostname'] = name
      instance['ApplicationName'] = verfahren
      instances.append(instance)
      instances_table.append([idx, instance['InstanceId'], name, ip, instance['State'].get('Name', ''), verfahren])

  print(tabulate(instances_table, headers=['ID', 'Instance', 'Name', 'Private IP', 'State', 'ApplicationName']))
  print
  if (len(instances_table) == 1):
    choice = 1
  else:
    choice = input("Select instance to create snapshot from (1-%d): " % ( len(instances_table) ) )

  instance = None
  if choice == "":
    return 2
  else:
    try:
      instance = instances[int(choice)-1]

    except:
      print("Invalid response, aborting")
      return 1

  #print instance

  version = 0

  # get all AMIs built from this image master and select recent one
  images_response = ec2.describe_images(Filters=[{'Name': 'tag:ImageMaster', 'Values': [instance['InstanceId']]}])
  images = sorted(images_response['Images'], key=lambda k: k['CreationDate'], reverse=True)

  # get latest version
  if len(images) > 0:
    image = images[0]

    # detect last images version
    if 'Tags' in image:
      for tag in image['Tags']:
        if tag['Key'] == 'Version':
          version = int(tag['Value'])

  # increase version
  version = version + 1

  # get description from terminal input
  description = args.comment
  if description == "":
    description = input("Please describe your changes: ")

  # get additional info for naming
  delivery_version = args.KM
  if delivery_version == "":
    delivery_version = input("KM delivery number: ")

  # create AMI from Image Master
  print("Creating AMI...")
  create_image_response = ec2.create_image(InstanceId=instance['InstanceId'], Name="Golden Image from %s-%s V%03d" % ( instance['Hostname'], delivery_version, version ), Description=description)
  ami_id = create_image_response['ImageId']
  #ami_id = "ami-6dd81d02"
  print(" + " + ami_id)

  # wait for available state
  print("Waiting for image to become available...")
  image = session.resource('ec2').Image(ami_id)
  while image.state == 'pending':
    sys.stdout.write('.')
    sys.stdout.flush()
    time.sleep(5)
    image.reload()
  print(" " + image.state)

  if image.state != 'available':
    print("FATAL: image state reported as " + image.state)
    return 1

  # prepare tags
  tags = []
  name = ""
  if 'Tags' in instance:
    for tag in instance['Tags']:
      if tag['Key'] in copy_tags:
        tags.append({ 'Key': tag['Key'], 'Value': tag['Value'] })
      if tag['Key'] == 'Name':
        name= tag['Value']

  tags.append({ 'Key': 'ImageMaster', 'Value': instance['InstanceId'] })
  tags.append({ 'Key': 'Version', 'Value': str(version) })
  tags.append({ 'Key': 'Name', 'Value': name.replace('-host-', '-ami-') })

  print("Tagging AMI...")
  tag_response = ec2.create_tags(Resources=[ami_id], Tags=tags)

  # get related snapshots
  print("Analyzing snapshots...")
  snapshots = []
  for mapping in image.block_device_mappings:
    if 'Ebs' in mapping:
      snapshotId = mapping['Ebs']['SnapshotId']
      print(" + " + snapshotId)
      snapshots.append(snapshotId)

  print("Tagging snapshots...")
  for tag in tags:
    if tag['Key'] in ['Name']:
      tag['Value'] = tag['Value'].replace('-ami-', '-snap-')
  tag_response = ec2.create_tags(Resources=snapshots, Tags=tags)

  print("Done.")

  return 0


if __name__ == '__main__':
  # parse command line arguments
  args = parse_args()

  # init boto session
  session = boto3.Session(region_name='eu-central-1')
  ec2 = session.client('ec2', config=config)

  # dispatch subcommand
  exit(run(args))

