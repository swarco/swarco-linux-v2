#!/bin/sh
#*****************************************************************************
#* 
#*  @file          prepare_kern.sh
#*
#*                 prepares Linux Kernel build tree 
#*                 2010 SWARCO Traffic Systems GmbH
#*
#*  @version       0.1 (\$Revision: 286 $)
#*  @author        Guido Classen
#*
#*  $LastChangedBy: clg9tr $
#*  $Date: 2011-01-07 18:03:18 +0100 (Fr, 07 Jan 2011) $
#*  $URL: svn://server-i/weiss-linux/prepare_tree.sh $
#* 
#*  @par change history:
#*    2006-12-07 gc: initial version 
#*  
#*****************************************************************************

TFTP_ROOT_DIR=tftp_root
BUILDROOT_BASE=buildroot
BUILDROOT_DIR=buildroot-2.0
BUILDROOT_SOFT_FLOAT_DIR=buildroot-2.0-soft-float
U_BOOT_BASE=u-boot
U_BOOT_DIR=u-boot-v2010.09-ccm2200
KERNEL_BASE=kernel

if [ -z "$1" ] || [ ! -d "$1" ] ; then
  echo Syntax: $0 '<directory to SWARCO Traffic Systems Embedded-Linux CD>'
  exit
fi

if [ -z "$2" ] ; then
  set "$1" 2.6.21
  exit
fi


#prepare ccm2200 kernel directory
prepare_kernel_directory() {
(
  KERNEL_VANILLA_DIR=$1
  KERNEL_CCM2200_DIR=$KERNEL_VANILLA_DIR-ccm2200
  KERNEL_CD_DIR=$2
  KERNEL_OUTPUT_DIR=output-${KERNEL_CCM2200_DIR##*linux-}

  cd $KERNEL_BASE
  mkdir $KERNEL_OUTPUT_DIR

  # copy kernel config
  cp $KERNEL_CD_DIR/kernel-config-${KERNEL_CCM2200_DIR##*linux-} $KERNEL_OUTPUT_DIR/.config

  # remove old kernel source if available
  \rm -rf $KERNEL_VANILLA_DIR $KERNEL_CCM2200_DIR

  # extract kernel
  tar xjvf $KERNEL_CD_DIR/linux-*.tar.bz2
  mv $KERNEL_VANILLA_DIR $KERNEL_CCM2200_DIR
  cd $KERNEL_CCM2200_DIR

  # apply patches
  for patch in $KERNEL_CD_DIR/[0-9]*.patch 
  do 
    echo appying patch $patch
    patch -p1 < $patch
  done

  if [ -f $KERNEL_CD_DIR/cifs_1.44.tar.gz ] ; then
      tar xvzf $KERNEL_CD_DIR/cifs_1.44.tar.gz
  fi

  # create symlink for build script
  rm build-ccm2200.sh
  ln -s ../build-ccm2200.sh .
)
}

# prepare_kernel_directory  linux-2.6.12.6                        \
#                           $1/sources/kernel/2.6.12.6/


# prepare_kernel_directory  linux-2.6.21                          \
#                           $1/sources/kernel/2.6.21/

#prepare_kernel_directory  linux-2.6.35                            \
#                          $1/sources/kernel/2.6.35/

prepare_kernel_directory  linux-2.6.37                            \
                          $1/sources/kernel/2.6.37/

# Local Variables:
# mode: shell-script
# compile-command: "sh ./prep_kern.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

