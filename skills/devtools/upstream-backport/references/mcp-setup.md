# 推荐 MCP 配置（Claude Code / 其他 code agent）

分三层：**取证层**（远程上游）→ **理解层**（文档/架构）→ **本地层**（目标树）。无 MCP 的环境全部可用 shell（curl + jq + base64）兜底。

## 取证层

| MCP | 安装命令 | 用途 |
|---|---|---|
| Fetch | `claude mcp add fetch -- uvx mcp-server-fetch@2026.8.18` | 通用网页/JSON API 抓取（小内容；大 patch 仍用 curl） |
| GitHub 官方 | `claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer <PAT>"}}'` | GitHub 仓库 commit / PR / search / issue |
| GitLab（社区 gitlab-mcp） | `claude mcp add gitlab-debian -e GITLAB_API_URL=https://salsa.debian.org/api/v4 -e GITLAB_PERSONAL_ACCESS_TOKEN=<token> -- uvx gitlab-mcp` | salsa / freedesktop 等自建 GitLab |
| Gerrit（社区） | `claude mcp add gerrit -- npx -y @yangkangsky/mcp-gerrit` | AOSP review（社区版质量一般，REST 兜底） |
| grep.app | `claude mcp add grep -- uvx grep-mcp` | GitHub 全量仓库代码搜索（定位符号/修复） |

注意：
- **Fetch / Git 两个 MCP 上游已归档**（modelcontextprotocol/servers-archived，不再维护但可用）；安装命令已固定版本（`mcp-server-fetch@2026.8.18`、`mcp-server-git@2026.8.18`、`@upstash/context7-mcp@4.0.4`）防止安装漂移，升级时同步更新本文件；配套插件发行版（upstream-backport-plugin）的 `.mcp.json` 沿用同一版本号
- GitLab 官方 MCP（GitLab 18.3+，URL 形式 `https://<host>/api/v4/mcp`）需实例管理员开启 `mcp_server` feature flag；salsa 若未开启，退回社区 `gitlab-mcp`（如上）或直接 REST API
- cgit / gitiles / lore / Debian API **没有专用 MCP**，用 `scripts/fetch_patch.sh` 或 curl 模板

## 理解层

| MCP | 安装命令 | 用途 |
|---|---|---|
| Context7 | `claude mcp add context7 -- npx -y @upstash/context7-mcp` | 库 API 的**版本精确**文档（防 API 漂移：补丁用的 API 在目标版本是否存在/签名是否一致） |
| DeepWiki | `claude mcp add -s user -t http deepwiki https://mcp.deepwiki.com/mcp` | GitHub 公开仓库架构问答（限 GitHub，且 wiki 为 LLM 生成需回源码验证） |

## 本地层

| MCP | 安装命令 | 用途 |
|---|---|---|
| Git | `claude mcp add git --scope user -- uvx mcp-server-git@2026.8.18` | 本地目标树 status/log/diff/branch/show（12 工具，**无 blame**） |
| Serena | `uv tool install -p 3.13 serena-agent && serena init`（或传统方式 `uvx --from git+https://github.com/oraios/serena serena start-mcp-server`） | 本地符号级检索：find_references / 符号定义 / 跨文件引用 |

Serena 关键提醒：
- C/C++ 走 clangd，**大型代码库必须有 `compile_commands.json`**，否则符号解析不全（Yocto/内核构建目录可生成；内核用 `make compile_commands.json` 或 bear）
- 内核级巨型树首次索引慢，建议用 `.serena/project.yml` 排除无关目录

## 最小可用集

只装三个即可跑通全流程：**shell（curl）+ Git MCP + Serena**。其余按摩擦点逐步加——工具越多上下文越重，4~6 个为宜。
