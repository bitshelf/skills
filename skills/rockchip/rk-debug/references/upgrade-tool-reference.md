# upgrade_tool Routing

Run upgrade_tool on the USB host connected to the selected target. The presence of the executable on the DUT does not establish a self-flashing topology.

Use the installed tool's help/version for syntax. `LD` enumerates connections; it does not independently identify the requested DUT. `PL`, where supported, provides the current partition layout. Do not infer rootfs flags or offsets from another board's parameter file.

## Operation reference

| Operation | Purpose |
|---|---|
| `LD` | Enumerate USB devices |
| `DB <loader>` | Download a board-compatible loader to RAM (MASKROM recovery entry) |
| `PL` | Inspect partition layout where supported |
| `DI -<partition> <image>` | Write a partition image by name, e.g. `di -boot boot.img` |
| `WL <start-sector> <image>` | Write a raw image at a verified sector offset |
| `UF <update.img>` | Apply a packaged full firmware image |
| `RD` | Reset the selected USB target |

Commands are shown as the uppercase mnemonics printed by the tool's help; in practice they are typed lowercase (`upgrade_tool uf update.img`).

## Recovery notes

- `DI -r` denotes recovery in common versions, not rootfs; verify installed mappings.
- A Rockchip packaged `update.img` is not generally a raw SD-card image: never feed it to `dd` just because of its extension.
- Never reuse a historical LBA or `/dev/mmcblk0pN`; derive start sector and capacity from the current target partition table and verify sector units before `WL`.
- Stop on loader errors or unexpected storage information; do not blindly retry writes or escalate to erase/full recovery.

For the full flashing procedure (transfer verification, size checks, boot acceptance), use the `rk-build` skill. The write workflow lives there; this page only routes recovery operations.
