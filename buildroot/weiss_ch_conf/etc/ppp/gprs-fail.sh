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
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*    2009-09-24 gc: initial version
#*  
#*****************************************************************************

if [ -f /etc/default/gprs ]
then
    . /etc/default/gprs
    
    if [ \! -z "$GPRS_DEVICE" ]
    then
        /bin/kill `/bin/cat /var/run/ppp0.pid`
        sleep 20
        /bin/kill -9 `/bin/cat /var/run/ppp0.pid`
    fi
fi
