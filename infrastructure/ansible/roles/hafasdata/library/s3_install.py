#!/usr/bin/python
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

import mimetypes
import os
#import urlparse
import shutil
import tarfile
import zipfile
from ssl import SSLError

try:
    import boto
    import boto.ec2
    from boto.s3.connection import Location
    from boto.s3.connection import OrdinaryCallingFormat
    from boto.s3.connection import S3Connection
    from boto.s3.acl import CannedACLStrings
    HAS_BOTO = True
except ImportError:
    HAS_BOTO = False

STATE_FILENAME = 'package_info.json'

DOCUMENTATION = '''
---
module: s3_install
short_description: install a Zip file from S3.
description:
    - This module allows the user to download and install a Zip file from S3 buckets. The Zip file is cached and downloaded on subsequent runs only if the remote file was modified since the timestamp of the cached file. Before installing a new package the previously installed files are automatically removed.
version_added: "2.1"
options:
  aws_access_key:
    description:
      - AWS access key id. If not set then the value of the AWS_ACCESS_KEY environment variable is used.
    required: false
    default: null
    aliases: [ 'ec2_access_key', 'access_key' ]
  aws_secret_key:
    description:
      - AWS secret key. If not set then the value of the AWS_SECRET_KEY environment variable is used.
    required: false
    default: null
    aliases: ['ec2_secret_key', 'secret_key']
  bucket:
    description:
      - Bucket name.
    required: true
    default: null
    aliases: []
  dest:
    description:
      - The destination directory to extract the package to.
    required: true
    default: null
    aliases: []
  region:
    description:
     - "AWS region to retrieve the object from. If not set then the value of the AWS_REGION and EC2_REGION environment variables are checked, followed by the aws_region and ec2_region settings in the Boto config file.  If none of those are set the region defaults to the S3 Location: US Standard."
    required: false
    default: null
  object:
    description:
      - Keyname of the object inside the bucket.
    required: true
    default: null
  cache_dir:
    description:
      - The directory to download the package to.
    required: false
    default: /tmp
    aliases: []
  version:
    description:
      - Version ID of the object inside the bucket. Can be used to get a specific version of a file if versioning is enabled in the target bucket.
    required: false
    default: null
    aliases: []
  retries:
    description:
     - On recoverable failure, how many times to retry before actually failing.
    required: false
    default: 0
requirements: [ "boto" ]
author:
    - "Thorsten Huhn (thorstenhuhn@me.com)"
extends_documentation_fragment: aws
'''

EXAMPLES = '''
# Install content of Zip file in destination folder
- s3_install: bucket=plandaten object=/bhf/bhf.zip dest=/app/hafas/plandaten/bhf
'''

def key_check(module, s3, bucket, obj, version=None):
    try:
        bucket = s3.lookup(bucket)
        key_check = bucket.get_key(obj, version_id=version)
    except s3.provider.storage_response_error, e:
        # If a specified version doesn't exist a 400 is returned.
        if version is not None and e.status == 400:
            key_check = None
        else:
            module.fail_json(msg=str(e))
    if key_check:
        return True
    else:
        return False

def bucket_check(module, s3, bucket):
    try:
        result = s3.lookup(bucket)
    except s3.provider.storage_response_error, e:
        module.fail_json(msg=str(e))
    if result:
        return True
    else:
        return False

def get_bucket(module, s3, bucket):
    try:
        return s3.lookup(bucket)
    except s3.provider.storage_response_error, e:
        module.fail_json(msg=str(e))

def download_s3file(module, s3, bucket, obj, dest, retries, version=None):
    # retries is the number of loops; range/xrange needs to be one
    # more to get that count of loops.
    bucket = s3.lookup(bucket)
    key = bucket.get_key(obj, version_id=version)
    headers = {}
    mode = 'wb'
    updating = False

    # add If-Modified-Since header if target file exists
    if os.path.isfile(dest):
        mode = 'r+b'
        updating = True
        modified_since = os.path.getmtime(dest)
        timestamp = datetime.datetime.utcfromtimestamp(modified_since)
        headers['If-Modified-Since'] = timestamp.strftime("%a, %d %b %Y %H:%M:%S GMT")

    for x in range(0, retries + 1):
        try:
            with open(dest, mode) as f:
                key.get_contents_to_file(f, headers)
                f.truncate()
            return 200
        except s3.provider.storage_copy_error, e:
            module.fail_json(msg=str(e))
        except boto.exception.S3ResponseError as e:
            if not updating:
                # delete the file that was created due to mode = 'wb'
                os.remove(dest)
            return e.status
        except SSLError as e:
            if x >= retries:
                module.fail_json(msg="s3 download failed; %s" % e)
            pass


#            key.get_contents_to_filename(dest)
#            module.exit_json(msg="GET operation complete", changed=True)
#        except s3.provider.storage_copy_error, e:
#            module.fail_json(msg= str(e))
#        except SSLError as e:
#            # actually fail on last pass through the loop.
#            if x >= retries:
#                module.fail_json(msg="s3 download failed; %s" % e)
#            # otherwise, try again, this may be a transient timeout.
#            pass


def install_package(module, package_path, dest_dir):

    state_file = os.path.join(dest_dir, STATE_FILENAME)

    # cleanup if state exists
    if os.path.exists(state_file):

        # read last state file
        with open(state_file, 'r') as f:
            package_info = json.load(f)

        # delete previously installed files
        for filename in package_info['content']:
            os.remove(os.path.join(dest_dir, filename))
        os.remove(state_file)

    # extract package (including directory structure)
    #with zipfile.ZipFile(package_path) as z:
    #    z.extractall(dest_dir)

    # detect package type
    app_type = mimetypes.guess_type(package_path)[0]

    # extract package
    # removing subdirectories for convenience and safety
    package_filelist = []

    if "zip" in app_type:
        with zipfile.ZipFile(package_path) as zip_file:
            for member in zip_file.namelist():
                filename = os.path.basename(member)
                # skip directories
                if not filename:
                    continue

                # copy file (taken from zipfile's extract)
                source = zip_file.open(member)
                target = file(os.path.join(dest_dir, filename), "wb")
                with source, target:
                    shutil.copyfileobj(source, target)
                package_filelist.append(filename)

    elif app_type == 'application/x-tar':
        with tarfile.open(package_path, 'r') as tar_file:
            for member in tar_file.getmembers():
                if member.isreg():
                    member.name = os.path.basename(member.name)
                    tar_file.extract(member, dest_dir)
                    package_filelist.append(member.name)

    else:
        module.fail_json(msg='mime type ' + app_type + " for " + package_path + " not implemented")

    # build package info
    package_info = {
        'package': os.path.basename(package_path),
        'content': package_filelist
    }

    # write package info to state file
    with open(state_file, 'w') as f:
        json.dump(package_info, f, indent=2)


def main():
    argument_spec = ec2_argument_spec()
    argument_spec.update(dict(
        bucket         = dict(required=True),
        object         = dict(),
        version        = dict(default=None),
        dest           = dict(default=None),
        retries        = dict(aliases=['retry'], type='int', default=0),
        cache          = dict(required=False, default='/tmp'),
    ))
    module = AnsibleModule(argument_spec=argument_spec)

    if not HAS_BOTO:
        module.fail_json(msg='boto required for this module')

    bucket = module.params.get('bucket')
    if module.params.get('dest'):
        dest = os.path.expanduser(module.params.get('dest'))
    obj = module.params.get('object')
    if module.params.get('cache'):
        cache = os.path.expanduser(module.params.get('cache'))
    version = module.params.get('version')
    retries = module.params.get('retries')

    region, ec2_url, aws_connect_kwargs = get_aws_connection_info(module)

    if region in ('us-east-1', '', None):
        # S3ism for the US Standard region
        location = Location.DEFAULT
    else:
        # Boto uses symbolic names for locations but region strings will
        # actually work fine for everything except us-east-1 (US Standard)
        location = region

    # bucket names with .'s in them need to use the calling_format option,
    # otherwise the connection will fail. See https://github.com/boto/boto/issues/2836
    # for more details.
    if '.' in bucket:
        aws_connect_kwargs['calling_format'] = OrdinaryCallingFormat()

    try:
        aws_connect_kwargs['is_secure'] = True
        s3 = connect_to_aws(boto.s3, location, **aws_connect_kwargs)
        # use this as fallback because connect_to_region seems to fail
        # in boto + non 'classic' aws accounts in some cases
        if s3 is None:
            s3 = boto.connect_s3(**aws_connect_kwargs)

    except boto.exception.NoAuthHandlerFound, e:
        module.fail_json(msg='No Authentication Handler found: %s ' % str(e))
    except Exception, e:
        module.fail_json(msg='Failed to connect to S3: %s' % str(e))

    if s3 is None: # this should never happen
        module.fail_json(msg='Unknown error, failed to create s3 connection, no information from boto.')

    # First, we check to see if the bucket exists, we get "bucket" returned.
    bucketrtn = bucket_check(module, s3, bucket)
    if bucketrtn is False:
        module.fail_json(msg="Source bucket cannot be found", failed=True)

    # Next, we check to see if the key in the bucket exists. If it exists, it also returns key_matches md5sum check.
    keyrtn = key_check(module, s3, bucket, obj, version=version)
    if keyrtn is False:
        module.fail_json(msg="Key %s does not exist."%obj, failed=True)

    object_filename = os.path.basename(obj)
    cache_location = os.path.join(cache, object_filename)
    sc = download_s3file(module, s3, bucket, obj, cache_location, retries, version=version)

    if sc == 304:

        # Not Modified:
        # The package already exists in cache
        # but the object might have changed (e.g. fallback)
        state_file = os.path.join(dest, STATE_FILENAME)
        if os.path.exists(state_file):
            with open(state_file, 'r') as f:
                package_info = json.load(f)

            if package_info is None or package_info['package'] != object_filename:
                install_package(module, cache_location, dest)
                module.exit_json(msg="Package %s different from %s and reinstalled from cache" % ( object_filename, package_info['package']), failed=False, changed=True)
            else:
                module.exit_json(msg="Package %s already installed" % object_filename, failed=False, changed=False)

        else:
            install_package(module, cache_location, dest)
            module.exit_json(msg="Package %s was installed from cache" % object_filename, failed=False, changed=True)


    if sc == 200:

        # The package was downloaded successfully
        install_package(module, cache_location, dest)
        module.exit_json(msg="Package %s was downloaded and installed" % object_filename, failed=False, changed=True)

    module.exit_json(msg="Unexpected status code %d when retrieving %s" % (sc, object_filename), failed=True, changed=False)


# import module snippets
from ansible.module_utils.basic import *
from ansible.module_utils.ec2 import *

main()
