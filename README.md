SWARCO Embedded Linux V2 operating system
=========================================

<img src="https://www.swarco.com/var/em_plain_site/storage/images/media/images/swarco-traffic-systems/interurban/primos/primos_compact_ohnetouch_grau/1166093-1-eng-US/Primos_Compact_ohneTouch_grau_315px.jpg" width="200" title="SWARCO CCM2200 CPU" alt="">


| :warning: Warning <br> This is a legacy SWARCO linux environment used for CCM2200 board until 2016. <br> It is only for documentation purposes, please don't use it for starting new projects.<br>See [SWARCO Linux V3](https://github.com/swarco/swarco-linux-v3) for the current environment |
|--------------------|

# Getting started

1. Install packages needed for SWARCO Linux build

    * Debian / Ubuntu Linux

        ```sh
        apt-get install git cpp gcc g++ make
        apt-get install libc6-dev libncurses5-dev
        apt-get install gettext texinfo flex bison autoconf
        apt-get install liblzo2-dev liblzo2-2 libz-dev
        ```

    * Fedora Linux

        ```sh
        yum install git autoconf automake binutils bison flex gcc gcc-c++
        yum install gdb gettext libtool texinfo make strace ncurses-devel
        yum install lzo-devel zlib-devel patch
        ```


2. Clone the repo: 

    ```sh
        git clone https://github.com/swarco/swarco-linux-v2
    ```
    
3. Download needed packages and repos and prepare our build tree (be
  prepared, this will download over 1.6G of data...):

    ```sh
        cd swarco-linux-v2
        ./prepare_tree_github.sh
    ```

4. compile everything (now you shoud grab a coffee, this can take an
  hour or more...):

    ```sh
        make
    ```

# Output of a successfully build (in directory `tftp_root`):

| File                         | Description                                                            |
|------------------------------|------------------------------------------------------------------------|
| ccm2200.bin                  | U-Boot script for updating kernel and rootfs with an USB flash drive   |
| rootfs-ccm2200-lp-nand.jffs2 | Image of JFFS2 rootfs which can be written to NAND-flash with U-Boot   |
| u-boot-ccm2200dev.bin        | Binary Image of U-Boot (for installation with JTAG or USB flash drive) |
| u-boot-update/               | Files for updating u-boot with an USB flash drive                      |
| uImage-ccm2200dev.bin        | Linux Kernel image in u-boot image format                              |


# Documentation

This repository contains a skeleton for the SWARCO Embedded Linux V2
build environment. It also contains a Makefile for controlling the overall-
build process.

The complete environment will be populated using the prepare_tree.sh.
This script extracts the the necessary source and build system files
from buildroot, Linux kernel and uBoot sources at right places and applies the
needed patches.

An old version of the documentation for SWARCO Embedded Linux V2 can be
found under:

[doc/SWARCO-LINUX.md](doc/SWARCO-LINUX.md)


# License Information 

This project contains code from Buildroot project (from
[http://git.buildroot.net/buildroot](http://git.buildroot.net/buildroot)) which is a base for the SWARCO
Embedded Linux V2 operating system used on the CCM2200 CPU.

Buildroot itself and all files in this repository contributed by
SWARCO are licensed under the
[GNU General Public License, version 2](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
or (at your option) any later version, with the exception of the
package patches.

Buildroot also bundles patch files, which are applied to the sources
of the various packages. Those patches are not covered by the license
of Buildroot. Instead, they are covered by the license of the software
to which the patches are applied. When said software is available
under multiple licenses, the Buildroot patches are only provided under
the publicly accessible licenses.

The packages included in Buildroot and SWARCO Linux are licensed under
various open source licenses.  Some licenses require you to publish
the license text in the documentation of your product. Others require
you to redistribute the source code of the software to those that
receive your product. Please refer the Buildroot documentation and the
license documentation of each used package when distributing a product
based on this software.
