#!/bin/sh

BUILDROOT_BASE=$PWD
BUILDROOT_SVN=buildroot-svn-20081211
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
  # 2011-01-12 gc: .config has removed kernel version, restore it!
  sed -i-e 's/^.*BR2_DEFAULT_KERNEL_HEADERS.*/BR2_DEFAULT_KERNEL_HEADERS="2.6.37/g' \
      .config

)


# Local Variables:
# mode: shell-script
# compile-command: "./prepare_tree.sh ~/mnt/entwicklung/WeissEmbeddedLinux/DistriCD"
# End:

