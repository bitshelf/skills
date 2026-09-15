# Allwinner Flashing and Download Mode

## Image kinds

- `./build.sh pack*` produces a packed firmware image (PhoenixSuit/LiveSuit
  format) under `out/`. `pack_card`/`pack -d` produce `*_card0.img` variants
  whose serial output is routed to the TF card slot for production use.
- `boot.img` (boot partition payload, boot.img or uImage format depending on
  board config) and `rootfs.img` (squashfs by default) are partition images
  inside the package, not standalone flashable files.
- A packed image is **not** a raw disk image: never `dd` it to media. For
  bootable cards use PhoenixCard with the card image, not a raw writer.

## Tools

| Tool | Host | Purpose |
|---|---|---|
| PhoenixSuit | Windows | Development flashing: full image, per-partition, keep-data upgrade, erase, address-targeted writes |
| PhoenixUSBpro | Windows | Mass production, up to 24 devices over USB |
| PhoenixCard | Windows | Writes card-bootable images |
| LiveSuit | Ubuntu | USB flashing (use the Linux64 build on 64-bit hosts) |

Windows tools are bundled in APST (Allwinner Platform Service Tool); each tool
carries its own docs. The copies inside the SDK `tools/` tree are deprecated
and scheduled for removal — prefer platform releases. For offline/burner
programming see the SDK's offline flashing guide (Linux_MMC_NOR 离线烧录).

Windows requires the AW USB driver (in the tool's `Drivers/AW_Driver`); the
device must enumerate as a download-mode device before the tool can see it.

## Entering download mode (FEL/EFEX)

Any one of these suffices, in rough order of convenience:

1. From a running Linux system: `reboot efex` (or `adb shell reboot efex`).
2. At the U-Boot console: `efex`.
3. Serial '2' key: hold the `2` key in the serial terminal while powering on —
   boot0 detects the repeated character and enters download mode.
4. FEL button (if wired on the board): hold while powering on.
5. Blank or unreadable boot media (new/erased flash): BROM falls back to
   download mode automatically.
6. `fel_key` config: a key press within configured min/max key values at
   power-on.
7. Special boot card: boot from a prepared card that drops into download mode.

U-Boot additionally exposes standard `fastboot` commands on boards where the
feature is enabled.

## Cautions

- Confirm the tool actually lists the device before starting; retrying a flash
  that never enumerated wastes a cycle and proves nothing.
- For USB flashing, connect directly to the host (or a powered hub); download
  mode resets the bus during the process.
- Respect the project's choice between full-image and partition-scope writes;
  a keep-data upgrade and an erase upgrade are different operations.
- After flashing, verify over serial: boot log, kernel version, board, and
  rootfs type must match the built configuration before declaring success.
