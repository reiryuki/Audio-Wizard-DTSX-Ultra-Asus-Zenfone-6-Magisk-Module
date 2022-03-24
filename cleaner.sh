PKG="com.asus.maxxaudio.audiowizard
     com.asus.maxxaudio
     com.dts.dtsxultra"
for PKGS in $PKG; do
  rm -rf /data/user/*/$PKGS/cache/*
done


