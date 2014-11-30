#!/bin/bash
# Build script for nightly release

# ccache variables
export USE_CCACHE=1
export CCACHE_DIR=/home/mustaavalkosta/storage/ccache-3.1.9

# Cron doesn't get this without exporting it here.
export USER=mustaavalkosta

# Android source tree root
SOURCE_ROOT=/home/mustaavalkosta/storage/cm_nightly

# CM version, eg. 11
CM_VERSION=11

# Base path for downloads
LOCAL_BASE_DIR=/home/mustaavalkosta/downloads

build()
{
    # Device
    local DEVICE=$1

    # Local dirs on codefi.re server
    local PROJECT_DIR=cm-$CM_VERSION-unofficial-$DEVICE/

    # Run build
    cd $SOURCE_ROOT
    make clean
    repo sync local_manifest # update manifest to bring in manifest changes first
    repo sync -j8
    cd $SOURCE_ROOT/vendor/cm
    ./get-prebuilts
    cd $SOURCE_ROOT
    source build/envsetup.sh
    lunch cm_$DEVICE-userdebug
    mka bacon

    # Check for build fail
    if [ $? -eq 0 ]
    then
        cp -v $SOURCE_ROOT/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$DEVICE.zip* $LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/
        make clean
        cd $LOCAL_BASE_DIR/$PROJECT_DIR
        rm -v `ls -t $LOCAL_BASE_DIR/$PROJECT_DIR | awk 'NR>24'`
        cd $SOURCE_ROOT
    else
        echo "##############################################################"
        echo "##                        BUILD FAILED                      ##"
        echo "##############################################################"
        exit 0
    fi

    # Sync with beard.ovh
    if [ "$DEVICE" = "ace" ]
    then
        rsync -avvruO -e ssh --delete --timeout=60 $LOCAL_BASE_DIR/$PROJECT_DIR mustaavalkosta@beard.ovh:~/downloads/$PROJECT_DIR
    fi

    # Basketbuild
    bash /home/mustaavalkosta/storage/build_scripts/basketbuild.sh $LOCAL_BASE_DIR/$PROJECT_DIR /$PROJECT_DIR

    # Sync with goo.im
    rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' --exclude '.cm-11-*' $LOCAL_BASE_DIR/$PROJECT_DIR Mustaavalkosta@upload.goo.im:~/public_html/$PROJECT_DIR
}

# Build ace
build "ace"

# Build saga
build "saga"
