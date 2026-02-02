MODPATH=${0%/*}

# log
LOGFILE=$MODPATH/debug.log
exec 2>$LOGFILE
set -x

# var
API=`getprop ro.build.version.sdk`
if [ ! -d $MODPATH/vendor ]\
|| [ -L $MODPATH/vendor ]; then
  MODSYSTEM=/system
fi

# property
resetprop -n ro.audio.ignore_effects false
resetprop -n ro.build.product ZS630KL
resetprop -n ro.product.model ASUS_I01WD
#resetprop -n ro.product.name WW_I01WD
resetprop -n ro.build.asus.sku WW
resetprop -n ro.dts.licensepath /vendor/etc/dts/
resetprop -n ro.dts.cfgpath /vendor/etc/dts/
resetprop -n ro.vendor.dts.licensepath /vendor/etc/dts/
resetprop -n ro.vendor.dts.cfgpath /vendor/etc/dts/
resetprop -n audio.wizard.default.mode smart
resetprop -n ro.asus.audio.dualSPK true
resetprop -n ro.asus.aw.settingentry 1
resetprop -n ro.asus.dts.headphone.default_enable false
resetprop -n ro.asus.audiowizard.outdoor 1
resetprop -n ro.asus.audio.realStereo true
resetprop -n ro.product.lge.globaleffect.dts false
resetprop -n ro.lge.globaleffect.dts false
resetprop -n ro.odm.config.dts_licensepath /vendor/etc/dts/
#resetprop -n vendor.dts.audio.dump_input false
#resetprop -n vendor.dts.audio.dump_output false
#resetprop -n vendor.dts.audio.dump_driver false
#resetprop -n vendor.dts.audio.skip_shadow false
#resetprop -n vendor.dts.audio.set_bypass false
#resetprop -n vendor.dts.audio.log_time false
#resetprop -n vendor.dts.audio.dump_initial false
#resetprop -n vendor.dts.audio.dump_eagle false
#resetprop -n vendor.dts.audio.allow_offload false
#resetprop -n vendor.dts.audio.print_eagle false
#resetprop -n vendor.dts.audio.disable_undoredo false
#resetprop -n ro.config.versatility ID
#resetprop -n ro.config.versatility IN
resetprop -n persist.asus.aw.ivt 50
resetprop -p --delete persist.asus.aw.forceToGetDevices
resetprop -p --delete persist.asus.stop.audio_wizard_service
PROP=`getprop persist.sys.cta.security`
if [ ! "$PROP" ]; then
  resetprop -n persist.sys.cta.security 0
fi

# restart
if [ "$API" -ge 24 ]; then
  SERVER=audioserver
else
  SERVER=mediaserver
fi
killall $SERVER\
 android.hardware.audio@4.0-service-mediatek\
 android.hardware.audio.service

# wait
sleep 20

# aml fix
AML=/data/adb/modules/aml
DIR=$AML$MODSYSTEM/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi
AUD=`grep AUD= $MODPATH/copy.sh | sed -e 's|AUD=||g' -e 's|"||g'`
DIR=$AML$MODSYSTEM/vendor
FILES=`find $DIR -type f -name $AUD`
if [ -d $AML ] && [ ! -f $AML/disable ]\
&& find $DIR -type f -name $AUD; then
  if ! grep '/odm' $AML/post-fs-data.sh && [ -d /odm ]\
  && [ "`realpath /odm/etc`" == /odm/etc ]; then
    for FILE in $FILES; do
      DES=/odm`echo $FILE | sed "s|$DIR||g"`
      if [ -f $DES ]; then
        umount $DES
        mount -o bind $FILE $DES
      fi
    done
  fi
  if ! grep '/my_product' $AML/post-fs-data.sh\
  && [ -d /my_product ]; then
    for FILE in $FILES; do
      DES=/my_product`echo $FILE | sed "s|$DIR||g"`
      if [ -f $DES ]; then
        umount $DES
        mount -o bind $FILE $DES
      fi
    done
  fi
fi

# wait
until [ "`getprop sys.boot_completed`" == 1 ]; do
  sleep 10
done

# list
PKGS="`cat $MODPATH/package.txt`
       com.asus.audiowizard"
for PKG in $PKGS; do
  magisk --denylist rm $PKG 2>/dev/null
  magisk --sulist add $PKG 2>/dev/null
done
if magisk magiskhide sulist; then
  for PKG in $PKGS; do
    magisk magiskhide add $PKG
  done
else
  for PKG in $PKGS; do
    magisk magiskhide rm $PKG
  done
fi

# settings
SET=system_theme_type
VAL=`settings get system $SET`
if [ "$VAL" != 1 ]; then
  settings put system $SET 1
fi

# grant
PKG=com.asus.maxxaudio.audiowizard
if appops get $PKG > /dev/null 2>&1; then
  pm grant --all-permissions $PKG
  if [ "$API" -ge 33 ]; then
    appops set $PKG ACCESS_RESTRICTED_SETTINGS allow
  fi
  if [ "$API" -ge 30 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
  PKGOPS=`appops get $PKG`
  UID=`dumpsys package $PKG 2>/dev/null | grep -m 1 Id= | sed -e 's|    userId=||g' -e 's|    appId=||g'`
  if [ "$UID" ] && [ "$UID" -gt 9999 ]; then
    UIDOPS=`appops get --uid "$UID"`
  fi
fi

# grant
PKG=com.dts.dtsxultra
if appops get $PKG > /dev/null 2>&1; then
  pm grant --all-permissions $PKG
  if [ "$API" -ge 33 ]; then
    appops set $PKG ACCESS_RESTRICTED_SETTINGS allow
  fi
  if [ "$API" -ge 30 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
  PKGOPS=`appops get $PKG`
  UID=`dumpsys package $PKG 2>/dev/null | grep -m 1 Id= | sed -e 's|    userId=||g' -e 's|    appId=||g'`
  if [ "$UID" ] && [ "$UID" -gt 9999 ]; then
    UIDOPS=`appops get --uid "$UID"`
  fi
fi

# grant
PKG=com.asus.maxxaudio
if appops get $PKG > /dev/null 2>&1; then
  pm grant --all-permissions $PKG
  appops set $PKG WRITE_SETTINGS allow
  if [ "$API" -ge 30 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
  PKGOPS=`appops get $PKG`
  UID=`dumpsys package $PKG 2>/dev/null | grep -m 1 Id= | sed -e 's|    userId=||g' -e 's|    appId=||g'`
  if [ "$UID" ] && [ "$UID" -gt 9999 ]; then
    UIDOPS=`appops get --uid "$UID"`
  fi
fi

# function
stop_log() {
SIZE=`du $LOGFILE | sed "s|$LOGFILE||g"`
if [ "$LOG" != stopped ] && [ "$SIZE" -gt 50 ]; then
  exec 2>/dev/null
  set +x
  LOG=stopped
fi
}
check_audioserver() {
if [ "$NEXTPID" ]; then
  PID=$NEXTPID
else
  PID=`pidof $SERVER`
fi
sleep 15
stop_log
NEXTPID=`pidof $SERVER`
[ "$PID" != "$NEXTPID" ] && killall $PROC
check_audioserver
}

# check
PROC=com.asus.audiowizard
killall $PROC
check_audioserver









