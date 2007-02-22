#!/bin/sh
#*****************************************************************************
#* 
#*  @file          S21firstboot
#*
#*  /etc/init.d    script initializes the ssh keys on first system boot 
#*
#*  @version       1.0 (\$Revision: 1818 $)
#*  @author        Markus Forster <br>
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy: fom9tr $  
#*  $Date: 2006-08-27 $
#*  $URL:  $
#*
#*  @par Modification History:
#*    2006-08-27 mf: initial version (unixdef)
#*
#*  
#*****************************************************************************
SSH_KEYGEN=/usr/bin/ssh-keygen
HOST_KEY_RSA1=/etc/ssh_host_key
HOST_KEY_DSA=/etc/ssh_host_dsa_key
HOST_KEY_RSA=/etc/ssh_host_rsa_key

HOST_KEY_RSA1_TMP=/tmp/ssh_host_key
HOST_KEY_DSA_TMP=/tmp/ssh_host_dsa_key
HOST_KEY_RSA_TMP=/tmp/ssh_host_rsa_key

mount -o remount,rw /


# 2007-02-06 gc: start watchdog trigger daemon!
# 2007-02-22 mf: no longer needed cause of standard ssh key files
#/sbin/watchdog -t 1 /dev/ccm2200_watchdog

logger "rsa1, dsa and rsa keys for openSSH will be created..."
${SSH_KEYGEN} -b 1024 -t rsa1 -f ${HOST_KEY_RSA1_TMP} -N ""
cp ${HOST_KEY_RSA1_TMP} ${HOST_KEY_RSA1}
${SSH_KEYGEN} -b 1024 -t dsa -f ${HOST_KEY_DSA_TMP} -N ""
cp ${HOST_KEY_DSA_TMP} ${HOST_KEY_DSA}
${SSH_KEYGEN} -b 1024 -t rsa -f ${HOST_KEY_RSA_TMP} -N ""
cp ${HOST_KEY_RSA_TMP} ${HOST_KEY_RSA}
# change permissions of ssh key files to non other access
chown ftp:ftp /home/ftp
#rm /etc/.firstboot

chmod 600 ${HOST_KEY_RSA1}
chmod 600 ${HOST_KEY_DSA}
chmod 600 ${HOST_KEY_RSA}

rm ${HOST_KEY_RSA1_TMP}*
rm ${HOST_KEY_DSA_TMP}*
rm ${HOST_KEY_RSA_TMP}*


rm /etc/.firstboot
mount -o remount,ro /

logger "done.with openSSH-key creation"
