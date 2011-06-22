#!/bin/sh
#*****************************************************************************
#* 
#*  @file          S*grps
#*
#*  Start GPRS dialin ppp network interface
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Guido Classen <br>
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*    2007-12-03 gc: initial version
#*  
#*****************************************************************************


if ! [ -f /etc/default/gprs ]
then
  echo "missing file /etc/default/gprs"
# GPRS not configured -> exit
  exit 1
fi

GPRS_PPP_IFACE=ppp0
GPRS_PPP_LED=/sys/class/leds/led10/brightness 
. /etc/default/gprs
export GPRS_PPP_IFACE

if [ -z "$GPRS_DEVICE" -o \
     \( -z "$GPRS_APN" -a "$GPRS_ONLY_CSD" -ne 1 \) ]
then
  echo "Necessary settings missing in /etc/default/gprs"
  exit 1
fi

start() {
	if [ -f /tmp/gprs_disable ]
	then
  		echo "GPRS dialin disabled"
  		exit 1
	fi

	echo "Starting GPRS PPP dialin interface"
	#nohup /usr/bin/starter_gprs_dialin >/dev/null 2>&1 &
	start-stop-daemon --start --quiet --background \
		--make-pidfile --pidfile /var/run/gprs.pid \
		--exec /usr/bin/starter_gprs_dialin 
}

stop() {
	echo "Stopping GPRS PPP dialin interface"
	#killall starter_gprs_dialin
	start-stop-daemon --stop --quiet --signal 1 \
		--pidfile /var/run/gprs.pid 

        pid_file=/var/run/${GPRS_PPP_IFACE}.pid
        if [ -r "$pid_file" ] ; then
            kill -1 `cat $pid_file`
            rm $pid_file
        fi
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

# Local Variables:
# mode: shell-script
# backup-inhibited: t
# End:
