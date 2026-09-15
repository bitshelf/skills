# Rockchip upgrade_tool Reference

`upgrade_tool` is the Rockchip USB firmware flashing utility, typically located
at `${PLATFORM_TOOLS}/upgrade_tool.exe` on the Windows side.

## Common Commands

| Command | Purpose |
|---------|---------|
| `upgrade_tool uf <image>` | Flash update.img |
| `upgrade_tool ul <loader>` | Flash loader (MiniLoader) only |
| `upgrade_tool rd` | Reset device |
| `upgrade_tool ld` | List connected Rockchip devices |

## Flash Workflow (via win-remote)

```bash
source .win-target.conf
DESKTOP=$(./scripts/run.sh \
    "powershell -Command '[Environment]::GetFolderPath(\"Desktop\")'" 2>&1 | tr -d '\r')
./scripts/run.sh \
    "& \"${PLATFORM_TOOLS}\\upgrade_tool.exe\" uf \"${DESKTOP}\\remote_winspace\\update.img\""
```

## Prerequisites

- Target device in Loader or Maskrom mode
- Windows detects the device as "Rockusb Device"
- `upgrade_tool.exe` and `config.ini` in `${PLATFORM_TOOLS}`
