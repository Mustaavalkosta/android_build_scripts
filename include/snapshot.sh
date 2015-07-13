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
    local DEVICE="$1"

    # Local dirs on codefi.re server
    local PROJECT_DIR="cm-$(echo $CM_VERSION |tr . -)-unofficial-$DEVICE"

    # Run build
    cd "$SOURCE_ROOT"
    repo sync local_manifest # update manifest to bring in manifest changes first
    repo sync -j8 -d
    REVISION_TIMESTAMP=$(date -u +"%Y-%m-%d %R %Z")
    source build/envsetup.sh
    lunch cm_$DEVICE-userdebug
    make clean
    TARGET_UNOFFICIAL_BUILD_ID="$RELEASE_NAME" mka bacon

    # Check for build fail
    if [ $? -eq 0 ]
    then
        cp -v "$SOURCE_ROOT"/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$RELEASE_NAME-$DEVICE.zip* "$LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/"

        ZIPNAME=`find $SOURCE_ROOT/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$RELEASE_NAME-$DEVICE.zip -exec basename {} .zip \;`

        if [ -d "$LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/revisions/" ]
        then
            LAST_REVISIONS=`find $LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/revisions/ -maxdepth 1 -type f | sort | tail -n 1`
            if [ ! -z "$LAST_REVISIONS" ]
            then
                NEW_REVISIONS="$LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/revisions/$ZIPNAME.txt"
                CHANGELOG="$LOCAL_BASE_DIR/$PROJECT_DIR/snapshots/changelogs/$ZIPNAME.changelog"
                generate_changelog "$LAST_REVISIONS" "$NEW_REVISIONS" "$CHANGELOG" "$REVISION_TIMESTAMP"
            fi
        fi

        make clean
    else
        echo "##############################################################"
        echo "##                        BUILD FAILED                      ##"
        echo "##############################################################"
        exit 0
    fi

    # Sync with opendesireproject.org
    rsync -avvruO -e ssh --delete --timeout=600 "$LOCAL_BASE_DIR/$PROJECT_DIR" "mustaavalkosta@opendesireproject.org:~/dl.opendesireproject.org/www/"
    ssh mustaavalkosta@opendesireproject.org 'cd ~/ota-scanner/ && python scanner.py'

    # Basketbuild
    sync_basketbuild "$LOCAL_BASE_DIR/$PROJECT_DIR/" "/$PROJECT_DIR"
}
