---
name: win-remote
description: 通过 SSH 传输文件、执行 Windows PowerShell、运行 ADB 或操作已配置的远程烧写主机。适用于明确涉及 Windows 主机的工作；普通 Linux upgrade_tool 操作使用 rk-build。
license: MIT
metadata:
  author: loh
  version: "1.0"
---

# Windows 远程操作

默认 SSH 密钥认证，配置 `WIN_PASS` 时使用 `sshpass`。首次使用脚本先运行 `scripts/run.sh --help`。密钥配置见 [references/ssh-setup.md](references/ssh-setup.md)，命令转义见 [references/powershell.md](references/powershell.md)，认证维护见 [references/security.md](references/security.md)，烧写工具边界见 [references/upgrade-tool.md](references/upgrade-tool.md)。

运行需要 Bash、OpenSSH ssh/scp 及已启用 OpenSSH 服务的 Windows；密码认证可选 sshpass。

## 配置

将 [assets/.win-target.conf](assets/.win-target.conf) 复制到项目根目录并填入当前主机信息。脚本从 `$PWD` 向父目录查找，也支持 `WIN_CONF` 指定文件、`WIN_CONF_DIR` 指定查找起点。配置会作为 shell 脚本加载，只使用可信项目文件。

```bash
WIN_HOST=<ip-or-hostname>
WIN_USER=<username>
WIN_PASS=<password>
PLATFORM_TOOLS=D:/tools/platform-tools
```

`WIN_PASS` 可省略，`PLATFORM_TOOLS` 只是项目约定的工具位置，不保证其中有任何特定烧写器。调用者 shell 不会自动获得脚本加载的变量；外部 `scp` 命令若要使用配置，需自行加载可信配置或使用 SSH 主机别名。

## 执行命令

`scripts/run.sh` 将**一个完整命令字符串**交给 SSH，远端默认 shell 不一定是 PowerShell。PowerShell 操作需显式调用，复杂或含路径/用户数据的命令优先编码传输，示例见引用文档。不要依赖当前 shell profile。

```bash
bash <skill-dir>/scripts/run.sh 'powershell.exe -NoProfile -NonInteractive -Command "Get-Service sshd | Select-Object Status,StartType"'
```

SSH 不可达时，远程查询 sshd 同样不会成功；通过已有其他管理通道或主机现场诊断服务、网络和防火墙。

## 文件传输与工作目录

先通过 `[Environment]::GetFolderPath('Desktop')` 解析实际桌面，按项目约定创建 `remote_winspace` 或任务子目录，不硬编码用户名和桌面路径。路径捕获只读取 stdout，不将 stderr 合并进路径；先检查 SSH 成功再使用返回值。

使用 `scp` 传文件并核对两端 SHA256。含空格路径按本机 OpenSSH 的 SFTP/远端 shell 规则处理。`WIN_PASS` 认证时外部传输也需正确的认证方式，不能假设脚本会给父 shell 配置认证。

## ADB 与烧写

确认 `adb.exe` 的真实路径后显式通过 PowerShell 调用其 `devices`，多设备使用已核实序列号选择目标。ADB 主机是 Windows，ADB 目标是 DUT，不能混淆。

Rockchip Windows 通常使用 RKDevTool，Linux `upgrade_tool` 参数不能直接套到一个假定存在的 `.exe`。若项目提供自定义命令行程序，先查看其帮助及设备枚举。GUI 程序需现有桌面自动化能力，不能宣称 SSH 已完成 GUI 烧写。

执行授权范围内的烧写前核实 USB 主机、DUT、模式、镜像和范围；写入后收集本次启动与功能验证。细节见 [references/upgrade-tool.md](references/upgrade-tool.md)。
