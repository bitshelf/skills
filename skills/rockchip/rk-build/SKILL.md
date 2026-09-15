---
name: rk-build
description: Build, configure, package, and flash Rockchip Linux SDK components using the project's build workflow. Use for Rockchip kernel, bootloader, rootfs, firmware, or upgrade_tool tasks; route Android SDK builds to the Android workflow.
---

# Rockchip Linux Build and Flash

## Establish the project workflow

Find the SDK root, project instructions, selected board configuration, and relevant build scripts. Inspect `./build.sh help` and the component hooks before choosing commands: SDK generations differ in command names, output paths, and packaging side effects. Use the project's wrapper when available; use component commands only when the repository workflow or user request calls for them.

Identify build machine, USB flashing host, and selected DUT separately. They may share a machine in a local setup. Use current project configuration and observed connections, not remembered IPs, credentials, or board names. With multiple DUTs, resolve the requested alias to its host and serial endpoint; never select the first entry implicitly.

## Build only the requested scope

Common wrapper commands include `kernel`, `loader`, `kernel-config`, `kernel-savedefconfig`, `firmware`, and `updateimg`; verify support locally. Choose the configured rootfs builder instead of assuming Buildroot or a particular distribution.

- For a code compilation request, build the affected component and report its result.
- For a kernel config change, update the persistent defconfig/fragment used by the SDK, then verify the resulting configuration.
- For flashable artifacts, inspect what the component build actually produced and run the packaging step if needed. Do not assume compiling refreshes `rockdev/` or `output/firmware/`.
- For a complete release or recovery image, use the project's full firmware packaging workflow. Do not expand a partition update into a full flash automatically.

Resolve artifact symlinks and check freshness, format, size, and checksum before transfer. Determine where this board loads its DTB and modules; a kernel change can require matching modules or resource images. Avoid broad clean operations unless stale output requires them.

## Flash and verify

Read [references/flashing.md](references/flashing.md) before preparing or executing a write. A build request alone does not authorize flashing. Existing authorization for a specified target and image remains valid; ask only when identity, scope, or required destructive action is unresolved.

For managed serial recovery and boot evidence, use the available sermcp tools and the `rk-debug` workflow. If those tools are unavailable, use an already configured target SSH path where appropriate; do not seize a managed serial endpoint.

After a write, verify the target boots the expected kernel/image and exercise the changed feature. Report build success, transfer/write success, and hardware validation separately. Preserve useful logs and artifact paths; do not claim hardware success from a build or a successful downloader exit alone.

## Optional source navigation

For clangd setup only, read [references/clangd.md](references/clangd.md). Normal builds do not require editor configuration changes.
