#!/usr/bin/env bash
# install.sh — install skills from this repository into AI harness skill directories.
#
# Two install scopes:
#   user (default)    symlink skills into per-harness user directories
#                     (copy mode when running remotely, see below)
#   --project <dir>   copy skills into <dir>'s per-harness project directories
#                     (self-contained, survives sharing the project tree)
#
# The script runs straight from GitHub with no local clone: it downloads the
# repo tarball to a temp dir and installs from there (copy mode only).
# Pin the version with --ref <tag|sha>, point at a fork with --repo owner/name.
#
# Examples:
#   curl -fsSL https://raw.githubusercontent.com/bitshelf/skills/main/install.sh | \
#       bash -s -- --profile linux
#   cd /path/to/rk-linux-sdk && curl -fsSL https://raw.githubusercontent.com/bitshelf/skills/main/install.sh | \
#       bash -s -- --project . --profile linux
#   ./install.sh                                        # local clone: all skills, all harnesses, user scope
#   ./install.sh --category rockchip,devtools           # only these categories
#   ./install.sh --profile linux                        # curated SDK workflow set
#   cd /path/to/aosp        && /path/to/install.sh --project . --profile android --harness zcode,claude
#   ./install.sh --project . semcode                    # single skill into current project
#   ./install.sh --uninstall --project .                # remove what was installed
#   ./install.sh --list
#
# Harness skill directory map (verified against each harness's docs and the npx skills CLI):
#   harness   user-level                project-level
#   claude    ~/.claude/skills/         .claude/skills/
#   codex     ~/.agents/skills/         .agents/skills/
#   zcode     ~/.zcode/skills/          .zcode/skills/ + .agents/skills/
#   deepseek  ~/.agents/skills/         .deepcode/skills/     (Deep Code)
#   pi        ~/.pi/agent/skills/       .pi/agent/skills/

set -euo pipefail

GH_REPO_DEFAULT="bitshelf/skills"
GH_REF_DEFAULT="main"
GH_REPO="$GH_REPO_DEFAULT"
GH_REF="$GH_REF_DEFAULT"

# A local checkout = this script sits next to a skills/ directory. Anything else
# (piped from curl, saved standalone) must fetch the repo tarball from GitHub.
SELF_DIR=""
if [ -f "${BASH_SOURCE[0]:-}" ]; then
    _d="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")" 2>/dev/null || true)"
    [ -n "${_d:-}" ] && [ -d "$_d/skills" ] && SELF_DIR="$_d"
fi

HARNESSES=(claude codex zcode deepseek pi)

PROFILE_LINUX=(rk-build rk-debug schematic-terminal upstream-backport semcode win-remote writing-bash-scripts)
PROFILE_ANDROID=(android aosp-docs schematic-terminal upstream-backport semcode win-remote writing-bash-scripts)
PROFILE_ALLWINNER=(aw-build schematic-terminal upstream-backport semcode win-remote writing-bash-scripts)

usage() {
    cat <<'EOF'
install.sh — install skills from bitshelf/skills into AI harness skill directories.

Scopes:
  user (default)     symlink into per-harness user dirs (copy when running remotely)
  --project <dir>    copy into <dir>'s per-harness project dirs (self-contained)

Remote, no clone needed (downloads the repo tarball from GitHub, copy mode only):
  curl -fsSL https://raw.githubusercontent.com/bitshelf/skills/main/install.sh | bash -s -- --profile linux
  cd /path/to/rk-linux-sdk && curl -fsSL https://raw.githubusercontent.com/bitshelf/skills/main/install.sh | \
      bash -s -- --project . --profile linux
  ... | bash -s -- --repo owner/name --ref <tag|sha>    # fork / pin

From a local clone:
  ./install.sh                                          # all skills, all harnesses, user scope
  ./install.sh --category rockchip,devtools             # only these categories
  ./install.sh --profile linux                          # curated SDK workflow set
  ./install.sh --project . semcode                      # single skill into current project
  ./install.sh --uninstall [--project .]                # remove what was installed
  ./install.sh --list

Harness skill directory map (user-level / project-level):
  claude    ~/.claude/skills/         .claude/skills/
  codex     ~/.agents/skills/         .agents/skills/
  zcode     ~/.zcode/skills/          .zcode/skills/ + .agents/skills/
  deepseek  ~/.agents/skills/         .deepcode/skills/
  pi        ~/.pi/agent/skills/       .pi/agent/skills/
EOF
}

list_skills() {
    echo "Skills (skills/<category>/<name>):"
    find "$SKILLS_ROOT" -mindepth 2 -maxdepth 2 -type d | sed "s|^$SKILLS_ROOT/|  |" | sort
    echo
    echo "Categories: $(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f ')(select with --category <list>)"
    echo
    echo "Profiles:"
    echo "  linux:     ${PROFILE_LINUX[*]}"
    echo "  android:   ${PROFILE_ANDROID[*]}"
    echo "  allwinner: ${PROFILE_ALLWINNER[*]}"
    echo "  all:       ${PROFILE_ALL[*]}"
    echo
    echo "Harnesses: ${HARNESSES[*]} (user and project scope; see header comment for paths)"
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# user_dirs <harness> → absolute dirs (one per line)
user_dirs() {
    case "$1" in
    claude) echo "$HOME/.claude/skills" ;;
    codex) echo "$HOME/.agents/skills" ;;
    zcode) echo "$HOME/.zcode/skills" ;;
    deepseek) echo "$HOME/.agents/skills" ;;
    pi) echo "$HOME/.pi/agent/skills" ;;
    *) die "unknown harness '$1'" ;;
    esac
}

# project_dirs <harness> → dirs relative to project root (space-separated)
project_dirs() {
    case "$1" in
    claude) echo ".claude/skills" ;;
    codex) echo ".agents/skills" ;;
    zcode) echo ".zcode/skills .agents/skills" ;;
    deepseek) echo ".deepcode/skills" ;;
    pi) echo ".pi/agent/skills" ;;
    *) die "unknown harness '$1'" ;;
    esac
}

# skill_src <name> → absolute source dir under skills/<category>/<name>
skill_src() {
    local name="$1" src
    src="$(find "$SKILLS_ROOT" -mindepth 2 -maxdepth 2 -type d -name "$name" | head -n1)"
    [ -n "$src" ] || die "unknown skill '$name' (searched $SKILLS_ROOT/<category>/$name)"
    echo "$src"
}

# ── Argument parsing ──
SCOPE=user
PROJECT_DIR=""
HARNESS_SEL="all"
PROFILE=""
MODE="" # link | copy; derived from scope when empty
FORCE=false
UNINSTALL=false
LIST=false
SELECTED=()

while [ $# -gt 0 ]; do
    case "$1" in
    --project)
        SCOPE=project
        PROJECT_DIR="${2:?--project requires a directory}"
        shift 2
        ;;
    --harness)
        HARNESS_SEL="${2:?--harness requires a list}"
        shift 2
        ;;
    --profile)
        PROFILE="${2:?--profile requires a name}"
        shift 2
        ;;
    --category)
        CATEGORY_SEL="${2:?--category requires a list}"
        shift 2
        ;;
    --repo)
        GH_REPO="${2:?--repo requires owner/name}"
        case "$GH_REPO" in
        */*) ;;
        *) die "--repo expects owner/name, got '$GH_REPO'" ;;
        esac
        shift 2
        ;;
    --ref)
        GH_REF="${2:?--ref requires a git ref}"
        shift 2
        ;;
    --link)
        MODE="link"
        shift
        ;;
    --copy)
        MODE=copy
        shift
        ;;
    --force)
        FORCE=true
        shift
        ;;
    --uninstall)
        UNINSTALL=true
        shift
        ;;
    --list)
        LIST=true
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    --*) die "unknown option '$1'" ;;
    *)
        SELECTED+=("$1")
        shift
        ;;
    esac
done

if [ "$SCOPE" = project ]; then
    PROJECT_DIR="$(realpath "$PROJECT_DIR")"
    [ -d "$PROJECT_DIR" ] || die "project directory not found: $PROJECT_DIR"
fi

# ── Resolve skill sources: local checkout, or GitHub tarball when piped in ──
REMOTE=false
if [ -n "$SELF_DIR" ]; then
    REPO_ROOT="$SELF_DIR"
    if [ "$GH_REPO" != "$GH_REPO_DEFAULT" ] || [ "$GH_REF" != "$GH_REF_DEFAULT" ]; then
        echo "NOTE: --repo/--ref ignored — running from a local checkout" >&2
    fi
else
    REMOTE=true
    fetch=()
    if command -v curl >/dev/null 2>&1; then
        fetch=(curl -fsSL)
    elif command -v wget >/dev/null 2>&1; then
        fetch=(wget -qO-)
    else
        die "remote install needs curl or wget — clone the repo and run ./install.sh instead"
    fi
    tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/skills-install.XXXXXX")"
    trap 'rm -rf "$tmpdir"' EXIT
    url="https://codeload.github.com/${GH_REPO}/tar.gz/${GH_REF}"
    echo "Fetching $url"
    "${fetch[@]}" "$url" | tar -xzf - -C "$tmpdir"
    REPO_ROOT="$(echo "$tmpdir"/*)"
    [ -d "$REPO_ROOT/skills" ] || die "unexpected tarball layout from $url (no skills/ at root)"
    echo "Using $GH_REPO@$GH_REF"
fi
SKILLS_ROOT="$REPO_ROOT/skills"
mapfile -t PROFILE_ALL < <(find "$SKILLS_ROOT" -mindepth 3 -maxdepth 3 -name SKILL.md -printf '%h\n' | sed 's|.*/||' | sort)

if $LIST; then
    list_skills
    exit 0
fi

if [ -z "$MODE" ]; then
    if [ "$SCOPE" = project ] || [ "$REMOTE" = true ]; then MODE=copy; else MODE="link"; fi
fi
if [ "$REMOTE" = true ] && [ "$MODE" = link ]; then
    die "--link needs a local checkout — a remote install copies skill files"
fi

EXPLICIT=false
if [ -n "$PROFILE" ]; then
    EXPLICIT=true
    case "$PROFILE" in
    linux) mapfile -t SELECTED < <(printf '%s\n' "${PROFILE_LINUX[@]}") ;;
    android) mapfile -t SELECTED < <(printf '%s\n' "${PROFILE_ANDROID[@]}") ;;
    allwinner) mapfile -t SELECTED < <(printf '%s\n' "${PROFILE_ALLWINNER[@]}") ;;
    all) mapfile -t SELECTED < <(printf '%s\n' "${PROFILE_ALL[@]}") ;;
    *) die "unknown profile '$PROFILE' (linux|android|allwinner|all)" ;;
    esac
fi
if [ -n "${CATEGORY_SEL:-}" ]; then
    EXPLICIT=true
    IFS=',' read -r -a cats <<<"$CATEGORY_SEL"
    for c in "${cats[@]}"; do
        d="$SKILLS_ROOT/$c"
        [ -d "$d" ] || die "unknown category '$c' (available: $(find "$SKILLS_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f '))"
        while IFS= read -r n; do SELECTED+=("$n"); done < <(ls "$d")
    done
fi
# dedupe (profile + category + names may overlap), keep first occurrence
[ ${#SELECTED[@]} -gt 0 ] && mapfile -t SELECTED < <(printf '%s\n' "${SELECTED[@]}" | awk '!seen[$0]++')
if [ ${#SELECTED[@]} -eq 0 ]; then
    $EXPLICIT && die "selection resolved to no skills"
    # bare invocation = all skills
    mapfile -t SELECTED < <(printf '%s\n' "${PROFILE_ALL[@]}")
fi

if [ "$HARNESS_SEL" = all ]; then
    mapfile -t HARNESS_LIST < <(printf '%s\n' "${HARNESSES[@]}")
else
    mapfile -t HARNESS_LIST < <(tr ',' '\n' <<<"$HARNESS_SEL")
fi
# Validate the complete selection before changing any destination.
for h in "${HARNESS_LIST[@]}"; do
    user_dirs "$h" >/dev/null
done
for name in "${SELECTED[@]}"; do
    src="$(skill_src "$name")"
    [ -f "$src/SKILL.md" ] || die "skill '$name' has no SKILL.md"
done

# ── Install / uninstall one skill into one directory ──
ai_dev_warned=false
check_ai_dev() {
    local resolved
    resolved="$(realpath "$1" 2>/dev/null || echo "$1")"
    if ! $ai_dev_warned && [[ "$resolved" == *"/.config/ai-dev/"* ]]; then
        echo "  WARNING: $1 resolves into ~/.config/ai-dev — that layer is rebuilt from"
        echo "           skill-map.yaml (chezmoi); entries may be removed on the next"
        echo "           'chezmoi apply'. See README 'ai-dev takeover' for the stable setup." >&2
        ai_dev_warned=true
    fi
}

install_one() {
    local src="$1" dest="$2" name
    name="$(basename "$src")"

    if [ -L "$dest" ]; then
        if [ "$MODE" = link ] && [ "$(readlink "$dest")" = "$src" ]; then
            echo "  = $dest (already linked)"
            return
        fi
        $FORCE || {
            echo "  ! skip $dest (existing symlink, use --force)"
            return
        }
        if [ "$MODE" = link ]; then
            ln -sfn "$src" "$dest"
            echo "  ~ $dest -> $src"
            return
        fi
        unlink "$dest"
    fi

    if [ -e "$dest" ]; then
        $FORCE || {
            echo "  ! skip $dest (exists, use --force)"
            return
        }
        local bak="$dest.bak.$$"
        mv "$dest" "$bak"
        echo "  ~ backed up old $dest -> $bak"
    fi

    if [ "$MODE" = link ]; then
        ln -s "$src" "$dest"
        echo "  + $dest -> $src"
    else
        cp -a "$src" "$dest"
        if [ "$REMOTE" = true ]; then
            echo "github:${GH_REPO}@${GH_REF}" >"$dest/.skill-source" # uninstall marker
        else
            echo "$REPO_ROOT" >"$dest/.skill-source"                   # uninstall marker
        fi
        echo "  + $dest (copied)"
    fi
}

uninstall_one() {
    local dest="$1"
    if [ -L "$dest" ] && [[ "$(readlink "$dest")" == "$REPO_ROOT"* ]]; then
        unlink "$dest"
        echo "  - $dest (link)"
    elif [ -d "$dest" ] && [ -f "$dest/.skill-source" ]; then
        rm -rf "$dest"
        echo "  - $dest (copy)"
    else
        echo "  = $dest (not installed by this repo, left alone)"
    fi
}

# ── Main ──
git_exclude() {
    # project scope: keep installed dirs out of the project's git status without
    # touching the tracked .gitignore
    local proj="$1" rel="$2" exclude
    exclude="$(git -C "$proj" rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null)" || return 0
    mkdir -p "$(dirname "$exclude")"
    grep -qxF "$rel/" "$exclude" 2>/dev/null || echo "$rel/" >>"$exclude"
}

for name in "${SELECTED[@]}"; do
    src="$(skill_src "$name")"
    # codex and zcode both target .agents/skills; install each skill only once per directory
    declare -A seen_dirs=()
    for h in "${HARNESS_LIST[@]}"; do
        if [ "$SCOPE" = user ]; then
            while IFS= read -r dir; do
                if [ -n "${seen_dirs[$dir]:-}" ]; then continue; fi
                seen_dirs[$dir]=1
                check_ai_dev "$dir"
                mkdir -p "$dir"
                if $UNINSTALL; then uninstall_one "$dir/$name"; else install_one "$src" "$dir/$name"; fi
            done < <(user_dirs "$h")
        else
            for rel in $(project_dirs "$h"); do
                dir="$PROJECT_DIR/$rel"
                if [ -n "${seen_dirs[$dir]:-}" ]; then
                    echo "  = $dir/$name (already handled by another harness, skipped)"
                    continue
                fi
                seen_dirs[$dir]=1
                if $UNINSTALL; then uninstall_one "$dir/$name"; else
                    mkdir -p "$dir"
                    install_one "$src" "$dir/$name"
                    git_exclude "$PROJECT_DIR" "$rel"
                fi
            done
        fi
    done
done

done_msg="Done. ($SCOPE scope, mode=$MODE, harnesses: ${HARNESS_LIST[*]})"
[ "$REMOTE" = true ] && done_msg="$done_msg [source: github:${GH_REPO}@${GH_REF}]"
echo "$done_msg"
