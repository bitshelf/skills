# Native Components and Packaging

## Resolve the Android15 environment

The following reflects the inspected SDK and its Android15 guide V1.3.0 (2025-07-14). Recheck scripts for another branch. Run setup, lunch, variable queries, and dependent commands in one Bash shell; stop at a failing step. For example, with an explicitly resolved lunch combo:

```bash
source build/envsetup.sh || exit $?
lunch "$LUNCH_COMBO" || exit $?
get_build_var TARGET_PRODUCT
get_build_var TARGET_RELEASE
get_build_var TARGET_BUILD_VARIANT
get_build_var PRODUCT_OUT
get_build_var PRODUCT_KERNEL_PATH
get_build_var PRODUCT_KERNEL_VERSION
get_build_var PRODUCT_KERNEL_ARCH
get_build_var PRODUCT_KERNEL_CONFIG
get_build_var PRODUCT_KERNEL_DTS
get_build_var PRODUCT_UBOOT_CONFIG
get_build_var BOARD_BUILD_GKI
get_build_var BOARD_USES_AB_IMAGE
```

Set `LUNCH_COMBO` to the requested `<product>-<release>-<variant>` first. Locate product registrations in `device/rockchip/**/AndroidProducts.mk` and the checkout's release definitions; use inherited BoardConfig/product files to corroborate the resolved values. Do not run a full build just to discover a target.

## Inspect the full wrapper, not just usage

In the inspected tree, SDK-root `build.sh` points to `device/rockchip/common/build/rockchip/build.sh`. It is not a Linux SDK target-based wrapper. Its options include `-K` kernel, `-U` U-Boot, `-A` Android, `-u` update.img, `-o` OTA, `-p` release collection, `-d` DTS override, and `-J` jobs. These options enable stages; they do not necessarily skip the remaining script.

- `-K` executes kernel `make clean`, config and DT/image build; when GKI is enabled it invokes `mkcombinedroot/copy_moduls.sh`. It also has external driver stages. Inspect their status handling: the local rvcam stage prints an error but has its `exit 1` commented out.
- `-U` runs U-Boot clean/mrproper/distclean before its build.
- `-A` runs `make installclean` before Android compilation. The OTA branch also runs `make dist` and its OTA packaging script. Prefer a focused module or image target when the request is incremental and that branch supports it.
- Without `-A`, the wrapper still runs `make bootimage` and `make bootimage_debug`; resource packing and, outside its OTA branch, `./mkimage.sh` also run. Thus `-K`, `-U`, `-u`, and even no arguments are not isolated, side-effect-free probes. Read the script instead of invoking it without options to discover usage.
- `-u` uses staged images and the SDK firmware tool to produce `update.img`; `-p` additionally gathers release images, patches and build metadata. They are different deliverables.

The local wrapper hard-codes host JDK/PATH entries, whereas the guide's direct kernel example names a different Clang. Resolve the actual branch's required tools and inspect the commands they run; do not install that JDK or copy that compiler revision into another tree just because the wrapper mentions it.

## Kernel and U-Boot

Read the selected product's kernel version, source/output directories, defconfig/fragments, DT selection, toolchain, and vendor wrapper. Use the wrapper that supplies those values. Direct component commands are appropriate only when the local workflow supports them and their required arguments are established.

Do not assume all Android kernels use the same Clang revision, all trees support `make compile_commands.json`, or every board's kernel build produces a complete boot image. Preserve persistent kernel configuration in the defconfig/fragments actually consumed by the SDK; `savedefconfig` output alone may not update them.

### GKI versus non-GKI delivery

Resolve `BOARD_BUILD_GKI` first. The Android15 SDK guide §2.7 routes GKI work to the Android14 GKI guide. In that flow the generic `boot.img` and vendor driver modules are separate inputs; adding a driver can require a config fragment, a module-loading list, staging of newly built `.ko` files, and repacking the image containing them.

Inspect the current product's `mkcombinedroot/` makefiles and loading lists: the guide distinguishes vendor ramdisk, vendor-stage, and recovery modules. Preserve existing early-load ordering. Trace whether the changed module is consumed by vendor_boot, vendor_dlkm/super, or recovery in this product. Do not assume a boot-only update delivers it. After direct kernel compilation, run the verified staging step before the applicable Android image target; in the inspected checkout that helper is `copy_moduls.sh`, not the guide's `copy_modules.sh`. Its module directory is regenerated, so it is not a read-only discovery command.

For non-GKI, the Android15 guide §2.7.1 packages kernel/resource into `boot.img`. Its direct `BOOT_IMG=... <dts>.img` example depends on an existing compatible boot image and correct DT/configuration. For newer Rust-enabled direct repacking, including a GKI product only when its current packaging implementation supports it, read [kernel-boot.md](kernel-boot.md). Verify the input image belongs to the selected product, inspect the kernel packaging implementation, and inspect the new artifact before delivery. A direct repack does not replace GKI module staging or prove that boot alone is the required deployment set.

For requested clangd support, inspect the kernel's compilation-database targets or `scripts/clang-tools/gen_compile_commands.py --help`, and use the actual object output directory. Preserve existing `.clangd` settings and check a relevant source file; avoid blanket diagnostic suppression.

## Bundled kernel helper

Keep [scripts/kernel.sh](../scripts/kernel.sh) available for the Rockchip Android fast-build workflow. Run it from the SDK root, or copy it there when the requested workflow needs a local helper and no project copy exists. Do not overwrite an existing project script.

| Argument | Operation |
|---|---|
| No argument | Build the configured kernel/DT image |
| `uboot` | Build U-Boot |
| `menuconfig` | Open kernel configuration and generate savedefconfig |
| `compile_commands` | Generate the kernel compilation database |

Run `scripts/kernel.sh --help` first. The helper requires an explicit lunch target,
uses the product's architecture or an explicit override, and requires the SDK's
verified `KERNEL_TOOLCHAIN_BIN` and `KERNEL_MAKE_ARGS`. Image builds additionally
require `BOOT_IMG`; `KERNEL_DIR` can override the product-derived directory.
Make assignments are passed as arguments, not evaluated as shell code.

The helper does not choose an output directory as a target, pin a Clang revision,
perform automatic clean/mrproper/distclean, or add an SPL variant flag. It returns
the failed command's status. Use the SDK wrapper when the selected layout,
out-of-tree object directory, U-Boot variant, or packaging requires more setup.

This helper is not a replacement for the GKI workflow: it does not copy modules into `mkcombinedroot/`, update module-loading lists, or regenerate vendor_boot/vendor_dlkm/super. Its `BOOT_IMG` path supports only the verified direct repack flow. Prefer the SDK's supported path when GKI or module/image integration is involved.

## Android modules

After setup and lunch in the same shell, use a module name declared by the tree with `m`, or a supported directory-build helper such as `mmm`. Verify helper availability in this branch. Choose focused tests appropriate to the changed behavior, and distinguish compilation from deployment and execution.

## Firmware packaging

Inspect the SDK's wrapper and packaging scripts to determine component dependencies, source image paths, output paths, and signing steps. Flags such as `./build.sh -A -u` are examples from some Rockchip SDKs, not a portable command contract. Check whether a wrapper performs `installclean` or rebuilds components before using it for an incremental request.

Use the resolved product output and inspect `rockdev` links if this SDK uses them. Check that the packaged inputs belong to the selected product/variant and current build. Android boot layouts vary: account for the board's boot/vendor_boot/init_boot/DTBO images, AVB metadata, dynamic partitions, and slots only where applicable. Do not infer that a kernel change can always be deployed by writing boot alone.

In the inspected checkout, `mkimage.sh` removes and recreates `rockdev/Image-$TARGET_PRODUCT` before copying images, may prompt if `$OUT/kernel` is missing, and can skip missing images. Preserve required artifacts before staging, verify prerequisites to avoid a blocked noninteractive build, and inspect the expected image set afterward. Packaging existing outputs is still a write to the staging directory, and a successful exit alone does not prove that every required image was collected.

Only create `update.img`, OTA packages, or target-files archives when requested or needed by the established delivery workflow. Preserve the project's keys and signing configuration; a build issue does not justify disabling verification or changing keys.

## Failure handling

Read the wrapper exit status and its referenced logs. If a pipeline or helper reports success despite a failed compiler command, diagnose that failure before packaging. Preserve useful intermediates and logs; clean only the affected output when evidence supports stale state. Do not retry a full build repeatedly without addressing the observed failure.

Official background, interpreted for the checkout's version:

- [Build Android](https://source.android.com/docs/setup/build/building)
- [Build kernels](https://source.android.com/docs/setup/build/building-kernels)
