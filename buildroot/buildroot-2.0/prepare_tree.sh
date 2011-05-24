#!/bin/sh

BUILDROOT_BASE=$PWD
BUILDROOT_SVN=buildroot-svn-20110524
#prepare buildroot-svn tree for basesystem 2.0
(
  cd $BUILDROOT_BASE
  # extract buildroot svn
  tar xvjf ../dl/${BUILDROOT_SVN}.tar.bz2 --exclude .svn
  patch -p1 <${BUILDROOT_SVN}-swarco-basesystem2.patch
  # copy template tree over extracted buildroot source tree
  (cd swarco/template_tree; tar cf - --exclude .svn .) | \
    (cd $BUILDROOT_BASE; tar xvf -)
  make oldconfig
  # 2011-01-12 gc: oldconfig has removed kernel version, restore it!
  mv .config .oldconfig
  sed 's/^.*BR2_DEFAULT_KERNEL_HEADERS.*/BR2_DEFAULT_KERNEL_HEADERS="2.6.35/g' \
      <.oldconfig >.config
  rm .oldconfig

)


# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

