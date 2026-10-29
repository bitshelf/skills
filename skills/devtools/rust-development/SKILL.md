---
name: rust-development
description: Rust 代码编写、重构、审查与 bug 排查；遵守 Rust 官方及 Google 风格，按当前证据选择多人持续维护的 crate，覆盖错误处理、日志、性能、测试、unsafe 与 no_std。适用于 .rs、Cargo 项目及已有构建系统中的 Rust 代码。
---

# Rust development

在目标项目中实现可维护、可验证的 Rust 代码。相对资源路径以本 SKILL.md 所在目录为基准；构建和检查在目标项目执行。

## 规范与适用范围

- 采用 [Rust 官方风格](https://github.com/rust-lang/rust/tree/main/src/doc/style-guide/src)（[阅读版](https://doc.rust-lang.org/style-guide/)）及 [Google Rust Style Guide](https://google.github.io/styleguide/rustguide.html)，API 设计参考 [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)。不复制整份上游手册，遇到具体规则查对应章节。
- 对两份规范的冲突，采用 Google 在该项目适用的规则；项目已有显式约束或用户要求与之不同时，指出差异并遵循项目约束，不把例外宣称为上游规范。
- Google 的 `[chrome]`、`[Fuchsia]` 和内部构建工具条款只用于相应代码库。普通 Cargo 项目不因此禁用 async、标准库线程或嵌套目录。库的公共 API 规则按库场景执行；应用内部保持直接、避免过度抽象。
- 编写或审查代码时读 [references/style.md](references/style.md)；新增、升级或替换依赖时读 [references/dependencies.md](references/dependencies.md)；排障、性能、并发及检查矩阵见 [references/quality.md](references/quality.md)。按任务需要加载。

## 工作流程

1. **先识别项目约束。** 阅读项目说明、CI、manifest、lockfile、工具链与格式配置。确认 edition、最低支持 Rust 版本（MSRV）、target、features、`std` / `alloc` / `no_std`、同步或异步，以及构建入口。已有 AOSP/内核/GN/Bazel 工程继续使用其原生构建流程，不擅自改为 Cargo，也不引入另一个 runtime。
2. **选择最小合适方案。** 优先标准库和已有依赖；新第三方直接依赖必须满足下述维护门槛。用所有权和类型表达不变量，优先安全 Rust、清晰控制流、小而明确的 API；不通过无理由的 clone、全局锁或 lint 豁免消除诊断。
3. **落实错误与可观测性。** 可恢复错误用 `Result` 和 `?` 保留错误链；预期缺失用 `Option`。输入、I/O、网络失败不靠 panic。按现有日志栈记录结构化上下文，在负责处理错误的边界输出一次，避免泄露密钥和用户数据。
4. **验证实际行为。** bug 修复先复现，增加能暴露原缺陷的回归用例；功能变更按风险覆盖边界、失败和取消路径。运行匹配项目的格式、lint、测试与文档检查；性能修改先建立基线再测量。区分执行通过、仅编译和未验证目标。
5. **交付证据。** 简述行为变化、关键取舍、执行的检查及限制。依赖变更附来源、版本/features、维护评估日期与证据；性能声明附环境、负载和前后数据。缺工具或网络时明确尚未验证，不编造通过结果。

## 第三方 crate 的维护门槛

这是本技能按用户要求制定的选型政策，不是 Rust 或 Google 官方规定：

- 新增或替换直接依赖前，实时查 crates.io 指向的真实上游、发布、近期 PR/issue、维护政策及 RustSec；不能凭记忆、star 数、下载量或累计贡献者数量认定合格。
- 要有至少两位真人近期参与实质维护的可核验证据，以及当前仍有问题响应、发布/兼容性维护或安全修复的迹象。默认查看最近 12 个月，结合最近 90 天活动及项目成熟度判断；bot、偶发拼写贡献和组织名不等于多人维护。
- 未来维护无法保证；只能基于维护团队延续、交接机制、支持政策和历史响应给出有日期的判断，并保留升级、替换或隔离方案。没有证据就写“未验证”，不宣称“未来一定维护”。
- 不新增 archived、deprecated、明确停止维护、无人响应的 crate，或当前用途涉及未解决严重安全问题的版本。成熟低频发布不自动等于弃维护，但仍需多人维护的证据。
- 没有合格候选时先考虑标准库、已有受支持能力或缩小实现；确实需要例外时说明证据缺口和替代方案，由用户决定取舍。已有依赖的历史风险单独报告，避免把普通修改扩展成全量迁移。
- 依赖树同样检查漏洞、许可证、来源和维护告警；对间接依赖中的维护单点记录风险与可行的上游升级/替换路径，不将直接依赖的合格结论泛化到整棵依赖树。

## 编码底线

- 默认 stable；不为格式偏好启用 nightly、不擅自提升 MSRV。特殊平台的必要 unstable 功能必须有项目依据。
- 可读性优先；API 接受合适的 `&str`、`&[T]`、`&Path`，不无谓绑定 `String`、`Vec` 或 `PathBuf`。用 newtype、enum、可见性表达业务约束，避免含义不明的 bool 参数。
- 使用 `match` / `if let` / `let else` 表达分支；不要先检查再 unwrap。确有无法通过类型表达的不变量时用附原因的 `expect`，并记录可能 panic 的公共契约。
- 不吞掉错误、不绕过 mutex poison、不滥用 `catch_unwind`；不在 `main()` 前运行隐式初始化代码。公共库不安装全局日志 subscriber 或 panic hook。
- 优先 safe Rust；不得仅凭“更快”引入 unsafe。确需 unsafe 时隔离为最小安全抽象，给出 `SAFETY:` 证明和必要性，覆盖指针有效性、对齐、初始化、别名、生命周期及线程约束。
- 使用项目已有 rustfmt/Clippy 配置；新增 lint 限制应局部、具体且有原因。不对旧工程直接启用整组 pedantic/restriction 并批量修改无关代码。
