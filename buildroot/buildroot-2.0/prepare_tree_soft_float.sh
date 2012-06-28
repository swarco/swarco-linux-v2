#!/bin/sh

BUILDROOT_BASE=$PWD
BUILDROOT_SVN=buildroot-svn-20081211
#prepare buildroot-svn tree for basesystem 2.0
(
  cd $BUILDROOT_BASE
  # extract buildroot svn
  tar xvjf ../dl/${BUILDROOT_SVN}.tar.bz2 --exclude .svn
  patch -p1 <${BUILDROOT_SVN}-swarco-basesystem2.patch
  make oldconfig
)


# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree_soft_float.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

