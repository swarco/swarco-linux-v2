#!/bin/sh

BUILDROOT_BASE=.

#prepare buildroot-svn tree for basesystem 2.0
(
  cd $BUILDROOT_BASE
  # extract buildroot svn
  tar xvjf ../dl/buildroot-svn-20080612.tar.bz2 --exclude .svn
  patch -p0 <buildroot-svn-2008061-weiss-basesystem2.patch
  make oldconfig
)


# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

