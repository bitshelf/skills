# 正确性、性能、日志与 bug 排查

## 错误与结构化日志

- 库向调用者暴露可处理的领域错误，保留 source；应用边界可用项目已有的错误上下文方案。`thiserror`、`anyhow` 等只是可能的实现选择，新增时同样经过维护评估，不能把 crate 名当作默认合格证据。
- 区分用户输入、外部 I/O、取消、超时与程序不变量破坏；用 `?`、显式转换及错误上下文传播。不得用 `let _ = ...`、`.ok()`、默认值或空集合掩盖失败；确实允许忽略时解释影响与理由。
- 优先已有日志 facade。需要结构化事件和异步因果关联时可评估 `tracing`；简单同步库可沿用 `log`。subscriber/logger 的初始化、过滤、输出与关闭由应用负责，库不能夺取全局配置。
- 日志字段记录操作、错误类别/错误链、耗时及安全的关联 ID。正常事件 `info`，可恢复异常按需 `warn`，无法完成的操作 `error`，细节 `debug/trace`；在真正处理错误的边界记录，避免每层重复报错。
- 密钥、token、口令、个人信息、原始请求体不直接进入日志。`#[instrument]` 默认可能记录参数，应显式 skip 敏感参数或采用 `skip_all`，只选择可记录字段；也要检查错误 `Display`/`Debug` 是否包含敏感内容。
- 使用 tracing 时，不跨 `.await` 持有 `Span::enter()` guard；使用 `#[instrument]` 或 future 的 `Instrument`。异步缓冲日志需确认丢弃策略、背压和退出 flush；普通 CLI 的机器可读 stdout 与诊断 stderr 分开。

来源：[tracing 官方文档](https://docs.rs/tracing/latest/tracing/)、[log 官方文档](https://docs.rs/log/latest/log/)。

## 性能与资源预算

- 先确定问题与指标：吞吐、p50/p95/p99 延迟、分配次数/峰值内存、CPU、二进制体积、启动/编译时间。只采集与任务相关的指标，别让小修改变成全套压测。
- 以匹配部署的 release/profile、target、硬件、工具链、features 和代表性负载测基线；记录输入、预热、重复次数与波动，区分 I/O、锁等待、分配与计算瓶颈。debug 时间不用于发布性能结论。
- 先改善算法、数据结构、批处理和 I/O，再减少热点中的 clone/分配/字符串格式化；按实际上界合理预分配。不要为减少一点分配引入不清晰的生命周期、无界缓存或维护成本更高的依赖。
- 通过 profiler 与 benchmark 验证瓶颈及收益。基准工具使用项目已有方案；若选 Criterion 等第三方工具，仍须维护审查；bench 使用 `std::hint::black_box` 等合适措施避免被优化掉。
- 泛型单态化、LTO、codegen units、allocator、哈希算法、SIMD 和并行化均有代价；逐项测量。不为性能关闭输入校验、溢出检查或随机哈希防护，不无依据引入 unsafe。
- 对不可信输入限制长度、深度、分配及并发，使用 checked 运算处理尺寸/偏移，避免 release 下溢出和拒绝服务；选择与语义相符的 saturating/wrapping 需说明理由。

参考：[The Rust Performance Book](https://nnethercote.github.io/perf-book/)。

## 并发、async 与嵌入式

- 无实际并发需求先用同步实现；沿用已有 runtime，不混用 runtime，不在异步执行线程中直接执行长时间阻塞 I/O/CPU 工作。使用适合负载且受限的阻塞/计算池。
- 明确 timeout、取消安全、重试上限、退避/抖动与幂等性，设置队列容量/背压和任务上限。关闭时停止接收、通知取消、等待任务并按政策处理剩余工作；跟踪 JoinHandle 中的失败。
- 不跨 `.await` 持有普通锁 guard 或不适合跨 await 的借用；检查锁顺序、临界区、原子内存序与 `Send`/`Sync`。共享状态优先清楚的所有权边界或消息传递，不机械改为 `Arc<Mutex<_>>`。
- `no_std` 分清是否有 `alloc`、allocator、panic handler、原子指令与中断约束；不引入依赖 std 的日志/错误/runtime。目标、linker、ABI、工具链和硬件限制从当前工程解析，不固化板型。
- FFI 明确 ABI、缓冲区长度、资源所有权和跨边界错误策略，防止不允许的 unwind 跨边界；packed/MMIO/volatile/原子操作按实际平台契约处理。内核/AOSP 代码遵守原生工具链、API 和依赖准入流程，不自行从 crates.io 拉包。

## 测试与检查矩阵

先用现有 CI；下面只适用于普通 Cargo 工程。根据 workspace 支持情况缩小到相关 `-p`/target/features，不能要求混合宿主/嵌入式 workspace 全部在宿主可运行。

```bash
cargo fmt --all --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
cargo test --workspace --doc --locked
cargo doc --workspace --no-deps --locked
```

- `--locked` 要求已有兼容 lockfile；首次创建或项目明确不跟踪 lockfile 时调整命令并说明。第三行默认包含 doctest，第四行仅用于单独定位/验证 doctest，通常无需重复执行。
- `-D warnings` 适合项目已采用的 CI 门槛；旧工程先区分基线 warning 与本次引入问题，不为通过检查批量关闭 lint。文档检查沿用项目 rustdoc lint 设置，不能从 `cargo doc` 退出成功推断没有 warning。
- 默认 features、无默认 features、可支持的关键组合分别选择测试；`--all-features` 仅在组合合法时使用，不把全部启用当作覆盖了禁用路径。发布库按承诺检查 MSRV 和受支持目标；最低编译检查与完整行为测试区分。
- `--all-targets` 不等于覆盖所有平台，也不能代替单独的 doctest。交叉编译只证明编译能力，运行测试需目标 runner/设备；不能把 `cargo check` 称为目标设备测试。
- 测试断言外部行为与契约。覆盖空输入、边界、非法编码/截断、错误来源、资源释放及相关超时/取消路径；避免只复述实现。时间/网络/文件系统依赖尽量可控，使用唯一临时目录，避免全局环境变量引入并行干扰。
- 对解析器/不可信二进制输入可考虑 property test/fuzz；unsafe 或自定义并发原语按风险使用 Miri、sanitizer 或模型检查。先核对工具支持；Miri 通常需要独立 nightly 工具链且不能运行所有系统/FFI 调用，通过不等于证明全部内存安全，不要求每个普通修改安装它。
- 安全审查工具依据 [RustSec](https://rustsec.org/) 与项目策略运行；工具缺失、联网受限、测试失败都单独报告，不写成“检查通过”。

命令语义：[cargo test](https://doc.rust-lang.org/cargo/commands/cargo-test.html)、[Clippy](https://doc.rust-lang.org/clippy/usage.html)、[cargo doc](https://doc.rust-lang.org/cargo/commands/cargo-doc.html)、[Miri](https://github.com/rust-lang/miri)。

## bug 排查与交付

记录预期/实际、最小复现、工具链/target/features、关键错误链与脱敏日志。必要时在本地用 `RUST_BACKTRACE=1` 分析 panic；不为了拿日志启用包含密钥的全量生产追踪。先定位根因，再写会在旧实现失败的回归用例并修改；并发/偶发问题注明触发条件和证据局限，不用增加 sleep 或吞错误掩盖。

交付包括：用户可见行为、兼容性/资源代价、检查结果，以及确实存在的未验证部分。性能变化用前后数据支持，库的公开 API/feature/MSRV 变化明确说明迁移影响。
