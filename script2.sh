#!/bin/bash

mkdir unpack
cd unpack
../magiskboot unpack ../r.img

ramdisk="ramdisk.cpio"
if [ -f vendor_ramdisk/recovery.cpio ]; then
    ramdisk="vendor_ramdisk/recovery.cpio"
elif [ -f vendor_ramdisk_recovery.cpio ]; then
    ramdisk="vendor_ramdisk_recovery.cpio"
fi

../magiskboot cpio "$ramdisk" extract
# Reverse fastbootd ENG mode check
../magiskboot hexpatch system/bin/recovery e10313aaf40300aa6ecc009420010034 e10313aaf40300aa6ecc0094 # 20 01 00 35
../magiskboot hexpatch system/bin/recovery eec3009420010034 eec3009420010035
../magiskboot hexpatch system/bin/recovery 3ad3009420010034 3ad3009420010035
../magiskboot hexpatch system/bin/recovery 50c0009420010034 50c0009420010035
../magiskboot hexpatch system/bin/recovery 080109aae80000b4 080109aae80000b5
../magiskboot hexpatch system/bin/recovery 20f0a6ef38b1681c 20f0a6ef38b9681c
../magiskboot hexpatch system/bin/recovery 23f03aed38b1681c 23f03aed38b9681c
../magiskboot hexpatch system/bin/recovery 20f09eef38b1681c 20f09eef38b9681c
../magiskboot hexpatch system/bin/recovery 26f0ceec30b1681c 26f0ceec30b9681c
../magiskboot hexpatch system/bin/recovery 24f0fcee30b1681c 24f0fcee30b9681c
../magiskboot hexpatch system/bin/recovery 27f02eeb30b1681c 27f02eeb30b9681c
../magiskboot hexpatch system/bin/recovery b4f082ee28b1701c b4f082ee28b970c1
../magiskboot hexpatch system/bin/recovery 9ef0f4ec28b1701c 9ef0f4ec28b9701c
../magiskboot hexpatch system/bin/recovery 9ef00ced28b1701c 9ef00ced28b9701c
../magiskboot hexpatch system/bin/recovery 2001597ae0000054 2001597ae1000054 # ccmp w9, w25, #0, eq ; b.e #0x20 ===> b.ne #0x20
../magiskboot hexpatch system/bin/recovery 2001597ac0000054 2001597ac1000054 # ccmp w9, w25, #0, eq ; b.e #0x1c ===> b.ne #0x1c
../magiskboot hexpatch system/bin/recovery 9ef0fcec28b1701c 9ef0fced28b1701c
../magiskboot hexpatch system/bin/recovery 9ef00ced28b1701c 9ef00ced28b9701c
../magiskboot hexpatch system/bin/recovery 24f0f2ea30b1681c 24f0f2ea30b9681c
../magiskboot hexpatch system/bin/recovery e0031f2a8e000014 200080528e000014
../magiskboot hexpatch system/bin/recovery 41010054a0020012f44f48a9 4101005420008052f44f48a9
../magiskboot cpio "$ramdisk" 'add 0755 system/bin/recovery system/bin/recovery'
# 1. Repack the image
../magiskboot repack ../r.img new-boot.img

# 2. Move it to the main folder immediately (Overwriting any old file)
mv new-boot.img ../recovery-patched.img

# 3. Go to the main folder so we are looking at the SAME file as avbtool
cd ..

# 4. Calculate the padding needed
SIZE=$(stat -c%s recovery-patched.img)
echo "Original size: $SIZE"
REM=$((SIZE % 4096))

if [ "$REM" -ne "0" ]; then
    NEED=$((4096 - REM))
    echo "Padding with $NEED bytes to make it align to 4096..."
    dd if=/dev/zero bs=1 count=$NEED >> recovery-patched.img
else
    echo "File is already aligned. No padding needed."
fi

# 5. Verify final size
NEW_SIZE=$(stat -c%s recovery-patched.img)
echo "Final size: $NEW_SIZE"
