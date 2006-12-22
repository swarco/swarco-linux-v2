#!/bin/sh
#*****************************************************************************
#* 
#*  @file          dialup-ppp.sh
#*
#*                 Dialup ppp connection und redial if it breaks
#*                 2004 Weiss-Electronic GmbH
#*
#*  @version       0.1.0
#*  @date          <2004-12-22 18:17:46 gc>
#*  @author        Guido Classen
#* 
#*  @par change history:
#*    2004-12-22 gc: initial version 
#*  
#*****************************************************************************


while true
do
  /bin/pppd call gprs nodetach
done

exit 0

# Local Variables:
# mode: shell-script
# time-stamp-pattern: "20/@date[\t ]+<%%>"
# End:
