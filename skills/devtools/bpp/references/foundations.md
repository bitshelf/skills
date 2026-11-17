# 基础系统：来源、社区与人物

初次收集：2026-10-29。以下是检索入口及当日证据快照，不是永久有效的人员/版本名单。运行技能时只读取相关栈，按目标 ref 重新定位文档与负责人；滚动文档中的新能力不能直接推定旧 BSP 支持。

## Linux kernel

- **官方规范与实现**：[内核文档](https://docs.kernel.org/)、[kernel.org 源码树](https://git.kernel.org/)、[维护者索引](https://docs.kernel.org/process/maintainers.html)、[stable 接收规则](https://docs.kernel.org/process/stable-kernel-rules.html)。以 checkout 的版本、配置和子系统文档为执行依据；发行版与厂商内核可能含回移补丁，不能仅凭版本号推断能力/漏洞状态。
- **社区讨论**：[lore 邮件归档](https://lore.kernel.org/)；从维护者文件找到子系统列表，再跟踪 patch series、后续版本、review 与最终合入 commit。邮件中有 Reviewed-by 不等于已进入目标稳定树。
- **人物线索**：Greg Kroah-Hartman（driver core/TTY 等）、Thomas Gleixner（时间、IRQ 等）可由官方维护者索引核对；Linus Torvalds 的主线、Greg/Sasha Levin 的稳定树可从 kernel.org 树及提交记录定位。具体驱动优先其维护者，不默认找总维护者。
- **当前应调查的技术**：相关驱动框架和 DT binding、资源/电源管理、锁与并发、kselftest/KUnit、trace/perf、PREEMPT_RT。按故障选择，不能一律启用调试选项或实时配置。
- **工程方向**：受支持的内核/发行版维护分支、小范围上游修复、可追溯配置与硬件回归。跨主版本升级需另证收益、驱动与 ABI 兼容、产品支持周期。

## U-Boot

- **官方资料**：[文档](https://docs.u-boot.org/en/latest/)、[开发与 custodian 流程](https://docs.u-boot.org/en/latest/develop/process.html)、[源码与 MAINTAINERS](https://github.com/u-boot/u-boot/blob/master/MAINTAINERS)。官方文档对应的发布版与实际厂商分支可能差异很大。
- **社区讨论**：[U-Boot 邮件归档](https://lore.kernel.org/u-boot/)、[Patchwork](https://patchwork.ozlabs.org/project/uboot/list/)。追到最终 commit 和目标 release，不能直接采用仍在评审的启动链改造。
- **人物线索**：Tom Rini、Simon Glass；当日 MAINTAINERS 可定位其负责范围。按目标板/子系统重新查对应 custodian，不把二人列为所有问题的专家。
- **技术入口**：[Standard Boot](https://docs.u-boot.org/en/latest/develop/bootstd/index.html)、[Verified Boot/FIT](https://docs.u-boot.org/en/latest/usage/fit/verified-boot.html)。先查分支具备的命令、Kconfig、信任链与存储布局。
- **工程方向**：有验证根的启动链、受控启动选择、升级状态与失败回退。FIT 验签只是信任链中的机制；公钥可信存放、前级验证和回滚保护须各自落实，不能只签内核便声称整机安全启动。A/B 更新还需要用户态健康确认和 bootloader 状态协作。

## Debian

- **官方资料**：[Debian Policy](https://www.debian.org/doc/debian-policy/)、[开发者参考](https://www.debian.org/doc/manuals/developers-reference/)、[发行与生命周期](https://www.debian.org/releases/)、[安全跟踪器](https://security-tracker.debian.org/tracker/)、[管理员手册生命周期章节](https://www.debian.org/doc/manuals/debian-handbook/sect.release-lifecycle.en.html)。区分 stable、安全更新、LTS/扩展支持的包及架构范围。
- **社区与源码**：[Salsa](https://salsa.debian.org/)、[BTS](https://bugs.debian.org/)、[邮件列表](https://lists.debian.org/)、[包跟踪器](https://tracker.debian.org/)。从 source package 的 Maintainer/Uploaders、补丁和 changelog 查包级决策。
- **人物线索**：Raphaël Hertzog；上述管理员手册明确记录其与 Freexian/LTS 的关系。系统政策及具体包问题仍以相应维护团队、已接受补丁与安全公告为准，不以作者个人观点作发行版要求。
- **技术方向**：包化交付、可追溯依赖、安全回移、镜像再构建、升级与配置兼容；镜像工程可调查 [Isar 上游仓库](https://github.com/ilbers/isar)（基于 Debian 构建定制系统镜像）。使用 Isar 是候选路线，不是所有 Debian 项目的必需项。
- **工程方向**：在既有受支持发行分支修复并通过包/服务/镜像回归。不要混用发行代号的软件源、任意替换系统库或用上游最新版本覆盖发行版的安全回移策略。

## Ubuntu

- **官方资料**：[生命周期](https://ubuntu.com/about/release-cycle)、[SRU 稳定更新流程](https://ubuntu.com/project/docs/SRU/stable-release-updates/)、[Ubuntu Core 文档](https://documentation.ubuntu.com/core/)、[安全公告](https://ubuntu.com/security/notices)。LTS 是基础线索；具体包、架构、仓库组件和订阅支持范围仍需核实。
- **社区与源码**：[Launchpad](https://launchpad.net/ubuntu)、[Ubuntu Discourse](https://discourse.ubuntu.com/)。从包任务、补丁、回归报告和 SRU 验证看是否适用；个人 PPA 不等同官方更新通道。
- **人物线索**：[Julian Andres Klode / juliank](https://launchpad.net/~juliank) 的公开主页与团队/包活动，可作为包管理方向的检索起点。其他主题从对应包维护者、Foundations/Kernel/SRU 团队定位。
- **技术方向**：稳定分支修复与 SRU 验证、系统服务、受控镜像；设备产品另查 Core 的模型、组件、更新和[恢复模式](https://documentation.ubuntu.com/core/explanation/recovery-modes/)。
- **工程方向**：先区分 Server/Desktop/定制 rootfs 与 Ubuntu Core。Core 的恢复和更新机制不能直接宣称普通 apt 系统已有；更换产品形态需要用户明确的架构选择。

## 资料使用规则

参考人员名单是搜索导航，不自动授权联系任何人或向邮件列表/issue 发帖。发现链接迁移、职责变更或文档状态未知时先查官方仓库和索引；没有直接读到正文的链接只记作待核线索。
