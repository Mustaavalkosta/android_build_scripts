#!/bin/bash
# FTP mirror script for BasketBuild.
# Based on http://serverfault.com/questions/24622/how-to-use-rsync-over-ftp

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
LOCAL_DIR="/home/mustaavalkosta/downloads/cm-11-unofficial-ace"

# Remote dir on BasketBuild server
REMOTE_DIR="/cm-11-unofficial-ace"

# Uncomment this to delete old files
DELETE="--delete"

# Run sync between codefi.re and BasketBuild using lftp
lftp -c "set ftp:list-options -a;
open '$FTPURL';
lcd $LOCAL_DIR;
cd $REMOTE_DIR;
mirror --reverse \
	$DELETE \
	--use-cache \
	--parallel=2 \
	--verbose \
	--exclude-glob *.md5sum"
