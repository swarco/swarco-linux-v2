#!/bin/sh
#*****************************************************************************
#* 
#*  @file          run_xgettext
#*
#*                 Run GNU xgettext to extract system messages from
#*                 startup and GPRS shell scripts
#*                 2010 Swarco Traffic Systems GmbH
#*
#*  @version       0.1 (\$Revision$)
#*  @author        Guido Classen
#*
#*  $LastChangedBy$
#*  $Date$
#*  $URL$
#* 
#*  @par change history:
#*    2007-05-08 gc: adoption new LED concept!
#*    2006-12-07 gc: initial version 
#*  
#*****************************************************************************

xgettext --output system_messages.pot           \
         --default-domain=system_messages       \
         --directory=.                          \
         --add-comments                         \
         --keyword                              \
         --keyword=M_                           \
         --from-code=ISO-8859-1                 \
         --language=Shell                       \
         ch_conf/etc/ppp/*.sh                   \
         ch_conf/etc/init.d/S*

# Local Variables:
# mode: shell-script
# compile-command: "./run_xgettext.sh"
# End:
