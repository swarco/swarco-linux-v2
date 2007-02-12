#! /bin/sh

TFTP_ROOT_DIR=tftp_root
BUILDROOT_BASE=buildroot
BUILDROOT_DIR=buildroot-1.0
BUILDROOT_SOFT_FLOAT_DIR=buildroot-1.0-soft-float
U_BOOT_BASE=u-boot
U_BOOT_DIR=u-boot-ccm2200
KERNEL_BASE=kernel
KERNEL_DIR=linux-2.6.12.5-ccm2200


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
  cp -a $1/sources/userland/dl dl
)

#prepare a copy of buildroot to create the soft-float toolchain 
# necessary to build u-boot
(
  cd $BUILDROOT_BASE
  svn export $BUILDROOT_DIR $BUILDROOT_SOFT_FLOAT_DIR
  cp dot_config_buildroot-1.0-soft-float $BUILDROOT_SOFT_FLOAT_DIR/.config  
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
(
  cd $KERNEL_BASE
  mkdir output

  # copy kernel config
  cp $1/sources/kernel/kernel-config-ccm2200 output/.config

  # remove old kernel source if available
  \rm -rf linux-2.6.12.5 $KERNEL_DIR

  # extract kernel
  tar xjvf $1/sources/kernel/linux-2.6.12.5.tar.bz2
  mv linux-2.6.12.5 $KERNEL_DIR
  cd $KERNEL_DIR

  # apply patches
  for patch in $1/sources/kernel/[0-9]*.patch 
  do 
    patch -p1 < $patch
  done

  tar xvzf $1/sources/kernel/cifs_1.44.tar.gz

  # create symlink for build script
  rm build-ccm2200.sh
  ln -s ../build-ccm2200.sh .
)



# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

