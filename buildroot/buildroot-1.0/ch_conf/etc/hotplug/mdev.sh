#!/bin/sh

mount -t sysfs none /sys
mount -t tmpfs -o size=512k tmpfs /dev
mkdir /dev/pts
mount -t devpts /dev/pts
mdev -s

mkdir /dev/misc
ln -s /dev/ccm2200_gpio /dev/misc/ccm2200_gpio
test ! -c /dev/rtc -a -c /dev/rtc0 && ln -s /dev/rtc0 /dev/rtc

echo /etc/hotplug/ccm2200_hotplug >/proc/sys/kernel/hotplug


