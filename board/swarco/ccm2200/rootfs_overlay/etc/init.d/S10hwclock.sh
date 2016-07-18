#! /bin/sh
#*****************************************************************************/
#* 
#*  @file          S*hwclock.sh
#*
#*  sets system clock to hardware clock
#*  
#*  @version       0.1
#*  @date          <2006-07-06 15:01:33 mf>
#*  @author        Markus Forster
#* 
#*  Changes:
#*    2006-07-06 mf: initial version
#*  
#****************************************************************************/
set -e;

exec="/sbin/hwclock"

test -x "${exec}" || exit 0;

if test -c "/dev/rtc"; then
    device="/dev/rtc";
elif test -c "/dev/misc/rtc"; then
    device="/dev/misc/rtc";
fi

if test -z "${device}"; then
    exit 0;
fi

case "${1}" in
    start)
	echo -n "Setting system time... ";
	${exec} -s;
	echo "done";
	;;
    *)
	echo "Usage: $0 start"
	exit 1
	;;
esac
