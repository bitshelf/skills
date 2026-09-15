#!/usr/bin/env bash
# install.sh — install skills from this repository into AI harness skill directories.
#
# Two install scopes:
#   user (default)    symlink skills into per-harness user directories
#   --project <dir>   copy skills into <dir>'s per-harness project directories
#                     (self-contained, survives sharing the project tree)
#
# Examples:
#   ./install.sh                                        # all skills, all harnesses, user scope
#   ./install.sh --category rockchip,devtools           # only these categories
#   ./install.sh --profile linux                        # curated SDK workflow set
#   cd /path/to/rk-linux-sdk && /path/to/install.sh --project . --profile linux
#   cd /path/to/aosp        && /path/to/install.sh --project . --profile android --harness zcode,claude
#   ./install.sh --project . semcode                    # single skill into current project
#   ./install.sh --uninstall --project .                # remove what was installed
#   ./install.sh --list
#
# Harness skill directory map (verified against each harness's docs and the npx skills CLI):
#   harness   user-level                project-level
#   claude    ~/.claude/skills/         .claude/skills/
#   codex     ~/.codex/skills/          .agents/skills/       (.codex/skills/ is also scanned)
#   zcode     ~/.zcode/skills/          .zcode/skills/ + .agents/skills/
#   deepseek  ~/.agents/skills/         .deepcode/skills/     (Deep Code)
#   pi        ~/.pi/agent/skills/       .pi/agent/skills/

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SKILLS_ROOT="$REPO_ROOT/skills"
HARNESSES=(claude codex zcode deepseek pi)

PROFILE_LINUX=(rk-build rk-debug schematic-terminal upstream-backport semcode win-remote)
PROFILE_ANDROID=(android aosp-docs schematic-terminal upstream-backport semcode win-remote)
PROFILE_ALLWINNER=(aw-build schematic-terminal upstream-backport semcode win-remote)
PROFILE_ALL=(android aosp-docs rk-build rk-debug semcode win-remote aw-build upstream-backport schematic-terminal)

usage() { sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

list_skills() {
    echo "Skills (skills/<category>/<name>):"
    find "$SKILLS_ROOT" -mindepth 2 -maxdepth 2 -type d | sed "s|^$SKILLS_ROOT/|  |" | sort
    echo
    echo "Categories: $(ls "$SKILLS_ROOT" | tr '\n' ' ')(select with --category <list>)"
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
    codex) echo "$HOME/.codex/skills" ;;
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
    --link)
        MODE=link
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
        list_skills
        exit 0
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
MODE="${MODE:-$([ "$SCOPE" = project ] && echo copy || echo link)}"

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
        [ -d "$d" ] || die "unknown category '$c' (available: $(ls "$SKILLS_ROOT" | tr '\n' ' '))"
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
        if [ "$(readlink "$dest")" = "$src" ]; then
            echo "  = $dest (already linked)"
            return
        fi
        $FORCE || {
            echo "  ! skip $dest (existing symlink, use --force)"
            return
        }
        ln -sfn "$src" "$dest"
        echo "  ~ $dest -> $src"
        return
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
        echo "$REPO_ROOT" >"$dest/.skill-source" # uninstall marker
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
    exclude="$(git -C "$proj" rev-parse --git-path info/exclude 2>/dev/null)" || return 0
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

echo "Done. ($SCOPE scope, mode=$MODE, harnesses: ${HARNESS_LIST[*]})"
