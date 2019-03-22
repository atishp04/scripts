#!/bin/bash

#./run.sh <arch> <platform> <run>

arch=$1
plat=$2
run=$3

#kernel path
#kernel="/scratch/workspace/freedom-u-sdk/work/linux/arch/riscv/boot/Image"
kernel_riscv="/home/atish/workspace/linux/arch/riscv/boot/Image"
kernel_arm="/home/atish/workspace/linux/arch/arm/boot/zImage"
kernel_arm64="/home/atish/workspace/linux/arch/arm64/boot/Image"

#rootfs path
rootfs_path="/home/atish/workspace/rootfs_images"
rootfs_arm="$rootfs_path/arm_busybox_rootfs.img"
rootfs_arm64="$rootfs_path/arm64_busybox_rootfs.img"
#rootfs_arm64="/home/atish/workspace/rootfs_images/arm64_busybox_rootfs.ext2"

#qemu path
qemu_bin_riscv64="/home/atish/workspace/qemu/riscv64-softmmu/qemu-system-riscv64"
qemu_bin_riscv32="/home/atish/workspace/qemu/riscv32-softmmu/qemu-system-riscv32"
qemu_bin_arm="/home/atish/workspace/qemu/arm-softmmu/qemu-system-arm"
qemu_bin_arm64="/home/atish/workspace/qemu/aarch64-softmmu/qemu-system-aarch64"

#rootargs
rootarg_vda="root=/dev/vda"
rootarg_ram="root=/dev/ram0"

#kernel cmdline
cmdline_riscv="'$rootarg_vda rw console=ttyS0 earlycon=sbi'"
cmdline_arm="'$rootarg_ram rw console=ttyS0 console=ttyAMA0'"
cmdline_arm64="'$rootarg_ram rw console=ttyS0 console=ttyAMA0'"

qemu_payload_riscv64="~/workspace/opensbi/build/platform/qemu/virt/firmware/fw_payload.elf"

if [ "$arch" == "riscv64" ]; then
	export CROSS_COMPILE=riscv64-linux-
	XLEN=64
	qemu_bin=$qemu_bin_riscv64
	rootfs_riscv_initramfs="$rootfs_path/riscv64_busybox_rootfs.img"
elif [ "$arch" == "riscv32" ]; then
	export CROSS_COMPILE=riscv32-unknown-linux-gnu-
	XLEN=32
	qemu_bin=$qemu_bin_riscv32
	rootfs_riscv_initramfs="$rootfs_path/riscv32_busybox_rootfs.img"
fi

#arch specific
if [ "$arch" == "riscv64" ] || [ "$arch" == "riscv32" ]; then
	cmdline=$cmdline_riscv
	kernel=$kernel_riscv
	#rootfs_riscv_ext2="/home/atish/workspace/rootfs_images/riscv64_busybox_rootfs.ext2"
	rootfsargs="-initrd $rootfs_riscv_initramfs"
	#rootfsargs="-drive file=$rootfs_riscv_ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
	qemu_run_cmd="$qemu_bin -M virt -m 256M -smp 8 -display none -serial mon:stdio -kernel $qemu_payload_riscv64 \
		$rootfsargs \
		-netdev user,id=net0 -device virtio-net-device,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::10000-:22 -s -append $cmdline" 

elif [ "$arch" == "arm" ]; then
	qemu_bin=$qemu_bin_arm
	cmdline=$cmdline_arm
	kernel=$kernel_arm
	rootfsargs="-initrd $rootfs_arm"
	#rootfsargs="-drive file=$rootfs_arm,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
	qemu_run_cmd="$qemu_bin -M virt -m 256M -smp 8 -display none -serial mon:stdio -kernel $kernel \
		$rootfsargs \
		-netdev user,id=net0 -device virtio-net-device,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::10000-:22 -s -append $cmdline" 

elif [ "$arch" == "arm64" ]; then
	qemu_bin=$qemu_bin_arm64
	cmdline=$cmdline_arm64
	kernel=$kernel_arm64
	rootfsargs="-initrd $rootfs_arm"
	#rootfsargs="-drive file=$rootfs_arm64,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
	qemu_run_cmd="$qemu_bin -M virt -m 256M -smp 8 -cpu cortex-a57 -display none -serial mon:stdio -kernel $kernel \
		$rootfsargs \
		-netdev user,id=net0 -device virtio-net-device,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::10000-:22 -s -append $cmdline" 
fi

#Build the firmware if riscv
if [ "$arch" == "riscv64" ] || [ "$arch" == "riscv32" ]; then
	make distclean
	echo "Building the firmware...."
	export ARCH=riscv
if [ "$plat" == "qemu" ]; then
	make -j 32 PLATFORM=qemu/virt FW_PAYLOAD_PATH=$kernel PLATFORM_RISCV_XLEN=$XLEN
elif [ "$plat" == "fu540" ]; then
	#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=$kernel
	make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=$kernel FW_PAYLOAD_FDT="unleashed_topology.dtb"
	cp build/platform/sifive/fu540/firmware/fw_payload.bin /tmp/bl.bin 
elif [ "$plat" == "fu540_uboot" ]; then
	~/workspace/u-boot/tools/mkimage -A riscv -O linux -T kernel -C none -a 0x80200000 -e 0x80200000 -n Linux -d $kernel uImage
	#4k Aligned address
	#~/workspace/u-boot/tools/mkimage -A riscv -O linux -T kernel -C none -a 0x80020000 -e 0x80020000 -n Linux -d $kernel uImage
	cp uImage /tftpboot/	
	#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=~/workspace/u-boot/u-boot.bin FU540_ENABLED_HART_MASK=0x02
	#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=~/workspace/u-boot/u-boot.bin
	make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=~/workspace/u-boot/u-boot.bin FW_PAYLOAD_FDT="unleashed_topology.dtb"
	cp build/platform/sifive/fu540/firmware/fw_payload.bin /tmp/bl.bin 
elif [ "$plat" == "fu540_uboot_linux" ]; then
	~/workspace/u-boot-riscv/tools/mkimage -A riscv -O linux -T kernel -C none -a 0x80200000 -e 0x80200000 -n Linux -d $kernel uImage
	dd if=~/workspace/u-boot/u-boot.bin of=/tmp/temp.bin bs=1M
	dd if=uImage of=/tmp/temp.bin bs=1M seek=4
	#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=/tmp/temp.bin FU540_ENABLED_HART_MASK=0x02
	make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=/tmp/temp.bin
	cp build/platform/sifive/fu540/firmware/fw_payload.bin /tmp/bl.bin
fi
echo "Firmware build done...."
fi

#QEMU command

if [ "$plat" == "qemu" -a "$run" == "run" ];then
	echo "Running in QEMU: $qemu_run_cmd"
	eval $qemu_run_cmd
fi
