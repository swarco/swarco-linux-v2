#! /bin/sh

if [ "$1" == "" ] || [ ! -d "$1" ] ; then
  echo Syntax: $0 '<directory to Weiss-Embedded-Linux CD>'
  exit
fi


if [ ! -f /mnt/weiss/weiss-linux/prepare_tree.sh ] ||
	 [ ! /mnt/weiss/weiss-linux/prepare_tree.sh -ef $0 ] ; then
  echo Warning: recommended installation place for Weiss-Embedded-Linux Repository
  echo          is /mnt/weiss/weiss-linux
fi


#prepare buildroot dl directory
(
  cd buildroot
  tar xvzf $1/sources/userland/application_sources.tar.gz
)

#prepare ccm2200 u-boot directory
(
  cd u-boot
  \rm -rf u-boot-weiss
  # warning, only example, this is not current u-boot-release
  # DO NOT USE THIS VERSION
  tar xvzf $1/sources/u-boot/u-boot-weiss-20061020.tar.gz

)

#prepare ccm2200 kernel directory
(
  cd kernel
  mkdir output

  # copy kernel config
  cp $1/sources/kernel/kernel-config-ccm2200 output/.config

  # extract kernel
  \rm -rf linux-2.6.12.5 linux-2.6.12.5-ccm2200

  tar xjvf $1/sources/kernel/linux-2.6.12.5.tar.bz2
  mv linux-2.6.12.5 linux-2.6.12.5-ccm2200
  cd linux-2.6.12.5-ccm2200

  # apply patches
  for patch in $1/sources/kernel/[0-9]*.patch 
  do 
    patch -p1 < $patch
  done

  tar xvzf $1/sources/kernel/cifs_1.44.tar.gz
)



# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

