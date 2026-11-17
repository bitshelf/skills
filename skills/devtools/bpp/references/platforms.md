# 平台：来源、社区与人物

初次收集：2026-10-29。只读取当前任务涉及的部分；分支、生命周期、人物职责、兼容性与漏洞状态在实际使用时刷新。Android/AOSP 属于同一平台链路的不同层面，不重复执行两套研究。

## Yocto / OpenEmbedded

- **官方资料**：[文档索引及版本选择](https://docs.yoctoproject.org/)、[发布与 stable 规则](https://docs.yoctoproject.org/ref-manual/release-process.html)、[可复现构建](https://docs.yoctoproject.org/test-manual/reproducible-builds.html)、[层索引](https://layers.openembedded.org/)。先从 manifest、layer 分支和配置确定发行系列，避免拼接不兼容的 layer。
- **社区与实现**：[OpenEmbedded 邮件归档](https://lists.openembedded.org/)、[Yocto 邮件列表](https://lists.yoctoproject.org/)、[OE-Core 源码](https://git.openembedded.org/openembedded-core/)、[BitBake 源码](https://git.openembedded.org/bitbake/)。从 recipe、class、补丁及维护分支追到实现。
- **人物线索**：Richard Purdie（Yocto 架构与构建系统）、Ross Burton（OE/Yocto 维护与测试）。一手背景见 [LF 的 Yocto/Boeing 发布报道](https://www.linuxfoundation.org/press/yocto-announces-new-release-and-platinum-member-boeing)与 [Yocto 2021 年回顾](https://www.yoctoproject.org/blog/2022/01/27/2021-a-year-in-review/)。后者证明当年 TSC 情况，不证明当前任职；本次任务需结合提交史/维护者信息重新核对。
- **技术方向**：配方与 layer 分层、源及依赖锁定、重现构建、许可证/SBOM、CVE 分析、ptest/testimage 与硬件 CI。变量名、任务和可用测试以对应 release 手册及实际工程为准。
- **工业方向**：匹配支持周期的发行系列 + 自有产品 layer + 源码/制品留存 + 签名升级 + 目标回归。LTS、CVE 报告或可重现构建各自只解决部分问题；不能由其中一项推导整机受支持或无漏洞。Boeing 加入是可追溯的采用背景，不证明本任务配置已验证。

## OpenHarmony

- **官方资料**：[开发者文档源码](https://gitee.com/openharmony/docs)、[Release Notes](https://gitee.com/openharmony/docs/blob/master/zh-cn/release-notes/Readme.md)、[社区治理与贡献](https://gitee.com/openharmony/community)、[PMC](https://gitee.com/openharmony/community/blob/master/zh/pmc.md)。从目标 manifest/ref 对齐文档、子系统和版本约束。
- **社区与实现**：从 community 的 SIG、目标仓库的维护信息、评审与 issues 获取领域讨论。查源码声明和构建配置识别轻量/小型/标准系统及所用内核，不默认所有 OpenHarmony 设备都是同一种 Linux 系统。
- **人物线索**：当日 PMC 页面列出任革林（总架构）、易见（内核 SIG）、赵文华（驱动框架 SIG）、邢文华（QA-SIG）；它们是定位主题的线索。具体问题继续找到目标版本的实际维护者和已经接受的方案。
- **技术方向**：HDF 驱动适配、系统能力/接口约束、进程与权限模型、升级机制、组件裁剪及 XTS/子系统测试。按发行版官方文档验证适用范围，不移植 Android HAL/SELinux/OTA 的结论作为 OpenHarmony 规范。
- **工业方向**：在明确支持的设备与发行分支上按官方适配流程集成，保留升级恢复和兼容性测试证据。社区发布、产品兼容性证明与功能安全认证是不同证据；没有当前产品的一手量产资料时标为“待评估路线”，不编造落地客户或认证结论。

## openEuler

- **官方资料**：[官网与文档导航](https://www.openeuler.org/)、[社区仓库](https://gitee.com/openeuler/community)、[Embedded SIG 元数据](https://gitee.com/openeuler/community/blob/master/sig/sig-embedded/sig-info.yaml)、[yocto-meta-openeuler](https://gitee.com/openeuler/yocto-meta-openeuler)。先区分服务器 RPM 发行形态与 Embedded/Yocto 工程，核对对应版本和 BSP。
- **社区与实现**：从 SIG 元数据找到相关仓库、维护者、贡献入口与议题记录，跟踪目标分支 PR/issue 和 CI；内核、安全、实时、容器等问题分别查对应 SIG。
- **人物线索**：当日 Embedded SIG 的 `sig-info.yaml` 列出 Wayne Ren（vonhust）、Xinyu Li（alichinese_admin）、Linxu Fang（fanglinxu）。查到具体仓库后继续按 repo_admin/committers 定位，不把 SIG 总名单当所有模块的评审名单。
- **技术方向**：[官方 Embedded 架构文章](https://www.openeuler.org/en/blog/G11N-SIG/20230615-embedded/openEuler%20Embedded%20--%20Towards%20Multi-Scenario%20Embedded%20Platforms.html)介绍 Yocto 工程、实时与混合关键性方向。它是 2023 年方案背景；文章的时延、体积、启动时间不作为其他设备的性能保证。
- **工业方向**：匹配发行分支的镜像工程、包/层管理、设备兼容性与实时测量。PREEMPT_RT 或 Linux/RTOS 协作需结合目标芯片能力、隔离/通信、负载和故障模型验证；不能仅凭架构宣传宣称硬实时或安全等级。当日 SIG 元数据含 `mature_level: startup`，这是一项治理字段，既不能证明所有组件成熟，也不能推定所有组件不可用，须逐组件取证。

## Android / AOSP 系统

- **官方资料**：[AOSP 架构](https://source.android.com/docs/core/architecture)、[AOSP 文档中文域入口](https://source.android.google.cn/docs)、[源码](https://android.googlesource.com/)、[Gerrit](https://android-review.googlesource.com/)。从 manifest、平台版本、内核/GKI 与 vendor 接口确定实际组合；文档的当前默认开发分支不能替代产品的发布分支。
- **社区与人物**：以相关目录的 `OWNERS`、Gerrit 作者/评审及合入记录定位；[frameworks/base 顶层 OWNERS](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/OWNERS)明确要求优先更深层负责团队。Dianne Hackborn 的[官方多任务设计文章](https://android-developers.googleblog.com/2010/04/multitasking-android-way.html)是历史设计资料的检索起点；2010 年文章不是当前后台执行/权限规则，规则需按目标版本重新查。`hackbod`、`smoreland` 等 OWNERS 账号用于追踪相关源码评审，不推断其覆盖全部系统模块。
- **技术方向**：稳定接口与 HAL、VINTF、SELinux、[GKI](https://source.android.com/docs/core/architecture/kernel/generic-kernel-image)、CTS/VTS、[AVB](https://source.android.google.cn/docs/security/features/verifiedboot/avb?hl=en)、[Legacy A/B OTA](https://source.android.com/docs/core/ota/ab)及[Virtual A/B](https://source.android.com/docs/core/ota/virtual_ab)。新产品调查当前官方推荐的更新形态；既有 BSP 按其实际实现核实，不能因旧文档仍可访问而把旧方案作为所有新产品默认。GKI 不意味着任意 ko 都能加载。
- **工业方向**：沿产品既有 AOSP/BSP 发布线修复，按改动范围验证接口、权限、兼容性、升级和故障恢复。AVB、A/B、Virtual A/B、动态分区各有适用条件，不能等同或混套；OTA 回退需关注持久数据兼容、rollback index 和健康标记。
- **边界**：本技能覆盖系统开发和系统行为研究。独立 Android App/Jetpack/Compose/Play 问题使用 Google 上游 `android/skills` 的相应技能，不在此复制应用开发规范。
