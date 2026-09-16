---
name: semcode
description: 使用 semcode MCP 检索 Linux 内核及 C/C++ 源码中的函数、类型、调用关系和提交，并按需建立索引，包含 SDK 中内核树位于子目录的布局（自动配置 SEMCODE_GIT_REPO）。适用于语义检索、定位定义、追踪调用链和上游邮件研究；工具未安装时使用本地文本搜索。
---

# semcode 语义源码导航

`semcode-mcp` 在其所指向的 git 仓库下自动发现 `.semcode.db`（默认即工作目录）。先检查当前工具列表、项目索引和本地命令帮助，不把本文示意参数当作固定 MCP schema。

## 首次准备

确认 `semcode-mcp`、`semcode-index` 可用，索引是否存在且对应当前源码。索引缺失并且任务需要时，从项目目录执行：

```bash
semcode-index -s .
```

需要配置 MCP 时可运行随附脚本：

```bash
bash <skill-dir>/setup-semcode.sh --force <project-dir>
```

`<skill-dir>` 指本技能目录。脚本会在需要时建索引并合并项目 `.mcp.json`，保留其他服务和已有 semcode 配置。仅检测到 Claude 配置时合并其工具许可；该许可仅适用于对应客户端。其他客户端的配置入口查当前客户端说明，不能假设都会读取 `.mcp.json`。

缺少可执行文件时先解决安装或使用 `rg`/Git 回退，不创建一个无法启动的服务。需要重载时沿客户端支持的流程操作；配置存在不等于本次会话已加载工具。

## 内核树位于子目录时

`semcode-mcp` 在其所指向的 git 仓库下自动发现 `.semcode.db`（`--git-repo`，环境变量 `SEMCODE_GIT_REPO`，默认 `.` 即工作目录）。厂商 SDK 把内核放在下一层（`kernel-6.1/`、`linux-5.10/`，或 `kernel` 符号链接），而 Agent 从 SDK 根启动，默认值就解析到根目录、在那里找不到索引，工具随即返回空结果。

随附脚本会识别这种布局并写入：

```json
{ "mcpServers": { "semcode": {
    "command": "semcode-mcp",
    "env": { "SEMCODE_GIT_REPO": "kernel-6.1" } } } }
```

取值是相对项目根目录的目录名，不是绝对路径。以下情况脚本不动：

- **项目根目录本身就是内核树**（根下有 `Makefile` + `arch/` + `Kconfig`）：默认 `.` 已能解析，不写 env。
- **根目录下有多棵内核树**：不猜，提示手工设置 `SEMCODE_GIT_REPO`。
- **自己已设过的值**：永不覆盖。

检测漏掉的布局手工设置后重启会话。索引要建在**指向的那棵树**上，而不是项目根：`cd kernel-6.1 && semcode-index -s .`。

## 按问题选工具

| 问题 | 常见操作 |
|---|---|
| 函数/宏定义 | `find_function` |
| 结构体、类型、typedef | `find_type` |
| 谁调用此函数 | `find_callers` |
| 此函数调用谁 | `find_calls` |
| 多层调用链 | `find_callchain` |
| 函数体正则搜索 | `grep_functions` |
| 按含义搜索 | `vgrep_functions`，需向量索引支持 |
| 符号相关提交 | `find_commit` |
| 从 diff 提取符号 | `diff_functions` |
| 邮件列表取证 | `lore_search`、`dig` |
| 索引情况 | `indexing_status`、`list_branches` |
| 比较分支 | `compare_branches` |

例如定位 `btrfs_submit_bio`、查 `mutex_lock` 的调用方或追踪 `submit_bio` 的调用链。先按工具 schema 选择路径、深度、方向和结果数量，避免无界查询。语义工具适合符号和调用关系；普通文本、配置和未索引文件仍可用 `rg`。

## 索引维护

```bash
semcode-index -s .
semcode-index -s . --git HEAD~20..
semcode-index -s . --vectors
```

以上增量/向量选项需查本地帮助；提交范围必须存在，向量模式可能需要模型。拉取较大改动后核对索引新旧。是否自动覆盖未提交修改由当前版本实现决定，不假设所有修改无需重建索引。

## 验证

使用工具列表或 `indexing_status` 确认服务可用，查询一个本地已知符号并对照源码。工具缺失时标明回退方式和调用关系分析的限制，不因缺少 MCP 中断可由本地工具完成的工作。
