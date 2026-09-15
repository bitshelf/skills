# Direct kernel build and boot image repack

Use when the requested workflow builds a Rockchip Android kernel/DT target and replaces the kernel/resource payloads in an existing compatible `boot.img`. Newer kernels can require Rust, bindgen, kernel host tools, and host libraries in addition to Clang. This is a direct build workflow, not a full Android rebuild.

## Resolve the inputs from this checkout

1. Establish the product, kernel source directory, architecture, DTS and config chain. Read the selected SDK wrapper and the build configuration it actually uses (`build.config*`, toolchain definitions or generated build commands). Kernel build configuration can select a different compiler from Android userspace Soong. Prefer the configuration for this build path over another compiler declaration elsewhere in the SDK.
2. Resolve absolute paths for the selected Clang root, Rust root, kernel-build-tools root, bindgen executable and libclang directory. Inspect available prebuilts only to locate the configured versions. Do not hard-code a Clang revision, Rust version, SDK directory, or pick the lexically latest directory. If the selected versions cannot be established, resolve that ambiguity before building.
3. Read the required make assignments and ordered defconfig/fragments. Use the branch's Android fragment and chip/product fragments; do not substitute an `android-16.config` fragment into another AOSP version. Resolve architecture/cross-prefix and flags such as `KBUILD_GENDWARFKSYMS_STABLE=1` from this branch, not from the kernel version alone.
4. Resolve the existing input boot image, confirm its product/variant/layout compatibility, and record its checksum. `BOOT_IMG` supplies an existing image to the kernel packer; it is not a generic output-path option. Inspect the `<dts>.img` recipe and packing script to determine the actual output and whether the input is overwritten. Preserve the input when the implementation writes in place.
5. Check GKI versus non-GKI behavior in that packing implementation. Use the repack path for either only when supported by this branch. For GKI, still trace module staging, loading lists and vendor_boot/vendor_dlkm/recovery outputs; this method alone does not deliver updated `.ko` files or authorize replacing a generic kernel with an incompatible one.

## Parameterized Bash recipe

Run from the resolved kernel source directory. Populate the following variables and arrays from the selected product and kernel build configuration in the same Bash process before using this recipe:

| Input | Meaning |
|---|---|
| `CLANG_ROOT`, `RUST_ROOT` | Absolute roots containing the selected tools' `bin/` directories |
| `KERNEL_BUILD_TOOLS_ROOT` | Absolute root containing the required host `bin/`, `lib64/` and `include/` |
| `BINDGEN`, `LIBCLANG_PATH` | Absolute path to the selected bindgen executable and matching libclang directory |
| `KERNEL_ARCH`, `KERNEL_DTS` | Resolved architecture and DT image target stem |
| `BOOT_IMG` | Absolute path to a compatible existing boot image |
| `KERNEL_CONFIGS` | Bash array of base defconfig followed by ordered Android/chip/product fragments |
| `KERNEL_MAKE_ARGS` | Bash array of verified make assignments, e.g. LLVM/cross-prefix and branch-required stable-symbol flags |
| `BUILD_JOBS` | Job count selected for the build host |

These arrays are shell data, not command strings to evaluate. Preserve quoting, including paths with spaces. This recipe assumes the checkout's verified in-tree build; if it requires `O=` or another environment, adapt configuration, packing inputs and output paths consistently using its supported workflow.

```bash
set -eo pipefail
: "${CLANG_ROOT:?Resolve the selected kernel Clang root}"
: "${RUST_ROOT:?Resolve the matching Rust root}"
: "${KERNEL_BUILD_TOOLS_ROOT:?Resolve matching kernel host tools}"
: "${BINDGEN:?Resolve bindgen}"
: "${LIBCLANG_PATH:?Resolve matching libclang}"
: "${KERNEL_ARCH:?Resolve the product kernel architecture}"
: "${KERNEL_DTS:?Resolve the product DT image target}"
: "${BOOT_IMG:?Select an existing compatible boot image}"
: "${BUILD_JOBS:?Select build parallelism}"
[[ ${#KERNEL_CONFIGS[@]} -gt 0 && ${#KERNEL_MAKE_ARGS[@]} -gt 0 ]] || {
    echo 'Resolve kernel configuration and make argument arrays first.' >&2
    exit 1
}
[[ -x "$CLANG_ROOT/bin/clang" && -x "$RUST_ROOT/bin/rustc" && -x "$BINDGEN" ]]
[[ -d "$LIBCLANG_PATH" && -d "$KERNEL_BUILD_TOOLS_ROOT/bin" ]]
[[ -d "$KERNEL_BUILD_TOOLS_ROOT/include" && -d "$KERNEL_BUILD_TOOLS_ROOT/lib64" ]]
[[ "$BOOT_IMG" = /* && -f "$BOOT_IMG" ]]

export PATH="$KERNEL_BUILD_TOOLS_ROOT/bin:$CLANG_ROOT/bin:$RUST_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$KERNEL_BUILD_TOOLS_ROOT/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LIBCLANG_PATH

host_args=(
    "HOSTCFLAGS=-I$KERNEL_BUILD_TOOLS_ROOT/include"
    "HOSTLDFLAGS=-L$KERNEL_BUILD_TOOLS_ROOT/lib64"
    "BINDGEN=$BINDGEN"
)
make "${KERNEL_MAKE_ARGS[@]}" "${host_args[@]}" \
    "ARCH=$KERNEL_ARCH" "${KERNEL_CONFIGS[@]}"
make "${KERNEL_MAKE_ARGS[@]}" "${host_args[@]}" \
    "ARCH=$KERNEL_ARCH" "BOOT_IMG=$BOOT_IMG" "$KERNEL_DTS.img" "-j$BUILD_JOBS"
```

The two make invocations configure first, then build/repack; a failed configuration must stop the image build. Merge any additional SDK-required host flags into the arrays rather than discarding them. Check `clang --version`, `rustc --version` and bindgen compatibility against the selected configuration, and retain the build log. Inspect the actual new boot image and checksum, then report its path and any additional GKI artifacts still needed. Do not claim Android images or device validation were refreshed merely because this target succeeded.
