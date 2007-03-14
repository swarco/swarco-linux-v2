#!/bin/sh

mount -t sysfs none /sys
mount -t tmpfs -o size=512k tmpfs /dev
mkdir /dev/pts
mount -t devpts /dev/pts
mdev -s

mkdir /dev/misc
ln -s /dev/ccm2200_gpio /dev/misc/ccm2200_gpio
echo /sbin/mdev >/proc/sys/kernel/hotplug

