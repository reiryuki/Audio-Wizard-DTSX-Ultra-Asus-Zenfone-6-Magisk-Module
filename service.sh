(

MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

# debug
exec 2>$MODPATH/debug.log
set -x

# prevent soft reboot
echo 0 > /proc/sys/kernel/panic
echo 0 > /proc/sys/kernel/panic_on_oops
echo 0 > /proc/sys/kernel/panic_on_rcu_stall
echo 0 > /proc/sys/kernel/panic_on_warn
echo 0 > /proc/sys/vm/panic_on_oom

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
#resetprop -n persist.asus.aw.ivt 10000
resetprop -p --delete persist.asus.aw.forceToGetDevices
resetprop -p --delete persist.asus.stop.audio_wizard_service
PROP=`getprop persist.sys.cta.security`
if ! [ "$PROP" ]; then
  resetprop -n persist.sys.cta.security 0
fi

# restart
killall audioserver

# wait
sleep 20

# mount
NAME="*audio*effects*.conf -o -name *audio*effects*.xml -o -name *policy*.conf -o -name *policy*.xml"
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system/vendor
else
  DIR=$AML/system/vendor
fi
FILE=`find $DIR/odm/etc -maxdepth 1 -type f -name $NAME`
if [ "`realpath /odm/etc`" != /vendor/odm/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="$(echo $i | sed "s|$DIR||")"
    umount $j
    mount -o bind $i $j
  done
  killall audioserver
fi
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system
else
  DIR=$AML/system
fi
FILE=`find $DIR/etc -maxdepth 1 -type f -name $NAME`
if [ -d /my_product/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="$(echo $i | sed "s|$DIR||")"
    umount /my_product$j
    mount -o bind $i /my_product$j
  done
  killall audioserver
fi

# wait
sleep 40

# grant
PKG=com.asus.maxxaudio
if pm list packages | grep $PKG ; then
  pm grant $PKG android.permission.READ_EXTERNAL_STORAGE
  pm grant $PKG android.permission.WRITE_EXTERNAL_STORAGE
  pm grant $PKG android.permission.READ_PHONE_STATE
  pm grant $PKG android.permission.READ_CALL_LOG
  appops set $PKG WRITE_SETTINGS allow
  if [ "$API" -gt 29 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
  PKG=com.asus.audiowizard
  PID=`pidof $PKG`
  if [ $PID ]; then
    echo -17 > /proc/$PID/oom_adj
    echo -1000 > /proc/$PID/oom_score_adj
  fi
fi

# grant
PKG=com.asus.maxxaudio.audiowizard
if pm list packages | grep $PKG ; then
  pm grant $PKG android.permission.RECORD_AUDIO
  if [ "$API" -gt 29 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
fi

# grant
PKG=com.dts.dtsxultra
if pm list packages | grep $PKG ; then
  pm grant $PKG android.permission.READ_EXTERNAL_STORAGE
  pm grant $PKG android.permission.WRITE_EXTERNAL_STORAGE
  pm grant $PKG android.permission.ACCESS_MEDIA_LOCATION
  if [ "$API" -gt 29 ]; then
    appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
  fi
fi

) 2>/dev/null


