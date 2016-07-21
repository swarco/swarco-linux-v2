#!/bin/sh
#*****************************************************************************
#* 
#*  @file          prepare_tree.sh
#*
#*                 Unpacks packages from SWARCO Traffic Systems
#*                 Embdedded Linux CD and
#*                 prepares Linux build tree 
#*                 2010-2016 SWARCO Traffic Systems GmbH
#*
#*  @version       0.1 (\$Revision$)
#*  @author        Guido Classen
#*
#*  $LastChangedBy$
#*  $Date$
#*  $URL$
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
KERNEL_VERS=2.6.21
#KERNEL_VERS=2.6.37

if [ -z "$1" ] || [ ! -d "$1" ] ; then
  echo Syntax: $0 '<directory to SWARCO Traffic Systems Embedded-Linux CD>'
  exit
fi


# if [ ! -f /mnt/weiss/weiss-linux/prepare_tree.sh ] ||
# 	 [ ! /mnt/weiss/weiss-linux/prepare_tree.sh -ef $0 ] ; then
#   echo Warning: recommended installation place for Weiss-Embedded-Linux Repository
#   echo          is /mnt/weiss/weiss-linux
#   echo          Press Return to continue, Ctrl-C to abort
#   read line
# fi



#prepare buildroot dl directory
(
  cd $BUILDROOT_BASE
#  tar xvzf $1/sources/userland/application_sources.tar.gz
  mkdir dl
  #cp -a $1/sources/userland/dl .
)

# 2011-01-07 gc: prepare a copy of buildroot 2 to create the soft-float
# toolchain necessary to build u-boot
(
  cd $BUILDROOT_BASE

  # if [ -d $BUILDROOT_DIR/.svn ]
  # then 
  #   svn export $BUILDROOT_DIR $BUILDROOT_SOFT_FLOAT_DIR
  # fi

  # fallback if svn export is not available (weiss-linux tree is 
  # created from .tar.gz)
  if ! [ -f $BUILDROOT_SOFT_FLOAT_DIR/Makefile ]
  then
    cp -aT $BUILDROOT_DIR $BUILDROOT_SOFT_FLOAT_DIR
  fi

  ( cd $BUILDROOT_SOFT_FLOAT_DIR; ./prepare_tree_soft_float.sh )
  cp dot_config_buildroot-2.0-soft-float $BUILDROOT_SOFT_FLOAT_DIR/.config  
)


#prepare buildroot 2.0 tree

(
    cd $BUILDROOT_BASE/buildroot-2.0
    ./prepare_tree.sh
)

#prepare a copy of buildroot to create the soft-float toolchain 
# necessary to build u-boot
# (
#   cd $BUILDROOT_BASE
  
#   if [ -d $BUILDROOT_DIR/.svn ]
#   then 
#     svn export $BUILDROOT_DIR $BUILDROOT_SOFT_FLOAT_DIR
#   fi

#   # fallback if svn export is not available (weiss-linux tree is 
#   # created from .tar.gz)
#   if ! [ -d $BUILDROOT_SOFT_FLOAT_DIR ]
#   then
#     cp -a $BUILDROOT_DIR $BUILDROOT_SOFT_FLOAT_DIR
#   fi

#   cp dot_config_buildroot-1.0-soft-float $BUILDROOT_SOFT_FLOAT_DIR/.config  
#   cp uClibc.config-soft-float $BUILDROOT_SOFT_FLOAT_DIR/toolchain/uClibc/uClibc.config
# )


#prepare ccm2200 u-boot directory
(
  cd $U_BOOT_BASE

  \rm -rf $U_BOOT_DIR
  # warning, only example, this is not current u-boot-release
  # DO NOT USE THIS VERSION
  #tar xvzf $1/sources/u-boot/u-boot-ccm2200-20070209.tar.gz


  # create symlink for build script
  #cd $U_BOOT_DIR
  #rm build-ccm2200.sh
  #ln -s ../build-ccm2200.sh .


  tar xvzf $1/sources/u-boot/v2010.09/u-boot-git-v2010.09.tar.gz 
  mv u-boot-git ${U_BOOT_DIR}
  cd ${U_BOOT_DIR} ;patch -p1 <$1/sources/u-boot/v2010.09/u-boot-v2010.09-ccm2200-redu-20140127.patch

)




#prepare ccm2200 kernel directory
prepare_kernel_directory() {
(
  KERNEL_VANILLA_DIR=$1
  KERNEL_CCM2200_DIR=${KERNEL_VANILLA_DIR}-ccm2200
  KERNEL_CD_DIR=$2
  KERNEL_TAR_BALL=$3
  KERNEL_OUTPUT_DIR=output-${KERNEL_CCM2200_DIR##*linux-}

  if [ -z "$KERNEL_TAR_BALL" ]; then
      KERNEL_TAR_BALL=$KERNEL_CD_DIR/linux-*.tar.bz2
  fi

  cd $KERNEL_BASE
  mkdir $KERNEL_OUTPUT_DIR

  # copy kernel config
  cp $KERNEL_CD_DIR/kernel-config-${KERNEL_CCM2200_DIR##*linux-} $KERNEL_OUTPUT_DIR/.config

  # remove old kernel source if available
  \rm -rf $KERNEL_VANILLA_DIR $KERNEL_CCM2200_DIR

  # extract kernel
  tar xjvf $KERNEL_TAR_BALL
  mv $KERNEL_VANILLA_DIR $KERNEL_CCM2200_DIR
  cd $KERNEL_CCM2200_DIR

  # apply patches
  for patch in $KERNEL_CD_DIR/[0-9]*.patch 
  do 
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


echo KERNEL_VERS=$KERNEL_VERS > version.mk

case "$KERNEL_VERS" in
    2.6.12)
        prepare_kernel_directory  linux-2.6.12.6                        \
                                  $1/sources/kernel/2.6.12.6/
        ;;
    
    2.6.21)
        # now use kernel sources from our repository
        prepare_kernel_directory  linux-2.6.21                          \
                                  $PWD/board/swarco/ccm2200/kernel/2.6.21/   \
                                  $PWD/buildroot/dl/linux-2.6.21.tar.bz2
                                  
        ;;
    
    2.6.35)
        prepare_kernel_directory  linux-2.6.35                            \
                                  $1/sources/kernel/2.6.35/               \
                                  $1/sources/userland/dl/linux-2.6.35.tar.bz2
        ;;
    
    2.6.37)
        prepare_kernel_directory  linux-2.6.37                            \
                                  $1/sources/kernel/2.6.37/
        ;;

    3.4)
        prepare_kernel_directory  linux-3.4                            \
                                  $1/sources/kernel/3.4/
        ;;
esac

# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

