#!/usr/bin/env bash
# Exercise the upstream CLI in an isolated project.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
PROJECT_DIR="$TEST_DIR/project with spaces"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
git init -q

npx --yes skills add "$REPO_DIR" --skill '*' --agent codex claude-code --copy -y

# Check discovery across categories and retention of bundled resources.
for agent_dir in .agents/skills .claude/skills; do
    for source in "$REPO_DIR"/skills/*/*/SKILL.md; do
        skill_dir="$(dirname "$source")"
        cmp "$source" "$agent_dir/${skill_dir##*/}/SKILL.md"
    done
    cmp "$REPO_DIR/skills/devtools/bpp/references/foundations.md" "$agent_dir/bpp/references/foundations.md"
    cmp "$REPO_DIR/skills/rockchip/win-remote/assets/.win-target.conf" "$agent_dir/win-remote/assets/.win-target.conf"
    [[ -x "$agent_dir/writing-bash-scripts/scripts/pref_bash_script_template.sh" ]]
done

npx --yes skills remove bpp rk-debug -y
for agent_dir in .agents/skills .claude/skills; do
    [[ ! -e "$agent_dir/bpp" && ! -e "$agent_dir/rk-debug" ]]
    [[ -f "$agent_dir/rk-build/SKILL.md" ]]
done
printf '%s\n' 'PASS: npx skills installation, bundled resources, and selective removal'
