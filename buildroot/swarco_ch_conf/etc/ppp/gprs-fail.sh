#!/bin/sh
#*****************************************************************************
#* 
#*  @file          gprs-fail.sh
#*
#*  This script starts running if establishing GPRS/UMTS internet connection 
#*  has failed (e.g. on failed NTP-query to multiple servers)
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Guido Classen <br>
#*                 SWARCO Traffic Systems GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*    2009-09-24 gc: initial version
#*  
#*****************************************************************************

if [ -x /usr/swarco/bin/sys-mesg ]; then
    SYS_MESG=/usr/swarco/bin/sys-mesg
else
    SYS_MESG=/usr/weiss/bin/sys-mesg
fi
sys_mesg() {
    test -x $SYS_MESG && $SYS_MESG -n GPRS "$@"

}
M_() {
  echo "$@"
}

if [ -f /etc/default/gprs ]
then
    . /etc/default/gprs
    
    if [ \! -z "$GPRS_DEVICE" ]
    then
        /bin/kill `/bin/cat /var/run/ppp0.pid`
        sleep 20
        /bin/kill -9 `/bin/cat /var/run/ppp0.pid`
        sys_mesg -e NTL -p error `M_ "NTP time sync over GPRS failed, probably no connection" `

    fi
fi
