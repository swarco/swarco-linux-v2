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
#*  @date          <2012-11-13 12:45:03 gc>
#*  @author        Guido Classen
#* 
#*  @par change history:
#*    2010-01-07 gc: initial version 
#*  
#*****************************************************************************

# KERNEL_MINOR=`uname -r | sed -e 's/2\.6\.\([0-9]*\).*/\1/'`
# case "$1" in
#   start|restart|reload)
#         if [ "$KERNEL_MINOR" -gt 21 ]; then
# 	    echo "Setting real time parameters"
# 	    echo 10000 > /proc/sys/kernel/sched_rt_period_us 
# 	    echo 1000  > /proc/sys/kernel/sched_rt_runtime_us 
#         fi
# 	;;
#   stop)
#   	exit 0
# 	;;
#   *)
# 	echo $"Usage: $0 {start|stop|restart}"
# 	exit 1
# esac


# Local Variables:
# mode: shell-script
# time-stamp-pattern: "20/@date[\t ]+<%%>"
# backup-inhibited: t
# End:
