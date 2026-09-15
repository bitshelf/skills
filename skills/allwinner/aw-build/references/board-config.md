# Board Scheme Configuration

A "board scheme" is a directory under
`device/config/chips/<ic>/configs/<board>/` — the unit selected as
`LICHEE_BOARD` during `./build.sh config`. `target/` mirrors these per board
during the build. Layout (verify in the actual checkout; variants exist):

```
<board>/
├── BoardConfig.mk            # build variables for the scheme
├── sys_config.fex            # SoC/board-level configuration
├── sys_config_ddr_*.fex      # per-DDR-capacity variants
├── uboot-board.dts           # U-Boot device tree
├── spl.dts, boottone.fex
├── buildroot/ debian/ yocto/ dragonboard/   # per-OS-overlay dirs
│   ├── BoardConfig.mk
│   ├── env.cfg               # U-Boot environment for this OS
│   └── sys_partition.fex     # partition table for this OS
└── linux-<ver>/              # per-kernel-version dirs (linux-5.10/5.15/6.6)
    ├── board.dts             # kernel device tree for this board
    ├── bsp_defconfig         # kernel config consumed by the SDK
    ├── bsp_recovery_defconfig
    ├── env-<ver>.cfg
    └── sys_partition.fex
```

## Key files

- `sys_partition.fex` — partition table (names, sizes, download images,
  user-data flags). Packing runs `update_mbr` on it to regenerate
  `sunxi_mbr.fex` / `sunxi_gpt.fex` and the download list `dlinfo.fex`.
- `env*.cfg` — U-Boot environment; packed via `u_boot_env_gen env.cfg env.fex`.
- `sys_config.fex` — legacy SoC/board configuration still consumed by packing
  and some drivers.
- `board.dts` / `bsp_defconfig` — the kernel-side board definition; changes
  require `./build.sh kernel` (and pack) to take effect on the target.

## Adaptation discipline

- Start from the closest existing scheme: copy the directory to a new name
  under the same chip, then adjust. Cross-chip ports are not file renames —
  follow the chip's porting checklist in `docs/`.
- Partition edits must keep image sizes consistent with the built artifacts;
  after editing `sys_partition.fex`, re-run `./build.sh pack` and verify the
  boot log partition table matches.
- Kernel config changes: `./build.sh menuconfig` then `./build.sh saveconfig`
  writes back to the scheme's defconfig — confirm the file actually changed in
  the scheme directory, not only in `out/`.
- Boot packaging (boot0/U-Boot/boot_package) is handled by the pack step;
  `boot_package.cfg` and signing inputs are driven by `dragonsecboot` inside
  the packing tools. Do not hand-assemble boot images.

Details: `Tina_Linux_打包流程_使用指南.pdf` and `Tina_Linux_存储_开发指南.pdf`
(see [doc-map.md](doc-map.md)).
