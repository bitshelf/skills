# Allwinner 烧写与下载模式

## 镜像类型

`./build.sh pack*` 通常在 `out/` 生成 PhoenixSuit/LiveSuit 固件包。`pack_card`/`pack -d` 的 `*_card0.img` 是串口转 TF 卡槽的变体，不等于原始 SD 镜像。

`boot.img`、`rootfs.img` 是包内分区载荷，格式随板级配置变化，不假设 rootfs 一定是 squashfs。单分区能否直接写入取决于烧写工具和当前布局。固件包不能直接 `dd`；制作启动卡时按 PhoenixCard 文档选择模式和输入。

## 工具

| 工具 | 主机 | 用途 |
|---|---|---|
| PhoenixSuit | Windows | 开发烧写；分区、保留数据和擦除选项按版本核实 |
| PhoenixUSBpro | Windows | USB 多设备量产，数量上限查本版文档 |
| PhoenixCard | Windows | 制作启动卡/量产卡 |
| LiveSuit | Linux | USB 烧写，选择匹配主机架构的发行包 |

部分 AIoT 指南要求从全志平台/APST 获取维护工具，不继续依赖 SDK 内旧副本。安装与离线烧录见当前工具和 SDK 文档。Windows 检查 AW USB 驱动以及下载模式枚举。

## FEL/EFEX 入口

按当前板和引导程序支持选择：

1. 运行中的 Linux 使用 `reboot efex`，启用 ADB 时可 `adb shell reboot efex`。
2. U-Boot 提示符使用 `efex`。
3. 在引导阶段通过受管串口重复发送 `2`；该入口依赖相应软件执行。
4. 板上已接线的 FEL 按键配合上电。
5. 启动介质无有效镜像时的 BROM 下载回退；不要为此主动擦除介质。
6. 固件支持的 `fel_key` 按键阈值配置。
7. 文档指定的下载模式启动卡。

并非任一方法都适用于任一板。启用了 fastboot 的 U-Boot 还可能提供该模式，它与 FEL/EFEX 分开验证。

## 写入和验收

写入前核对指定 DUT、镜像校验和、模式、工具枚举、分区或整包范围。USB 烧写可能重枚举，检查线缆和供电。保留数据升级与擦除升级是不同操作。

写入后通过串口验证本次启动、内核、板卡、rootfs 及变更功能，再报告成功。
