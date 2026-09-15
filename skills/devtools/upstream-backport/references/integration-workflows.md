# 四大生态落地工作流

## Buildroot

### 补丁放置约定

- `package/<pkg>/000N-<描述>.patch`（按文件名字典序应用，统一 `-p1`）
- 或全局补丁目录：`BR2_GLOBAL_PATCH_DIR="<dir>"`，目录结构与 `package/` 平行
- 应用时机：extract 之后、configure 之前
- **补丁头惯例**：首行注释 `Upstream: <commit URL>`（buildroot 审查要求溯源）

### 工作流

```bash
# 1. 解压目标包源码
make <pkg>-extract          # 到 output/build/<pkg>-<version>/

# 2. 干跑测试上游 patch
cd output/build/<pkg>-<version>
patch -p1 --dry-run < /tmp/backport-x/upstream.patch

# 3. 有 fuzz/冲突 → 手工改 → 重新生成干净补丁
#    方法：保留原始副本 diff -u，或进源码目录用 quilt（QUILT_PATCHES=. 自建系列）
quilt new 0001-fix.patch && quilt add <files>
# 修改 → quilt refresh

# 4. 放入 package 目录
cp 0001-fix.patch ../../package/<pkg>/0001-<描述>.patch

# 5. 验证
make <pkg>-rebuild          # 触发 reextract + repatch + rebuild
```

注意：
- buildroot 包补丁**只支持 `-p1`**；上游 patch 若是 `-p0` 或路径前缀不同（如 `a/`、`b/` 缺失）需先调整
- 若修复已在上游新版本，优先考虑 **bump 包版本** 而非堆补丁（补丁越少维护成本越低）

## Yocto / OpenEmbedded

### 首选：devtool（标准流程，自动生成 bbappend）

```bash
devtool modify <recipe>                    # 源码拉到 workspace/sources/<recipe>（git 仓库）
cd workspace/sources/<recipe>
git am /tmp/backport-x/upstream.patch      # 冲突则人工解 → git am --continue
devtool build <recipe>                     # 编译验证
devtool update-recipe <recipe>             # 生成 bbappend + patch 到目标 layer
devtool finish <recipe> <layer>            # 收尾，清 workspace
```

### 手工路径（不用 devtool）

```
meta-<your-layer>/recipes-*/<pkg>/<pkg>_%.bbappend
meta-<your-layer>/recipes-*/<pkg>/files/0001-fix.patch
```

bbappend 内容：

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://0001-fix.patch"
```

### Upstream-Status（OE 审计强制，补丁头必写）

```
Upstream-Status: Backport [https://git.kernel.org/.../commit/?id=<sha>]
```

合法值：`Pending` / `Submitted [链接]` / `Accepted` / `Backport [链接]` / `Inappropriate [原因]` / `Denied`。backport 场景固定用 `Backport`。

### 排错

- `do_patch` 失败：看 `tmp/work/.../temp/log.do_patch`（底层是 quilt push，会显示 fuzz/拒绝的 hunk）
- 找 recipe 在哪个 layer：`bitbake-layers show-recipes <name>`；远程查 layerindex API：`https://layers.openembedded.org/layerindex/api/recipes/?q=<name>`

## AOSP

### repo 多仓环境

```bash
# 单项目应用
cd <project>
git am /tmp/backport-x/aosp.patch

# 从 Gerrit 直接 cherry-pick（等价于网页 Cherry pick 按钮）
repo download platform/frameworks/base 1234567/3    # <change>/<patchset>

# 批量（同一修复涉及多项目，按项目名分发 patch）
repo forall -p -c 'git am /tmp/backport-x/${REPO_PROJECT}.patch' || true

# 构建验证
source build/envsetup.sh && lunch <target> && m -j$(nproc)
```

### 注意

- `repo download` 就是 Gerrit cherry-pick 的封装，需要 Gerrit 可达且已配认证
- manifest 锁定的 tag（如 `android-12.1.0_r27`）与上游 `main` 差异可能很大——**分析阶段务必用 gitiles 各拉一份目标 tag 和上游版本的同文件对比**（见 fetch-recipes.md 第 2 节）
- AOSP 内核（`kernel/`、`vendor/*kernel*`）按内核流程走 `git am -3`
- 若 Gerrit CL 依赖其他 CL（`/changes/<id>/revisions/current/related` 端点或 change 的 topic），按 patchset 顺序逐个 repo download

## Linux 内核

```bash
git am -3 /tmp/backport-x/fix.patch     # -3：三方合并，blob 可匹配时自动解冲突
# 冲突时
git am --show-current-patch=diff        # 查看当前补丁
# 手工修改 → git add <files> → git am --continue
```

### stable 风格溯源（commit message 约定）

message 末尾加（stable 规则硬性要求）：

```
commit <upstream-sha> upstream.

[backport 调整说明：与上游的差异点，例如路径变化、上下文适配]
```

### 辅助

- 风格检查：`./scripts/checkpatch.pl --strict < patch`
- 查补丁是否已在 stable queue：cgit stable-rc 树 `/log/?h=queue/<ver>&qt=grep&q=<关键词>`，或 lore 搜 stable 子系统邮件
- 系列补丁（N/M）：`b4 am <msgid>` 整组拉取，保持系列顺序
- 若上游修复跨子系统（如 PCIe + PM），确认目标内核是否缺少其中某个子系统的中间提交——这是内核 backport 最常见的坑

## 通用验证矩阵（交付报告时必须给出）

| 层级 | 验证项 |
|---|---|
| 应用层 | patch --dry-run / git am --3way 无拒绝 hunk |
| 构建层 | 目标包/内核/镜像编译通过 |
| 静态层 | checkpatch（内核）、oelint-adv（Yocto）、lintian（Debian） |
| 功能层 | 修复对应的功能/安全测试（如 PoC 复现后确认已修复） |
| 回归层 | 受影响子系统的既有测试（如内核 kselftest 相关项） |
