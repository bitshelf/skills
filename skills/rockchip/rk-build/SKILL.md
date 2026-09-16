---
name: rk-build
description: 按项目流程配置、构建、打包和烧写 Rockchip Linux SDK 的内核、引导程序、rootfs 与固件，处理 upgrade_tool 操作。Rockchip Android SDK 构建使用 android 技能。
---

# Rockchip Linux 构建与烧写

## 确认项目流程

定位 SDK 根目录、项目说明、已选板级配置和构建脚本。选择命令前检查 `./build.sh help` 及组件钩子：SDK 版本间的命令、产物路径和打包副作用可能不同。优先使用项目封装入口；仅在项目流程或用户要求时直接调用组件命令。

分别确认构建机、USB 烧写主机和 DUT，本地环境中它们可能部分重合。依据当前配置和连接，不复用记忆中的 IP、凭证或板名。多 DUT 时将所选别名映射到主机和串口端点，不默认首项。

## 只构建请求范围

常见命令包括 `kernel`、`loader`、`kernel-config`、`kernel-savedefconfig`、`firmware`、`updateimg`，先核对本地支持情况。按实际配置选择 rootfs 构建器，不假设一定使用 Buildroot 或某个发行版。

- 编译请求：构建受影响组件并报告结果。
- 内核配置修改：更新 SDK 实际使用的持久 defconfig/fragment，验证最终配置。
- 可烧写产物：检查组件实际输出，必要时打包。不要假设编译会自动刷新 `rockdev/` 或 `output/firmware/`。
- 完整发布或恢复镜像：遵循完整固件打包流程；不要自动把分区更新扩大为整机烧写。

传输前解析产物符号链接，核对新旧、格式、大小和校验和。确认 DTB、模块的实际加载位置；内核更新可能还需要匹配的模块或 resource 镜像。只有陈旧产物证据支持时才清理。

## 烧写与验证

准备或执行写入前阅读 [references/flashing.md](references/flashing.md)。构建请求本身不授权烧写；此前针对目标和镜像的授权持续有效，仅在身份、范围或必要破坏性动作未明确时询问。

串口恢复和启动取证使用当前可用的 sermcp 工具及 `rk-debug` 技能。工具缺失时可在适用场景使用已配置并核实的目标 SSH，不抢占受管串口。

写入后验证预期内核/镜像成功启动，并测试变更功能。分别报告构建、传输/写入、真机验证结果，保留日志和产物位置。不能仅凭编译或下载器退出成功宣称真机通过。

## 可选源码导航

只有请求 clangd 配置时才阅读 [references/clangd.md](references/clangd.md)。普通构建无需修改编辑器配置。
