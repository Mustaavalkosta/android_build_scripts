#!/bin/bash
# Build script for nightly release

if [ -z "$CM_VERSION" ]
then
    echo "CM_VERSION not set."
    exit 0
fi

# ccache variables
export USE_CCACHE=1
export CCACHE_DIR=/home/mustaavalkosta/storage/ccache/$CM_VERSION

# Android source tree root
SOURCE_ROOT=/home/mustaavalkosta/storage/cm/$CM_VERSION/nightly

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
    repo sync -j8
    REVISION_TIMESTAMP="$(date -u +"%Y-%m-%d %R %Z")"
    # Run get-prebuilts only for CM11
    if [ "$CM_VERSION" == "11" ]
    then
        cd "$SOURCE_ROOT/vendor/cm"
        ./get-prebuilts
        cd "$SOURCE_ROOT"
    fi
    source build/envsetup.sh
    lunch cm_$DEVICE-userdebug
    make clean
    mka bacon

    # Check for build fail
    if [ $? -eq 0 ]
    then
        cp -v "$SOURCE_ROOT"/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$DEVICE.zip* "$LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/"

        ZIPNAME=`find $SOURCE_ROOT/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$DEVICE.zip -exec basename {} .zip \;`

        if [ -d "$LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/revisions/" ]
        then
            LAST_REVISIONS=`find $LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/revisions/ -maxdepth 1 -type f | sort | tail -n 1`
            if [ ! -z "$LAST_REVISIONS" ]
            then
                NEW_REVISIONS="$LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/revisions/$ZIPNAME.txt"
                CHANGELOG="$LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/changelogs/$ZIPNAME.changelog"
                generate_changelog "$LAST_REVISIONS" "$NEW_REVISIONS" "$CHANGELOG" "$REVISION_TIMESTAMP"
            fi
        fi

        # Clean up
        rm -v `find $LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/ -maxdepth 1 -type f | sort -r | awk 'NR>14'`
        rm -v `find $LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/changelogs/ -maxdepth 1 -type f | sort -r | awk 'NR>7'`
        rm -v `find $LOCAL_BASE_DIR/$PROJECT_DIR/nightlies/revisions/ -maxdepth 1 -type f | sort -r | awk 'NR>7'`

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
        rsync -avvruO -e ssh --delete --timeout=60 "$LOCAL_BASE_DIR/$PROJECT_DIR" "mustaavalkosta@opendesireproject.org:~/dl.opendesireproject.org/www/"
        ssh mustaavalkosta@opendesireproject.org 'cd ~/ota-scanner/ && python scanner.py'
    fi

    # Basketbuild
    sync_basketbuild "$LOCAL_BASE_DIR/$PROJECT_DIR/" "/$PROJECT_DIR"

    # Sync with goo.im
    rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' --exclude '.cm-11-*' "$LOCAL_BASE_DIR/$PROJECT_DIR" "Mustaavalkosta@upload.goo.im:~/public_html/"
}
