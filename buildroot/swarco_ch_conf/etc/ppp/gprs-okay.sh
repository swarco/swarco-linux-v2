#!/bin/sh
#*****************************************************************************
#* 
#*  @file          gprs-okay.sh
#*
#*  This script starts running if GPRS/UMTS internet connection is
#*  successfully established (e.g. on successfully completed NTP-query)
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

SYS_MESG=/usr/weiss/bin/sys-mesg

if [ -f /etc/default/gprs ]
then

  . /etc/default/gprs
  
  if [ \! -z "$GPRS_DEVICE" ]
  then

	echo GPRS_ERROR_COUNT=0 >/tmp/gprs-error
        test -x $SYS_MESG && $SYS_MESG -n GPRS -r
  fi

fi
