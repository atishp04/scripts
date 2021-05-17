#!/bin/bash

#./run.sh <arch> <platform> <run> <distro> <debug> <bootloader> <numa> 

arch=$1
plat=$2
run=$3
distro=$4
debug=$7
bl=$6
numa_on=$5

work_dir="/home/atish/workspace"
#kernel path
#kernel="/scratch/workspace/freedom-u-sdk/work/linux/arch/riscv/boot/Image"
kernel_riscv="$work_dir/linux/arch/riscv/boot/Image"
kernel_riscv_gz="$work_dir/linux/arch/riscv/boot/Image.gz"
#kernel_riscv_gz="$work_dir/linux/arch/riscv/boot/Image.lzma"
#kernel_riscv_gz="$work_dir/linux/arch/riscv/boot/Image.lzo"
#kernel_riscv_gz="$work_dir/linux/arch/riscv/boot/Image.bz2"
kernel_arm="$work_dir/linux/arch/arm/boot/zImage"
kernel_arm64="$work_dir/linux/arch/arm64/boot/Image"
#kernel_arm64="$work_dir/linux/arch/arm64/boot/Image.gz"
#kernel_arm64="$work_dir/linux/arch/arm64/boot/Image.lzma"
#kernel_arm64="$work_dir/linux/arch/arm64/boot/Image.lzo"

kernel_dt_path="$work_dir/linux/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb"
#rootfs path
rootfs_path="$work_dir/rootfs_images"
rootfs_arm="$rootfs_path/arm_busybox_rootfs.img"
rootfs_arm64="$rootfs_path/arm64_busybox_rootfs.img"
#rootfs_arm64="$work_dir/rootfs_images/arm64_busybox_rootfs.ext2"

#qemu path
qemu_bin_riscv64="$work_dir/qemu/build/riscv64-softmmu/qemu-system-riscv64"
qemu_bin_riscv32="$work_dir/qemu/build/riscv32-softmmu/qemu-system-riscv32"
qemu_bin_arm="$work_dir/qemu/build/arm-softmmu/qemu-system-arm"
qemu_bin_arm64="$work_dir/qemu/build/aarch64-softmmu/qemu-system-aarch64"

#rootargs
rootarg_vda="root=/dev/vda"
rootarg_ram="root=/dev/ram"

#u-boot
uboot="$work_dir/u-boot/u-boot.bin"

#numa args:
echo $numa_on
if [ "$numa_on" == "numa" ]; then
	numa_args="-object memory-backend-ram,size=1024M,policy=bind,host-nodes=0,id=ram-node0 \
		   -numa node,memdev=ram-node0 \
		   -object memory-backend-ram,size=1024M,policy=bind,host-nodes=0,id=ram-node1 \
		   -numa node,memdev=ram-node1 \
		   -object memory-backend-ram,size=1024M,policy=bind,host-nodes=0,id=ram-node2 \
		   -numa node,memdev=ram-node2 \
		   -object memory-backend-ram,size=1024M,policy=bind,host-nodes=0,id=ram-node3 \
		   -numa node,memdev=ram-node3"
fi
#kernel cmdline
#cmdline_riscv="'$rootarg_vda rw console=ttyS0 earlycon=sbi'"
cmdline_arm="'$rootarg_ram rw console=ttyS0 console=ttyAMA0'"
cmdline_arm64="'$rootarg_ram rw console=ttyS0 console=ttyAMA0'"

#qemu_payload_riscv="~/workspace/opensbi/build/platform/generic/firmware/fw_jump.elf"
#qemu_payload_riscv="~/workspace/opensbi/build/platform/qemu/virt/firmware/fw_jump.bin"
qemu_payload_riscv="~/workspace/opensbi/build/platform/generic/firmware/fw_dynamic.elf"
script_dir="~/workspace/scripts"
uboot_env="$script_dir/tftp-boot.txt"

if [ "$arch" == "riscv64" ]; then
	export CROSS_COMPILE=riscv64-unknown-linux-gnu-
	export ARCH=riscv
	XLEN=64
	trace_args=""
	qemu_bin=$qemu_bin_riscv64
	kernel=$kernel_riscv
	if [ "$distro" == "busybox" ]; then
		if [ "$bl" == "uboot" ];then
			rootfs_riscv_ext2="/home/atish/workspace/rootfs_images/efi_sdcard.img"
			sudo losetup -P /dev/loop20 $rootfs_riscv_ext2
			mkdir -p /tmp/p3
			sudo mount /dev/loop20p3 /tmp/p3
			sudo cp $kernel /tmp/p3/image/
			sudo umount /dev/loop20p3
			sudo losetup -d /dev/loop20 
			rootfsargs="-drive file=$rootfs_riscv_ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
			rootarg="root=/dev/vda3 rootfstype=ext2"
			kernel=$uboot
		else
			rootfs_riscv_initramfs="$rootfs_path/rootfs_kvm_riscv64.img"
			rootfsargs="-initrd $rootfs_riscv_initramfs"
			rootarg=$rootarg_ram
			#trace_args="--trace events=/tmp/events"
		fi
	elif [ "$distro" == "kvm" ]; then
		cd /home/atish/workspace/kvmtool
		KVM_ROOTFS="/home/atish/workspace/busybox-1.27.2-kvm-riscv64/"
		LKVM_STATIC="lkvm-static"
		make -j 32 $LKVM_STATIC
		riscv64-unknown-linux-gnu-strip lkvm-static
		cd -
		#TODO: build lkvm and copy that as well
		cp -f $work_dir/kvmtool/lkvm-static $KVM_ROOTFS/_install/apps
		cp -f $work_dir/linux/arch/riscv/boot/Image $KVM_ROOTFS/_install/apps
		cd $KVM_ROOTFS/_install
		find ./ | cpio -o -H newc > $rootfs_path/rootfs_kvm_riscv64.img;
		#find ./ | cpio -H newc -o > $rootfs_path/rootfs_kvm_riscv64.cpio;
		cd -
		rootfs_riscv_initramfs="$rootfs_path/rootfs_kvm_riscv64.img"
		rootfsargs="-initrd $rootfs_riscv_initramfs"
		rootarg=$rootarg_ram
	elif [ "$distro" == "fedora" ];then
		if [ "$bl" == "uboot" ];then
			kernel=$uboot
		fi
		rootfs_riscv_ext2="/scratch2/fedora_image/Fedora-Developer-Rawhide-20200108.n.0-sda.raw"
		rootfsargs="-drive file=$rootfs_riscv_ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
		rootarg="root=/dev/vda2"
		#rootarg="root=/dev/vda"
	elif [ "$distro" == "debian" ];then
		rootfs_riscv_ext2="/scratch2/debian_image/riscv64-debianrootfs-qemu.qcow2"
		rootfsargs="-device virtio-blk-device,drive=hd0 -drive file=riscv64-debianrootfs-qemu.qcow2,format=qcow2,id=hd0"
		rootarg="root=/dev/vda2 rootfstype=ext4"
        fi
elif [ "$arch" == "riscv32" ]; then
	export CROSS_COMPILE=riscv64-unknown-linux-gnu-
	export ARCH=riscv
	XLEN=32
	qemu_bin=$qemu_bin_riscv32
	#rootfs_riscv_initramfs="$rootfs_path/riscv32_busybox_rootfs.img"
	#rootfsargs="-initrd $rootfs_riscv_initramfs"
	#rootarg="root=/dev/ram"
	rootfs_riscv_ext2="$rootfs_path/core-image-minimal-qemuriscv32.ext4"
	rootfsargs="-drive file=$rootfs_riscv_ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
	rootarg="root=/dev/vda"
fi

#arch specific
if [ "$arch" == "riscv64" ] || [ "$arch" == "riscv32" ]; then
	#cmdline="'$rootarg rw console=ttyS0 earlycon'"
	#cmdline="'$rootarg rw loglevel=8 memblock=debug console=ttyS0 earlycon=uart8250,mmio,0x10000000'"
	cmdline="'$rootarg rw loglevel=8 memblock=debug console=ttyS0 earlycon=sbi'"
	echo "Setting qemu run cmd for $distro with $debug"
	if [ "$debug" == "gdb" ]; then
		doptions="-S"
	else
		doptions="-d in_asm -D log"
	fi
	echo $doptions
	if [ "$distro" == "kvm" ]; then
		qemu_run_cmd="$qemu_bin -monitor null -cpu rv64,x-h=true -M virt -m 4G -smp 8 -display none -serial mon:stdio -bios $qemu_payload_riscv \
			-kernel $kernel $rootfsargs \
			-object rng-random,filename=/dev/urandom,id=rng0 \
			-device virtio-rng-device,rng=rng0 \
			-device virtio-net-device,netdev=usernet \
			-netdev user,id=usernet,hostfwd=tcp::10000-:22 -s -append $cmdline $doptions"
	else
		qemu_run_cmd="$qemu_bin -M virt -m 1G -smp 8 $numa_args -display none -serial mon:stdio -bios $qemu_payload_riscv \
			-kernel $kernel $rootfsargs \
			-object rng-random,filename=/dev/urandom,id=rng0 \
			-device virtio-rng-device,rng=rng0 \
			-device virtio-net-device,netdev=usernet \
			-netdev user,id=usernet,hostfwd=tcp::10000-:22 -s -append $cmdline $doptions" 
		
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
	if [ "$bl" == "uboot" ]; then
		echo "Setting qemu run cmd for $distro"
		qemu_run_cmd="$qemu_bin -M virt -m 2G -smp 8 $numa_args -cpu cortex-a57 -display none -serial mon:stdio \
			-bios $uboot \
			-kernel $kernel $rootfsargs \
			-device loader,file=$kernel,addr=0x40400000 $rootfsargs \
			-netdev user,id=net0 -device virtio-net-device,netdev=usernet \
			-netdev user,id=usernet,hostfwd=tcp::10000-:22 -s -append $cmdline" 
	else 
	#rootfsargs="-drive file=$rootfs_arm64,format=raw,id=hd0 -device virtio-blk-device,drive=hd0" 
	qemu_run_cmd="$qemu_bin -M virt -m 2G -smp 8 -cpu cortex-a57 $numa_args -display none -serial mon:stdio -kernel $kernel \
		$rootfsargs \
		-netdev user,id=net0 -device virtio-net-device,netdev=usernet \
		-netdev user,id=usernet,hostfwd=tcp::10000-:22 -s -append $cmdline" 
	fi
fi

cmd_uboot_script="~/workspace/u-boot/tools/mkimage -A riscv -T script -C none -n 'U-Boot boot script' -d $uboot_env ${work_dir}/boot.scr.uimg; cp ${work_dir}/boot.scr.uimg /tftpboot/"
cmd_uboot_uImage="~/workspace/u-boot/tools/mkimage -A riscv -O linux -T kernel -C none -a 0x80200000 -e 0x80200000 -n Linux -d $kernel uImage; cp uImage /tftpboot/"

#Build the firmware if riscv
if [ "$arch" == "riscv64" ] || [ "$arch" == "riscv32" ]; then
	cd /home/atish/workspace/opensbi/
	make distclean
	echo "Building the firmware...."
	if [ "$plat" == "qemu" ]; then
		make -j 32 PLATFORM=generic PLATFORM_RISCV_XLEN=$XLEN
		#make -j 32 PLATFORM=qemu/virt
	fi
	cd -
	echo "Firmware build done...."
fi
#QEMU command

if [ "$plat" == "qemu" -a "$run" == "run" ];then
	echo "Running in QEMU: $qemu_run_cmd"
	eval $qemu_run_cmd
fi
