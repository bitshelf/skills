# 工业方案筛选与验证

本页把上游机制映射为工程候选，属于 BPP 的判断框架，不是各社区共同颁布的强制标准。资料收集日期为 2026-10-29；“有实现”“有采用案例”“适合本产品”“已在本机验证”分别取证。

## 如何证明“成熟”

对影响本次选型的候选检查下列证据，缺项明确说明，不虚构固定年限、星数或客户数量门槛：

| 维度 | 需要查明的事实 |
| --- | --- |
| 接入与兼容 | 实际发布版、硬件/架构支持、依赖、接口、许可证及产品约束；不能只读 main 分支 README |
| 可维护性 | 目标分支仍有支持、维护职责、漏洞处理、升级路径；有商业支持时核实覆盖范围和期限 |
| 可验证性 | 上游测试、适用硬件 CI、已知问题、可复现构建或可追溯制品；测试存在不等于本产品测试通过 |
| 失效行为 | 有界超时/重试、状态持久化、完整性检查、失败恢复、数据格式向前/向后兼容 |
| 工业采用 | 优先采用方技术报告、部署文档、可审查代码/配置与故障经验；营销徽标仅作线索 |
| 全周期成本 | 集成和现场调试、存储/内存/功耗、密钥与证书管理、OTA 运维、维护期限及退出成本 |

证据冲突时列出目标版本差异、未知项及验证方法。没有证据不能把“常见”写成“生产已验证”；有采用案例也不能替代当前工程的验收。

## 可调查的工业方案

按本次功能选择一条相关路线，不强制给已有产品叠加全部机制。

| 场景 | 方案与一手依据 | 适用条件及关键验证 |
| --- | --- | --- |
| 嵌入式 Linux 可靠升级 | [RAUC 集成指南](https://rauc.readthedocs.io/en/latest/integration.html)：签名 bundle、slot、bootloader 协作、启动健康确认 | 可采用冗余槽或 recovery 布局，但必须核实空间、启动选择、boot 状态写入可靠性；测试更新中断、坏镜像、失败启动及回退。RAUC 不能自动修复错误分区布局 |
| 多组件设备更新 | [SWUpdate 文档](https://sbabic.github.io/swupdate/swupdate.html)：更新描述、handler、签名及 bootloader 协作等 | 按组件依赖和实际存储确定事务/恢复边界；不要从“有 SWUpdate”推定整体更新原子性。与 RAUC 比较既有集成和恢复语义，不按流行度替换 |
| 可信启动 | [U-Boot Verified Boot](https://docs.u-boot.org/en/latest/usage/fit/verified-boot.html)、[Android AVB](https://source.android.google.cn/docs/security/features/verifiedboot/avb?hl=en) | 匹配平台的完整信任链、生产密钥与回滚策略；错误签名、篡改与旧版本行为均需实测。熔丝与防回滚状态变更可能不可逆，不能作为普通冒烟测试 |
| 可维护定制 Linux 镜像 | [Yocto 发布规则](https://docs.yoctoproject.org/ref-manual/release-process.html)、[重现构建](https://docs.yoctoproject.org/test-manual/reproducible-builds.html) | 对齐产品支持期、BSP/layer/工具链；保留源码 ref、配置、补丁、依赖和镜像校验值。CVE/SBOM 输出还需分析适用性和修复状态 |
| Debian 工业镜像 | [Isar 上游仓库](https://github.com/ilbers/isar)、[CIP 项目定位](https://www.cip-project.org/about) | 可调查 Debian 包生态与可重建镜像、长期维护的组合。CIP 是工业长期维护的一条路线，实际内核、架构、组件和支持期需按对应分支确认 |
| Ubuntu 设备产品 | [Core 恢复机制](https://documentation.ubuntu.com/core/explanation/recovery-modes/)、[SRU](https://ubuntu.com/project/docs/SRU/stable-release-updates/) | Core 与传统 Ubuntu 的机制分开评估；对已有系统优先沿既有更新和回归流程处理，不默认迁移到 Core |
| Android 系统升级与兼容 | [Virtual A/B](https://source.android.com/docs/core/ota/virtual_ab)、[Legacy A/B](https://source.android.com/docs/core/ota/ab)、[GKI](https://source.android.com/docs/core/architecture/kernel/generic-kernel-image)及目标版 CTS/VTS 文档 | 在当前启动/分区与 vendor 接口契约下验证；新产品与既有 BSP 分开选型，不把旧 A/B 方案无条件用于新产品；数据迁移、健康确认、签名与防回滚条件分别检查 |
| OpenHarmony 设备集成 | [发行记录](https://gitee.com/openharmony/docs/blob/master/zh-cn/release-notes/Readme.md)、目标分支适配和测试文档 | 先识别系统类型/内核/部件与设备支持；XTS/子系统回归、升级恢复均按实际版本执行。缺少产品部署证据时作为候选，不冠以量产成熟结论 |
| openEuler Embedded / 实时产品 | [Embedded SIG](https://gitee.com/openeuler/community/blob/master/sig/sig-embedded/sig-info.yaml)、[产品 layer](https://gitee.com/openeuler/yocto-meta-openeuler) | 区分 Linux 实时与异构 OS 协作；对齐 BSP、隔离、通信和负载；量测尾延迟与故障恢复，不能从 PREEMPT_RT 开关推导硬实时保证 |

以上参考支持机制或项目定位，不统一构成所有路线的量产认证。关键机制仍需阅读对应发布版详细文档；旧文章只作背景。

## 让验证回答实际问题

**先定验收，再选工具。** 能力存在不代表应全部运行；简单局部改动使用相称检查，跨启动链/存储/升级的变更增加故障恢复验证。

| 改动 | 应取得的关键证据 |
| --- | --- |
| kernel 驱动/DT | 对应配置构建、相关 binding/静态检查、针对逻辑的测试；目标上枚举/探测、正常与错误路径，涉及电源时测 suspend/resume、重启和负载 |
| U-Boot/启动 | 目标配置构建及相关 sandbox/启动测试；目标冷启动/复位、加载失败和回退。先验证可恢复路径再动启动介质 |
| Debian/Ubuntu 包与服务 | 包构建和既有包测试、升级/配置保留、服务启停/失败重启、日志和权限；使用适用的隔离测试环境 |
| Yocto/镜像 | 目标配方和镜像构建、工程 QA；按需要使用 ptest/testimage、许可证/CVE/SBOM 与重现性检查；仍需目标启动和实际功能 |
| OpenHarmony/openEuler | 目标分支的原生构建/测试入口，相关子系统和兼容性测试；硬件相关改动另验证启动、驱动、权限、升级与异常路径 |
| Android/AOSP | 对应模块/产品构建、相关单测和权限/接口检查；按影响选择 CTS/VTS/专项测试；内核/镜像/OTA 改动另测目标启动和升级恢复 |
| 性能/实时 | 固定镜像/配置、硬件、负载、温度和电源条件；记录工具与运行方式、样本/时长、分布及尾延迟。观测最大值不能证明最坏执行时间上界 |
| 长稳/恢复 | 与失效模型相关的持续负载和故障注入；记录观察窗、循环数、失败与恢复时间。短时“没报错”不能推断长期无故障 |

故障注入、断电、存储破坏和重启不是无害的“只读验证”。先准备隔离对象、备份/恢复和中止条件，按用户已有授权操作；缺少条件时完成测试准备并明确待测。

## 精简的交付证据

只有跨多个关键取舍或需要长期追踪时才保存如下记录；简单修复可在最终答复中表达，不强制新增工程文档。

```text
任务/范围：用户要改变什么；当前不改变什么
目标与基线：ref、配置、环境、复现与观测值
关键依据：结论 | URL/commit/章节 | 目标版本 | 本地差异 | 访问日期
决策：候选/推荐/取舍；未决项及其影响
改动：文件/配方/配置/补丁/制品及其目的
验证：命令/环境/预期/实际/日志；功能、回归、失败路径
恢复：触发条件、旧制品/配置、数据兼容、恢复步骤与验证状态
结论：已研究/已实现/已构建/目标已测；明确剩余工作
```

“最佳实践”最终必须落在适配条件与证据上。信息不足时交付已完成部分和精准缺口，不补写成功日志、认证、客户采用或社区共识。
