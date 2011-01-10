#!/bin/sh
#*****************************************************************************
#* 
#*  @file          /etc/S*sched_rt_param
#*
#*                 Setze Linux Kernel > 2.6.35 realtime scheduler parameter
#*                 Buildroot uclibc linux
#*                 2010 SWARCO Traffic Systems GmbH
#*
#*  @version       0.2
#*  @date          <2011-01-10 19:33:35 gc>
#*  @author        Guido Classen
#* 
#*  @par change history:
#*    2010-01-07 gc: initial version 
#*  
#*****************************************************************************

case "$1" in
  start)
	echo "Setting real time parameters"
	echo 10000 > /proc/sys/kernel/sched_rt_period_us 
	echo 1000  > /proc/sys/kernel/sched_rt_runtime_us 
	;;
  stop)
  	exit 0
	;;
  restart|reload)
  	restart
	;;
  *)
	echo $"Usage: $0 {start|stop|restart}"
	exit 1
esac


# Local Variables:
# mode: shell-script
# time-stamp-pattern: "20/@date[\t ]+<%%>"
# backup-inhibited: t
# End:
