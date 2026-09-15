---
name: win-remote
description: Transfer files, execute PowerShell, and run firmware or ADB tools on a remote Windows host over SSH. Use for Windows flashing hosts, remote Windows workspaces, or ADB on Windows; select the firmware tool supported by the actual SDK.
license: MIT
compatibility: Requires bash, ssh+scp (OpenSSH), Windows with OpenSSH server installed. sshpass optional for password auth.
metadata:
  author: loh
  version: "1.0"
---

# Windows Remote Operations

**Bundled paths:** Resolve relative paths from the directory containing this SKILL.md, while keeping build and target commands in the requested project directory.

SSH remote control of a Windows machine (key-based by default; password via `sshpass`
if `WIN_PASS` is set).  See [SSH setup](references/ssh-setup.md) for key configuration,
[PowerShell notes](references/powershell.md) for quoting rules,
[security](references/security.md) for hardening and CVE alerts,
and [upgrade-tool.md](references/upgrade-tool.md) for flashing commands.

## Quick Start

**Always run scripts with `--help` first** to see usage without reading source.

```
Is the Windows SSH server reachable?
├─ No  → Verify sshd is running: ./scripts/run.sh "Get-Service sshd"
│        See [ssh-setup.md](references/ssh-setup.md) if not installed.
├─ Yes → What do you need?
│        ├─ Transfer file  → scp + ssh (see Transfer below)
│        ├─ Flash firmware → [upgrade_tool reference](references/upgrade-tool.md)
│        ├─ ADB test       → run.sh "& ...adb.exe devices" (see ADB below)
│        └─ Arbitrary cmd  → ./scripts/run.sh <command>
```

## Configuration

Place `.win-target.conf` at project root. `scripts/run.sh` walks up from `$PWD`
to find it (like `.git`).  Template at `assets/.win-target.conf`:
copy to project root and fill in your values.

```bash
WIN_HOST=<ip-or-hostname>
WIN_USER=<username>
WIN_PASS=<password>                                 # optional — set for password auth (requires sshpass)
PLATFORM_TOOLS=D:/Users/<username>/Documents/platform-tools
```

- Auth defaults to key-based. If `WIN_PASS` is set, `sshpass` is used for password auth.
- `PLATFORM_TOOLS` — directory on Windows containing the configured tools, such as `adb.exe`. Verify each executable and its host support; a Linux `upgrade_tool` command does not establish that a Windows `upgrade_tool.exe` exists.

## Scripts

| Script | Purpose |
|---|---|
| `scripts/run.sh --help` | Show usage. Execute command on Windows via SSH. |

**Always run scripts with `--help` first** before reading source.

## CRITICAL Rules

1. **Never hardcode paths** — resolve with `[Environment]::GetFolderPath()`.
2. **Workspace is `remote_winspace`** under Desktop on the Windows side.
3. **Use `scripts/run.sh`** for all SSH commands (except `scp` and `powershell`
   one-liners that capture output — those need raw `ssh`).

## Workflow

All examples assume `.win-target.conf` exists at project root.

### Transfer file to Windows

```bash
# Resolve desktop path (raw ssh — PowerShell one-liner capturing output)
DESKTOP=$(ssh ${WIN_USER}@${WIN_HOST} \
    "powershell -Command '[Environment]::GetFolderPath(\"Desktop\")'" \
    2>&1 | tr -d '\r')
ssh ${WIN_USER}@${WIN_HOST} \
    "New-Item -ItemType Directory -Force -Path '${DESKTOP}\\remote_winspace'" >/dev/null 2>&1
scp update.img "${WIN_USER}@${WIN_HOST}:${DESKTOP}\\remote_winspace\\update.img"
```

### Flash from Windows

See [upgrade-tool.md](references/upgrade-tool.md) for command reference.

```bash
DESKTOP=$(./scripts/run.sh \
    "powershell -Command '[Environment]::GetFolderPath(\"Desktop\")'" \
    2>&1 | tr -d '\r')
# Select the SDK's verified Windows flashing executable or GUI workflow.
# Do not append .exe to a Linux tool name or reuse its flags automatically.
```

### Check ADB

```bash
./scripts/run.sh "& \"${PLATFORM_TOOLS}\\adb.exe\" devices"
```

### Verify SSH server health

```bash
./scripts/run.sh "Get-Service sshd | Select-Object Status,StartType"
```
