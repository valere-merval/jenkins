#!/bin/bash -e

# init some defaults
APPLICATION_NAME=nvsbibe
SUBSYSTEM=app
BUCKET_FOLDER=install/plays
SUFFIX=tgz
PATCH_VERSION=0

function abort() {
    echo $1
    exit 1
}

# get bucket name from CloudFormation exports
echo -n "Detecting bucket name... "
BUCKET_NAME=$(aws cloudformation list-exports --query 'Exports[?Name==`nvs-common-infra-NvsBucket`].[Value]' --output text)
echo $BUCKET_NAME

# identify current branch name
echo -n "Detecting branch name... "
GIT_SYM_REF=$(git symbolic-ref HEAD 2>/dev/null)
BRANCH_NAME=${GIT_SYM_REF##refs/heads/}
echo $BRANCH_NAME

# check if we are on a release branch
if [[ $BRANCH_NAME == release* ]]; then
    # we are working on a release branch and force a clean, tagged environment
    echo -n "Release branch found, checking workspace... "
    git fetch
    git diff --exit-code > /dev/null || abort "found locally modified files"
    git diff --staged --exit-code > /dev/null || abort "found locally modified files in index"
    echo "done"

    # git tag for current commit
    echo -n "Searching tags for current commit... "
    TAG=$(git describe --tags --exact-match 2>/dev/null)
    if [ -z "$TAG" ]; then
        abort "no tags found"
    else
        echo "done"
    fi
    PACKAGE_NAME=${APPLICATION_NAME}-${SUBSYSTEM}-${TAG}.${SUFFIX}
else
    # create a packaged named by BRANCH_NAME
    PACKAGE_NAME=${APPLICATION_NAME}-${SUBSYSTEM}-${BRANCH_NAME}.${SUFFIX}
fi

echo -n "Creating package ${PACKAGE_NAME}... "
tar czf $PACKAGE_NAME -T dist.filelist
echo "done"

echo "Uploading package... "
aws s3 cp $PACKAGE_NAME s3://${BUCKET_NAME}/${BUCKET_FOLDER}/${PACKAGE_NAME}

exit

# set package name prefix
PACKAGE_NAME_PREFIX=${APPLICATION_NAME}-${SUBSYSTEM}-${RELEASE}-

# identify existing versions on the bucket
LATEST_PACKAGE=$(aws s3 ls s3://$BUCKET_NAME/$BUCKET_FOLDER/$PACKAGE_NAME_PREFIX | sed 's/.* //' | sort -n -k1.$(expr ${#PACKAGE_NAME_PREFIX} + 1) | tail -1)
echo $LATEST_PACKAGE
TMP=${LATEST_PACKAGE#$PACKAGE_NAME_PREFIX}
echo $TMP
VERSION=${TMP%.$SUFFIX}
echo $VERSION

# increment version
VERSION=$(expr $VERSION + 1)
PACKAGE_NAME=${PACKAGE_NAME_PREFIX}$VERSION.${SUFFIX}
echo "Packing to $PACKAGE_NAME"
