---
name: rk-debug
description: 通过受管串口日志、目标 SSH 和运行证据诊断 Rockchip Linux 启动、I2C、GPIO、regulator、交换机/PTP、U-Boot 与 Loader/MASKROM 恢复问题。固件构建和写入使用 rk-build。
---

# Rockchip 目标机调试

## 确认 DUT 与连接

查阅当前项目及父目录的说明和目标配置，解析所选 DUT 的串口端点、Dev Host、继电器映射与凭证。不默认 IP、root 登录、网卡名、I2C 总线或首台设备。JSONC 使用项目解析器或配置查询工具；正则去注释可能破坏字符串。需要创建配置时参考[配置示例](.target.jsonc.example)，按已安装 sermcp 的字段校验，替换占位符并省略未接线的继电器。

Dev Host 提供串口/USB 连接，DUT 是被测板。依据当前目标证据确定 SSH 地址，并核对型号、内核和存储。不要因调试 DUT 而重启主机或修改其存储。

受管串口使用可用的 sermcp MCP 工具，调用前检查当前 schema。此处工具名称表示操作，不是固定参数签名。不在受管引擎运行时并行使用裸 socat/nc/tio 或交互式 `dutabo serial`。MCP 缺失时检查配置，适用工作可用已验证的 DUT SSH；配置文件存在不代表服务已启动。不要覆盖配置或创建第二个串口所有者来绕过故障。

## 先取证

复位前读取状态和近期日志，保存故障及所属启动周期。`crashed` 需要 panic/BUG/Oops 证据；超时和空白回显不能证明内核崩溃或物理掉电。短而完整的 shell 提示符也是存活证据。区分传输断连与 DUT 无响应。

Linux 命令使用 `serial_send_command`，已确认的 U-Boot 提示符使用 `serial_uboot_command`，观察使用状态/日志工具。已授权重启后跟踪新周期并按板级里程碑判断；自动登录系统未必输出 `login:`。重启期间超时可能只是 shell 消失，重复动作前先查状态。

连接和启动阶段诊断见 [references/remote-target-debug.md](references/remote-target-debug.md)，外设诊断见 [references/peripherals.md](references/peripherals.md)。

## 恢复

进入 U-Boot 时，响应正常的 shell 可软件重启，否则使用已配置硬件恢复；尊重用户选定方法。按配置发送中断字符并验证提示符，`bootdelay=0` 下能否中断取决于板级实现。

Loader 入口需当前 Linux/U-Boot 支持，并在 USB 主机确认枚举。MASKROM 的物理入口依赖真实按键/复位接线。部分 Rockchip 引导程序还支持开机串口快捷键，见 [references/remote-target-debug.md](references/remote-target-debug.md)；它们需要相应软件阶段运行，不能代替启动链损坏时的硬件恢复。先检查工具语义，不假设 `maskrom pulse` 自动包含完整复位时序。不要仅为获取提示符执行持久 `saveenv`、分区写入或替换引导程序。

一次恢复失败后先检查新日志、继电器/工具结果和 USB 状态。身份、接线未明或下一步超出授权时停止相关操作。请求写固件时使用 `rk-build`；[references/upgrade-tool-reference.md](references/upgrade-tool-reference.md)说明操作边界。

## 板级信息

板级 I2C 映射、DTS 链和 pinmux 个案保留在实际项目文档中，不随通用技能发布。总线、控制器与设备地址从运行系统解析，不使用历史默认值。

报告观察、诊断、修改和验证限制，附 DUT 及日志/产物位置。不凭单条命令成功宣称外设已修复。
