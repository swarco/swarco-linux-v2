#! /bin/sh

TFTP_ROOT_DIR=tftp_root
BUILDROOT_BASE=buildroot
BUILDROOT_DIR=buildroot-1.0
BUILDROOT_SOFT_FLOAT_DIR=buildroot-1.0-soft-float
U_BOOT_BASE=u-boot
U_BOOT_DIR=u-boot-ccm2200
KERNEL_BASE=kernel

if [ "$1" == "" ] || [ ! -d "$1" ] ; then
  echo Syntax: $0 '<directory to Weiss-Embedded-Linux CD>'
  exit
fi


if [ ! -f /mnt/weiss/weiss-linux/prepare_tree.sh ] ||
	 [ ! /mnt/weiss/weiss-linux/prepare_tree.sh -ef $0 ] ; then
  echo Warning: recommended installation place for Weiss-Embedded-Linux Repository
  echo          is /mnt/weiss/weiss-linux
  echo          Press Return to continue, Ctrl-C to abort
  read 
fi



#prepare buildroot dl directory
(
  cd $BUILDROOT_BASE
#  tar xvzf $1/sources/userland/application_sources.tar.gz
  mkdir dl
  cp -a $1/sources/userland/dl .
)

#prepare buildroot 2.0 tree

(
    cd $BUILDROOT_BASE/buildroot-2.0
    ./prepare_tree.sh
)

#prepare a copy of buildroot to create the soft-float toolchain 
# necessary to build u-boot
(
  cd $BUILDROOT_BASE
  
  if [ -d $BUILDROOT_DIR/.svn ]
  then 
    svn export $BUILDROOT_DIR $BUILDROOT_SOFT_FLOAT_DIR
  fi

  # fallback if svn export is not available (weiss-linux tree is 
  # created from .tar.gz)
  if ! [ -d $BUILDROOT_SOFT_FLOAT_DIR ]
  then
    cp -a $BUILDROOT_DIR $BUILDROOT_SOFT_FLOAT_DIR
  fi

  cp dot_config_buildroot-1.0-soft-float $BUILDROOT_SOFT_FLOAT_DIR/.config  
  cp uClibc.config-soft-float $BUILDROOT_SOFT_FLOAT_DIR/toolchain/uClibc/uClibc.config
)

#prepare ccm2200 u-boot directory
(
  cd $U_BOOT_BASE
  \rm -rf $U_BOOT_DIR
  # warning, only example, this is not current u-boot-release
  # DO NOT USE THIS VERSION
  tar xvzf $1/sources/u-boot/u-boot-ccm2200-20070209.tar.gz

  # create symlink for build script
  cd $U_BOOT_DIR
  rm build-ccm2200.sh
  ln -s ../build-ccm2200.sh .
)




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


prepare_kernel_directory  linux-2.6.21                          \
                          $1/sources/kernel/2.6.21/

# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

