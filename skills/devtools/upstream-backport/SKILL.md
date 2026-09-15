---
name: upstream-backport
description: 从分散的远程上游（kernel.org cgit、googlesource gitiles、salsa.debian.org GitLab、Gerrit、GitHub）免克隆取证补丁，完成 Buildroot / Yocto / AOSP / Debian 包 / Linux 内核的 backport 分析、冲突预判与落地指导。当用户提到 backport、移植补丁、cherry-pick 到旧分支、CVE 修复移植、stable 补丁、上游 commit 适配到本地旧版本，或涉及 buildroot/yocto/AOSP/Debian/内核的补丁集成时触发。不适用于全新功能开发、代码重构，或上游与目标在同一本地仓库的简单 cherry-pick。
---

# Upstream Backport 助手

## 核心原则

1. **AI 只做分析与建议，不直接修改工作区代码文件**。产出物是 backport 分析报告 + 适配后的 patch 文件；apply / cherry-pick / 冲突解决 / 构建由用户人工执行。原因：backport 冲突解决依赖对目标分支历史上下文的理解，AI 盲目落笔会引入隐蔽回归。
2. **免克隆取证**。内核约 4GB、AOSP 超 100GB，不做完整 clone；用各 git web 前端的 raw URL 直接拿 patch / 文件 / diff。取证阶段只需要 commit 粒度内容，clone 是浪费。
3. **先定位、再取证、后落地，不跳步**。backport 失败的主因不是"应用不上"，而是找错补丁、漏掉依赖补丁、没察觉目标分支上下文漂移。

## 入口判断（按用户输入路由）

- **给了 CVE 编号** → 从阶段 1 开始（CVE → fixed version → commit 定位）
- **给了上游 commit SHA 或 URL** → 跳过定位，从阶段 2 取证开始
- **给了 patch 文件 / 邮件列表链接 / 本地 diff** → 跳过取证，从阶段 3 分析开始
- **只描述了 bug 现象** → 先帮用户定位上游修复（grep.app / codesearch.debian.net / lore 搜索），确认后走全流程

## 五阶段工作流

### 阶段 1：定位上游修复

目标：拿到准确的上游 commit SHA（或 patch URL）**和完整的依赖补丁链**。

按来源选择定位工具（URL 细节见 `references/fetch-recipes.md`）：

| 线索类型 | 定位路径 |
|---|---|
| CVE 编号 | 内核：kernel.org vulns.git（`cve/published/<year>/CVE-*.mbox` 直接列 fix commit）；其他生态：Debian security-tracker / OSV (api.osv.dev) / NVD 拿 fixed version → 反查 commit。URL 语法见 `references/fetch-recipes.md` 第 0 节 |
| 内核 bug | lore.kernel.org 搜邮件列表；stable queue（linux-stable-rc.git）确认是否已排队 |
| Debian 包 bug | codesearch.debian.net（需 API key）正则搜；sources.debian.org 看 debian/patches；snapshot.debian.org 相邻版本 debdiff |
| 代码符号/模式 | grep.app 搜 GitHub 全量；Sourcegraph |
| Yocto/Buildroot 包 bug | 先确认包的上游项目地址（repology.org），再到上游 git 找修复 |

**依赖链检查（不可省）**：commit message 的 `Fixes:` 标签、邮件系列的 N/M 编号、补丁引用了但自身未定义的符号——依赖补丁必须一并 backport。

**确认门**：向用户展示 patch 头部 + commit message 摘要，确认"是这个修复"后再继续。找错补丁是最大浪费源。

### 阶段 2：免克隆取证

识别上游托管平台，用对应 recipe 把 raw 内容拉到临时目录 `/tmp/backport-<任务名>/`。完整 URL 语法见 `references/fetch-recipes.md`；也可用 `scripts/fetch_patch.sh <commit页面URL>` 自动识别平台（cgit / sourceware gitweb / gitiles / Gerrit / GitHub / GitLab / lore URL 直贴）拉取——脚本自带 HTTP 错误与 HTML 错误页检查，失败即报错清理，不会把错误页留盘误导后续分析。

| 站点特征 | 前端 | 典型上游 |
|---|---|---|
| git.kernel.org / git.yoctoproject.org / git.openembedded.org / git.busybox.net / sourceware.org | cgit | 内核、Yocto、OE、Buildroot、glibc |
| *.googlesource.com | gitiles | AOSP、Chromium |
| android-review.googlesource.com 等 | Gerrit REST | AOSP review |
| salsa.debian.org / gitlab.freedesktop.org / gitlab.gnome.org | GitLab | Debian 包、freedesktop |
| github.com | GitHub | 各项目镜像 |

通用规则：
- **大 patch（>3000 字符）一律 `curl -sL -o` 落盘再读**，不用 Fetch 类工具（会截断，截断的 patch 会漏 hunk 导致错误结论）
- gitiles `format=TEXT` 与 Gerrit patch 响应是 **base64**，必须 `| base64 -d`
- Gerrit / gitiles 的 JSON 响应带 `)]}'` 前缀，`tail -c +5` 去掉

### 阶段 3：补丁分析

读取 patch，产出：

1. **变更符号清单**：函数 / 结构体 / 宏 / 文件
2. **每个 hunk 的意图**：结合 commit message 解释"为什么改"，而非复述 diff
3. **外部依赖符号**：补丁引用但未定义的符号——目标树上必须存在，否则编译失败
4. **版本敏感点**：涉及的子系统 API 在目标版本是否有差异（库 API 用 Context7 查版本文档；GitHub 镜像仓库架构用 DeepWiki 问）

### 阶段 4：本地落点定位与冲突预判

在用户提供的本地目标树上：

- 用 Serena（find_references / 符号搜索）定位每个变更符号的本地定义与全部引用点；C/C++ 大项目需先确认 `compile_commands.json` 存在，否则 clangd 解析不全；**Serena 未安装时降级为 Grep/Glob 正则检索并标注置信度**。若运行环境配置了只读分析子代理（如插件版提供的 backport-analyst），优先派它按此降级路径工作
- 逐 hunk 对比补丁上下文行与本地实际代码，标记上下文漂移
- 用 Git MCP `git_log`（或 git log --grep）检查本地是否已含该修复、或有冲突提交
- 每个 hunk 给出预判：**✅ 可直接应用 / ⚠️ 上下文偏移需适配 / ❌ 结构差异需人工重写**

### 阶段 5：落地指导与报告

按目标生态给出集成路径（详细步骤见 `references/integration-workflows.md`）：

| 目标生态 | 集成路径 | 溯源标注（审计必需） |
|---|---|---|
| Buildroot | `package/<pkg>/000N-*.patch` 或 `BR2_GLOBAL_PATCH_DIR` | 补丁头加 `Upstream: <commit URL>` |
| Yocto/OE | `devtool modify` → 改源码 → `devtool update-recipe`；或 bbappend + `SRC_URI:append = " file://..."` | 补丁头 `Upstream-Status: Backport [<url>]` |
| AOSP | `git am` / `repo download <project> <change>/<patchset>` / `repo forall` 批量 | commit message 注明上游来源 |
| Debian | `quilt new/add/refresh`（QUILT_PATCHES=debian/patches）或 `gbp pq` | DEP-3 头（Origin / Applied-Upstream） |
| 内核 | `git am -3`；系列补丁 `b4 am <msgid>` | message 末尾 `commit <sha> upstream.` |

输出：按 `assets/backport-report-template.md` 生成分析报告；适配后 patch 落盘到用户指定目录。

**确认门**：报告交付即结束。不主动执行 apply / 构建 / 提交，除非用户明确说"直接改"。

## 工具配置

推荐 MCP 组合与安装命令见 `references/mcp-setup.md`。最小可用集只需：**shell（curl 取证）+ Git MCP（本地树状态）+ Serena（本地符号检索）**。无 MCP 的环境，全部取证可用 curl + jq + base64 兜底；可将 `assets/claude-md-snippet.md` 内容直接写入项目 CLAUDE.md 作为常驻 SOP。

## 反模式（禁止）

- ❌ 取证不完整就分析（截断 patch → 漏 hunk → 错误结论）
- ❌ 直接修改本地代码文件（除非用户明确授权）
- ❌ 漏掉依赖补丁链（只拿单个 commit，不管它的 Fixes 前序）
- ❌ 省略溯源标注（Yocto Upstream-Status / 内核 upstream 标注是审计硬性要求）
- ❌ 把 gitiles / Gerrit 的 base64 响应当明文解析
- ❌ 用 git log/diff 直接操作未 clone 的远程 URL（git 不支持，必须用 web 前端 URL）

## 示例

**示例 1：CVE 驱动的内核补丁 backport 到 Yocto 5.15 内核**

输入："把 CVE-2024-26600 的修复 backport 到我们 Yocto 的 linux 5.15 内核"

流程：security-tracker JSON 查 fixed version → cgit `/patch/?id=<sha>` 拉 patch → 阶段 3 分析出变更符号 → Serena 在本地 5.15 树查引用 → 发现某函数在 5.15 路径不同（⚠️ 适配）→ 产出适配 patch + 报告 → 指导 `devtool modify linux-yocto` 集成 → 用户人工 `devtool build` 验证。

**示例 2：AOSP Gerrit CL 移植到 android-12 本地分支**

输入："https://android-review.googlesource.com/c/platform/frameworks/base/+/1234567 移植到我的 android-12 分支"

流程：Gerrit REST 拿 patch（base64 -d）→ 分析 → 本地 repo 树 Serena 定位 → 报告中指出该 CL 依赖的另一个前序 CL → 用户确认后产出 patch → 指导 `repo download` 或 `git am` → 用户人工解冲突、`m` 构建。

**示例 3：Debian 已修复的 CVE 提取补丁给 Buildroot 用**

输入："buildroot 里的 openssl 版本有 CVE-2023-XXXX，Debian 已修，帮我提取"

流程：security-tracker 查 bookworm fixed version → snapshot.debian.org 拉相邻两版本 dsc → `debdiff` 提取修复 → 整理成 buildroot 风格 `package/openssl/000N-*.patch`（加 Upstream 头）→ 报告 + 验证命令 `make openssl-rebuild`。

## 资源目录

- `scripts/fetch_patch.sh` — 输入 commit 页面 URL，自动识别平台（cgit / sourceware gitweb / gitiles / GitHub / GitLab / Gerrit / lore）拉取 raw patch 落盘；HTTP 错误、空响应、HTML 错误页、非法 base64 一律报错并清理
- `references/fetch-recipes.md` — 各平台免克隆取证 URL 完整语法（含 lore/b4、base64 处理）
- `references/debian-toolchain.md` — Debian 专用：security-tracker / sources / codesearch / snapshot API + quilt / gbp pq
- `references/integration-workflows.md` — 四大生态落地工作流完整步骤与排错
- `references/mcp-setup.md` — 推荐 MCP 分层配置与安装命令
- `assets/backport-report-template.md` — 分析报告模板
- `assets/claude-md-snippet.md` — 可直接粘贴进项目 CLAUDE.md 的常驻 SOP
