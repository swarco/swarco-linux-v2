#!/bin/sh

BUILDROOT_BASE=.
BUILDROOT_SVN=buildroot-svn-20081211
#prepare buildroot-svn tree for basesystem 2.0
(
  cd $BUILDROOT_BASE
  # extract buildroot svn
  tar xvjf ../dl/${BUILDROOT_SVN}.tar.bz2 --exclude .svn
  patch -p1 <${BUILDROOT_SVN}-weiss-basesystem2.patch
  cp  weiss/uClibc-0.9.29.config toolchain/uClibc/uClibc-0.9.29.config
  make oldconfig
)


# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

