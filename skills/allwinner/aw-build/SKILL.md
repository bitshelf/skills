---
name: aw-build
description: Build, configure, adapt, pack, and flash Allwinner AIoT Linux SDK firmware using the SDK's build.sh workflow. Use in an AIoT Linux checkout with build/ and device/config/chips; covers board/SoC selection via ./build.sh config, board scheme adaptation (sys_config.fex, sys_partition.fex, env.cfg, board.dts), partial builds, pack image generation, FEL/EFEX flashing entry, and routing to the SDK's official module/production docs. Rockchip builds belong to rk-build/rk-debug; AOSP builds belong to the android skill.
---

# Allwinner AIoT Linux Build and Flash

**Bundled paths:** Resolve relative paths from the directory containing this SKILL.md, while keeping build and target commands in the requested project directory.

## Resolve the checkout and configuration

Work from the SDK root (the directory containing `build.sh` and `build/`). The
entry script is `build.sh -> build/top_build.sh`; selections are persisted in
`.buildconfig` at the root. Read `.buildconfig` first when it exists: it records
the currently selected platform, OS variant, SoC (`LICHEE_IC`), board scheme
(`LICHEE_BOARD`), flash media, and kernel version. Do not assume a previous
selection matches the requested board; re-run config when the target changes.

## Configure with ./build.sh config

`./build.sh config` is an interactive selector (logic in `build/mkcommon.sh` and
`build/mkcmd.sh`) with this order:

1. platform (linux), 2. OS variant (bsp / dragonboard / buildroot / debian /
yocto), 3. SoC (`LICHEE_IC`), 4. board scheme — enumerated live from
`device/config/chips/<ic>/configs/`, 5. flash media, 6. kernel version.

The chip list is discovered dynamically from `device/config/chips/`; never
hardcode a SoC or board name — enumerate what this checkout offers and select
per the request. After config, the environment exports `LICHEE_*` variables and
`out/` becomes the output root.

## Build only the requested scope

| Request | Command |
|---|---|
| Full build (recommended flow) | `./build.sh` |
| Bootloader (boot0/U-Boot, brandy) | `./build.sh bootloader` |
| Kernel | `./build.sh kernel` |
| Kernel modules | `./build.sh modules` |
| DTB / DTS | `./build.sh dtb` / `./build.sh dts` |
| Boot image | `./build.sh bootimg` |
| Buildroot rootfs | `./build.sh buildroot_rootfs` |
| Debian / Yocto / openWrt rootfs | `./build.sh debian_rootfs` / `yocto_rootfs` / `openwrt_rootfs` |
| One buildroot package | `./build.sh buildroot_package <pkg>` |
| Kernel menuconfig and save back | `./build.sh menuconfig` then `./build.sh saveconfig` |
| U-Boot menuconfig and save back | `./build.sh uboot_menuconfig` then `./build.sh uboot_saveconfig` |
| Rootfs menuconfig | `./build.sh buildroot_menuconfig` (also bsp_/openwrt_ variants) |
| Clean | `./build.sh clean` / `distclean` |

Details, output locations, and config-fragment handling: [references/build-reference.md](references/build-reference.md).

Build in a fresh shell from the SDK root so the wrapper sets its own
environment; do not carry `LICHEE_*` variables between different configs. A
failed step must be diagnosed from its log before packaging; the wrapper's
final exit status alone is not sufficient evidence when a pipeline ran.

## Pack

After a successful build, generate the flashable image (full-image packaging,
not per-partition writes):

| Image | Command |
|---|---|
| Normal firmware | `./build.sh pack` |
| Secure firmware | `./build.sh pack_secure` |
| Card (card0) image, serial output on TF card | `./build.sh pack_card` |
| Secure card image | `./build.sh pack_secure_card` |

The produced image lands under `out/` (naming follows the configured board and
variant; `pack -d`/`pack_card` produce `*_card0.img`). A packed firmware image
is a PhoenixSuit/LiveSuit image — it is not a raw SD/eMMC image for `dd`.

## Flash

Flashing uses Allwinner tools (bundled SDK tools are deprecated; prefer current
releases from the Allwinner customer service platform — all Windows tools ship
inside APST):

| Tool | Host | Use |
|---|---|---|
| PhoenixSuit | Windows | USB full/partial image flash (development) |
| PhoenixUSBpro | Windows | Mass production, multi-device USB |
| PhoenixCard | Windows | Bootable card image writing |
| LiveSuit | Ubuntu | USB image flash |

For remote Windows flashing hosts, the `win-remote` skill can drive these tools
over SSH.

The device must enter download (FEL/EFEX) mode first. Documented entry methods:
hold `2` on the serial console while powering on; `efex` at the U-Boot prompt;
`reboot efex` (or `adb shell reboot efex`) from a running system; FEL button if
wired; blank/blanked boot media falls back to BROM download automatically.
Details and cautions: [references/flashing.md](references/flashing.md).

## Verify

After flashing, capture the boot log over serial and check the expected build
identity (kernel version, board, rootfs type) before further work. For flashing
failures, confirm the download-mode entry method actually engaged and that the
tool recognized the device before retrying.

## Adapt a board scheme

Board adaptation happens in the scheme directory
`device/config/chips/<ic>/configs/<board>/` (kernel DTS, defconfig, partition
table, U-Boot env, sys_config), not by editing generated output under `out/`.
Layout, key files, and adaptation discipline: [references/board-config.md](references/board-config.md).

## Target access and diagnostics

- Serial console is the primary evidence source; the SDK's `reboot efex`,
  U-Boot `efex`, and the serial-'2' download entry all act through it.
- USB `adb` is available when the image enables it (`adb shell`, `adb push`);
  the development guide's adb chapter covers enabling and troubleshooting.
- After a kernel crash, the system may enter crashdump mode (watch for
  `crashdump enter` on serial); `dmesg` in that shell shows the death scene —
  see `docs/Product 量产指导文档/产线指南/Crashdump_使用指南.pdf`.
- For subsystem questions (TWI, display, Wi-Fi, NPU, secure boot, OTA,
  production triage), route via [references/doc-map.md](references/doc-map.md)
  instead of guessing; the SDK ships the authoritative guide for each module
  under `docs/`.
