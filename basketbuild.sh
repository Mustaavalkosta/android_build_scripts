#!/bin/bash
# FTP mirror script for BasketBuild.
# Based on http://serverfault.com/questions/24622/how-to-use-rsync-over-ftp

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
    echo "Usage: `basename $0` [device name] [local path] [remote path]"
    exit 0
fi

# Device
DEVICE=$1

# File format:
# USERNAME:PASSWORD
BASKET_PASSWD_FILE="/home/mustaavalkosta/storage/build_scripts/.basket_passwd"

# BasketBuild FTP address
HOST="s.basketbuild.com"

# Login information
USER=`awk -F':' '{ print $1 }' $BASKET_PASSWD_FILE`
PASS=`awk -F':' '{ print $2 }' $BASKET_PASSWD_FILE`

# Full URL for FTP connection
FTPURL="ftp://$USER:$PASS@$HOST"

# Local dir on codefi.re server
LOCAL_DIR=$2

# Remote dir on BasketBuild server
REMOTE_DIR=$3

# Uncomment this to delete old files
DELETE="--delete"

# Run sync between codefi.re and BasketBuild using lftp
lftp -c "set ftp:list-options -a;
set ftp:passive-mode off;
set net:reconnect-interval-base 5;
set net:max-retries 2;
set cmd:fail-exit true;
open '$FTPURL';
lcd $LOCAL_DIR;
cd $REMOTE_DIR;
mirror --reverse \
	$DELETE \
	--use-cache \
	--parallel=2 \
	--verbose \
	--exclude-glob *.md5sum"
