MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

# debug
exec 2>$MODPATH/debug.log
set -x

# property
resetprop ro.build.product ZS630KL
resetprop ro.product.model ASUS_I01WD
#resetprop ro.product.name WW_I01WD
resetprop ro.build.asus.sku WW
resetprop ro.dts.licensepath /vendor/etc/dts/
resetprop ro.dts.cfgpath /vendor/etc/dts/
resetprop ro.vendor.dts.licensepath /vendor/etc/dts/
resetprop ro.vendor.dts.cfgpath /vendor/etc/dts/
resetprop audio.wizard.default.mode smart
resetprop ro.asus.audio.dualSPK true
resetprop ro.asus.aw.settingentry 1
resetprop ro.asus.dts.headphone.default_enable false
resetprop ro.asus.audiowizard.outdoor 1
resetprop ro.asus.audio.realStereo true
resetprop ro.config.media_vol_steps 20
resetprop ro.product.lge.globaleffect.dts false
resetprop ro.lge.globaleffect.dts false
resetprop ro.odm.config.dts_licensepath /vendor/etc/dts/
#resetprop vendor.dts.audio.dump_input true
#resetprop vendor.dts.audio.dump_output true
#resetprop vendor.dts.audio.dump_driver true
#resetprop vendor.dts.audio.skip_shadow true
#resetprop vendor.dts.audio.set_bypass true
#resetprop vendor.dts.audio.log_time true
#resetprop vendor.dts.audio.dump_initial true
#resetprop vendor.dts.audio.dump_eagle true
#resetprop vendor.dts.audio.allow_offload true
#resetprop vendor.dts.audio.print_eagle true
#resetprop vendor.dts.audio.disable_undoredo true
#resetprop ro.config.versatility ID
#resetprop ro.config.versatility IN
resetprop -n persist.asus.aw.ivt 50
resetprop -p --delete persist.asus.aw.forceToGetDevices
resetprop -p --delete persist.asus.stop.audio_wizard_service
PROP=`getprop persist.sys.cta.security`
if ! [ "$PROP" ]; then
  resetprop -n persist.sys.cta.security 0
fi

# restart
if [ "$API" -ge 24 ]; then
  SERVER=audioserver
else
  SERVER=mediaserver
fi
PID=`pidof $SERVER`
if [ "$PID" ]; then
  killall $SERVER
fi

# wait
sleep 20

# aml fix
DIR=$AML/system/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`realpath /dev/*/.magisk`
fi

# path
MIRROR=$MAGISKTMP/mirror
SYSTEM=`realpath $MIRROR/system`
VENDOR=`realpath $MIRROR/vendor`
ODM=`realpath $MIRROR/odm`
MY_PRODUCT=`realpath $MIRROR/my_product`

# mount
NAME="*audio*effects*.conf -o -name *audio*effects*.xml -o -name *policy*.conf -o -name *policy*.xml"
if [ -d $AML ] && [ ! -f $AML/disable ]\
&& find $AML/system/vendor -type f -name $NAME; then
  NAME="*audio*effects*.conf -o -name *audio*effects*.xml"
#p  NAME="*audio*effects*.conf -o -name *audio*effects*.xml -o -name *policy*.conf -o -name *policy*.xml"
  DIR=$AML/system/vendor
else
  DIR=$MODPATH/system/vendor
fi
FILES=`find $DIR/etc -maxdepth 1 -type f -name $NAME`
if [ ! -d $ODM ] && [ "`realpath /odm/etc`" == /odm/etc ]\
&& [ "$FILES" ]; then
  for FILE in $FILES; do
    DES="/odm$(echo $FILE | sed "s|$DIR||")"
    if [ -f $DES ]; then
      umount $DES
      mount -o bind $FILE $DES
    fi
  done
fi
if [ ! -d $MY_PRODUCT ] && [ -d /my_product/etc ]\
&& [ "$FILES" ]; then
  for FILE in $FILES; do
    DES="/my_product$(echo $FILE | sed "s|$DIR||")"
    if [ -f $DES ]; then
      umount $DES
      mount -o bind $FILE $DES
    fi
  done
fi

# wait
until [ "`getprop sys.boot_completed`" == "1" ]; do
  sleep 10
done

# grant
PKG=com.asus.maxxaudio.audiowizard
if pm list packages | grep $PKG ; then
  pm grant $PKG android.permission.RECORD_AUDIO
  if [ "$API" -ge 33 ]; then
    appops set $PKG ACCESS_RESTRICTED_SETTINGS allow
  fi
  if [ "$API" -ge 30 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
fi

# grant
PKG=com.dts.dtsxultra
if pm list packages | grep $PKG ; then
  if [ "$API" -ge 33 ]; then
    pm grant $PKG android.permission.POST_NOTIFICATIONS
  fi
  if [ "$API" -ge 30 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
fi

# grant
PKG=com.asus.maxxaudio
if pm list packages | grep $PKG ; then
  pm grant $PKG android.permission.READ_EXTERNAL_STORAGE
  pm grant $PKG android.permission.WRITE_EXTERNAL_STORAGE
  pm grant $PKG android.permission.READ_PHONE_STATE
  pm grant $PKG android.permission.READ_CALL_LOG
  appops set $PKG WRITE_SETTINGS allow
  if [ "$API" -ge 30 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
fi

# function
stop_log() {
FILE=$MODPATH/debug.log
SIZE=`du $FILE | sed "s|$FILE||"`
if [ "$LOG" != stopped ] && [ "$SIZE" -gt 50 ]; then
  exec 2>/dev/null
  LOG=stopped
fi
}
check_audioserver() {
if [ "$NEXTPID" ]; then
  PID=$NEXTPID
else
  PID=`pidof $SERVER`
fi
sleep 10
stop_log
NEXTPID=`pidof $SERVER`
if [ "`getprop init.svc.$SERVER`" != stopped ]; then
  until [ "$PID" != "$NEXTPID" ]; do
    check_audioserver
  done
  killall $PROC
  check_audioserver
else
  start $SERVER
  check_audioserver
fi
}

# check
PROC="com.asus.audiowizard com.asus.maxxaudio.audiowizard com.dts.dtsxultra"
killall $PROC
check_audioserver









