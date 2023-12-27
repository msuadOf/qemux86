export ARCH=x86

PWD=$(shell pwd)
Linux_name=linux-4.14.334
Linux_pkgname=$(Linux_name).tar.xz
Linux_src=$(Linux_name)/
BusyBox_name=busybox-1.32.0
BusyBox_src=$(BusyBox_name)/
BUILD_DIR=build
ROOTFS_SRC=$(BUILD_DIR)/rootfs.img

file_download:
	@ sh scripts/file_download.sh
	@ echo " - Download finished"

mkdir_build:
	mkdir -p $(BUILD_DIR)

$(Linux_name).tar.gz busybox-1.32.0.tar.bz2:file_download
$(Linux_name):$(Linux_pkgname)
	tar -xvf $^

busybox-1.32.0:busybox-1.32.0.tar.bz2
	tar -jxvf $^

make_busybox:busybox-1.32.0
	cp scripts/.config.busybox busybox-1.32.0/.config
	make -C  busybox-1.32.0/ -j

$(ROOTFS_SRC):$(BusyBox_name) mkdir_build make_busybox
	cd $(BusyBox_src) && sh $(PWD)/scripts/gen_rootfs.sh
	cp $(BusyBox_name)/rootfs.img $(ROOTFS_SRC)

build_linux_kernel:
	make -C $(Linux_src) x86_64_defconfig
	make -C $(Linux_src) -j
	@ echo " - Linux Kernel Build finished !"

bzImage:$(Linux_name) mkdir_build build_linux_kernel
	cp $(Linux_src)/arch/x86_64/boot/bzImage $(BUILD_DIR)

pack_image image_release:bzImage $(ROOTFS_SRC)
	cp -r build qemu-linux-x86_64-imgpkg
	tar -czvf qemu-linux-x86_64-imgpkg.tar qemu-linux-x86_64-imgpkg

unpack_image:
	tar -xvf  qemu-linux-x86_64-imgpkg.tar 

qemu:bzImage $(ROOTFS_SRC)
	qemu-system-x86_64 -kernel ./build/bzImage  -hda ./build/rootfs.img  -append "root=/dev/sda console=ttyS0" -nographic

.default qemu