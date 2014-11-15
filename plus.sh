#!/bin/bash
# Build script for plus release

# ccache variables
#export USE_CCACHE=1
#export CCACHE_DIR=/home/mustaavalkosta/storage/ccache-3.1.9

# Cron doesn't get this without exporting it here.
export USER=mustaavalkosta

# Release name
RELEASE_NAME="M11Plus"

# Android source tree root
SOURCE_ROOT=/home/mustaavalkosta/storage/cm_release

build()
{
    # Device
    local DEVICE=$1

    # Local dirs on codefi.re server
    local LOCAL_DIR=/home/mustaavalkosta/downloads/cm-11-unofficial-$DEVICE/plus/
    if [ "$DEVICE" = "ace" ]
    then
        local LOCAL_EXTRAS_DIR=/home/mustaavalkosta/downloads/cm-11-unofficial-$DEVICE/extras/
    fi

    # Remote dirs on goo.im server
    local REMOTE_DIR=/home/Mustaavalkosta/public_html/cm-11-unofficial-$DEVICE/plus/
    if [ "$DEVICE" = "ace" ]
    then
        local REMOTE_EXTRAS_DIR=/home/Mustaavalkosta/public_html/cm-11-unofficial-$DEVICE/extras/
    fi

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
    TARGET_UNOFFICIAL_BUILD_ID="$RELEASE_NAME" mka bacon

    # Check for build fail
    if [ $? -eq 0 ]
    then
        cp -v $SOURCE_ROOT/out/target/product/ace/cm-11-*-UNOFFICIAL-$RELEASE_NAME-ace.zip* $LOCAL_DIR
        make clean
        cd $SOURCE_ROOT
    else
        echo "##############################################################"
        echo "##                        BUILD FAILED                      ##"
        echo "##############################################################"
        exit 0
    fi

    # Basketbuild
    bash /home/mustaavalkosta/storage/build_scripts/basketbuild.sh $DEVICE

    # Sync with goo.im
    rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' --exclude '.cm-11-*' $LOCAL_DIR Mustaavalkosta@upload.goo.im:$REMOTE_DIR
    if [ "$DEVICE" = "ace" ]
    then
        rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' $LOCAL_EXTRAS_DIR Mustaavalkosta@upload.goo.im:$REMOTE_EXTRAS_DIR
    fi
}

# Build ace
build "ace"

# Build saga
#build "saga"
