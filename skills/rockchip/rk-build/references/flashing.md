# Flashing Rockchip Linux Images

## Resolve the write target

Record the selected DUT, USB host, artifact checksum, intended partition or full-image scope, and observed device mode. On remote setups, transfer the artifact to a task-specific directory on the USB host and compare checksums there. Use configured SSH credentials and normal host-key verification.

Run the installed `upgrade_tool` help/version and `LD` on the host physically connected to the DUT. Enumeration proves a Rockusb device is present, not that it is the intended board. Correlate USB path/serial/chip information and the project topology. With multiple or ambiguous devices, stop before writing until selection is unambiguous. Do not reboot the Dev Host or write its disks as part of a DUT flash.

For target SSH, corroborate identity using serial-derived network information, model, kernel, and storage layout. Two boards may have the same model; a matching SoC alone is insufficient.

## Enter the required mode

Use the current serial tool schema and configured DUT. From responsive Linux, a supported `reboot loader` may enter Rockusb directly. From U-Boot, inspect command support and storage numbering before using `rockusb 0 mmc <device>`. A U-Boot prompt is not itself Loader mode; confirm USB enumeration afterward.

If software entry is unavailable, use a configured reset/MASKROM sequence within the authorized recovery scope. Boot-time serial shortcuts are another hardware-level entry: hold `ctrl+d` (Loader) or `ctrl+b` (MASKROM) from power-on — retries may be needed and they are ineffective with secure boot enabled. Confirm the wiring and tool behavior; do not assume a button pulse includes reset. Follow board documentation for physical recovery, not a generic pin-short recipe.

In MASKROM, download a board-compatible loader with `DB` when required, then re-enumerate before the next operation. Stop on loader errors or unexpected storage information; do not blindly retry writes or escalate to erase/full recovery.

## Select the image operation

Consult installed help for exact syntax and supported flags. Typical operations:

| Operation | Purpose |
|---|---|
| `LD` | Enumerate USB devices |
| `DB <loader>` | Download a loader to RAM |
| `PL` | Inspect partition layout where supported |
| `DI -<partition> <image>` | Write a partition image by name, e.g. `di -boot boot.img`, `di -uboot uboot.img` |
| `WL <start-sector> <image>` | Write a raw image at a verified sector offset |
| `UF <update.img>` | Apply a packaged full firmware image |
| `RD` | Reset the selected USB target |

Commands are shown as the uppercase mnemonics printed by the tool's help; in practice they are typed lowercase (`upgrade_tool uf update.img`, `wl 0 rootfs.wic`). Follow the installed help for exact syntax and flags.

For raw rootfs/partition iteration, derive the start and capacity from the current target partition table and compare with the intended firmware layout. Verify sector units and that the expanded image fits. Sparse or packaged images require a compatible writer or conversion; file size alone does not establish fit. Never reuse a historical LBA or `/dev/mmcblk0pN`. `DI -r` denotes recovery in common versions, not rootfs; verify installed mappings.

Use partition writes when they satisfy the requested update. Use `update.img` for the requested full firmware/recovery workflow. A Rockchip packaged `update.img` is not generally a raw SD-card image: never feed it to `dd` just because of its extension. For removable media, use the SDK's documented raw disk image and verify the destination is the intended unmounted removable device.

Target-side `dd` is an alternative only when explicitly chosen or supported by the project workflow. Verify the exact target, resolve partition names, inspect mounts, and ensure the image fits; do not overwrite a mounted root filesystem. Flush writes and check command success before rebooting. A failure from `DI` is not permission to guess a block-device fallback.

## Acceptance

Keep writer output and verify content by supported readback/checksum when practical. After reset, capture the current boot and check expected build identity, storage/mount state, and changed functionality. If writing succeeds but boot verification fails, retain evidence and diagnose before another write.
