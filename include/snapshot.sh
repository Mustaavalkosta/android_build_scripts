#!/bin/bash
# Build script for M release

# ccache variables
#export USE_CCACHE=1
#export CCACHE_DIR=/home/mustaavalkosta/storage/ccache-3.1.9

if [ -z "$CM_VERSION" ]
then
    echo "CM_VERSION is not set."
    exit 0
fi

if [ -z "$RELEASE_NAME" ]
then
    echo "RELEASE_NAME is not set."
    exit 0
fi

# Android source tree root
SOURCE_ROOT=/home/mustaavalkosta/storage/cm/$CM_VERSION/snapshot

build()
{
    if [ -z "$1" ]
    then
        echo "Insufficient parameters. Usage: $FUNCNAME [device]"
        exit 0
    fi

    # Device
    local DEVICE=$1

    # Local dirs on codefi.re server
    local PROJECT_DIR=cm-$(echo $CM_VERSION |tr . -)-unofficial-$DEVICE

    # Run build
    cd $SOURCE_ROOT
    repo sync local_manifest # update manifest to bring in manifest changes first
    repo sync -j8
    CHANGELOG_TIMESTAMP=$(date +"%Y-%m-%d %R")
    source build/envsetup.sh
    lunch cm_$DEVICE-userdebug
    make clean
    TARGET_UNOFFICIAL_BUILD_ID="$RELEASE_NAME" mka bacon

    # Check for build fail
    if [ $? -eq 0 ]
    then
        cp -v $SOURCE_ROOT/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$RELEASE_NAME-$DEVICE.zip* $LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/

        # Create rough changelog if possible
        if [ -f $SCRIPT_DIR/timestamps/snapshot-$CM_VERSION-$DEVICE ]
        then
            SINCE=$(head -n 1 $SCRIPT_DIR/timestamps/snapshot-$CM_VERSION-$DEVICE)
            echo -e "## Changes since $SINCE $(date +%Z) ##\n" > $LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/changelogs/cm-$CM_VERSION-$(date -u +%Y%m%d)-UNOFFICIAL-$RELEASE_NAME-$DEVICE.changelog
            repo forall -pvc '
            git log --oneline --no-merges --after="'"$SINCE"'"
            ' | cat >> $LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/changelogs/cm-$CM_VERSION-$(date -u +%Y%m%d)-UNOFFICIAL-$RELEASE_NAME-$DEVICE.changelog
        fi

        # Save new timestamp
        echo $CHANGELOG_TIMESTAMP > $SCRIPT_DIR/timestamps/snapshot-$CM_VERSION-$DEVICE

        make clean
    else
        echo "##############################################################"
        echo "##                        BUILD FAILED                      ##"
        echo "##############################################################"
        exit 0
    fi

    # Sync with opendesireproject.org
    if ([ "$DEVICE" = "ace" ] || ([ "$DEVICE" = "saga" ] && [ "$CM_VERSION" = "12.1" ])) && [ "$CM_VERSION" != "11" ]
    then
        rsync -avvruO -e ssh --delete --timeout=60 $LOCAL_BASE_DIR/$PROJECT_DIR mustaavalkosta@opendesireproject.org:~/dl.opendesireproject.org/www/
        ssh mustaavalkosta@opendesireproject.org 'cd ~/ota-scanner/ && python scanner.py'
    fi

    # Basketbuild
    sync_basketbuild $LOCAL_BASE_DIR/$PROJECT_DIR/ /$PROJECT_DIR

    # Sync with goo.im
    rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' --exclude '.cm-11-*' $LOCAL_BASE_DIR/$PROJECT_DIR Mustaavalkosta@upload.goo.im:~/public_html/
}
