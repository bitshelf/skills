# AIoT build.sh 参考

从 SDK 根目录运行。常见调用链为 `build.sh` → `build/top_build.sh` → `build/mkcommon.sh` 参数解析 → `build/mkcmd.sh` 实现，以本地源码为准。

## 配置状态

根目录 `.buildconfig` 持久保存 `LICHEE_PLATFORM`、`LICHEE_LINUX_DEV`、`LICHEE_IC`、`LICHEE_BOARD`、介质和内核版本。`build/envsetup.sh` 通常由封装脚本加载，不必自行 source。

选项从源码目录动态枚举，板级方案位于 `device/config/chips/<ic>/configs/`，内核通常位于 `kernel/`。没有配置时部分版本自动进入 `mk_config`；脚本化选择先检查 `autoconfig` 是否支持及所需参数。

| 路径 | 用途 |
|---|---|
| `brandy/` | boot0、U-Boot、arisc、DRAM 库 |
| `bsp/` | 叠加于基础内核的全志驱动和改动 |
| `kernel/` | 各版本基础内核 |
| `buildroot/`、`debian/`、`yocto/` | rootfs 构建系统 |
| `device/config/chips/<ic>/configs/` | 板级方案 |
| `target/` | 板级/芯片配置映射，按实际用途检查 |
| `out/` | 输出根目录，工具链可能在 `out/external-toolchain/` |
| `tools/pack/` | 主机侧打包工具 |
| `docs/` | 硬件、软件和量产资料，可能含 `docs_list.txt` |

## 其他动作

部分版本还支持 `arisc`、`rtos`、`dsp`、`ramfs`、`recovery`、`independent_package`、`mergeconfig`、`loadconfig`、`recovery_menuconfig`/`recovery_saveconfig`、`bsp_rootfs`、`buildroot_saveconfig`、`check_gki*`、`uboot_force`。调用前查 `build/mkcommon.sh`。

## U-Boot 与内核配置

`brandy/brandy-2.0/` 可能含多个 U-Boot 版本，新版本可能将基础树和 `u-boot-bsp` 分开并在构建时合并。优先 `./build.sh bootloader`，仅在项目支持时直接进入组件编译。

`menuconfig` 编辑所选方案的有效配置，`saveconfig` 应写回持久配置。脚本化片段操作可检查 `mergeconfig`/`loadconfig`；不要假设保存命令覆盖所有片段。

## 环境和失败处理

主机发行版、依赖和初始化脚本从当前 SDK 开发指南确认，不固定为某个 Ubuntu 版本，也不断言根目录一定有或没有 `install.sh`。

若日志有 `ACTION List:`，据此定位失败动作及 `out/` 下关联日志。修复后只重跑需要的范围，不反复盲跑全量，不打包部分失败构建。
