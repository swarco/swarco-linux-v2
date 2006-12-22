#*****************************************************************************
#* 
#*  @file          /etc/init_common
#*
#*                 Common code sourced by init scripts
#*                 Buildroot uclibc linux
#*                 2005 Weiss-Electronic GmbH
#*
#*  @version       0.1
#*  @date          <2005-09-05 17:03:03 gc>
#*  @author        Guido Classen
#* 
#*  @par change history:
#*    2005-09-05 gc: initial version 
#*  
#*****************************************************************************


##############################################################################
# 2005-05-17 gc: Shell functions
##############################################################################
load_module() {
    module=$1
    shift
    if ! lsmod | grep ${module##*/} ; then 
      echo loading module: "$module $@"
      $INSMOD $MODULE_PATH/$module$MODULE_SUFF $@
    fi
}

##############################################################################
# 2005-05-17 gc: End shell functions
##############################################################################


kernel_version=`uname -r` 
kernel_minor=${kernel_version##*.}

case "$kernel_version" in
	2.6.*)
	        echo detected Kernel Version 2.6
		#exec /etc/rcS-2.6
#                INSMOD=/usr/bin/insmod.module-init-tools
                INSMOD=/sbin/insmod
#                MODULE_PATH=/mnt/weiss/lib/modules/$kernel_version
                MODULE_PATH=/lib/modules/$kernel_version
                MODULE_SUFF=.ko
                kernel_version_group=2.6
##############################################################################
# 2006-06-09 mf: /dev/pts already mounted
##############################################################################
                # mount /dev/pts explicitly
                # mount -t devpts none /dev/pts

	;;

	2.4.*)
	        echo detected Kernel Version 2.4
                INSMOD=/sbin/insmod
                MODULE_PATH=/lib/modules/$kernel_version
                MODULE_SUFF=.o
                if [ $kernel_minor -lt 20 ]
                then
                    kernel_version_group=2.4-early
                else
                    kernel_version_group=2.4-late
                fi

	;;
esac
