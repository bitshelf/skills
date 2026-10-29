# 依赖选型与持续维护

此处为用户要求的工程政策，不代表上游官方对 crate 质量的认证。每次新增、升级或替换依赖都要按当前日期取证；不维护一份声称永久可靠的 crate 白名单。

## 先确认是否需要依赖

检查标准库、项目已选依赖和平台提供的能力，避免为小功能扩大依赖树。保留已有日志 facade、错误风格、async runtime 和 TLS 后端，除非有明确迁移需求。开发依赖与运行时依赖分开，按使用路径启用最少 features；不习惯性开启 `full`。

## 查证流程

1. 从 crates.io 包页面核对 repository、文档、准确包名和目标版本，防止同名/近似包与失效链接。查看上游仓库归档状态、README、维护/安全政策和许可证；确认评估的是发布版本关联的仓库及组件。
2. 默认观察最近 12 个月发布、合并 PR、review、issue triage 和修复，结合最近 90 天判断当前响应。记录至少两位真人的实质维护证据；仅有两位贡献者、bot 提交、历史 contributor 总数或组织 owner 都不足以成立。
3. 检查维护延续：多个活跃维护者如何 review/发布，是否有公开支持政策、交接途径及安全响应渠道；公开信息看不到发布权限时明确未知，不能虚构多人拥有权限。成熟低 churn 项目查兼容性与安全响应，不强求为活跃度发布新版本。
4. 阅读目标版本 release notes、破坏性变更、MSRV、edition、平台/target、`no_std`、runtime 要求。验证需求是否匹配，不以最新版本代替兼容性分析。
5. 查 [RustSec](https://rustsec.org/)、仓库 security advisories，以及该版本是否 yanked；区分漏洞与维护状态告警。查看启用 features 后实际依赖树的 unsafe/FFI、`build.rs`、proc-macro、原生库及构建来源。安装/编译第三方代码可能执行构建脚本，先确认来源。
6. 对合理候选比较功能、维护团队、风险、性能证据、依赖数量/体积、许可证、迁移成本。优先多人持续维护、边界清晰、可替换的方案；不从一次本机 benchmark 推断所有平台最快。

无法联网、证据过旧或看不到近期维护参与者时标记“未验证”。新的直接依赖不能因此自动通过门槛；先寻找无需新增依赖的方案。用户确需例外时说明哪些要求不满足及替代方案。现有依赖不在普通任务中自动删除或批量替换。

## 记录最小选型依据

依赖 PR/交付说明中记录下面字段；小修改可以用简短段落，较多候选可用表格：

| 字段 | 内容 |
| --- | --- |
| 评估日期、用途 | 当前日期、为什么 std/已有依赖不够 |
| crate、版本、features | 具体约束、实际解析版本、来源 URL |
| 多人实质维护 | 至少两位真人及近期 review/修复/发布证据链接和日期 |
| 延续性判断 | 团队/支持/交接证据，已知未知项；不承诺未来 |
| 兼容性与供应链 | MSRV、target、runtime/no_std、许可证、RustSec 与间接依赖风险 |
| 取舍与退出方案 | 候选差异、必要的适配边界、替换或上游升级路径 |

## 版本、lockfile 与后续维护

- 依赖使用有边界的 SemVer 要求；不写 `*`，不依赖浮动 git 分支。确需 git 依赖时固定具体 `rev` 并说明原因、来源及返回发布版的计划。
- 按项目政策提交 `Cargo.lock`，应用通常应提交；[Cargo 当前建议](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html)是在不确定时纳入版本控制，不能机械套用“库永不提交”。lockfile 由 Cargo 维护，不手改。
- CI 有 lockfile 时用 `--locked` 防止隐式更新；它不代表禁止联网。完全离线复现另需缓存/供应商目录及对应离线设置。库的 lockfile 不会替下游锁定解析结果，还应验证声明的版本兼容范围。
- 用 `cargo tree -e features` 看实际 feature 传播，必要时用 `cargo tree -d` 查看重复版本；不能靠一处 `default-features = false` 保证整棵树禁用默认功能。
- 若已有工具与政策，执行 `cargo audit` 检查 lockfile 的已知公告、`cargo deny check` 检查配置中的许可/来源/依赖限制。读取结果并结合可达性与配置处置，不自动 ignore，不把“没有已知公告”解释为绝对安全。无工具时报告检查缺失，不虚构扫描结果。
- 更新单个依赖优先定向变更，例如 `cargo update -p crate_name`，审阅 lockfile 差异并运行相关检查，避免无目的升级整棵树。
- 建议项目在依赖更新时及定期维护时复查维护状态；可采用已有 Dependabot/Renovate 或 CI，但不因调用本技能就创建外部任务。新增 ignore/临时例外应注明理由、负责人及复查条件。

参考：[Cargo features](https://doc.rust-lang.org/cargo/reference/features.html)、[MSRV](https://doc.rust-lang.org/cargo/reference/rust-version.html)、[RustSec 工具说明](https://rustsec.org/)。
