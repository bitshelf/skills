# AIoT build.sh Reference

All commands run from the SDK root. Entry chain: `build.sh` → `build/top_build.sh`
→ `build/mkcommon.sh` (argument parsing) → `build/mkcmd.sh` (implementations).

## Configuration state

- `.buildconfig` (SDK root): persisted selection — `LICHEE_PLATFORM`,
  `LICHEE_LINUX_DEV`, `LICHEE_IC`, `LICHEE_BOARD`, flash media, kernel version.
- `build/envsetup.sh`: environment plumbing sourced by the wrapper; not a
  user-facing setup script.
- Selectors enumerate options live from the tree: board schemes from
  `device/config/chips/<ic>/configs/`, kernel versions from `kernel/`. The
  supported SoC set therefore depends on the checkout — enumerate, do not
  assume.
- Running any build command without `.buildconfig` drops into the same
  interactive `mk_config` selection first; `./build.sh autoconfig` exists for
  scripted selection.

## Directory map (build-relevant)

| Path | Role |
|---|---|
| `brandy/` | boot0, U-Boot, arisc, DRAM libs (`brandy-2.0/u-boot-*`) |
| `bsp/` | Allwinner drivers and kernel changes layered on the vanilla kernel |
| `kernel/` | vanilla kernel trees (`linux-5.10`, `linux-5.15`, …) |
| `buildroot/`, `debian/`, `yocto/` | rootfs build systems |
| `device/config/chips/<ic>/configs/` | board schemes |
| `target/` | board/chip business logic configuration mirroring `device/` |
| `out/` | build output root (`LICHEE_OUT_DIR`), toolchain under `out/external-toolchain/` |
| `tools/pack/` | host-side packing tools |
| `docs/` | per-chip hardware docs, software guides, production guides; see `docs/docs_list.txt` |

## Additional build actions

Beyond the table in SKILL.md, the wrapper accepts: `arisc`, `rtos`, `dsp`,
`bootimg`, `ramfs`, `recovery`, `independent_package`, `mergeconfig`,
`loadconfig`, `recovery_menuconfig`/`recovery_saveconfig`, `bsp_rootfs`,
`buildroot_saveconfig`, `check_gki*`, `uboot_force`. Discover the exact set for
this checkout from `build/mkcommon.sh` before relying on one.

## U-Boot variants

The SDK ships multiple U-Boot versions under `brandy/brandy-2.0/`. Newer
U-Boot (e.g. u-boot-2023) uses a split layout: vanilla U-Boot tree plus a
`u-boot-bsp` directory that the build merges in automatically. Treat
`./build.sh bootloader` as the only supported entry; do not build U-Boot by
hand inside `brandy/` unless the project workflow says otherwise.

## Kernel config fragments

`menuconfig` operates on the effective defconfig for the selected board;
`saveconfig` writes the result back to the board's config consumed by the SDK.
Prefer `mergeconfig`/`loadconfig` for scripted fragment application. Check
where the board scheme actually stores its defconfig before assuming
`saveconfig` covers every fragment in use.

## Environment note

The SDK is developed against Ubuntu (22.04 recommended); other distributions
may need host package adjustments. There is no SDK-root `install.sh`; host
setup guidance lives in the SDK development guide's environment chapter and
the platform download page.

## Failure handling

Each `./build.sh` run prints an `ACTION List:` line naming the functions it
will execute. On failure, identify the failing action, read its log under
`out/`, fix, and re-run that scope only. Do not loop full builds on an
unexplained error, and do not package an image from a partially failed build.
