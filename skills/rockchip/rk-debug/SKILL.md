---
name: rk-debug
description: Diagnose Rockchip Linux target boot and peripheral problems using managed serial logs, target SSH, and runtime evidence. Use for Rockchip I2C, GPIO, regulator, switch/PTP, U-Boot, and Loader/MASKROM recovery tasks; firmware building and writing belong to rk-build.
---

# Rockchip Target Debugging

**Bundled paths:** Resolve relative paths from the directory containing this SKILL.md, while keeping build and target commands in the requested project directory.

## Resolve the DUT and transport

Find current project instructions and target configuration, including parent directories. Select the requested DUT and resolve its serial endpoint, Dev Host, relay mapping, and credentials. Do not assume a default IP, root login, interface name, I2C bus, or first configured device. Use the project's parser or resolved config tools for JSONC; regex comment stripping can corrupt strings. When configuration creation is requested, adapt the [configuration example](assets/.target.jsonc.example) and verify its fields against the installed sermcp version; replace placeholders and omit unwired relay controls.

The Dev Host provides serial/USB access; the DUT is the board under test. Derive target SSH addresses from current target evidence and corroborate model, kernel, and storage. Do not reboot or modify host storage as a side effect of target debugging.

Use available sermcp MCP tools for managed serial access. Inspect their current schemas before calling them; examples here name operations, not fixed argument signatures. Do not connect raw socat/nc/tio or interactive `dutabo serial` alongside the managed engine. If MCP is absent, inspect setup and use verified target SSH for suitable work; configuration presence alone does not guarantee a running server. Do not overwrite configuration or start a second serial owner as a troubleshooting shortcut.

## Evidence first

Read state and recent logs before resetting. Save the failure evidence and identify its boot cycle. `crashed` needs panic/BUG/Oops evidence; a timeout or blank echo does not prove a kernel crash or physical power loss. A short complete shell prompt is useful liveness evidence. Distinguish a transport disconnect from a silent DUT.

Use `serial_send_command` for Linux commands, `serial_uboot_command` for a confirmed U-Boot prompt, and available log/state tools for observations. For an authorized reboot, follow the new boot's logs and use board-appropriate milestones; autologin systems may not emit `login:`. A tool timeout during reboot can reflect the expected disappearance of the shell: inspect state before repeating the action.

For connection or boot-stage diagnosis, read [references/remote-target-debug.md](references/remote-target-debug.md). For peripheral work, read [references/peripherals.md](references/peripherals.md).

## Recovery

When entering U-Boot, choose software restart for a responsive shell and configured hardware recovery when software entry is unavailable. Respect a user-selected method. Use the configured interrupt character/strategy and verify the resulting prompt; success with `bootdelay=0` is board-dependent.

Loader mode requires a supported Linux/U-Boot command and USB confirmation on the flashing host. Physical MASKROM entry requires the board's actual button/reset wiring. A functioning bootloader may also handle serial shortcuts — hold `ctrl+c` (U-Boot shell), `ctrl+d` (Loader), or `ctrl+b` (MASKROM) from power-on; see [references/remote-target-debug.md](references/remote-target-debug.md) for the key table and limits. Inspect tool semantics before assuming a MASKROM operation performs the full sequence. Avoid persistent `saveenv`, partition writes, or bootloader replacement merely to obtain a prompt.

After one unsuccessful recovery attempt, inspect new logs, relay/tool results, and USB state before choosing the next step. Stop when identity or wiring is unresolved, or recovery would exceed authorized scope. Use `rk-build` for a requested firmware write; [references/upgrade-tool-reference.md](references/upgrade-tool-reference.md) describes the boundary.

## Board-specific notes

Board-level case notes (I2C maps, DTS chains, per-board pinmux) do not belong inside this skill. Keep them with the project or in this repo's `boards/` directory, and resolve bus numbers, controller addresses, and device addresses from the running system instead of hardcoding them.

Report observations, diagnosis, changes, and verification limits separately. Include the selected DUT and relevant log/artifact locations. Do not declare a peripheral fixed solely because a command succeeded.
