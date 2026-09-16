# upgrade_tool 操作路由

工具运行在连接所选 DUT 的 USB 主机上，DUT 内存在可执行文件不代表支持自烧写。

语法、大小写及参数查已安装工具帮助。`LD` 仅枚举连接，不独立证明 DUT 身份。支持 `PL` 时用其读取当前布局，不从其他板的 parameter 文件推断 rootfs 参数或偏移。

| 操作 | 用途 |
|---|---|
| `LD` | 枚举 USB 设备 |
| `DB <loader>` | 下载兼容 loader 到 RAM |
| `PL` | 查询分区布局（若支持） |
| `DI -<partition> <image>` | 按分区名写入，如 `di -boot boot.img` |
| `WL <start-sector> <image>` | 按已验证偏移写原始镜像 |
| `UF <update.img>` | 写完整固件包 |
| `RD` | 复位所选 USB 目标 |

- 常见版本中 `DI -r` 是 recovery，不是 rootfs，须核实本机映射。
- 打包的 `update.img` 通常不是裸磁盘镜像，不按扩展名直接 `dd`。
- 不复用历史 LBA 或块设备号。`WL` 前从当前分区表核对起点、容量和扇区单位。
- loader 失败或存储异常时先诊断，不盲写或升级为擦除恢复。

传输校验、镜像容量、写入和启动验收的完整流程使用 `rk-build` 技能。
