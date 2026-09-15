#!/bin/bash
# Rockchip Android SDK — fast kernel/uboot build script
# Preferred over ./build.sh -K/-U (much faster, direct make invocation)
#
# Usage:
#   ./kernel.sh                  # build kernel
#   ./kernel.sh uboot            # build U-Boot
#   ./kernel.sh menuconfig       # kernel menuconfig
#   ./kernel.sh compile_commands # generate compile_commands.json

source build/envsetup.sh >/dev/null

# Auto-lunch if not set
if [[ ! $(get_build_var PRODUCT_KERNEL_VERSION) ]]; then
	TARGET_PRODUCT=$(ls out/target/product/ 2>/dev/null | head -1)
	if [[ -n "$TARGET_PRODUCT" ]]; then
		BUILD_VARIANT=$(get_build_var TARGET_BUILD_VARIANT 2>/dev/null || echo "userdebug")
		lunch ${TARGET_PRODUCT}-${BUILD_VARIANT}
	fi
fi

export PATH=$(gettop)/prebuilts/clang/host/linux-x86/clang-r487747c/bin:$PATH
ADDON_ARGS="CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"

KERNEL_DTS=$(get_build_var PRODUCT_KERNEL_DTS)
UBOOT_DEFCONFIG=$(get_build_var PRODUCT_UBOOT_CONFIG)
KERNEL_ARCH=arm64
BUILD_JOBS=$(nproc)
TARGET_PRODUCT=$(get_build_var TARGET_PRODUCT)
BOOT_IMG=../rockdev/Image-${TARGET_PRODUCT}/boot.img

if [[ "x$1" = "xuboot" ]]; then
	echo "start build uboot: $UBOOT_DEFCONFIG"
	cd u-boot && make clean && make mrproper && make distclean && make $UBOOT_DEFCONFIG && ./make.sh --spl-new && cd -
	exit 0
fi

KERNEL_VERSION=$(get_build_var PRODUCT_KERNEL_VERSION)
KERNEL_PATH=kernel-${KERNEL_VERSION}

pushd $KERNEL_PATH

if [[ "x$1" = "xmenuconfig" ]]; then
	make $ADDON_ARGS ARCH=$KERNEL_ARCH menuconfig
	make savedefconfig
elif [[ "x$1" = "xcompile_commands" ]]; then
	make $ADDON_ARGS ARCH=$KERNEL_ARCH compile_commands.json
else
	make $ADDON_ARGS ARCH=$KERNEL_ARCH BOOT_IMG=$BOOT_IMG $KERNEL_DTS.img -j$BUILD_JOBS
fi

popd
