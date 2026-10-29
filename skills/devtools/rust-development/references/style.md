# Rust 与 Google 风格的落地

规范来源：[Rust Style Guide 源码](https://github.com/rust-lang/rust/tree/main/src/doc/style-guide/src)、[阅读版](https://doc.rust-lang.org/style-guide/)、[Google Rust Style Guide](https://google.github.io/styleguide/rustguide.html)。具体疑问查当前原文，以下是工作索引与执行要点。

## 格式与代码组织

- 使用项目选择的格式化工具；Cargo 项目通常用 `cargo fmt`。默认 4 空格、100 列及 rustfmt 布局；已有显式配置遵循项目规则，不顺手重排整库。
- 工具链版本、语言 edition 和格式 style edition 分别确认，不通过改 edition 解决格式差异。Google 的一部分 rustfmt 选项可能在项目 stable 工具链不可用，先查该版本支持情况；不盲目复制 nightly 配置。
- 每个 `use` 导入同一个模块中的条目，例如 `use std::io::{Read, Write};`；另一个模块单独写 `use std::path::Path;`。`imports_granularity = "Module"` 的可用性须核实，不能假设 stable 已支持。
- 通常导入类型名直接使用；顶层自由函数保留模块限定，如 `fs::read`；常见歧义可用 `io::Error` 或重命名。只在一处用到的 trait 优先局部导入。
- 避免 glob import；Google 允许 inline 模块的 `use super::*`、局部枚举变体导入、非叶模块重导出等特定情况；第三方 prelude 需结合项目约定评估。
- 叶模块按主要类型/职责命名；非叶模块以声明和重导出为主，允许少量必要的连接逻辑。普通 Cargo 工程保持常规 `src/` 布局；Chromium 平铺文件及小 crate 规则只用于 Chromium。
- `#[rustfmt::skip]` 只用于必要的手工对齐或生成代码，附理由；不用它维持个人格式偏好。

## 命名、类型与 API

参考 [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/checklist.html)；Google 的上下文规则优先。

- 类型/trait 用 `UpperCamelCase`，函数/模块/变量用 `snake_case`，常量/静态用 `SCREAMING_SNAKE_CASE`；用清楚的业务名，避免含糊缩写。遵循 `as_` / `to_` / `into_` 的借用、转换、消费语义。
- 以借用表达共享读取，以所有权转移表达消费；不为了绕过 borrow checker 添加深拷贝。仅在确需共享所有权时用 `Rc` / `Arc`；克隆它们不是深拷贝，也不能让非线程安全内部数据自动变安全。
- 业务单位、ID、状态用 newtype/enum；多个有业务含义的返回字段用命名结构体。type alias 不提供类型隔离。布尔开关容易混淆时改为有语义的 enum。
- 泛型与 `dyn Trait` 按扩展需求、运行时异构、编译时间和代码大小选择；不为单个实现强造 trait，也不把“零成本抽象”当作无需测量的性能结论。
- 需要时实现标准 trait，优先合理的 derive；为有合理默认值的类型与 options struct 实现 `Default`。`Eq`、`Ord`、`Hash`、`Copy` 等实现必须满足其契约和未来 API 承诺；不为“齐全”添加错误语义。
- 对跨团队/跨 crate、预期扩展的公共 enum 与公开字段 struct，按 Google 规则使用 `#[non_exhaustive]`；固定枚举、承诺处理破坏性迁移、或需 struct update 语法等情况按原文例外评估。已有公共 API 加此属性可能破坏调用方，须审查兼容性。
- 对忽略返回值会误用的函数、惰性计算或关键状态类型使用 `#[must_use]`；`Result` 已有标注，不重复添加无意义标注。
- 公共 `const fn` 是兼容性承诺；不访问外部 `#[doc(hidden)]` 项，不用操作符表达与数学含义不符的操作，不依赖 `main()` 前的构造器副作用。
- getter/setter 保持 Rust 命名习惯；不机械添加 `get_`，也不为每个字段生成无约束 setter。必要时用方法维持不变量。

## 错误、文档与 unsafe

- 缺失且不构成错误用 `Option`，可恢复失败用 `Result`，程序缺陷/破坏的不变量按项目策略处理。公共错误类型提供可理解的 `Display`、`Debug` 以及适用的 `Error::source`；简单无持有资源的错误可按 Google 建议实现 `Copy`。
- `expect` 的消息解释“不变量为什么应成立”，不只写“失败”；断言消息给出诊断上下文。Google 不建议调用 `panic::catch_unwind`；普通错误恢复不用它，FFI 等特殊边界若项目要求捕获，需明确依据和 panic 策略。
- `///` 描述公共 API，`//!` 描述 crate/模块；解释行为、单位、不变量及必要的示例，按需要提供 `# Errors`、`# Panics`、`# Safety`。示例应能作为 doctest 运行；外部环境依赖示例明确说明为何不能执行。
- unsafe 函数记录调用方的安全义务；unsafe block 前写 `SAFETY:` 说明该处如何满足义务，并解释安全实现为什么不足。若唯一理由是性能，提供基准证据；测试不能代替安全论证。

## 作用域容易误用的 Google 条款

| 条款 | 适用方式 |
| --- | --- |
| `[chrome]` 禁用 async/await、禁止直接用标准库新建线程 | 仅 Chromium；其他项目按自己的 runtime 与线程模型 |
| `[chrome]` 平铺源文件、专用 import/构建工具 | 仅相应代码库，第三方 Cargo 代码还有原文例外 |
| `[Fuchsia]` 使用 `fuchsia_sync::Mutex` | 仅 Fuchsia，不向普通项目新增该依赖 |
| 不使用 unstable 功能 | 默认执行；上游列出的平台例外仍须有目标项目依据 |
| 不读取 poisoned mutex 内部数据 | Google 通用规则；传播失败/终止受影响操作，不以 `into_inner()` 静默继续 |
| 库的公共 API 设计规则 | 库中执行，应用内部强烈建议并兼顾简单直接 |
