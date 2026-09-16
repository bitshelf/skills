#!/usr/bin/env bash
# fetch_patch.sh — Fetch a raw patch from a commit/change URL without cloning
# Supports: cgit / sourceware gitweb / gitiles / GitHub / GitLab / Gerrit / lore
# Usage:
#   fetch_patch.sh <url> [outdir]
#   fetch_patch.sh --lore <list> <msgid> [outdir]
# On HTTP, empty, HTML, or base64 errors, remove partial output and fail
set -euo pipefail

DEFAULT_OUTDIR="/tmp/backport-fetch"

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
    cat >&2 <<'EOF'
用法:
  fetch_patch.sh <commit/change 页面 URL> [outdir]
  fetch_patch.sh --lore <邮件列表> <msgid> [outdir]
支持平台:
  cgit    git.kernel.org / git.yoctoproject.org / git.openembedded.org / git.busybox.net（/commit/?id=<sha>）
  gitweb  sourceware.org/git/?p=<repo>;a=commit;h=<sha>
  gitiles *.googlesource.com（/+/<sha 或多级 ref，如 refs/tags/xxx>）
  Gerrit  <host>/c/<project>/+/<change 号>（含 android-review 等任意 Gerrit）
  GitHub  github.com/<owner>/<repo>/commit/<sha>
  GitLab  含 /-/commit/<sha>（salsa.debian.org 等；私有仓库设 GITLAB_TOKEN）
  lore    lore.kernel.org/<list>/<msgid>/（或 --lore 形式）
outdir 默认 /tmp/backport-fetch
EOF
}

# Fail on HTTP errors, retry transient failures, and reject HTML responses
sniff_html() {  # Return zero for HTML-like content
    local chunk
    chunk="$(LC_ALL=C dd if="$1" bs=1024 count=1 2>/dev/null || true)"
    case "$chunk" in
        *"<!DOCTYPE"*|*"<!doctype"*|*"<html"*|*"<HTML"*) return 0 ;;
    esac
    return 1
}

fetch_raw() {  # $1=output file $2=URL remaining args: curl options; never include tokens in errors
    local out="$1" target="$2"; shift 2
    if ! curl -fsSL --retry 2 --retry-delay 2 --connect-timeout 15 "$@" "$target" -o "$out"; then
        rm -f "$out"; die "取证失败（HTTP 错误或网络不可达）: $target"
    fi
    if [ ! -s "$out" ]; then
        rm -f "$out"; die "取证失败（响应为空）: $target"
    fi
    if sniff_html "$out"; then
        rm -f "$out"; die "响应是 HTML 而非 patch（URL 或平台判断可能有误）: $target"
    fi
}

fetch_b64() {  # Like fetch_raw, but decode base64 from gitiles or Gerrit
    local out="$1" target="$2"; shift 2
    local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/fetch_b64.XXXXXX")"
    if ! curl -fsSL --retry 2 --retry-delay 2 --connect-timeout 15 "$@" "$target" -o "$tmp"; then
        rm -f "$tmp"; die "取证失败（HTTP 错误或网络不可达）: $target"
    fi
    if ! base64 -d "$tmp" > "$out" 2>/dev/null || [ ! -s "$out" ]; then
        rm -f "$tmp" "$out"; die "响应不是有效 base64（URL 大概率错误）: $target"
    fi
    rm -f "$tmp"
    if sniff_html "$out"; then
        rm -f "$out"; die "解码后内容是 HTML 而非 patch（URL 或平台判断可能有误）: $target"
    fi
}

safe_name() { echo "$1" | sed 's/[^a-zA-Z0-9]/_/g'; }

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

# ---------- --lore explicit mode ----------
if [ "${1:-}" = "--lore" ]; then
    list="${2:-}"; msgid="${3:-}"
    { [ -n "$list" ] && [ -n "$msgid" ]; } || { usage; exit 1; }
    OUTDIR="${4:-$DEFAULT_OUTDIR}"
    mkdir -p "$OUTDIR"
    out="$OUTDIR/lore-$(safe_name "$msgid").eml"
    fetch_raw "$out" "https://lore.kernel.org/${list}/${msgid}/raw"
    echo "$out"
    echo "提示: 系列补丁建议用 b4 am ${msgid} 整组拉取" >&2
    exit 0
fi

url="${1:-}"
[ -n "$url" ] || { usage; exit 1; }
OUTDIR="${2:-$DEFAULT_OUTDIR}"
mkdir -p "$OUTDIR"

# ---------- lore URL（https://lore.kernel.org/<list>/<msgid>[/raw]） ----------
if echo "$url" | grep -q 'lore\.kernel\.org'; then
    rest="${url#*lore.kernel.org/}"
    rest="${rest%%\?*}"; rest="${rest%/}"
    list="${rest%%/*}"; msgid="${rest#*/}"
    msgid="${msgid%/raw}"
    { [ -n "$list" ] && [ "$list" != "$rest" ] && [ -n "$msgid" ]; } \
        || die "lore URL 需含 <list>/<msgid> 两级路径: $url（或用 --lore <list> <msgid>）"
    out="$OUTDIR/lore-$(safe_name "$msgid").eml"
    fetch_raw "$out" "https://lore.kernel.org/${list}/${msgid}/raw"
    echo "$out"
    echo "提示: 系列补丁建议用 b4 am ${msgid} 整组拉取" >&2
    exit 0
fi

# ---------- cgit: /commit/?id= or /patch/?id= ----------
if echo "$url" | grep -qE 'git\.kernel\.org|git\.yoctoproject\.org|git\.busybox\.net|git\.openembedded\.org'; then
    if echo "$url" | grep -q '/commit/?id='; then
        patch_url="${url/\/commit\/?id=//patch/?id=}"
    elif echo "$url" | grep -q '/patch/?id='; then
        patch_url="$url"
    else
        die "cgit URL 无法识别（需要 /commit/?id= 或 /patch/?id= 形式）: $url"
    fi
    sha=$(echo "$patch_url" | sed -n 's/.*id=\([a-f0-9]*\).*/\1/p' | cut -c1-12)
    out="$OUTDIR/cgit-${sha:-unknown}.patch"
    fetch_raw "$out" "$patch_url"
    echo "$out"
    exit 0
fi

# ---------- sourceware gitweb: ?p=<repo>;a=commit;h=<sha>query or path form ----------
if echo "$url" | grep -q 'sourceware\.org'; then
    if echo "$url" | grep -qE '[;?]a=commit(diff)?([;#]|$)'; then   # Convert a=commit or a=commitdiff to a=patch
        patch_url=$(echo "$url" | sed -E 's/([;?])a=commit(diff)?([;#]|$)/\1a=patch\3/')
    elif echo "$url" | grep -qE '[;?]a=patch([;#]|$)'; then
        patch_url="$url"
    elif echo "$url" | grep -q '/commit/?id='; then
        patch_url="${url/\/commit\/?id=//patch/?id=}"
    else
        die "sourceware URL 无法识别（支持 ?p=<repo>;a=commit;h=<sha> 或 /commit/?id= 形式）: $url"
    fi
    sha=$(echo "$patch_url" | sed -n 's/.*[;?]h=\([a-f0-9]*\).*/\1/p')
    [ -n "$sha" ] || sha=$(echo "$patch_url" | sed -n 's/.*id=\([a-f0-9]*\).*/\1/p')
    out="$OUTDIR/sourceware-${sha:-unknown}.patch"
    fetch_raw "$out" "$patch_url"
    echo "$out"
    exit 0
fi

# ---------- Gerrit: review host /c/<proj>/+/<num> ----------
if echo "$url" | grep -qE 'review.*googlesource\.com|/c/.*/\+/[0-9]+'; then
    origin=$(echo "$url" | sed -n 's|^\(https\?://[^/]*\)/.*|\1|p')   # Include scheme for the URL prefix
    num=$(echo "$url" | sed -n 's|.*/+/\([0-9]*\).*|\1|p')
    [ -n "$origin" ] || die "Gerrit URL 需要 http(s):// 开头: $url"
    [ -n "$num" ] || die "无法从 Gerrit URL 解析 change 号: $url"
    out="$OUTDIR/gerrit-${num}.patch"
    fetch_b64 "$out" "${origin}/changes/${num}/revisions/current/patch"
    echo "$out"
    exit 0
fi

# ---------- gitiles: googlesource /+/(SHA or multi-component refs/tags ref) ----------
if echo "$url" | grep -q 'googlesource\.com'; then
    base=$(echo "$url" | sed -n 's|^\(https\?://[^/]*/[^+]*\)/+/.*|\1|p')
    ref=$(echo "$url" | sed -n 's|.*/+/\([^?]*\).*|\1|p')
    ref="${ref%/}"
    { [ -n "$base" ] && [ -n "$ref" ]; } || die "无法解析 gitiles URL（期望 <project>/+/<sha 或 ref>）: $url"
    case "$ref" in
        *'^!') range="$ref" ;;
        *)     range="${ref}^!" ;;
    esac
    out="$OUTDIR/gitiles-$(safe_name "${ref:0:12}").patch"
    fetch_b64 "$out" "${base}/+/${range}?format=TEXT"
    echo "$out"
    exit 0
fi

# ---------- GitHub ----------
if echo "$url" | grep -q 'github\.com'; then
    if echo "$url" | grep -q '/commit/'; then
        patch_url="${url%%\?*}.patch"   # Drop the query before appending .patch
        patch_url="${patch_url%.patch}.patch"  # Avoid duplicate suffixes
    else
        die "GitHub URL 需要 /commit/<sha> 形式: $url"
    fi
    sha=$(echo "$url" | sed -n 's|.*/commit/\([a-f0-9]*\).*|\1|p' | cut -c1-12)
    out="$OUTDIR/github-${sha:-unknown}.patch"
    fetch_raw "$out" "$patch_url"
    echo "$out"
    exit 0
fi

# ---------- GitLab(including self-hosted instances) ----------
if echo "$url" | grep -qE '/-/commit/'; then
    patch_url="${url%%\?*}.patch"
    patch_url="${patch_url%.patch}.patch"
    sha=$(echo "$url" | sed -n 's|.*/-/commit/\([a-f0-9]*\).*|\1|p')
    host=$(echo "$url" | sed -n 's|^https\?://\([^/]*\)/.*|\1|p')   # Hostname only, for the filename
    out="$OUTDIR/gitlab-${host}-${sha:-unknown}.patch"
    # Public repos need no token; private repos use GITLAB_TOKEN without logging it
    if [ -n "${GITLAB_TOKEN:-}" ]; then
        fetch_raw "$out" "$patch_url" --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}"
    else
        fetch_raw "$out" "$patch_url"
    fi
    echo "$out"
    exit 0
fi

die "未识别的平台: $url
支持: cgit(kernel.org/yocto/buildroot/oe) / sourceware gitweb / gitiles(googlesource) / Gerrit / GitHub / GitLab / lore（--lore 或 URL 直贴）
raw URL 取证语法见 references/fetch-recipes.md（-h 看用法）"
