#!/bin/sh
#*****************************************************************************
#* 
#*  @file          ssh_keygen.sh
#*
#*  script to initialize the ssh keys on first system boot 
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
#*    2007-12-04 gc: several improvements
#*    2006-08-27 mf: initial version
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

LOG="logger -p auth.notice -t $0"

$LOG "Starting OpenSSH key generator"
${SSH_KEYGEN} -q -b 1024 -t rsa1 -f ${HOST_KEY_RSA1_TMP} -N "" -C ""
${SSH_KEYGEN} -q -b 1024 -t dsa -f ${HOST_KEY_DSA_TMP} -N "" -C ""
${SSH_KEYGEN} -q -b 1024 -t rsa -f ${HOST_KEY_RSA_TMP} -N "" -C ""

$LOG "Copying newly generated OpenSSH keys to /etc"

remount_ro=
if mount | grep /dev/root | grep '[,(]ro[,)]' >/dev/null 2>&1
then
    mount -oremount,rw /
    remount_ro="mount -oremount,ro /"
fi 

cp ${HOST_KEY_RSA1_TMP} ${HOST_KEY_RSA1}
cp ${HOST_KEY_DSA_TMP} ${HOST_KEY_DSA}
cp ${HOST_KEY_RSA_TMP} ${HOST_KEY_RSA}

chmod 600 ${HOST_KEY_RSA1}
chmod 600 ${HOST_KEY_DSA}
chmod 600 ${HOST_KEY_RSA}

#???
chown ftp:ftp /home/ftp
rm /etc/.firstboot


$remount_ro

$LOG "Finished generating OpenSSH keys"

rm ${HOST_KEY_RSA1_TMP}*
rm ${HOST_KEY_DSA_TMP}*
rm ${HOST_KEY_RSA_TMP}*

