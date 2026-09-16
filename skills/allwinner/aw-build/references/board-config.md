# 板级方案配置

板级方案通常位于 `device/config/chips/<ic>/configs/<board>/`，对应 `LICHEE_BOARD`。构建期间可能生成 `target/` 映射，布局须查当前源码。

```text
<board>/
├── BoardConfig.mk
├── sys_config.fex
├── sys_config_ddr_*.fex
├── uboot-board.dts
├── spl.dts, boottone.fex
├── buildroot/ debian/ yocto/ dragonboard/
│   ├── BoardConfig.mk
│   ├── env.cfg
│   └── sys_partition.fex
└── linux-<ver>/
    ├── board.dts
    ├── bsp_defconfig
    ├── bsp_recovery_defconfig
    ├── env-<ver>.cfg
    └── sys_partition.fex
```

`BoardConfig.mk` 定义构建变量；OS 子目录提供各系统覆盖项，内核版本目录提供对应 DTS 和配置。

## 关键文件

- `sys_partition.fex`：分区名、大小、下载镜像及用户数据属性。先经 `script` 转为 `sys_partition.bin`，再由 `update_mbr` 等工具生成分区/下载信息；`sunxi_mbr.fex`、GPT、`dlinfo.fex` 的具体产物按本版本打包链核对，不能直接把文本交给 `update_mbr`。
- `env*.cfg`：U-Boot 环境，经 `u_boot_env_gen env.cfg env.fex` 转换。
- `sys_config.fex`：传统芯片/板级配置，打包及部分驱动仍可能使用。
- `board.dts` / `bsp_defconfig`：内核板级定义，修改后重建相关镜像、打包并部署才能验证。

## 适配要求

从同芯片最接近方案复制为新名称再修改；跨芯片不是简单改名，应按 `docs/` 的移植清单处理。

修改分区后重打包，核对产物容量及真机启动分区表。`menuconfig` 后运行 `saveconfig`，确认真正更新了方案 defconfig，不只是 `out/`；片段另行核对。

boot0/U-Boot/boot_package 按 SDK 打包流程生成。`dragonsecboot` 处理 `boot_package.cfg` 等输入，签名须沿项目配置，不自行拼接启动镜像。

参考《Tina_Linux_打包流程_使用指南》及存储指南，定位方式见 [doc-map.md](doc-map.md)。
