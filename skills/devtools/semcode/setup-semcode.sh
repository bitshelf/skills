#!/usr/bin/env bash
# Setup semcode MCP for a C/C++ project (kernel tree, etc.)
# Usage: setup-semcode.sh [--force] [project-dir]
#   --force       skip prompts, auto-index if .semcode.db missing
#   project-dir   path to the project (default: current dir)
#
# Merges into:
#   .mcp.json                     — MCP server config (no absolute paths)
#   .claude/settings.local.json   — Claude Code tool pre-approvals (only when
#                                   Claude Code is in use)
#
# Existing MCP servers, existing permissions, a user-set SEMCODE_GIT_REPO and
# an existing .semcode.db are all kept. Invalid JSON is reported, never
# overwritten.
#
# Requires: semcode-mcp and semcode-index on PATH, python3 for the JSON merge

set -euo pipefail

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
    shift
fi

PROJECT_DIR="${1:-$PWD}"
PROJECT_DIR="$(realpath "$PROJECT_DIR")"

echo "==> Setting up semcode MCP for: $PROJECT_DIR"

# Check semcode-mcp is available
if ! command -v semcode-mcp &>/dev/null; then
    echo "ERROR: semcode-mcp not found on PATH"
    echo "Install: cd semcode && cargo build --release && ln -s \$PWD/target/release/semcode-mcp ~/.local/bin/"
    exit 1
fi

# If no .semcode.db, auto-index (--force) or ask
if [ ! -e "$PROJECT_DIR/.semcode.db" ]; then
    if $FORCE; then
        echo "No .semcode.db found, auto-indexing..."
        (cd "$PROJECT_DIR" && semcode-index -s .)
        echo "Indexing complete."
    else
        echo ""
        echo "No .semcode.db found. Index the codebase first:"
        echo "  cd $PROJECT_DIR && semcode-index -s ."
        echo ""
        read -r -p "Run semcode-index now? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            (cd "$PROJECT_DIR" && semcode-index -s .)
            echo "Indexing complete."
        else
            echo "Skipping index. You MUST run 'semcode-index -s .' before semcode MCP works."
        fi
    fi
fi

# semcode-mcp resolves .semcode.db relative to its working directory
# (--git-repo, env SEMCODE_GIT_REPO, default "."). That misses SDK layouts
# where the kernel tree is a subdirectory (kernel-6.1/, linux-5.10/) and the
# agent starts in the SDK root — the server would look for .semcode.db at the
# root and find nothing. Point it at the real tree instead.

# A tree qualifies as a kernel tree when it has arch/ plus Makefile or Kconfig.
looks_like_kernel() {
    local dir="$1"
    [ -d "$dir/arch" ] || return 1
    [ -f "$dir/Makefile" ] || [ -f "$dir/Kconfig" ]
}

# Prints the kernel directory name relative to the project root, or nothing
# when the root is itself the kernel tree (the default already resolves) or
# when no single kernel tree can be identified. Never guesses between
# candidates: an ambiguous layout is reported and left for the user.
detect_kernel_dir() {
    local root="$1" candidate resolved trees="" count=0 real_name="" link_name=""

    if looks_like_kernel "$root"; then
        return 0
    fi

    # Unmatched globs stay literal, and the -d test then filters them out.
    for candidate in "$root"/kernel*/ "$root"/linux*/; do
        # The glob appends a trailing slash. Drop it, or -L below would
        # dereference the link and report a symlink as a real directory.
        candidate="${candidate%/}"
        [ -d "$candidate" ] || continue
        looks_like_kernel "$candidate" || continue
        # A `kernel -> kernel-6.1` symlink is the usual SDK layout, and both
        # globs then match the same tree. Record both names but count the
        # resolved tree once, so that is not mistaken for ambiguity.
        if [ -L "$candidate" ]; then
            [ -n "$link_name" ] || link_name="$(basename "$candidate")"
        else
            [ -n "$real_name" ] || real_name="$(basename "$candidate")"
        fi
        resolved="$(realpath "$candidate")"
        case " $trees " in
            *" $resolved "*) continue ;;
        esac
        trees="$trees $resolved"
        count=$((count + 1))
    done

    if [ "$count" -eq 1 ]; then
        # A real directory wins over a symlink to it: build scripts generate
        # the symlink, so a fresh checkout may not have it.
        printf '%s\n' "${real_name:-$link_name}"
    elif [ "$count" -gt 1 ]; then
        echo "  ! several kernel trees at the root, not guessing a SEMCODE_GIT_REPO." >&2
        echo "    Set it by hand in .mcp.json:\"env\":{\"SEMCODE_GIT_REPO\":\"<dir>\"}" >&2
    fi
    return 0
}

SEMCODE_KERNEL_DIR="$(detect_kernel_dir "$PROJECT_DIR")"
if [ -n "$SEMCODE_KERNEL_DIR" ]; then
    echo "    kernel tree: $SEMCODE_KERNEL_DIR/ (SEMCODE_GIT_REPO)"
else
    echo "    kernel tree: project root (SEMCODE_GIT_REPO not needed)"
fi
export SEMCODE_KERNEL_DIR

# Merge configuration without discarding existing servers or permissions.
command -v python3 >/dev/null || { echo "ERROR: python3 is required" >&2; exit 1; }
python3 - "$PROJECT_DIR" <<'PYCONFIG'
import json
import os
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
kernel_dir = os.environ.get("SEMCODE_KERNEL_DIR", "")

def read(path):
    value = json.loads(path.read_text()) if path.exists() else {}
    if not isinstance(value, dict):
        raise ValueError(f"Expected JSON object: {path}")
    return value

mcp_path = root / ".mcp.json"
mcp = read(mcp_path)
servers = mcp.setdefault("mcpServers", {})
if not isinstance(servers, dict):
    raise ValueError("mcpServers must be an object")
semcode = servers.setdefault("semcode", {"command": "semcode-mcp"})
if kernel_dir and isinstance(semcode, dict):
    env = semcode.setdefault("env", {})
    if not isinstance(env, dict):
        raise ValueError("semcode.env must be an object")
    # A value the user already set wins.
    env.setdefault("SEMCODE_GIT_REPO", kernel_dir)
updates = [(mcp_path, mcp)]
if (root / ".claude").is_dir() or (pathlib.Path.home() / ".claude").is_dir():
    path = root / ".claude/settings.local.json"
    settings = read(path)
    permissions = settings.setdefault("permissions", {})
    if not isinstance(permissions, dict):
        raise ValueError("permissions must be an object")
    allow = permissions.setdefault("allow", [])
    if not isinstance(allow, list):
        raise ValueError("permissions.allow must be an array")
    for name in ["find_function", "find_type", "find_callers", "find_calls",
                 "find_callchain", "diff_functions", "grep_functions",
                 "vgrep_functions", "find_commit", "vcommit_similar_commits",
                 "lore_search", "dig", "vlore_similar_emails", "indexing_status",
                 "list_branches", "compare_branches"]:
        entry = "mcp__semcode__" + name
        if entry not in allow:
            allow.append(entry)
    updates.append((path, settings))
# Every input parses before anything is written, so one invalid file cannot
# leave the project half-configured.
for path, value in updates:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")
    print(f"  + merged {path}")
PYCONFIG

echo ""
echo "Done. Restart your agent in $PROJECT_DIR so it picks up .mcp.json."
echo "Harness notes:"
echo "  - Claude Code / ZCode: read .mcp.json from the project root automatically."
echo "  - Codex: add to ~/.codex/config.toml:"
echo "        [mcp_servers.semcode]"
echo "        command = \"semcode-mcp\""
if [ -n "$SEMCODE_KERNEL_DIR" ]; then
    echo "        [mcp_servers.semcode.env]"
    echo "        SEMCODE_GIT_REPO = \"$SEMCODE_KERNEL_DIR\""
fi
