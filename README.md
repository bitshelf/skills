# skills

## Skill

| Skill | 分类 | linux profile | android profile | allwinner profile | 用途 |
| --- | --- | :---: | :---: | :---: | --- |
| `android` | rockchip | | ✓ | | Rockchip Android SDK 构建：framework 模块、kernel、U-Boot、update.img |
| `aosp-docs` | devtools | | ✓ | | AOSP 架构/源码研究：版本判定、官方文档检索、证据引用 |
| `rk-build` | rockchip | ✓ | | | Rockchip Linux SDK 构建与烧写：kernel/bootloader/rootfs/固件打包 |
| `rk-debug` | rockchip | ✓ | | | Rockchip 目标机调试：串口日志、SSH、I2C/GPIO/regulator、Loader/MASKROM 恢复 |
| `aw-build` | allwinner | | | ✓ | Allwinner AIoT Linux SDK：`./build.sh config` 板级选择、分模块/全量编译、pack 打包、FEL/EFEX 烧写 |
| `schematic-terminal` | devtools | ✓ | ✓ | ✓ | 原理图读图：多模态视觉读 PNG/JPEG/WebP/PDF，按 OBSERVED/LABEL-LINKED/INFERRED/UNKNOWN 建连接台账后在终端重绘（自带 locate/render/lint/preview 脚本；不用 OCR 反推连接） |
| `semcode` | devtools | ✓ | ✓ | ✓ | Linux kernel / C-C++ 语义代码检索（semcode MCP，首次使用自动配置；SDK 内核树位于子目录时自动写 `SEMCODE_GIT_REPO`） |
| `upstream-backport` | devtools | ✓ | ✓ | ✓ | 从远程上游（kernel.org/googlesource/salsa/Gerrit/GitHub/lore）免克隆取证补丁，backport 分析、冲突预判与落地指导（Buildroot/Yocto/AOSP/Debian/内核） |
| `win-remote` | rockchip | ✓ | ✓ | ✓ | SSH 远程控制 Windows：固件烧写、ADB 测试、PowerShell 远程执行 |

不同厂商 SDK 差异大，profile 互斥路由：Rockchip Linux 项目装 `linux`，Android 项目装 `android`，
Allwinner 项目装 `allwinner`（均含 schematic-terminal + upstream-backport + semcode + win-remote 通用件）。skill 本身不与
具体芯片/板卡型号绑定，板级个案放在仓库 `boards/` 目录。

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
`~/.codex/skills`、`~/.agents/skills`（ZCode / DeepSeek Deep Code）、`~/.pi/agent/skills` 等，路径表见下）。

### 方式三：本仓库 install.sh（离线 / 项目 profile）

```bash
cd /path/to/allwinner-sdk
/home/loh/res/skills/install.sh --project . --profile allwinner   # aw-build upstream-backport semcode win-remote
cd /path/to/rk-linux-sdk
/home/loh/res/skills/install.sh --project . --profile linux
# 按分类选择（如只要 Rockchip + devtools，不要 Allwinner）：
/home/loh/res/skills/install.sh --category rockchip,devtools [--project .]
```

项目级默认 **copy** 模式（自包含、可共享），自动把各 harness 目录追加进 `.git/info/exclude`；
用户级默认 symlink。`--uninstall`、`--harness <list>`、`--force` 可选。

### Harness 目录对照

| Harness | 用户级 | 项目级 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `<proj>/.claude/skills/` |
| Codex | `~/.codex/skills/` | `<proj>/.agents/skills/`（`.codex/skills/` 亦被扫描） |
| ZCode | `~/.zcode/skills/` | `<proj>/.zcode/skills/` + `<proj>/.agents/skills/` |
| DeepSeek Deep Code | `~/.agents/skills/` | `<proj>/.deepcode/skills/` |
| pi.dev | `~/.pi/agent/skills/` | `<proj>/.pi/agent/skills/` |

> 项目级 Codex 路径按 `npx skills` CLI 实测校正（`skillsDir: ".agents/skills"`，用户级仍为
> `~/.codex/skills/`）：仓库级 skill 在 `.agents/skills` 下被发现，`.codex/skills` 仅为兼容扫描项。
> `install.sh` 的 `codex` 项目级目录与上表一致；因 zcode 也落到 `.agents/skills`，同一 skill
> 不会重复安装到同一目录。
