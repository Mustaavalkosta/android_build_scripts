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
SOURCE_ROOT=/home/mustaavalkosta/storage/cm/$CM_VERSION/release

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
    local PROJECT_DIR=cm-$CM_VERSION-unofficial-$DEVICE/

    # Run build
    cd $SOURCE_ROOT
    repo sync local_manifest # update manifest to bring in manifest changes first
    repo sync -j8
    cd $SOURCE_ROOT/vendor/cm
    ./get-prebuilts
    cd $SOURCE_ROOT
    source build/envsetup.sh
    lunch cm_$DEVICE-userdebug
    make clean
    TARGET_UNOFFICIAL_BUILD_ID="$RELEASE_NAME" mka bacon

    # Check for build fail
    if [ $? -eq 0 ]
    then
        cp -v $SOURCE_ROOT/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$RELEASE_NAME-$DEVICE.zip* $LOCAL_BASE_DIR/$PROJECT_DIR/releases/
        make clean
    else
        echo "##############################################################"
        echo "##                        BUILD FAILED                      ##"
        echo "##############################################################"
        exit 0
    fi

    # Sync with opendesireproject.org
    if [ "$DEVICE" = "ace" ] && [ "$CM_VERSION" != "11" ]
    then
        rsync -avvruO -e ssh --delete --timeout=60 $LOCAL_BASE_DIR/$PROJECT_DIR mustaavalkosta@opendesireproject.org:~/downloads/$PROJECT_DIR
    fi

    # Basketbuild
    sync_basketbuild $LOCAL_BASE_DIR/$PROJECT_DIR /$PROJECT_DIR

    # Sync with goo.im
    rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' --exclude '.cm-11-*' $LOCAL_BASE_DIR/$PROJECT_DIR Mustaavalkosta@upload.goo.im:~/public_html/$PROJECT_DIR
}
