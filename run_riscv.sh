#!/bin/bash

#./run.sh <arch> <platform> <run> <distro> <debug> <bootloader> 

arch=$1
plat=$2
run=$3
distro=$4
debug=$5
bl=$6

#kernel path
#kernel="/scratch/workspace/freedom-u-sdk/work/linux/arch/riscv/boot/Image"
kernel_riscv="/home/atish/workspace/linux/arch/riscv/boot/Image"
kernel_arm="/home/atish/workspace/linux/arch/arm/boot/zImage"
kernel_arm64="/home/atish/workspace/linux/arch/arm64/boot/Image"

kernel_dt_path="/home/atish/workspace/linux/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb"
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

#u-boot
uboot_riscv="/home/atish/workspace/u-boot/u-boot.bin"

#kernel cmdline
#cmdline_riscv="'$rootarg_vda rw console=ttyS0 earlycon=sbi'"
cmdline_arm="'$rootarg_ram rw console=ttyS0 console=ttyAMA0'"
cmdline_arm64="'$rootarg_ram rw console=ttyS0 console=ttyAMA0'"

qemu_payload_riscv64="~/workspace/opensbi/build/platform/qemu/virt/firmware/fw_jump.bin"
script_dir="~/workspace/scripts"
uboot_env="$script_dir/tftp-boot.txt"
work_dir=$(pwd)

if [ "$arch" == "riscv64" ]; then
	export CROSS_COMPILE=riscv64-linux-
	export ARCH=riscv
	XLEN=64
	qemu_bin=$qemu_bin_riscv64
	if [ "$distro" == "busybox" ]; then
		rootfs_riscv_initramfs="$rootfs_path/riscv64_busybox_rootfs.img"
		rootfsargs="-initrd $rootfs_riscv_initramfs"
		rootarg=$rootargam
	elif [ "$distro" == "kvm" ]; then
		cd /home/atish/workspace/kvmtool
		make -j 32 lkvm-static
		riscv64-linux-strip lkvm-static
		cd -
		#TODO: build lkvm and copy that as well
		cp -f /home/atish/workspace/kvmtool/run.sh /home/atish/workspace/busybox-1.27.2-kvm-riscv64/_install/apps/
		cp -f /home/atish/workspace/kvmtool/lkvm-static /home/atish/workspace/busybox-1.27.2-kvm-riscv64/_install/apps
		cp -f /home/atish/workspace/linux/arch/riscv/boot/Image /home/atish/workspace/busybox-1.27.2-kvm-riscv64/_install/apps
		cd /home/atish/workspace/busybox-1.27.2-kvm-riscv64/_install; find ./ | cpio -o -H newc > ../../rootfs_kvm_riscv64.img; cd -
		cp rootfs_kvm_riscv64.img $rootfs_path
		rootfs_riscv_initramfs="$rootfs_path/rootfs_kvm_riscv64.img"
		rootfsargs="-initrd $rootfs_riscv_initramfs"
		rootarg=$rootargam
	elif [ "$distro" == "fedora" ];then
		#rootfs_riscv_ext2="/media/atish/scratch2/fedora_image/Fedora-Developer-Rawhide-20190328.n.0-sda.raw"
		#rootfs_riscv_ext2="/scratch2/fedora_riscv/Fedora-Developer-Rawhide-20190516.n.0-sda.raw"
		rootfs_riscv_ext2="/scratch2/fedora_riscv/Fedora_20190703_glibc_sdb.raw"
		#rootfs_riscv_ext2="/scratch2/fedora_riscv/Fedora-Developer-Rawhide-20190703.n.0-sda2.raw"
		rootfsargs="-drive file=$rootfs_riscv_ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
		rootarg="root=/dev/vda2"
		#rootarg="root=/dev/vda"
	fi
elif [ "$arch" == "riscv32" ]; then
	export ARCH=riscv
	export CROSS_COMPILE=riscv32-unknown-linux-gnu-
	XLEN=32
	qemu_bin=$qemu_bin_riscv32
	rootfs_riscv_initramfs="$rootfs_path/riscv32_busybox_rootfs.img"
fi

#arch specific
if [ "$arch" == "riscv64" ] || [ "$arch" == "riscv32" ]; then
	cmdline="'$rootarg rw console=ttyS0 earlycon=sbi'"
	kernel=$kernel_riscv
	echo "Setting qemu run cmd for $distro with $debug"
	if [ "$debug" == "gdb" ]; then
		doptions="-S"
	else
		doptions=""
	fi
	echo $doptions
	if [ "$distro" == "kvm" ]; then
		qemu_run_cmd="$qemu_bin -monitor null -cpu rv64,x-h=true -M virt -m 512M -smp 8 -display none -serial mon:stdio -kernel $qemu_payload_riscv64 \
		-device loader,file=$kernel,addr=0x80200000 $rootfsargs -append $cmdline $doptions"
	elif [ "$bl" == "uboot" ]; then
		echo "Setting qemu run cmd for $distro"
		qemu_run_cmd="$qemu_bin -M virt -m 16G -smp 8 -display none -serial mon:stdio -bios $qemu_payload_riscv64 \
			-kernel $uboot_riscv \
			-device loader,file=$kernel,addr=0x84000000 $rootfsargs \
			-object rng-random,filename=/dev/urandom,id=rng0 \
			-device virtio-rng-device,rng=rng0 \
			-netdev user,id=net0 -device virtio-net-device,netdev=usernet \
			-netdev user,id=usernet -append $cmdline $doptions" 
	else
		qemu_run_cmd="$qemu_bin -M virt -m 16G -smp 8 -display none -serial mon:stdio -bios $qemu_payload_riscv64 \
			-kernel $kernel $rootfsargs \
			-object rng-random,filename=/dev/urandom,id=rng0 \
			-device virtio-rng-device,rng=rng0 \
			-netdev user,id=net0 -device virtio-net-device,netdev=usernet \
			-netdev user,id=usernet -append $cmdline $doptions" 
		
	fi
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

cmd_uboot_script="~/workspace/u-boot/tools/mkimage -A riscv -T script -C none -n 'U-Boot boot script' -d $uboot_env ${work_dir}/boot.scr.uimg; cp ${work_dir}/boot.scr.uimg /tftpboot/"
cmd_uboot_uImage="~/workspace/u-boot/tools/mkimage -A riscv -O linux -T kernel -C none -a 0x80200000 -e 0x80200000 -n Linux -d $kernel uImage; cp uImage /tftpboot/"

#Build the firmware if riscv
if [ "$arch" == "riscv64" ] || [ "$arch" == "riscv32" ]; then
	cd /home/atish/workspace/opensbi/
	make distclean
	echo "Building the firmware...."
	if [ "$plat" == "qemu" ]; then
		make -j 32 PLATFORM=qemu/virt FW_PAYLOAD_PATH=$kernel PLATFORM_RISCV_XLEN=$XLEN
	elif [ "$plat" == "fu540" ]; then
		make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=$kernel
		#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=$kernel FW_PAYLOAD_FDT="unleashed_topology.dtb"
		#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=$kernel FW_PAYLOAD_FDT_PATH=$kernel_dt_path
		cp build/platform/sifive/fu540/firmware/fw_payload.bin /tmp/bl.bin 
	elif [ "$plat" == "fu540_uboot" ]; then
		cp $kernel /tftpboot/
		eval $cmd_uboot_uImage
		eval $cmd_uboot_script
		make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=~/workspace/u-boot/u-boot.bin FW_PAYLOAD_FDT_PATH=$kernel_dt_path 
		#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=~/workspace/u-boot/u-boot.bin
		#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=~/workspace/u-boot/u-boot.bin FW_PAYLOAD_FDT="unleashed_topology.dtb"
		cp build/platform/sifive/fu540/firmware/fw_payload.bin /tmp/bl.bin 
	elif [ "$plat" == "fu540_uboot_linux" ]; then
		~/workspace/u-boot-riscv/tools/mkimage -A riscv -O linux -T kernel -C none -a 0x80200000 -e 0x80200000 -n Linux -d $kernel uImage
		dd if=~/workspace/u-boot/u-boot.bin of=/tmp/temp.bin bs=1M
		dd if=uImage of=/tmp/temp.bin bs=1M seek=4
		#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=/tmp/temp.bin FU540_ENABLED_HART_MASK=0x02
		#make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=/tmp/temp.bin FW_PAYLOAD_FDT_PATH=/home/atish/workspace/linux/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb
		make -j 32 PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=/tmp/temp.bin
		cp build/platform/sifive/fu540/firmware/fw_payload.bin /tmp/bl.bin
	fi
	cd -
	echo "Firmware build done...."
fi
#QEMU command

if [ "$plat" == "qemu" -a "$run" == "run" ];then
	echo "Running in QEMU: $qemu_run_cmd"
	eval $qemu_run_cmd
fi
