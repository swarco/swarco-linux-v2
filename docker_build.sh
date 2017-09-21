#!/bin/bash

set -e -x
id

git clone https://github.com/swarco/swarco-linux-v2

cd swarco-linux-v2
./prepare_tree_github.sh && make
(
    cd tftp_root
    tar cjf ../../swarco-linux-v2_images.tar.bz2 .
)

#(
    #    tar cJf ../swarco-linux-v2_staging_dir.tar.bz2 buildroot/buildroot-2.0/build_arm/staging_dir
#)
pwd
cd ..

#test cross compiler
PATH=$PATH:$PWD/swarco-linux-v2/buildroot/buildroot-2.0/build_arm/staging_dir/usr/bin
export PATH
echo -e '#include <stdio.h>\nint main() { printf("Hello\\n"); }' >hello.c
arm-linux-uclibc-gcc -o hello hello.c        

mv swarco-linux-v2/buildroot/buildroot-2.0/build_arm/staging_dir .
ls -l

# remove swarco-linux-v2 build directory after build to prevent too
# large Docker image
rm -rf swarco-linux-v2
#mkdir swarco-linux-v2
mkdir -p swarco-linux-v2/buildroot/buildroot-2.0/build_arm/
mv staging_dir swarco-linux-v2/buildroot/buildroot-2.0/build_arm/

#cd swarco-linux-v2
#tar xjf ../swarco-linux-v2_staging_dir.tar.bz2
arm-linux-uclibc-gcc -o hello hello.c
#cd ..
ls -l

echo Oki Doki
exit 0
