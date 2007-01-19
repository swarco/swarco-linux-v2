#!/bin/sh

CPU=arm
CROSS_COMPILE="$CPU-linux-"
#BOARD=at91rm9200dk
BOARD=ccm2200
IMAGE_DIR=../../tftp_root/

#TOOLCHAIN=$PWD/../../toolchain-uboot-fsforth/
TOOLCHAIN=$PWD/../../buildroot/buildroot-1.0-soft-float/build_${CPU}_nofpu/staging_dir/
PATH=$PATH:$TOOLCHAIN/bin
export PATH

if [ "$1" == "makeall" ]; then
     export CROSS_COMPILE
     ./MAKEALL ARM9 
     exit 0
fi


if ! grep $BOARD include/config.h >/dev/null; then
  make ${BOARD}_config CROSS_COMPILE=$CROSS_COMPILE
fi

if [ "$1" == "" ]; then
set all
fi

make CROSS_COMPILE=$CROSS_COMPILE ARCH=arm  $@ || exit $?

echo coping u-boot.bin in tftp download directory
cp u-boot.bin $IMAGE_DIR/u-boot-ccm2200dev.bin
#cp u-boot.bin $IMAGE_DIR

tools/mkimage -A arm -O linux -T script -C none -a 0x20100000 -e 0x20100000 -n "Weiss U-Boot autoupdate script" -d ccm2200_usb_script/ccm2200.script $IAMGE_DIR/ccm2200.bin


# Local Variables:
# mode: shell-script
# compile-command: "sh ./build-ccm2200.sh"
# End:
