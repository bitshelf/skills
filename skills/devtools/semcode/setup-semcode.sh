#!/usr/bin/env bash
# Configure semcode without replacing existing MCP servers or permissions.
# Usage: setup-semcode.sh [--force] [project-dir]
# --force indexes a missing database without prompting; it never overwrites settings.
set -euo pipefail
FORCE=false
if [[ "${1:-}" == --help ]]; then
    printf '%s\n' 'Usage: setup-semcode.sh [--force] [project-dir]'
    exit 0
fi
if [[ "${1:-}" == --force ]]; then FORCE=true; shift; fi
PROJECT_DIR="$(realpath "${1:-$PWD}")"
[[ -d "$PROJECT_DIR" ]] || { printf 'Project not found: %s\n' "$PROJECT_DIR" >&2; exit 1; }
for binary in semcode-mcp jq; do
    command -v "$binary" >/dev/null || { printf 'Missing dependency: %s\n' "$binary" >&2; exit 1; }
done
if [[ ! -e "$PROJECT_DIR/.semcode.db" ]]; then
    command -v semcode-index >/dev/null || { printf '%s\n' 'Missing dependency: semcode-index' >&2; exit 1; }
    if ! $FORCE; then
        read -r -p 'Index this project with semcode-index? [y/N] ' answer
        [[ "$answer" =~ ^[Yy]$ ]] || { printf '%s\n' 'Skipped setup; no index exists.'; exit 0; }
    fi
    (cd "$PROJECT_DIR" && semcode-index -s .)
fi
# .mcp.json is a Claude Code project configuration, not a universal MCP format.
# Keep existing semcode entries, other servers, and all permission settings.
if [[ -d "$PROJECT_DIR/.claude" || -d "$HOME/.claude" ]]; then
    config="$PROJECT_DIR/.mcp.json"
    temp="$(mktemp "$PROJECT_DIR/.semcode-config.XXXXXX")"
    trap 'rm -f "$temp"' EXIT
    input=/dev/null
    [[ ! -e "$config" ]] || input="$config"
    jq -s 'if length == 0 then {} else .[0] end |
        if type != "object" then error("MCP config must be an object") else . end |
        .mcpServers = (.mcpServers // {}) |
        .mcpServers.semcode = (.mcpServers.semcode // {command: "semcode-mcp"})' "$input" > "$temp"
    mv "$temp" "$config"
    printf 'Configured Claude Code: %s (existing settings preserved)\n' "$config"
else
    printf '%s\n' 'Claude Code not detected; no client configuration written.'
fi
cat <<'EOF'
Connection guidance (reload using the active client's procedure):
  Claude Code: project .mcp.json; approve tools through the client's normal flow.
  Codex: configure the server in config.toml or use `codex mcp add semcode -- semcode-mcp`.
    [mcp_servers.semcode]
    command = "semcode-mcp"
  ZCode: add/import semcode in Settings > MCP. Native config is .zcode/config.json;
    .agents/mcp.json is a fallback only when native servers are absent.
  Deep Code: configure MCP using the installed version's documented settings.
  pi.dev: MCP requires a compatible extension; otherwise use local source search.
  Do not assume a config file makes server tools available in the current session.
EOF
