#!/usr/bin/env bash
# Rockchip Android direct kernel helper. Run from the SDK root after explicit lunch.
set -eo pipefail
if [[ "${1:-}" == --help ]]; then
    cat <<'EOF'
Usage: kernel.sh [uboot|menuconfig|compile_commands]
Requires an explicitly selected TARGET_PRODUCT and TARGET_BUILD_VARIANT.
Kernel builds require KERNEL_TOOLCHAIN_BIN, KERNEL_ARCH (or PRODUCT_KERNEL_ARCH),
and KERNEL_MAKE_ARGS selected from the SDK wrapper. BOOT_IMG is required for image builds.
Optional KERNEL_DIR overrides kernel-<PRODUCT_KERNEL_VERSION>; BUILD_JOBS sets jobs.
KERNEL_MAKE_ARGS is a whitespace-separated list of make assignments, not shell code.
Use the SDK wrapper when its layout or build arguments do not match this helper.
EOF
    exit 0
fi
[[ -n "${TARGET_PRODUCT:-}" && -n "${TARGET_BUILD_VARIANT:-}" ]] || {
    printf '%s\n' 'Select the requested lunch target explicitly before running this helper.' >&2; exit 1;
}
[[ -f build/envsetup.sh ]] || { printf '%s\n' 'Run from the Android SDK root.' >&2; exit 1; }
# shellcheck source=/dev/null
source build/envsetup.sh >/dev/null || exit $?
# envsetup does not consistently support nounset; enable it after loading.
set -u
MODE="${1:-kernel}"
case "$MODE" in kernel|uboot|menuconfig|compile_commands) ;; *) printf 'Unknown mode: %s\n' "$MODE" >&2; exit 1 ;; esac
if [[ "$MODE" == uboot ]]; then
    UBOOT_DEFCONFIG="$(get_build_var PRODUCT_UBOOT_CONFIG)"
    [[ -n "$UBOOT_DEFCONFIG" ]] || { printf '%s\n' 'PRODUCT_UBOOT_CONFIG is empty.' >&2; exit 1; }
    # No implicit clean or SPL flags; use the SDK wrapper for such variants.
    (cd u-boot && make "$UBOOT_DEFCONFIG" && ./make.sh)
    exit $?
fi
: "${KERNEL_TOOLCHAIN_BIN:?Resolve KERNEL_TOOLCHAIN_BIN from the selected SDK build wrapper}"
: "${KERNEL_MAKE_ARGS:?Provide the selected SDK kernel make assignments}"
[[ -d "$KERNEL_TOOLCHAIN_BIN" ]] || { printf '%s\n' 'Kernel toolchain directory does not exist.' >&2; exit 1; }
KERNEL_TOOLCHAIN_BIN="$(realpath "$KERNEL_TOOLCHAIN_BIN")"
export PATH="$KERNEL_TOOLCHAIN_BIN:$PATH"
KERNEL_ARCH="${KERNEL_ARCH:-$(get_build_var PRODUCT_KERNEL_ARCH)}"
[[ -n "$KERNEL_ARCH" ]] || { printf '%s\n' 'Resolve KERNEL_ARCH from the selected product.' >&2; exit 1; }
KERNEL_DIR="${KERNEL_DIR:-kernel-$(get_build_var PRODUCT_KERNEL_VERSION)}"
read -r -a MAKE_ARGS <<< "$KERNEL_MAKE_ARGS"
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"
case "$MODE" in
    menuconfig)
        (cd "$KERNEL_DIR" && make "${MAKE_ARGS[@]}" "ARCH=$KERNEL_ARCH" menuconfig && make "${MAKE_ARGS[@]}" "ARCH=$KERNEL_ARCH" savedefconfig)
        ;;
    compile_commands)
        (cd "$KERNEL_DIR" && make "${MAKE_ARGS[@]}" "ARCH=$KERNEL_ARCH" compile_commands.json)
        ;;
    kernel)
        : "${BOOT_IMG:?Resolve BOOT_IMG as expected relative to the kernel build directory}"
        KERNEL_DTS="$(get_build_var PRODUCT_KERNEL_DTS)"
        [[ -n "$KERNEL_DTS" ]] || { printf '%s\n' 'PRODUCT_KERNEL_DTS is empty.' >&2; exit 1; }
        (cd "$KERNEL_DIR" && make "${MAKE_ARGS[@]}" "ARCH=$KERNEL_ARCH" "BOOT_IMG=$BOOT_IMG" "$KERNEL_DTS.img" "-j$BUILD_JOBS")
        ;;
esac
