#! /bin/sh
#*****************************************************************************/
#* 
#*  @file          S11myvarinit.sh
#*
#*  mounts ram-disk with size 1MB to /tmp
#*  
#*  @version       0.1
#*  @date          <2006-07-06 15:01:33 mf>
#*  @author        Markus Forster
#* 
#*  Changes:
#*    2006-07-06 mf: initial version
#*  
#****************************************************************************/
#MYTMPSIZE=1024
#MYTMPDIR=/mnt/.ram1

case "$1" in
  start)
    echo "Initializing log filesystem..."
    
    # 2006-03-14 gc: now we are using the size option of tempfs in fstab
    #                to specify the MAXIMUM size of the ramdisk
    #                So we don't need to mess around with loopback devices
    #                and filesystems here!!!

    #mount -t ramfs /dev/ram0 $MYTMPDIR > /dev/null 2>&1
    #dd if=/dev/zero of=$MYTMPDIR/mytmp bs=1024 count=$MYTMPSIZE > /dev/null 2>&1
    #losetup /dev/loop7 $MYTMPDIR/mytmp > /dev/null 2>&1
    #mkfs.ext2 -b 1024 /dev/loop7 > /dev/null 2>&1
    #mount /dev/loop7 /tmp > /dev/null 2>&1


    mkdir -p /tmp/timestamp
    #ln -s /tmp /var/lib
    #ln -s /tmp /var/lock
    #ln -s /tmp /var/log
    #ln -s /tmp /var/pcmcia
    #ln -s /tmp /var/run
    #ln -s /tmp /var/spool
    #ln -s /tmp /var/tmp
    #ln -s /var/tmp /var/lib/dhcp
    #ln -s /var/tmp /var/lib/pcmcia
    touch /var/log/messages
    syslogd -s 200 -b 1 -m 0
    klogd 
    echo "done."
    ;;
  stop)
    killall klogd
    killall syslogd
    #umount /dev/loop7
    #losetup -d /dev/loop7
    ;;
  *)
    echo "Usage: myvarinit {start|stop}" >&2
    exit 1
    ;;
esac

# Local Variables:
# mode: shell-script
# backup-inhibited: t
# End:
