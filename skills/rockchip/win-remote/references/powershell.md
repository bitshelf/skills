# 远程 PowerShell 命令与转义

命令可能经过本地 Bash、SSH 远端默认 shell 和 PowerShell 三层解析。Bash 双引号内的 `$` 与命令替换先在本地展开，单引号可保留字面内容；PowerShell 内的变量按其自己的引号规则展开。不要把不可信路径或用户输入直接插入多层命令字符串。

复杂命令可将固定脚本编码为 UTF-16LE Base64，显式调用 `powershell.exe -NoProfile -NonInteractive -EncodedCommand`。这只是传输编码，不是加密。以下示例从技能目录运行：

```bash
PS_ENCODED=$(python3 - <<'PYCODE'
import base64
script = "[Environment]::GetFolderPath('Desktop')"
print(base64.b64encode(script.encode('utf-16le')).decode('ascii'))
PYCODE
)
if ! WIN_DESKTOP=$(./scripts/run.sh "powershell.exe -NoProfile -NonInteractive -EncodedCommand $PS_ENCODED"); then
    exit 1
fi
WIN_DESKTOP=$(printf '%s' "$WIN_DESKTOP" | tr -d '
')
```

stdout 只捕获路径，错误保留在 stderr。命令失败时停止，不把错误文本作为路径。

可在同一个 PowerShell 脚本中使用 `Join-Path` 创建目录：

```powershell
$desktop = [Environment]::GetFolderPath('Desktop')
$workspace = Join-Path $desktop 'remote_winspace'
New-Item -ItemType Directory -Force -Path $workspace | Out-Null
```

路径应动态解析，Bash 侧可使用正斜杠，PowerShell 用 `Join-Path` 避免手工拼接反斜杠。带引号的可执行路径使用调用运算符 `&`，原生程序退出码需显式传出：

```powershell
& 'D:\tools\adb.exe' devices
exit $LASTEXITCODE
```

此路径仅为示例，执行前替换为已核实位置。PowerShell cmdlet 失败可用 `$ErrorActionPreference = 'Stop'` 和异常处理传播，不能只查看 `$LASTEXITCODE`。
