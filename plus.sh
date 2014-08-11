#!/bin/bash
# Build script for plus release

# ccache variables
#export USE_CCACHE=1
#export CCACHE_DIR=/home/mustaavalkosta/storage/ccache-3.1.9

# Cron doesn't get this without exporting it here.
export USER=mustaavalkosta

# Release name
RELEASE_NAME="M9Plus"

# Android source tree root
SOURCE_ROOT=/home/mustaavalkosta/storage/cm_release

# Local dirs on codefi.re server
LOCAL_DIR=/home/mustaavalkosta/downloads/cm-11-unofficial-ace/plus/
LOCAL_EXTRAS_DIR=/home/mustaavalkosta/downloads/cm-11-unofficial-ace/extras/

# Remote dirs on goo.im server
REMOTE_DIR=/home/Mustaavalkosta/public_html/cm-11-unofficial-ace/plus/
REMOTE_EXTRAS_DIR=/home/Mustaavalkosta/public_html/cm-11-unofficial-ace/extras/

# Run build
cd $SOURCE_ROOT
make clean
repo sync local_manifest # update manifest to bring in manifest changes first
repo sync -j8
cd $SOURCE_ROOT/vendor/cm
./get-prebuilts
cd $SOURCE_ROOT
source build/envsetup.sh
lunch cm_ace-userdebug
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
bash /home/mustaavalkosta/storage/build_scripts/basketbuild.sh

# Sync with goo.im
rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' --exclude '.cm-11-*' $LOCAL_DIR Mustaavalkosta@upload.goo.im:$REMOTE_DIR
rsync -avvruO -e ssh --delete --timeout=60 --exclude '*.md5sum' $LOCAL_EXTRAS_DIR Mustaavalkosta@upload.goo.im:$REMOTE_EXTRAS_DIR
