# 免克隆取证速查（fetch recipes）

原则：所有 raw 内容用 `curl -sL -o` 落盘到 `/tmp/backport-<任务名>/` 再读取；预期超过 3000 字符的响应不要用 Fetch 类工具（截断会漏 hunk）。

```bash
mkdir -p /tmp/backport-<任务名>
```

---

## 0. CVE / bug → 上游 commit 定位（阶段 1 入口）

| 数据源 | 用法 | 说明 |
|---|---|---|
| kernel.org CVE 仓库（内核首选） | `https://git.kernel.org/pub/scm/linux/security/vulns.git/plain/cve/published/<year>/CVE-<id>.mbox` | 官方 CVE 公告，正文直接列出受影响与 fix commit SHA，无需二次反查 |
| OSV API | `curl -sL "https://api.osv.dev/v1/vulns/CVE-XXXX-YYYY" \| jq '.affected[] \| {package, ranges}'` | 跨生态（PyPI/Go/Debian…）拿 fixed version |
| NVD API 2.0 | `curl -sL "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-XXXX-YYYY" \| jq '.vulnerabilities[0].cve.references'` | 参考链接兜底，常滞后于上游 |
| Debian security-tracker | 见 `debian-toolchain.md` | 拿 fixed_version 后到上游仓库反查 |

注意：拿到 fixed version ≠ 拿到 commit。仍需到上游仓库反查（内核 stable 树 `/log/?h=<ver>&qt=grep&q=<关键词>`，或镜像仓库 `git log --grep`）；内核场景优先 vulns.git，一步到位。

---

## 1. cgit（kernel.org / Yocto / OE / Buildroot / sourceware）

URL 模式：`<repo-base>/<command>/<path>?<params>`

| 目的 | URL 形式 | 输出 |
|---|---|---|
| 单 commit raw patch | `<repo>/patch/?id=<sha>` | format-patch 格式，可直接 `git am` |
| 单 commit 页面 | `<repo>/commit/?id=<sha>` | HTML（message+stat+diff） |
| 两 ref 间 diff | `<repo>/diff/?id=<new>&id2=<old>` | HTML diff |
| 文件 raw | `<repo>/plain/<path>?h=<ref>` | 纯文本，ref 可用 tag/branch/sha |
| 目录列表 | `<repo>/tree/<path>?h=<ref>` | HTML |
| 提交日志 | `<repo>/log/?h=<ref>` | HTML；支持 `&qt=grep&q=<词>` 搜 message |

示例：

```bash
# 内核 stable 树某 commit 的 patch
curl -sL "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/patch/?id=<sha>" \
  -o /tmp/backport-x/fix.patch

# 目标版本某文件全文（用于与 patch 上下文对比）
curl -sL "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/pci/pcie/aspm.c?h=v5.15.167" \
  -o /tmp/backport-x/aspm-upstream.c
```

常用仓库根：

| 项目 | repo-base |
|---|---|
| 内核主线 | `https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git` |
| 内核 stable | `https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git` |
| 内核 stable-rc（queue） | `https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable-rc.git` |
| Yocto poky | `https://git.yoctoproject.org/poky`（部分实例为 `.../git/poky`，两种都试） |
| openembedded-core | `https://git.openembedded.org/openembedded-core` |
| Buildroot | `https://git.busybox.net/buildroot` |
| BusyBox | `https://git.busybox.net/busybox` |
| glibc / binutils / gdb | `https://sourceware.org/git/?p=glibc.git`（cgit query 形式，command 拼为 `;a=patch;id=<sha>`） |

注意：sourceware 的 cgit 用 query-string 风格（`?p=glibc.git;a=patch;h=<sha>`），不是 path 风格。

---

## 2. gitiles（*.googlesource.com — AOSP / Chromium / Gerrit 自带）

**所有 `format=TEXT` 响应都是 base64，必须 `base64 -d`。**

| 目的 | URL 形式 |
|---|---|
| 单 commit diff | `https://<host>/<project>/+/<sha>^!?format=TEXT` |
| 文件 raw | `https://<host>/<project>/+/<ref>/<path>?format=TEXT` |
| commit log | `https://<host>/<project>/+log/<ref>?format=JSON`（JSON 也带 `)]}'` 前缀） |
| ref 列表 | `https://<host>/<project>/+refs?format=TEXT` |

示例：

```bash
# AOSP frameworks/base 某 commit 的 diff
curl -sL "https://android.googlesource.com/platform/frameworks/base/+/<sha>^!?format=TEXT" \
  | base64 -d > /tmp/backport-x/aosp.patch

# 对比同一文件在两个 Android tag 上的版本（冲突预判关键步骤）
curl -sL "https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-12.1.0_r27/core/java/android/app/Activity.java?format=TEXT" \
  | base64 -d > /tmp/backport-x/Activity-a12.java
```

- 项目路径含层级：`platform/frameworks/base`、`kernel/common` 等
- `^!` 是 git range 语法，意为"只此 commit 本身的 diff"

---

## 3. Gerrit REST（android-review.googlesource.com 等）

```bash
# 拿 change 当前 patchset 的 patch（base64）
curl -sL "https://<gerrit-host>/changes/<change-id>/revisions/current/patch" | base64 -d > /tmp/backport-x/gerrit.patch

# change 详情（JSON 带 )]}' 前缀，去前 4 字节）
curl -sL "https://<gerrit-host>/changes/<change-id>/detail" | tail -c +5 | jq .

# 按 commit SHA 反查 change
curl -sL "https://<gerrit-host>/changes/?q=commit:<sha>" | tail -c +5 | jq .

# 拿某个文件的某 patchset 内容
curl -sL "https://<gerrit-host>/changes/<change-id>/revisions/current/files/<url-encoded-path>/content" | base64 -d
```

- `<change-id>` 可用数字号（URL 里的数字）或 `Change-Id`（I 开头哈希）
- 私有 Gerrit：Settings → HTTP Credentials 生成密码，`curl -u user:pass` 或写 `~/.netrc`

---

## 4. GitHub

```bash
# commit patch（公开仓库免 token）
curl -sL "https://github.com/<owner>/<repo>/commit/<sha>.patch" -o /tmp/backport-x/gh.patch

# compare diff
curl -sL "https://github.com/<owner>/<repo>/compare/<old>...<new>.diff" -o /tmp/backport-x/range.diff

# 文件 raw
curl -sL "https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>" -o /tmp/backport-x/file
```

有 token 时优先 GitHub MCP：`search_commits`、`get_commit`、`list_pull_requests`。

---

## 5. GitLab（salsa.debian.org / gitlab.freedesktop.org / gitlab.gnome.org）

```bash
# commit patch（公开仓库免 token）
curl -sL "https://<host>/<group>/<project>/-/commit/<sha>.patch" -o /tmp/backport-x/gl.patch

# 文件 raw
curl -sL "https://<host>/<group>/<project>/-/raw/<ref>/<path>" -o /tmp/backport-x/file

# REST v4（需 token）
curl -sL --header "PRIVATE-TOKEN: <token>" "https://<host>/api/v4/projects?search=<name>"   # 找项目 id
curl -sL --header "PRIVATE-TOKEN: <token>" "https://<host>/api/v4/projects/<id>/repository/commits/<sha>/diff"
```

salsa 路径惯例：`debian/<source-package>`。**源包名 ≠ 二进制包名**（如二进制 `libssl3` 的源包是 `openssl`）。源包名查询：`https://sources.debian.org/api/src/<pkg>/`。

---

## 6. 内核邮件列表（lore.kernel.org）

内核大量修复先在邮件列表，未进 git 树时只能从这里拿。

```bash
# 搜索（Web 界面）
https://lore.kernel.org/all/?q=<关键词>

# 单封邮件 raw mbox
curl -sL "https://lore.kernel.org/<list>/<msgid>/raw" -o /tmp/backport-x/mail.eml

# 整组系列补丁（推荐，自动整合 N/M 系列 + 去重 + 应用 replied 修正）
b4 am <msgid>            # 生成 *.mbx，git am 直接用
b4 am -o /tmp/backport-x/ <msgid>
```

`b4` 安装：`pip install b4` 或发行版包。这是内核 backport 的标准工具，比手工拼 mbox 可靠得多。

---

## 平台快速识别

| URL 特征 | 平台 |
|---|---|
| `git.kernel.org`、`git.yoctoproject.org`、`git.busybox.net`、`git.openembedded.org`、`sourceware.org/git` | cgit |
| `*.googlesource.com` 且含 `/+/` | gitiles |
| `*.googlesource.com` 且含 `/c/`（review 子域） | Gerrit |
| `github.com/.../commit/` | GitHub |
| `salsa.debian.org`、`gitlab.*`、`/-/commit/` | GitLab |
| `lore.kernel.org` | 邮件列表 |
