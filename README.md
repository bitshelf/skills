# skills

## Skill

| Skill | 分类 | linux profile | android profile | allwinner profile | 用途 |
| --- | --- | :---: | :---: | :---: | --- |
| `android` | rockchip | | ✓ | | Rockchip Android BSP/AOSP 开发与排障：framework、HAL、产品配置、RKDocs、GKI/驱动及固件构建 |
| `aosp-docs` | devtools | | ✓ | | AOSP 架构/源码研究：版本判定、官方文档检索、证据引用 |
| `rk-build` | rockchip | ✓ | | | Rockchip Linux SDK 构建与烧写：kernel/bootloader/rootfs/固件打包 |
| `rk-debug` | rockchip | ✓ | | | Rockchip 目标机调试：串口日志、SSH、I2C/GPIO/regulator、Loader/MASKROM 恢复 |
| `aw-build` | allwinner | | | ✓ | Allwinner AIoT Linux SDK：`./build.sh config` 板级选择、分模块/全量编译、pack 打包、FEL/EFEX 烧写 |
| `schematic-terminal` | devtools | ✓ | ✓ | ✓ | 原理图读图：多模态视觉读 PNG/JPEG/WebP/PDF，按 OBSERVED/LABEL-LINKED/INFERRED/UNKNOWN 建连接台账后在终端重绘（自带 locate/render/lint/preview 脚本；不用 OCR 反推连接） |
| `semcode` | devtools | ✓ | ✓ | ✓ | Linux kernel / C-C++ 语义代码检索（semcode MCP，首次使用自动配置） |
| `upstream-backport` | devtools | ✓ | ✓ | ✓ | 从远程上游（kernel.org/googlesource/salsa/Gerrit/GitHub/lore）免克隆取证补丁，backport 分析、冲突预判与落地指导（Buildroot/Yocto/AOSP/Debian/内核） |
| `win-remote` | rockchip | ✓ | ✓ | ✓ | SSH 远程控制 Windows：固件烧写、ADB 测试、PowerShell 远程执行 |
| `writing-bash-scripts` | devtools | ✓ | ✓ | ✓ | Bash 脚本创建、修改、错误诊断与 ShellCheck 检查 |
| `rust-development` | devtools | | | | Rust 编写、重构与排障：Rust 官方/Google 风格、多人持续维护的 crate 选型、错误/日志、性能与测试 |

不同厂商 SDK 差异大，profile 互斥路由：Rockchip Linux SDK 项目装 `linux`，AOSP 系统项目装 `android`，
Allwinner SDK 项目装 `allwinner`（均含 schematic-terminal + upstream-backport + semcode + win-remote 通用件）。
skill 本身不与具体芯片/板卡型号绑定，板级个案放在仓库 `boards/` 目录。

`rust-development` 可按需单独安装（也包含在 `all` / `devtools` 选择中），不默认加入 SDK profile：

```bash
./install.sh --project /path/to/project --harness codex rust-development
```

## Android App 开发：直接使用上游

本仓库面向嵌入式开发（Rockchip/Allwinner SDK、AOSP 系统）。Jetpack/Compose/Play 生态的 **App 开发
skill 不在本仓库收录副本**，直接安装 Google 官方上游 [android/skills](https://github.com/android/skills)
（Apache-2.0，24 个：adaptive、camerax、r8-analyzer、styles、wear-compose-m3 等，按 domain 分
build-system / camera / jetpack-compose / play / … 目录）：

```bash
# 官方 Android CLI（其安装说明见上游 android-cli skill）
android skills add r8-analyzer --project=.   # 单个 skill 装进当前项目
android skills add --all                    # 全部 skill，装给所有检测到的 agent

# 或用 skills CLI（与本仓库方式一同一套路，交互勾选 / -s <name> -a <agent> 子集）：
npx skills@latest add android/skills
npx skills update                           # 跟随上游更新
```

注意区分：本仓库 `rockchip/android` skill 是 Rockchip AOSP 系统/SDK 开发、排障与构建，与上游 App 开发 skill 互补。

> `upstream-backport` 移植自 `~/backport/upstream-backport-plugin`（保留原始插件仓库作完整插件发行：
> 斜杠命令、backport-analyst 只读子代理、内核 checkpatch 钩子、随插件 MCP 等）；本仓库收录其
> agentskills 标准技能本体，已去除对插件壳的引用。

## 安装

### 方式一：npx skills（推荐）

```bash
npx skills@latest add bitshelf/skills
# 交互界面勾选想要的 skill × 目标 agent —— 按需只选 Rockchip 或只选 Allwinner，
# 不需要分支或拆仓库；Codex 生态的图形化 skill 管理器同样按仓库列出可选技能。

# 非交互子集安装（在目标项目目录内执行；-g 装用户级）：
npx skills@latest add bitshelf/skills -s rk-build -s rk-debug -s semcode -a codex
npx skills update            # 按 skills-lock.json 升级
```

### 方式二：各 agent 官方推荐位置

不借助第三方安装器，把 skill 目录放进对应 agent 的 skills 目录即可（Claude 插件市场、
`~/.agents/skills`（Codex / DeepSeek Deep Code）、`~/.zcode/skills`、`~/.pi/agent/skills` 等，路径表见下）。

### 方式三：install.sh（curl 直装 / 离线 / 项目 profile）

无需克隆仓库，直接从 GitHub 执行 install.sh（自动下载 tarball，copy 模式）：

```bash
curl -fsSL https://raw.githubusercontent.com/bitshelf/skills/main/install.sh | \
    bash -s -- --profile linux                                   # 用户级
cd /path/to/rk-linux-sdk
curl -fsSL https://raw.githubusercontent.com/bitshelf/skills/main/install.sh | \
    bash -s -- --project . --profile linux                       # 项目级
# 固定版本 / 使用 fork：加 --ref <tag|sha>、--repo owner/name
# 想先审再跑：curl -fsSL … -o install.sh && less install.sh && ./install.sh …
```

已克隆仓库（或离线）时等价于本地脚本：

```bash
cd /path/to/allwinner-sdk
/path/to/skills/install.sh --project . --profile allwinner       # aw-build upstream-backport semcode win-remote
cd /path/to/rk-linux-sdk
/path/to/skills/install.sh --project . --profile linux
# 按分类选择（如只要 Rockchip + devtools，不要 Allwinner）：
/path/to/skills/install.sh --category rockchip,devtools [--project .]
```

项目级默认 **copy** 模式（自包含、可共享），自动把各 harness 目录追加进 `.git/info/exclude`；
用户级默认 symlink（远程 curl 安装时为 copy，symlink 需本地克隆）。`--uninstall`、
`--harness <list>`、`--force` 可选。

### Harness 目录对照

| Harness | 用户级 | 项目级 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `<proj>/.claude/skills/` |
| Codex | `~/.agents/skills/` | `<proj>/.agents/skills/`，从启动目录沿父目录扫描至仓库根 |
| ZCode | `~/.zcode/skills/` | `<proj>/.zcode/skills/` + `<proj>/.agents/skills/` |
| DeepSeek Deep Code | `~/.agents/skills/` | `<proj>/.deepcode/skills/` |
| pi.dev | `~/.pi/agent/skills/` | `<proj>/.pi/agent/skills/` |

目录依据及验证范围见 [审核报告](docs/review-report.md)。Codex 采用当前官方文档的
`.agents/skills`；旧版安装器的 `.codex/skills` 不作为跨版本保证。DeepSeek 这里指支持
Agent Skills 的 **Deep Code 客户端**，仅配置 DeepSeek 模型 API 不会自动发现技能。
ZCode 官方明确支持用户级 `.zcode/skills`；项目级目录需在目标版本的 Settings → Skills
刷新并检查诊断，或通过 Import 选择 Project。本安装器保留项目 `.zcode/skills` 与
`.agents/skills` 两个目标，不能以目录存在代替客户端加载验证。

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
