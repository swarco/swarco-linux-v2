#!/bin/sh
#*****************************************************************************
#* 
#*  @file          prepare_tree_github.sh
#*
#*                 Unpacks packages for SWARCO Embedded Linux V2
#*                 using the respective Github repositories and
#*                 prepares Linux build tree for compilation
#*                 2010-2016 SWARCO Traffic Systems GmbH
#*
#*  @version       0.1 (\$Revision$)
#*  @author        Guido Classen
#*
#*  @par change history:
#*    2016-08-04 gc: initial version 
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
KERNEL_VERS_BRANCH=linux-${KERNEL_VERS}.y-ccm2200
#KERNEL_VERS=2.6.37

#prepare buildroot dl directory
(
  cd $BUILDROOT_BASE
#  tar xvzf $1/sources/userland/application_sources.tar.gz
#  mkdir dl
#  cd dl
  git clone https://github.com/swarco/swarco-linux-v2-dl
  rm -rf dl
  ln -s swarco-linux-v2-dl/dl dl
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


#prepare ccm2200 u-boot directory
(
    cd $U_BOOT_BASE
    
    \rm -rf $U_BOOT_DIR
    git clone -b v2010.09-ccm2200 https://github.com/swarco/u-boot $U_BOOT_DIR
)


#prepare ccm2200 kernel directory
(
    KERNEL_OUTPUT_DIR=output-${KERNEL_VERS}-ccm2200
    KERNEL_CCM2200_DIR=linux-${KERNEL_VERS}-ccm2200
    KERNEL_BOARD_DIR=$PWD/board/swarco/ccm2200/kernel/${KERNEL_VERS}
    cd $KERNEL_BASE

    if ! [ -d $KERNEL_CCM2200_DIR ] ; then
        git clone -b ${KERNEL_VERS_BRANCH} https://github.com/swarco/linux-kernel $KERNEL_CCM2200_DIR
    else
        (
            cd $KERNEL_CCM2200_DIR
            git clean -d -x -f
            git checkout ${KERNEL_VERS_BRANCH}
        )
    fi
    mkdir $KERNEL_OUTPUT_DIR
    cp $KERNEL_BOARD_DIR/kernel-config-${KERNEL_CCM2200_DIR##*linux-} $KERNEL_OUTPUT_DIR/.config
    (
            cd ${KERNEL_CCM2200_DIR}
            ln -sf ../build-ccm2200.sh .
    )
)
echo KERNEL_VERS=${KERNEL_VERS} > version.mk

# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree_github.sh"
# End:

