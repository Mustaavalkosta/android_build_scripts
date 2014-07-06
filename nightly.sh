#!/bin/bash
export USE_CCACHE=1
export CCACHE_DIR=/home/mustaavalkosta/storage/ccache-3.1.9
export USER=mustaavalkosta

SOURCE_ROOT=/home/mustaavalkosta/storage/cm_nightly

## Regular nightly ##
DOWNLOAD_DIR=/home/mustaavalkosta/downloads/cm-11-unofficial-ace/nightlies/
REMOTE_DIR=/home/Mustaavalkosta/public_html/cm-11-unofficial-ace/nightlies/

cd $SOURCE_ROOT
make clean
repo sync local_manifest # update manifest to bring in manifest changes first
repo sync -j8
cd $SOURCE_ROOT/vendor/cm
./get-prebuilts
cd $SOURCE_ROOT
source build/envsetup.sh
lunch cm_ace-userdebug
mka bacon

if [ $? -eq 0 ]
then
    cp -v $SOURCE_ROOT/out/target/product/ace/cm-11-*-UNOFFICIAL-ace.zip* $DOWNLOAD_DIR
    make clean
    cd $DOWNLOAD_DIR
    rm -v `ls -t $DOWNLOAD_DIR | awk 'NR>24'`
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
