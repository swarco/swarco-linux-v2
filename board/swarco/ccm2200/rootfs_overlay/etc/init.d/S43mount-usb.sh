#!/bin/sh

if ! [ -f /etc/default/mount-usb ]
then
  exit 0
fi

. /etc/default/mount-usb

if [ -z "$USB_DEV" ]; then
  exit 0
fi

if ! [ -b $USB_DEV ]; then
  logger "no USB-Stick plugged in"
  exit 1
fi


start(){
  echo "Mounting USB Device: $USB_DEV"
  while ! mount | grep $USB_DEV >/dev/null 2>&1; do
     /sbin/watchdog -t 1 /dev/ccm2200_watchdog
     fsck.ext3 -p $USB_DEV
     killall watchdog
     mount $USB_DEV /mnt/usb
  done
}

stop(){
  echo "Un-Mounting USB Device: $USB_DEV"
  umount /mnt/usb
}

case "$1" in
  start)
    start  
  ;;

  stop)
    stop
  ;;

  restart)
    stop
    start
  ;;

  *)
    echo "Usage: $0 {start | stop | restart}"
    exit 1;

  ;;

esac

exit $?

# Local Variables:
# mode: shell-script
# backup-inhibited: t
# End:
