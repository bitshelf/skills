#!/usr/bin/env bash
# Setup semcode MCP for a C/C++ project (kernel tree, etc.)
# Usage: setup-semcode.sh [--force] [project-dir]
#   --force       skip prompts, auto-index if .semcode.db missing
#   project-dir   path to the project (default: current dir)
#
# Creates:
#   .mcp.json                     — MCP server config (no absolute paths)
#   .claude/settings.local.json   — Claude Code tool pre-approvals (only when
#                                   Claude Code is in use)
#
# Requires: semcode-mcp and semcode-index on PATH

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
if [ ! -d "$PROJECT_DIR/.semcode.db" ]; then
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

# Always (re)generate config files
write_mcp_config() {
    local dir="$1"
    cat > "$dir/.mcp.json" <<'MCPEOF'
{
  "mcpServers": {
    "semcode": {
      "command": "semcode-mcp"
    }
  }
}
MCPEOF
}

write_tool_approvals() {
    local dir="$1"
    mkdir -p "$dir/.claude"
    cat > "$dir/.claude/settings.local.json" <<'SETTINGSEOF'
{
  "permissions": {
    "allow": [
      "mcp__semcode__find_function",
      "mcp__semcode__find_type",
      "mcp__semcode__find_callers",
      "mcp__semcode__find_calls",
      "mcp__semcode__find_callchain",
      "mcp__semcode__diff_functions",
      "mcp__semcode__grep_functions",
      "mcp__semcode__vgrep_functions",
      "mcp__semcode__find_commit",
      "mcp__semcode__vcommit_similar_commits",
      "mcp__semcode__lore_search",
      "mcp__semcode__dig",
      "mcp__semcode__vlore_similar_emails",
      "mcp__semcode__indexing_status",
      "mcp__semcode__list_branches",
      "mcp__semcode__compare_branches"
    ]
  }
}
SETTINGSEOF
}

write_mcp_config "$PROJECT_DIR"
echo "  + $PROJECT_DIR/.mcp.json"

# Claude Code pre-approvals: only when Claude Code is actually in use
# (project already has a .claude/ dir, or a user-level ~/.claude exists).
if [ -d "$PROJECT_DIR/.claude" ] || [ -d "$HOME/.claude" ]; then
    write_tool_approvals "$PROJECT_DIR"
    echo "  + $PROJECT_DIR/.claude/settings.local.json"
else
    echo "  - skipping .claude/settings.local.json (Claude Code not detected)"
fi

echo ""
echo "Done. Restart your agent in $PROJECT_DIR so it picks up .mcp.json."
echo "Harness notes:"
echo "  - Claude Code / ZCode: read .mcp.json from the project root automatically."
echo "  - Codex: add to ~/.codex/config.toml:"
echo "        [mcp_servers.semcode]"
echo "        command = \"semcode-mcp\""
