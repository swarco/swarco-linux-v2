#!/bin/sh
#*****************************************************************************
#* 
#*  @file          S21firstboot
#*
#*  /etc/init.d    script initializes the ssh keys on first system boot 
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Markus Forster <br>
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*    2006-08-27 mf: initial version
#*
#*  
#*****************************************************************************

umask 022

if [ -f /etc/.firstboot ]; then
    /usr/sbin/ssh_keygen.sh &
fi

# Local Variables:
# mode: shell-script
# backup-inhibited: t
# End:
