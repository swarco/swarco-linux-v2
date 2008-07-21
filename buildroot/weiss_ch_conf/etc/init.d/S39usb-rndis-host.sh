#!/bin/sh
#
# Start the network....
#

start() {
 	echo "Starting USB rndis_host networking..."
        modprobe rndis_host
        # start dhcp server for usb RNDIS host interface!
        # udhcpd /etc/udhcp-usb0.conf
}	

stop() {
       true
}

restart() {
	stop
	start
}	

case "$1" in
  start)
  	start
	;;
  stop)
  	stop
	;;
  restart|reload)
  	restart
	;;
  *)
	echo $"Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?

