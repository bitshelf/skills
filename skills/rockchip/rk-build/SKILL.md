---
name: rk-build
description: Build, configure, package, and flash Rockchip Linux SDK components using the project's build workflow. Use for Rockchip kernel, bootloader, rootfs, firmware, or upgrade_tool tasks; route Android SDK builds to the Android workflow.
---

# Rockchip Linux Build and Flash

**Bundled paths:** Resolve relative paths from the directory containing this SKILL.md, while keeping build and target commands in the requested project directory.

Treat documented board names, toolchain versions, paths, and command examples as version-specific. For Rockchip Android SDK builds, use the `android` skill.

## Establish the project workflow

Find the SDK root, project instructions, release/manifest, selected board configuration, and relevant build scripts. Read `device/rockchip/common/README.md` when present, then inspect `./build.sh help` (or `-h`), `make help`, and the component hooks before choosing commands. SDK generations differ in command names, output paths, and packaging side effects. Use the project's wrapper when available; use component commands only when the repository workflow or user request calls for them.

Resolve the active kernel directory rather than assuming `kernel/`: SDKs can contain versioned trees or symlinks. Inspect `device/rockchip/` for the available chips and board defconfigs; determine the selected config and its includes from the current checkout. Do not copy a board choice or menu index from the guide. `rockchip_defconfig` may point to a default board rather than the requested one.

Build on the Linux host supported by the checked-out release. Resolve host dependencies and cross-compilers from its documentation, configuration, and `prebuilts/` or the configured rootfs toolchain. Confirm compiler version, architecture, ABI, and sysroot for direct component/application builds; do not hard-code the guide's GCC version or assume all boards use arm64.

Identify build machine, USB flashing host, and selected DUT separately. They may share a machine in a local setup. Use current project configuration and observed connections, not remembered IPs, credentials, or board names. With multiple DUTs, resolve the requested alias to its host and serial endpoint; never select the first entry implicitly.

## Select and persist configuration

Use only the selection syntax supported by local help: examples across SDK generations include `./build.sh lunch`, `lunch:<defconfig>`, `defconfig:<config>`, and `chip:<chip>:<config>`. Select the requested board explicitly and verify the resulting configuration before building. For unattended work, resolve the named target instead of relying on an interactive default.

Keep the configuration layers distinct:

| Layer | Configure and persist |
|---|---|
| SDK / board | Where supported, run SDK-root `make menuconfig`, then `make savedefconfig`; confirm the saved destination (`RK_DEFCONFIG` in the guide's workflow). This controls component selection, rootfs, boot format, and packaging. |
| Kernel | Use local wrapper targets such as `kernel-config` and `kernel-savedefconfig` when available. Update the actual defconfig/fragment chain consumed by this board; verify the generated kernel `.config`. SDK `make menuconfig` is a separate layer. |
| Buildroot | Select the matching rootfs target with the checkout's environment setup, such as `source buildroot/envsetup.sh <rootfs-config>`, and use its configured output. Save rootfs configuration with `make update-defconfig` in the configured Buildroot workflow. The SDK board target and Buildroot rootfs target need not have the same name. |

Review the saved source diff and ensure the wrapper consumes it. Editing only a generated `.config` or output tree is insufficient for a persistent configuration change.

## Build only the requested scope

Choose targets from local help. The following are candidates to verify, not a universal command set:

| Requested result | Candidate wrapper target / action |
|---|---|
| Kernel / device tree | `./build.sh kernel`; inspect the configured boot image format and DTB packaging. |
| Bootloader / loader | The local `uboot`, `U-Boot`, or `loader` target; check the hook's actual outputs and dependencies. |
| Root filesystem | `./build.sh rootfs` for the configured builder, or supported `buildroot`, `debian`, `yocto` targets. |
| Recovery | `./build.sh recovery` when enabled; inspect its kernel and ramdisk dependencies. |
| Image staging / full upgrade package | Supported `firmware` / `updateimg` targets and their prerequisites. |
| Full build / release | Check local semantics of `all`, no-argument `./build.sh`, `release`, and `all-release` before running. |

Choose the configured rootfs builder instead of assuming Buildroot. Some releases support `RK_ROOTFS_SYSTEM=buildroot|debian|yocto` as an override; verify the hook honors it and dependencies are available before changing builders. Use the SDK's matching Buildroot/Debian/Yocto development guide for distribution-specific setup instead of copying package-install commands from another release.

- For a code compilation request, build the affected component and report its result.
- For a kernel config change, update the persistent defconfig/fragment used by the SDK, then verify the resulting configuration.
- For a Buildroot package iteration, initialize the selected rootfs environment and use a supported package target such as `make <package>-rebuild`; rebuild the rootfs image afterward if a deployable filesystem is requested. Package compilation alone does not refresh that image.
- For flashable artifacts, inspect what the component build actually produced and run the packaging step if needed. Do not assume compiling refreshes `rockdev/` or `output/firmware/`.
- For a complete release or recovery image, use the project's full firmware packaging workflow. Do not expand a partition update into a full flash automatically.

Recovery images in the guide include a kernel. When the requested deliverable includes Recovery, regenerate it after kernel changes using the selected Recovery configuration and local rebuild/reconfigure workflow. Recovery is optional; do not enable it just to complete a normal kernel build.

For rootfs customization, inspect SDK `Rootfs → Post rootfs installs` and `Overlays` options and their actual hooks. Persist added files through a configured overlay or post-rootfs hook and save the SDK configuration. A supported `post-rootfs <rootfs-dir>` target applies hooks to a tree; verify separately how that tree becomes the final filesystem image. Avoid treating edits to generated rootfs files as the source of the change.

Avoid broad clean operations for routine iterations. After an SDK update or a demonstrated incompatible configuration/toolchain change, assess stale outputs and use supported component cleanup first where sufficient. The guide recommends `cleanall` around SDK updates; inspect its deletion scope and preserve needed artifacts before using it.

## Package and inspect artifacts

Resolve the packaging behavior of `all` and no-argument invocation from the checked-out wrapper and hooks; do not infer that compilation always creates a complete `update.img`.

Inspect the active parameter/partition definition, image staging, and `package-file` used by this release. Newer SDKs may generate `package-file` from the partition definition and matching images under `output/firmware/`; older ones may use a preset. Verify intended images are included and stale or unintended images are absent. Change the source configuration or supported package editor rather than relying on a generated-file edit that the next build overwrites. Take partition names, sizes, and offsets from the current project and target rather than the guide's sample layout.

Resolve artifact symlinks (`rockdev/` commonly points to `output/firmware/`) and check freshness, format, size, and checksum before transfer. Determine where this board loads its DTB and modules; a kernel change can require matching modules, resource images, or Recovery. Report the resolved output paths and distinguish component images, staged firmware, the full upgrade package, and any release archive.

## Flash and verify

Read [references/flashing.md](references/flashing.md) before preparing or executing a write. A build request alone does not authorize flashing. Existing authorization for a specified target and image remains valid; ask only when identity, scope, or required destructive action is unresolved.

For managed serial recovery and boot evidence, use the `rk-debug` skill and the configured serial service. If it is unavailable, use an already configured target SSH path where appropriate; do not seize a managed serial endpoint.

After a write, verify the target boots the expected kernel/image and exercise the changed feature. Report build success, transfer/write success, and hardware validation separately. Preserve useful logs and artifact paths; do not claim hardware success from a build or a successful downloader exit alone.

## Optional source navigation

For clangd setup only, read [references/clangd.md](references/clangd.md). Normal builds do not require editor configuration changes.
