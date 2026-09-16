# Windows Rockchip 烧写工具边界

[Radxa RKDevTool 文档](https://docs.radxa.com/en/rock3/rock3a/low-level-dev/rkdevtool)将 RKDevTool 定义为 Windows USB 烧写软件；[Linux Upgrade Tool 文档](https://wiki.radxa.com/Android/upgrage_tool)介绍 Linux 工具。不能假设 `${PLATFORM_TOOLS}/upgrade_tool.exe` 存在或接受 Linux 参数。

## 选择工具

- Windows：先查 SDK 配套 RKDevTool、驱动和实际工具文档。GUI 操作需要可用桌面交互/自动化接口，SSH 启动进程不等于完成烧写。
- 已配置的自定义 Windows 命令行工具：先检查可执行文件、帮助、版本和枚举，再按其接口操作。
- Linux USB 主机：使用 `rk-build` 的 upgrade_tool 流程，不从 Windows 操作说明推导参数。

Linux 工具常见 `UF` 写固件包、`UL` 更新 loader、`DB` 下载 loader 到 RAM；三者不能混用，具体语法查本机帮助。这些仅说明概念，不作为 Windows 命令模板。

## 验证

确认 USB 物理连接的主机、所选 DUT、Rockusb 驱动/模式和镜像校验和。MASKROM 可能需要先下载兼容 loader，不能一概认为任何模式都能直接整包写入。明确整包、分区、保留数据或擦除范围。

写入后保存工具日志，通过受管串口验证本次启动身份和目标功能。ADB 与 Rockusb 是不同连接模式，`adb devices` 不能替代 Loader/MASKROM 枚举。
