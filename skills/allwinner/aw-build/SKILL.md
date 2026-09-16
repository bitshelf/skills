---
name: aw-build
description: 使用 Allwinner AIoT Linux SDK 的 build.sh 流程选择芯片/板级方案、配置、适配、分模块构建、打包和 FEL/EFEX 烧写，并查阅 SDK 模块及量产文档。适用于包含 build/ 和 device/config/chips 的 AIoT Linux 源码树；Rockchip 使用 rk-build/rk-debug，Android 使用 android。
---

# Allwinner AIoT Linux 构建与烧写

## 确认源码和配置

从包含 `build.sh`、`build/` 的 SDK 根目录操作。常见入口为 `build.sh -> build/top_build.sh`，选择保存在根目录 `.buildconfig`。有该文件时先读取平台、OS、`LICHEE_IC`、`LICHEE_BOARD`、存储介质和内核版本。不要假设旧配置对应本次目标；换目标时重新配置。下面列出已知 AIoT SDK 流程，使用前以当前脚本和随附指南核对。

## 配置目标

`./build.sh config` 的逻辑通常位于 `build/mkcommon.sh` / `build/mkcmd.sh`，交互顺序为：平台、OS（bsp/dragonboard/buildroot/debian/yocto 等）、SoC、板级方案、存储介质、内核版本。

从 `device/config/chips/` 动态枚举芯片，从 `device/config/chips/<ic>/configs/` 枚举方案；不硬编码芯片或板名。配置持久化后，各次构建由脚本加载 `LICHEE_*` 环境并确定 `out/`，不要假设子进程可给父 shell 导出变量。

## 按范围构建

| 请求 | 常见命令（先核对本地支持） |
|---|---|
| 全量构建 | `./build.sh` |
| boot0/U-Boot/brandy | `./build.sh bootloader` |
| 内核 | `./build.sh kernel` |
| 内核模块 | `./build.sh modules` |
| DTB / DTS | `./build.sh dtb` / `./build.sh dts` |
| 启动镜像 | `./build.sh bootimg` |
| Buildroot rootfs | `./build.sh buildroot_rootfs` |
| Debian/Yocto/OpenWrt rootfs | `./build.sh debian_rootfs` / `./build.sh yocto_rootfs` / `./build.sh openwrt_rootfs` |
| 单个 Buildroot 包 | `./build.sh buildroot_package <pkg>` |
| 内核配置及保存 | `./build.sh menuconfig`，随后 `./build.sh saveconfig` |
| U-Boot 配置及保存 | `./build.sh uboot_menuconfig`，随后 `./build.sh uboot_saveconfig` |
| rootfs 配置 | `./build.sh buildroot_menuconfig`（其他变体按本地支持） |
| 必要的清理 | `./build.sh clean` / `./build.sh distclean` |

产物位置、配置片段和其他命令见 [references/build-reference.md](references/build-reference.md)。从 SDK 根目录的新 shell 构建，避免跨配置遗留 `LICHEE_*`。失败后先查日志，不打包部分失败产物；管道存在时不能仅凭封装脚本最终返回值判断成功。

## 打包

构建成功后按请求生成固件包：

| 镜像 | 命令 |
|---|---|
| 普通固件 | `./build.sh pack` |
| 安全固件 | `./build.sh pack_secure` |
| 串口转 TF 卡槽的 card0 调试变体 | `./build.sh pack_card` |
| 安全 card0 变体 | `./build.sh pack_secure_card` |

输出通常在 `out/`，名称由板级方案和变体决定。`pack_card` / `pack -d` 的 `*_card0.img` 表示串口路由变体，不等于已制作可启动 SD 卡。PhoenixSuit/LiveSuit 固件包不能作为裸磁盘镜像直接 `dd`。

## 烧写

| 工具 | 主机 | 用途 |
|---|---|---|
| PhoenixSuit | Windows | 开发阶段 USB 整包/分区烧写 |
| PhoenixUSBpro | Windows | USB 多设备量产 |
| PhoenixCard | Windows | 按工具模式制作启动卡或量产卡 |
| LiveSuit | Linux | USB 固件烧写 |

按当前 SDK 指南获取匹配工具；部分 AIoT 指南要求从全志平台/APST 获取维护版本，不能假设各 SDK 内置工具仍受支持。远程 Windows 操作可使用 `win-remote`；SSH 不能自动控制 GUI，需现有命令行/自动化接口。

先进入 FEL/EFEX 下载模式。候选入口包括运行系统的 `reboot efex`、ADB 对应命令、U-Boot `efex`、开机串口字符 `2`、接线支持的 FEL 按键及启动介质无效后的 BROM 回退。每项以当前引导实现为准，详见 [references/flashing.md](references/flashing.md)。不为进入模式主动擦除介质。

## 验证与板级适配

烧写后采集串口启动日志，核对内核、板卡和 rootfs 身份并测试变更功能。失败时先确认模式入口及工具枚举，不盲重试。

板级适配在 `device/config/chips/<ic>/configs/<board>/` 修改 DTS、defconfig、分区、U-Boot 环境及 sys_config，不仅改 `out/`。见 [references/board-config.md](references/board-config.md)。

受管串口使用当前可用 sermcp 工具，不并行抢占端点。镜像启用 ADB 时可用 `adb shell`、`adb push`。某些内核崩溃后进入 crashdump shell，观察 `crashdump enter` 后按对应指南取证，不能保证所有镜像均支持。TWI、显示、Wi-Fi、NPU、安全启动、OTA 和量产问题按 [references/doc-map.md](references/doc-map.md) 查当前 SDK 原文。
