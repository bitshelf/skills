# Select the Windows Firmware Tool

The SDK's Windows flashing tool and its Linux command-line tool are separate
interfaces. Resolve the tool from this checkout's documentation and Windows
host inventory before constructing a command. Rockchip's Linux upgrade guide
refers to Windows AndroidTool and Linux packaging tools separately; it does
not establish a portable `upgrade_tool.exe` interface.

For Rockchip Windows setups, inspect the supplied AndroidTool/RKDevTool package
and its supported automation or GUI workflow. Use a Windows command-line tool
only when that executable exists and its own help documents the operation.
Do not reuse Linux `upgrade_tool uf/ul/di` flags merely by adding `.exe`.
Allwinner Windows flashing uses the SDK's Phoenix tools; use the `aw-build`
skill for tool selection and download-mode entry.

Use `scripts/run.sh` from the directory containing this skill to inspect the
configured host, create the requested workspace, and run verified commands.
Keep project configuration discovery rooted in the user's project directory.
For transfers, resolve the Desktop directory with PowerShell, quote the remote
path, and compare the source and transferred checksums. Confirm the target's
actual download mode and USB identity before any write; retain the writer log
and validate the new boot afterward.

A build request alone does not authorize flashing. If the available tool is
GUI-only and no supported automation is present, report that limitation instead
of inventing command-line switches.
