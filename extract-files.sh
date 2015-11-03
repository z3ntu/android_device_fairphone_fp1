#!/bin/sh

VENDOR=fp
DEVICE=FP1

BASE=../../../vendor/$VENDOR/$DEVICE/proprietary

echo "Pulling $DEVICE files..."
for FILE in `cat proprietary-files.txt | grep -v ^# | grep -v ^$`; do
DIR=`dirname $FILE`
    if [ ! -d $BASE/$DIR ]; then
mkdir -p $BASE/$DIR
    fi

adb pull /system/$FILE $BASE/$FILE
done

# Pull extra stuff from FP OS
adb pull /system/lib/hw/audio_policy.default.so $BASE/lib/hw/audio_policy.mt6589.so
adb pull /system/lib/hw/libaudio.primary.default.so $BASE/lib/hw/audio.primary.mt6589.so
adb pull /system/lib/hw/audio.primary.default.so $BASE/lib/hw/audio.primary.mt6589.so

# Pull extra stuff from CM installations
adb pull /system/lib/hw/audio.primary.mt6589.so $BASE/lib/hw/audio.primary.mt6589.so

./setup-makefiles.sh
