#!/bin/sh
#*****************************************************************************
#* 
#*  @file          ntp-query.sh
#*
#*  Run NTP timeserver query as background process. 
#*  The ntpdate utility can run for several minutes until it has gotten
#*  a valid time in particular on a slow network connection (GPRS), a
#*  large timeout (-t option) and if many NTP-hosts are specified.
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

NTPDATE=/usr/bin/ntpdate
HWCLOCK=/sbin/hwclock

# synchronize systime from NTP-Server
test -f $NTPDATE || exit 0
test -f /etc/default/ntpdate || exit 0

. /etc/default/ntpdate

NTPDATA_FAIL_CMD=""

if [ -f /etc/default/gprs ]
then
    . /etc/default/gprs
    
    if [ ! -z "$GPRS_DEVICE" ]
    then
        NTPDATE_FAIL_CMD="/bin/kill `/bin/cat /var/run/ppp0.pid`; sleep 20; /bin/kill -9 `/bin/cat /var/run/ppp0.pid`"
    fi
fi


test -n "$NTPSERVERS" || exit 0

logger -t $0 "Running ntpdate to synchronize clock"
if $NTPDATE $NTPOPTIONS $NTPSERVERS; then
    $HWCLOCK -w
    logger -t $0 "ntpdate finished with: `date`"
else
    if [ ! -z "$NTPDATE_FAIL_CMD" ]; then
        
        logger -t $0 "ntpdate FAILED, executing cmd: $NTPDATE_FAIL_CMD"
        /bin/sh -c "$NTPDATE_FAIL_CMD"
    fi
fi
