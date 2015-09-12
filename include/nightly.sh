#!/bin/bash
# Build script for nightly release

if [ -z "$CM_VERSION" ]
then
    echo "CM_VERSION not set."
    exit 0
fi

# ccache variables
#export USE_CCACHE=1
#export CCACHE_DIR=/home/mustaavalkosta/storage/ccache/$CM_VERSION

# rsync retry count
MAX_RETRIES=10

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

    # Main output dir
    local OUTPUT_DIR="$LOCAL_BASE_DIR/$PROJECT_DIR/nightlies"

    # Check if output dirs exist and create them if they don't
    if [ ! -d "$OUTPUT_DIR" ]
    then
        mkdir -p "$OUTPUT_DIR"
    fi

    if [ ! -d "$OUTPUT_DIR/revisions" ]
    then
        mkdir -p "$OUTPUT_DIR/revisions"
    fi

    if [ ! -d "$OUTPUT_DIR/changelogs" ]
    then
        mkdir -p "$OUTPUT_DIR/changelogs"
    fi

    # Run build
    cd "$SOURCE_ROOT"
    repo sync local_manifest # update manifest to bring in manifest changes first
    repo sync -j8 -d
    # Check for sync error
    if [ $? -ne 0 ]
    then
        exit 1
    fi

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
        cp -v "$SOURCE_ROOT"/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$DEVICE.zip* "$OUTPUT_DIR"

        ZIPNAME=`find $SOURCE_ROOT/out/target/product/$DEVICE/cm-$CM_VERSION-*-UNOFFICIAL-$DEVICE.zip -exec basename {} .zip \;`

        LAST_REVISIONS=`find $OUTPUT_DIR/revisions -maxdepth 1 -type f | sort | tail -n 1`
        if [ ! -z "$LAST_REVISIONS" ]
        then
            NEW_REVISIONS="$OUTPUT_DIR/revisions/$ZIPNAME.txt"
            CHANGELOG="$OUTPUT_DIR/changelogs/$ZIPNAME.changelog"
            generate_changelog "$LAST_REVISIONS" "$NEW_REVISIONS" "$CHANGELOG" "$REVISION_TIMESTAMP"
        else
            NEW_REVISIONS="$OUTPUT_DIR/revisions/$ZIPNAME.txt"
            generate_revisions "$NEW_REVISIONS" "$REVISION_TIMESTAMP"
        fi

        # Clean up
        rm -v `find $OUTPUT_DIR -maxdepth 1 -type f | sort -r | awk 'NR>14'`
        rm -v `find $OUTPUT_DIR/changelogs -maxdepth 1 -type f | sort -r | awk 'NR>7'`
        rm -v `find $OUTPUT_DIR/revisions -maxdepth 1 -type f | sort -r | awk 'NR>7'`

        make clean
    else
        echo "##############################################################"
        echo "##                        BUILD FAILED                      ##"
        echo "##############################################################"
        exit 1
    fi

    # Sync with opendesireproject.org
    i=0
    false
    while [ $? -ne 0 -a $i -lt $MAX_RETRIES ]
    do
        i=$[$i+1]
        rsync -avvruO -e ssh --delete --timeout=120 "$LOCAL_BASE_DIR/$PROJECT_DIR" "mustaavalkosta@opendesireproject.org:~/dl.opendesireproject.org/www/"
    done
    ssh mustaavalkosta@opendesireproject.org 'cd ~/ota-scanner/ && python scanner.py'

    # Basketbuild
    sync_basketbuild "$LOCAL_BASE_DIR/$PROJECT_DIR/" "/$PROJECT_DIR"
}
