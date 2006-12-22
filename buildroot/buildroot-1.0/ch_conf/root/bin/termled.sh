#!/bin/sh

#pid=`ps ax |grep /root/bin/startled.sh |grep -v grep |awk '{print $1;}'`
#ccm2200_gpio /dev/misc/ccm2200_gpio led 0xf111
#kill -9 $pid

killall startled.sh
killall ledloop
ccm2200_gpio /dev/misc/ccm2200_gpio led 0xf111