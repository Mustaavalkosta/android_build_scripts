#!/bin/bash
#export USE_CCACHE=1
#export CCACHE_DIR=/home/mustaavalkosta/storage/ccache-3.1.9
export USER=mustaavalkosta

RELEASE_NAME="BR4"

SOURCE_ROOT=/home/mustaavalkosta/storage/cm_release

## Regular release ##
DOWNLOAD_DIR=/home/mustaavalkosta/downloads/cm-11-unofficial-ace/releases/
REMOTE_DIR=/home/Mustaavalkosta/public_html/cm-11-unofficial-ace/releases/

cd $SOURCE_ROOT
make clean
repo sync -j8
cd $SOURCE_ROOT/vendor/cm
./get-prebuilts
cd $SOURCE_ROOT
source build/envsetup.sh
lunch cm_ace-userdebug
TARGET_UNOFFICIAL_BUILD_ID="$RELEASE_NAME" mka bacon

if [ $? -eq 0 ]
then
    cp -v $SOURCE_ROOT/out/target/product/ace/cm-11-*-UNOFFICIAL-$RELEASE_NAME-ace.zip* $DOWNLOAD_DIR
    make clean
    cd $SOURCE_ROOT
else
    echo "##############################################################"
    echo "##                        BUILD FAILED                      ##"
    echo "##############################################################"
    exit 0
fi

rsync -avvruO -e ssh --delete --exclude '*.md5sum' --exclude '.cm-11-*' $DOWNLOAD_DIR Mustaavalkosta@upload.goo.im:$REMOTE_DIR

## Sync extras also
rsync -avvruO -e ssh --delete --exclude '*.md5sum' /home/mustaavalkosta/downloads/cm-11-unofficial-ace/extras/ Mustaavalkosta@upload.goo.im:/home/Mustaavalkosta/public_html/cm-11-unofficial-ace/extras/
