# Debian 专用工具链

Debian 没有现成 MCP，但官方 JSON/API 完备，全部可用 curl 完成。Debian 的价值在于：**安全团队已经把上游修复移植到各发行版版本**——很多 backport 不用自己做，去 Debian 拿现成的。

## 四个官方数据源

### 1. Security Tracker（CVE → 修复版本）

```bash
# 全量 JSON（约几十 MB，落盘后 jq 查询）
curl -sL "https://security-tracker.debian.org/tracker/data/json" -o /tmp/backport-x/debian-sec.json
jq '."<source-package>"."CVE-2024-XXXX"' /tmp/backport-x/debian-sec.json
```

输出含各 release（bullseye/bookworm/trixie）的 `status`（fixed/open/undetermined）与 `fixed_version`。拿到 fixed_version 后：
→ 到 snapshot.debian.org 拉相邻两版本，`debdiff` 提取修复补丁（见下）。

### 2. sources.debian.org（当前发行版源码浏览）

```bash
# 源包版本列表（API）
curl -sL "https://sources.debian.org/api/src/<pkg>/" | jq .

# 文件 raw（路径规则：/data/<pool前缀>/<p>/<pkg>/<version>/<path>）
curl -sL "https://sources.debian.org/data/main/o/openssl/3.0.13-1%2Bdeb12u1/debian/patches/series"
```

**看 `debian/patches/` 目录 + `series` 文件**：Debian maintainer 的 quilt 补丁系列就在里面，很多就是上游修复的现成 backport，且有 DEP-3 头标注来源。

### 3. codesearch.debian.net（全量源码正则搜索）

130GB+ 全部 Debian 源码的正则搜索。用途：确认"某符号在哪些包里出现"、"Debian 是否已给某包打过相关补丁"。

```bash
# 需先申请 API key：https://codesearch.debian.net/apikeys/
curl -sL "https://codesearch.debian.net/api/v1/search?q=<regex>&per_package=1" \
  -H "X-Api-Key: <key>" | jq .
```

Web 界面（免 key 低频用）：`https://codesearch.debian.net/search?q=<regex>`

### 4. snapshot.debian.org（历史版本时光机）

```bash
# 包的所有历史版本
curl -sL "https://snapshot.debian.org/package/<pkg>/"

# JSON API
curl -sL "https://snapshot.debian.org/mr/package/<pkg>/" | jq .

# 命令行下载历史 dsc 三件套（devscripts 包）
debsnap -d /tmp/backport-x <pkg> <version>
```

**debdiff 提取修复**（CVE backport 到非 Debian 生态时的核心手法）：

```bash
debdiff old.dsc new.dsc > /tmp/backport-x/debian-fix.diff
# 或两个已解压源码树之间只取上游部分（排除 debian/ 目录）
diff -ruN --exclude=debian old-tree/ new-tree/ > /tmp/backport-x/upstream-part.diff
```

## 获取源码包

```bash
apt source <pkg>          # 需要 deb-src 源
dget -u https://...dsc    # 从 snapshot / archive 直拉
dpkg-source -x <pkg>.dsc  # 解压（自动 quilt push -a）
```

## 本地补丁管理

### quilt（Debian 标准，dpkg-source 格式 3.0 的底层）

```bash
export QUILT_PATCHES=debian/patches
quilt push -a                      # 应用已有系列
quilt new 0001-fix-cve-xxxx.patch
quilt add path/to/file             # 关键：改文件前必须 add，否则 refresh 抓不到
# ... 手工修改 ...
quilt refresh                      # 生成/更新补丁
quilt header -e                    # 补 DEP-3 头
```

DEP-3 补丁头（审计要求）：

```
Description: Fix CVE-2024-XXXX buffer overflow in xxx
Origin: upstream, https://git.kernel.org/.../patch/?id=<sha>
Applied-Upstream: <version 或 commit URL>
Forwarded: not-needed
```

### gbp pq（git-buildpackage，把补丁系列当 git 分支操作）

```bash
gbp pq import        # debian/patches → patch-queue/<branch> 分支
git am /tmp/backport-x/fix.patch   # 在 patch-queue 分支上像普通 git 一样操作
gbp pq export        # 回写 debian/patches
```

## 典型场景：把 Debian 的 CVE 修复搬到 Buildroot/Yocto

1. security-tracker 拿 fixed_version（如 `3.0.13-1+deb12u1`）
2. snapshot 拉 `3.0.13-1` 和 `3.0.13-1+deb12u1` 两版 dsc
3. `debdiff` → 得到 Debian 安全团队的修复补丁
4. 去掉 debian/ 目录相关 hunk，只留上游源码部分
5. 若 Debian 补丁是 quilt 系列中的一支，直接取 `debian/patches/xxxx.patch` 单文件更干净
6. 按目标生态规范改名（000N-描述.patch）、补 Upstream 头
7. 注意 Debian 基线版本与 Buildroot/Yocto 中包的版本可能不同 → 走阶段 4 冲突预判
