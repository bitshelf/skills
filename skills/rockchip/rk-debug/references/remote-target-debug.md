# Remote Target and Boot Diagnosis

## Map connections

Resolve these independently from current configuration and evidence:

| Role | Evidence |
|---|---|
| Build machine | SDK checkout and generated artifacts |
| Dev Host | Configured SSH endpoint, serial bridge, USB topology |
| DUT | Selected alias, serial model/banner, current network and storage |

A Dev Host can itself be a Rockchip board. Model or missing switch ports alone cannot distinguish roles. A target DHCP address may change after reboot. Keep host maintenance outside a target-debug task unless separately requested.

## Serial and boot evidence

1. Inspect the selected server's state and recent logs. Preserve the original failure before a reset.
2. Check transport health separately from boot progress. A missing USB serial adapter can indicate host enumeration, cable, power, or mapping problems; it does not establish which one.
3. For a requested restart, capture logs for that cycle and identify the last successful stage: DDR/SPL, firmware, U-Boot, kernel, userspace, shell.
4. Use tool-supported waits/cursors or inspect retained logs so fast boot messages are not missed. Do not invent wait actions or assume sequential blocking waits run in parallel.
5. Check expected kernel/build identity and the failing feature after reaching userspace. Search error text in context; an isolated word such as `error` is not a diagnosis.

Use the server's log listing and returned paths rather than assuming archive numbering or log directory names. Preserve current evidence before loading reference logs or changing detector settings.

## U-Boot and USB modes

Use the managed U-Boot entry operation with supported arguments. On failure, inspect whether reboot occurred, which interrupt strategy ran, and what prompt is now present. Do not keep sending restart commands to a board already in U-Boot.

Check U-Boot `help`, storage devices, and supported Rockusb command before entering Loader. Verify `upgrade_tool LD` on the actual USB host. No enumerated Rockusb device can mean normal boot, a cable problem, permissions, or wrong host; it is not proof of normal operation.

A recovery transition may time out because the transport stopped responding. Recheck logs and USB state before retrying. Firmware writing and readback belong to the rk-build flashing workflow.

## Serial shortcut keys (boot-time)

Rockchip's U-Boot Nextdev guide (§2.12 Hotkey) documents serial key combinations
held at power-on. These require a functioning bootloader with the corresponding
handlers; confirm support in the selected checkout. They may need several
attempts and the documented handlers are **ineffective with secure boot enabled**.

| Key (hold from power-on) | Action |
|---|---|
| `ctrl+c` | Enter the U-Boot command line |
| `ctrl+d` | Enter Loader (flashing) mode |
| `ctrl+b` | Enter MASKROM (flashing) mode |
| `ctrl+f` | Enter fastboot mode |
| `ctrl+m` | Print bidram/system info |
| `ctrl+i` | Enable kernel `initcall_debug` |
| `ctrl+p` | Print cmdline info |
| `ctrl+s` | Enter the U-Boot command line after `Starting kernel...` |

These shortcuts do not require a Linux shell, but cannot recover a boot chain
that fails before the key handler executes. Use the board's documented physical
MASKROM entry for that case. Confirm a U-Boot prompt for shell shortcuts,
Rockusb enumeration for Loader/MASKROM, and `fastboot devices` for fastboot.
