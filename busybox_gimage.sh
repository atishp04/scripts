#!/bin/bash

mkdir -p ./_install/etc/init.d
mkdir -p ./_install/dev
mkdir -p ./_install/proc
mkdir -p ./_install/sys
ln -sf /sbin/init ./_install/init
cp -f ~/workspace/xvisor/tests/common/busybox/fstab ./_install/etc/fstab
cp -f ~/workspace/xvisor/tests/common/busybox/rcS ./_install/etc/init.d/rcS
cp -f ~/workspace/xvisor/tests/common/busybox/motd ./_install/etc/motd
cp -f ~/workspace/xvisor/tests/common/busybox/logo_linux_clut224.ppm ./_install/etc/logo_linux_clut224.ppm
cp -f ~/workspace/xvisor/tests/common/busybox/logo_linux_vga16.ppm ./_install/etc/logo_linux_vga16.ppm
#cd ./_install; find ./ | cpio -o -H newc | gzip -9 > ../rootfs_cpio.img; cd -
cd ./_install; find ./ | cpio -o -H newc > ../rootfs.img; cd -
