---
name: android
description: 使用 Rockchip Android SDK 构建和打包 framework 模块、内核、U-Boot 及 update.img。适用于包含 build/envsetup.sh 和 device/rockchip 的 Android 源码树；非 Android 的 Rockchip Linux SDK 使用 rk-build。
---

# Rockchip Android 构建

## 确认源码树和目标

定位 SDK 根目录、项目说明、Android 分支和厂商构建脚本。先检查封装脚本的选项，再使用 `-A`、`-K`、`-U`、`-u` 等参数；不同 SDK 的含义及副作用可能不同。Android 内核和 U-Boot 也应沿用本流程，以保留产品的工具链和打包配置。

使用用户指定或当前项目已确定的目标。否则检查产品声明、`AndroidProducts.mk`、支持的 lunch 选项和项目说明。已有输出目录、构建指纹只能佐证，不能代替目标选择。不要选取 `out/target/product/` 的第一个目录，也不要默认 `userdebug`。存在多个候选时，先澄清再编译。

## 保持构建环境

在同一个 Bash 进程中执行 `source build/envsetup.sh`、成功的 `lunch` 及依赖它们的构建命令。独立工具调用不会保留 shell 函数和环境变量；新建构建 shell 时重新初始化，也可以使用持久 shell 或脚本。初始化或 lunch 失败即停止。

使用当前分支支持的 lunch 语法；需要 release 配置时一并指定。通过该分支的构建变量查询工具确认产品、变体和输出目录。不要直接给 `$OUT` 追加 `target/product`，它可能已经是产品目录。

## 按请求选择范围

| 请求 | 操作 |
|---|---|
| 单模块编译 | 按真实模块名或路径使用分支支持的命令 |
| Android/framework 编译 | 使用 SDK 对应入口；仅在请求或交付流程需要时打包 |
| 内核或 U-Boot 编译 | 使用 SDK 组件脚本和已选产品配置 |
| 打包已有产物 | 先核对产物新旧、兼容性，再打包 |
| 完整固件构建 | 遵循 SDK 的组件依赖和打包顺序 |

保留随附的 [scripts/kernel.sh](scripts/kernel.sh)，供 Rockchip Android 内核/U-Boot 快速构建使用。调用或复制前阅读[用法及 SDK 假设](references/components.md#bundled-kernel-helper)。优先使用已匹配 SDK 的项目副本，保留本地定制。不要套用其他 SDK 的编译器，也不要把 clean/mrproper 当常规准备。组件与打包细节见 [references/components.md](references/components.md)。

## 验证与报告

日志经过管道时用 Bash `pipefail` 保留失败状态。扩大编译范围或清理前，先定位首个实质错误。使用该分支要求的 JDK、工具链和宿主环境，不要只凭 Android 大版本猜测 JDK。

报告目标、实际命令、退出结果及产物路径。模块编译不等于系统镜像已更新，打包完成不等于真机验收。烧写、擦除、解锁和切换源码分支须在用户授权范围内。执行已授权烧写时，按该板 Android 流程核对 DUT、镜像组合及启动结果。串口启动快捷键依赖具体引导程序支持；需要时使用 `rk-debug` 技能核对模式入口及验证方法。
