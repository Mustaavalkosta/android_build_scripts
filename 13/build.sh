#!/bin/bash
# Build script for CM 13.0

if [ -z "$1" ]
then
    echo "Insufficient parameters. Usage: `basename $0` [nightly|snapshot]"
    exit 0
fi

# Base dir for this script mess
SCRIPT_DIR="/home/mustaavalkosta/storage/build_scripts"

# Cron doesn't get this without exporting it here.
export USER=mustaavalkosta

# Hack for missing libatomic.so.1
export LD_LIBRARY_PATH=/mnt/nfs-fs1-nfshomes_storage/mustaavalkosta/cm/13.0/nightly/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8/x86_64-linux/lib64/

# CM version
CM_VERSION="13.0"

# Release name for release build
RELEASE_NAME=""

# Base path for downloads
LOCAL_BASE_DIR=/home/mustaavalkosta/downloads

# Max nightlies to keep on the server
MAX_NIGHTLIES=7

# Basketbuild login information
# File format:
# USERNAME:PASSWORD
BASKET_PASSWD_FILE="$SCRIPT_DIR/.basket_passwd"

source "$SCRIPT_DIR/include/basketbuild.sh"
source "$SCRIPT_DIR/include/changelog.sh"

if [ "$1" == "nightly" ]
then
    source "$SCRIPT_DIR/include/nightly.sh"
    build "aceopt"
    build "sagaopt"
elif [ "$1" == "snapshot" ]
then
    source "$SCRIPT_DIR/include/snapshot.sh"
    build "aceopt"
    build "sagaopt"
else
    echo "Invalid release type"
    exit 0
fi

