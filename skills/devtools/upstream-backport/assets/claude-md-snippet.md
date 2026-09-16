# CLAUDE.md 常驻片段

> 用法：把下面代码块内容粘贴到项目根目录的 `CLAUDE.md`（或 code agent 的等价配置文件）中，作为 backport 任务的常驻 SOP。配合 upstream-backport skill 使用更佳。

```markdown
# Backport SOP

## 铁律
1. 按请求范围工作：分析请求输出报告和 patch；实现请求完成已授权的应用、适配和验证，不重复索要已有授权
2. 上游取证不做完整 clone，按平台用下面的 URL 模板 curl 取证
3. 所有 patch 一律落盘 /tmp/backport-<任务名>/ 再读取（防截断漏 hunk）

## 取证 URL 模板
- cgit（kernel.org / git.yoctoproject.org / git.busybox.net / git.openembedded.org）：
  - patch:  <repo>/patch/?id=<sha>
  - 文件:   <repo>/plain/<path>?h=<ref>
  - diff:   <repo>/diff/?id=<new>&id2=<old>
- gitiles（*.googlesource.com，AOSP/Chromium）：
  - diff:   <repo>/+/<sha>^!?format=TEXT | base64 -d
  - 文件:   <repo>/+/<ref>/<path>?format=TEXT | base64 -d
- Gerrit：
  - patch:  curl -s <host>/changes/<id>/revisions/current/patch | base64 -d
  - JSON 响应带 )]}' 前缀，用 tail -c +5 去掉
- GitHub / GitLab：
  - <repo>/commit/<sha>.patch（GitLab 为 <repo>/-/commit/<sha>.patch），公开仓库免 token
- Debian：
  - CVE:    https://security-tracker.debian.org/tracker/data/json
  - 源码:   https://sources.debian.org/data/main/...
  - 历史版: snapshot.debian.org + debdiff
- 内核邮件列表系列补丁：b4 am <msgid>

## 输出要求
按 backport 报告结构输出：
上游信息 → 变更符号清单 → 本地落点（用 Serena find_references）→ 冲突预判（✅/⚠️/❌ 逐 hunk）
→ 适配 patch（落盘）→ 集成步骤 → 验证方案。
实现请求在报告后继续完成已授权的 apply、构建和冲突解决；仅分析请求则交付报告。

## 溯源标注（审计必需）
- Yocto: 补丁头 Upstream-Status: Backport [<url>]
- 内核: commit message 末尾 "commit <sha> upstream." + backport 差异说明
- Buildroot: 补丁头 Upstream: <url>
- Debian: DEP-3 Origin / Applied-Upstream
```
