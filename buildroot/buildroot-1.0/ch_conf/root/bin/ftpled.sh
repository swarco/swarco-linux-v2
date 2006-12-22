#!/bin/sh

while true;
  do
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0xf111
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x6666
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x9db9
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0xf999
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x9669
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x0000
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x171f
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x666f
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x1f9f
  sleep 1
  ccm2200_gpio /dev/misc/ccm2200_gpio led 0x0000
  sleep 1
done
