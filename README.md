# skills

## Skill

| Skill | 分类 | Linux 分组 | Android 分组 | Allwinner 分组 | 用途 |
| --- | --- | :---: | :---: | :---: | --- |
| `android` | rockchip | | ✓ | | Rockchip Android BSP/AOSP 开发与排障：framework、HAL、产品配置、RKDocs、GKI/驱动及固件构建 |
| `aosp-docs` | devtools | | ✓ | | AOSP 架构/源码研究：版本判定、官方文档检索、证据引用 |
| `bpp` | devtools | ✓ | ✓ | ✓ | 社区最佳实践落地：kernel/U-Boot、Debian/Ubuntu、Yocto、OpenHarmony/openEuler、Android/AOSP 的一手资料、维护者线索、工业方案、决策澄清、实现与验证 |
| `rk-build` | rockchip | ✓ | | | Rockchip Linux SDK 构建与烧写：kernel/bootloader/rootfs/固件打包 |
| `rk-debug` | rockchip | ✓ | | | Rockchip 目标机调试：串口日志、SSH、I2C/GPIO/regulator、Loader/MASKROM 恢复 |
| `aw-build` | allwinner | | | ✓ | Allwinner AIoT Linux SDK：`./build.sh config` 板级选择、分模块/全量编译、pack 打包、FEL/EFEX 烧写 |
| `schematic-terminal` | devtools | ✓ | ✓ | ✓ | 原理图读图：多模态视觉读 PNG/JPEG/WebP/PDF，按 OBSERVED/LABEL-LINKED/INFERRED/UNKNOWN 建连接台账后在终端重绘（自带 locate/render/lint/preview 脚本；不用 OCR 反推连接） |
| `semcode` | devtools | ✓ | ✓ | ✓ | Linux kernel / C-C++ 语义代码检索（semcode MCP，首次使用自动配置） |
| `upstream-backport` | devtools | ✓ | ✓ | ✓ | 从远程上游（kernel.org/googlesource/salsa/Gerrit/GitHub/lore）免克隆取证补丁，backport 分析、冲突预判与落地指导（Buildroot/Yocto/AOSP/Debian/内核） |
| `win-remote` | rockchip | ✓ | ✓ | ✓ | SSH 远程控制 Windows：固件烧写、ADB 测试、PowerShell 远程执行 |
| `writing-bash-scripts` | devtools | ✓ | ✓ | ✓ | Bash 脚本创建、修改、错误诊断与 ShellCheck 检查 |
| `rust-development` | devtools | | | | Rust 编写、重构与排障：Rust 官方/Google 风格、多人持续维护的 crate 选型、错误/日志、性能与测试 |

不同厂商 SDK 差异大，按项目选择上表分组：Rockchip Linux、AOSP 系统或 Allwinner。
分组是本仓库的推荐技能组合，安装时用 `--skill` 指定名称（完整命令见下文），不是 skills CLI 的 profile 参数。
skill 本身不与具体芯片/板卡型号绑定，板级个案放在仓库 `boards/` 目录。

`rust-development` 可按需单独安装，不默认加入 SDK 分组：

```bash
cd /path/to/project
npx skills add bitshelf/skills --skill rust-development --agent codex
```

`bpp` 面向“根据社区最佳实践，把 xxx 调好/做稳定”，也可单独安装：

```bash
# 用户级 Codex
npx skills add bitshelf/skills --skill bpp --agent codex -g
# 当前项目的 Claude Code
npx skills add bitshelf/skills --skill bpp --agent claude-code
```

例如“按社区最佳实践修复网关断网，保持当前发行版，先复现再验证”。支持斜杠技能调用的客户端
可用 `/bpp <任务>`；其他客户端按下文调用表选择 `bpp`（如 Codex 的 `$bpp <任务>`）。
技能正文也识别 `/bpp` 的任务意图，但不自行注册跨客户端通用命令。它按目标版本检索官方资料、
维护者讨论和工业方案，只追问关键取舍，并推进到修改、回归和回退证据；无设备时明确标注待测。

## Android App 开发：直接使用上游

本仓库面向嵌入式开发（Rockchip/Allwinner SDK、AOSP 系统）。Jetpack/Compose/Play 生态的 **App 开发
skill 不在本仓库收录副本**，直接安装 Google 官方上游 [android/skills](https://github.com/android/skills)
（Apache-2.0，24 个：adaptive、camerax、r8-analyzer、styles、wear-compose-m3 等，按 domain 分
build-system / camera / jetpack-compose / play / … 目录）：

```bash
npx skills add android/skills
npx skills update
```

注意区分：本仓库 `rockchip/android` skill 是 Rockchip AOSP 系统/SDK 开发、排障与构建，与上游 App 开发 skill 互补。

> `upstream-backport` 移植自 `~/backport/upstream-backport-plugin`（保留原始插件仓库作完整插件发行：
> 斜杠命令、backport-analyst 只读子代理、内核 checkpatch 钩子、随插件 MCP 等）；本仓库收录其
> agentskills 标准技能本体，已去除对插件壳的引用。

## 安装

统一使用上游 [skills CLI](https://github.com/vercel-labs/skills)。需要 Node.js 和 npm（包含 npx），
版本要求见上游文档。默认安装到当前项目；加 `-g` 安装到用户级。

```bash
# 在目标项目目录执行，交互选择技能和 agent
npx skills add bitshelf/skills

# 仅查看仓库中的技能
npx skills add bitshelf/skills --list

# 指定技能和 agent；-y 跳过交互确认
npx skills add bitshelf/skills --skill rk-build rk-debug semcode --agent codex -y

# 用户级安装；Claude Code 的 agent 名称为 claude-code
npx skills add bitshelf/skills --skill bpp --agent claude-code -g
```

### 按 SDK 分组安装

在目标 SDK 目录运行相应命令；`--agent codex` 可替换为 `--agent claude-code`，
也可省略以交互选择。用户级安装加 `-g`。

```bash
# Rockchip Linux
npx skills add bitshelf/skills --agent codex --skill \
  rk-build rk-debug bpp schematic-terminal upstream-backport semcode win-remote writing-bash-scripts

# Rockchip Android / AOSP 系统
npx skills add bitshelf/skills --agent codex --skill \
  android aosp-docs bpp schematic-terminal upstream-backport semcode win-remote writing-bash-scripts

# Allwinner Linux
npx skills add bitshelf/skills --agent codex --skill \
  aw-build bpp schematic-terminal upstream-backport semcode win-remote writing-bash-scripts
```

### 本地源码与安装管理

```bash
# 从本地 checkout 安装，在目标项目目录执行
npx skills add /path/to/skills --skill bpp --agent codex

# 查看、更新和卸载项目技能；用户级操作加 -g
npx skills list
npx skills update
npx skills remove bpp
```

### 客户端技能发现目录

| Harness | 用户级 | 项目级 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `<proj>/.claude/skills/` |
| Codex | `~/.agents/skills/` | `<proj>/.agents/skills/`，从启动目录沿父目录扫描至仓库根 |
| ZCode | `~/.zcode/skills/` | 在目标版本的 Settings → Skills 确认，或通过 Import 选择 Project |
| DeepSeek Deep Code | `~/.agents/skills/` | `<proj>/.deepcode/skills/` |
| pi.dev | `~/.pi/agent/skills/` | `<proj>/.pi/agent/skills/` |

目录依据及验证范围见 [审核报告](docs/review-report.md)。Codex 采用当前官方文档的
`.agents/skills`；旧版安装器的 `.codex/skills` 不作为跨版本保证。DeepSeek 这里指支持
Agent Skills 的 **Deep Code 客户端**，仅配置 DeepSeek 模型 API 不会自动发现技能。
ZCode 的旧项目安装可能在 `.zcode/skills` 和 `.agents/skills` 都留有副本或链接。

## 调用与验证

所有技能的相对路径以含 `SKILL.md` 的技能目录为基准，不能从 SDK 工作目录直接猜测
`scripts/` 的位置。安装器将分类目录中的每个技能展平到 `<skills-dir>/<name>/SKILL.md`。
直接把整个 `skills/<category>/` 当成 ZCode 插件的 skills 目录会导致技能不被发现。

| 客户端 | 显式调用与检查 |
| --- | --- |
| Codex | 输入 `$rk-build`，或 `/skills` 选择；检查是否被配置禁用，缺失时重启 |
| Claude Code | 输入 `/rk-build`；用 `/skills` 检查列表，新增目录时 `/reload-skills` |
| pi.dev | 输入 `/skill:rk-build`；修改后 `/reload`，检查启动诊断 |
| Deep Code | 输入 `/` 打开 skills 菜单，核对技能名称；命令形式以安装版本为准 |
| ZCode | Settings → Skills → Refresh，确认启用，再输入 `$rk-build` |

自动选择依赖 `description` 和当前模型，不能保证每次必触发。建议用正例「编译 Rockchip
Linux SDK 内核」检查 `rk-build`，在 Rockchip Android SDK 根目录或 HAL/framework 子目录用「修 camera provider」「加 sepolicy」「预装 APK」「更新 GKI 驱动 ko」检查 `android`（不必包含“编译”），
用「配置 Allwinner AIoT SDK 并 pack」检查 `aw-build`。通用 Bash 或 Windows 操作可能同时
加载辅助技能。ZCode 只注入描述的前 250 字符，应把任务与触发条件放在描述开头。

技能可被发现和 MCP 可连接是两个独立条件。`semcode` 的配置脚本保留已有服务器和权限；
Claude Code 使用项目 `.mcp.json`，Codex 使用 TOML，ZCode 使用原生配置或 `.agents/mcp.json`
回退。pi.dev 的 MCP 需要相应扩展，不能假定它会读取 `.mcp.json`。
