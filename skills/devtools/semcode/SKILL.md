---
name: semcode
description: 'Semantic code search for Linux kernel / C-C++ codebases via semcode MCP. Auto-setup .mcp.json and .semcode.db on first use. Use when: "find function", "who calls", "call chain", "search kernel code", "trace code path", "find definition", "find struct", "find type", "grep kernel", "semantic search", "commit search kernel". Always load this skill when working in a kernel tree that has or needs semcode index.'
invocation_policy: automatic
---

# Semcode MCP — Kernel Code Navigation

semcode provides semantic code search via MCP tools. The MCP server (`semcode-mcp`) auto-detects `.semcode.db` in the working directory.

## Auto-Setup (First Use)

Before using any semcode tool, verify the environment:

```
Check if .semcode.db exists in the project root.  If not, run:
  semcode-index -s .
This creates the index database.

Check if .mcp.json exists.  If not, run the setup script from this skill's
directory (it also handles indexing):
  bash <skill-dir>/setup-semcode.sh --force <project-dir>
# <skill-dir> is the directory containing this SKILL.md

The script writes .mcp.json for every harness that reads project-level MCP
config, and .claude/settings.local.json with tool pre-approvals when Claude
Code is in use. For Codex, add the printed mcp_servers snippet to
~/.codex/config.toml manually.
```

**CRITICAL**: If `semcode-mcp` is not found, the setup script does nothing. In that case, index with `semcode-index -s .` and create `.mcp.json` manually.

## MANDATORY: Always Use semcode for Kernel Code Tasks

When working on Linux kernel code and semcode MCP tools are available, you MUST use them for:

| Task | Tool | Why |
|---|---|---|
| Find a function definition | `find_function` | Exact + regex, faster than grep |
| Find a struct/type/typedef | `find_type` | Aware of typedef chains |
| Who calls this function | `find_callers` | Call graph in DB |
| What this function calls | `find_calls` | Downstream analysis |
| Full call chain | `find_callchain` | Forward + reverse |
| Search function bodies | `grep_functions` | Regex in function bodies only |
| Semantic search | `vgrep_functions` | Meaning-based, not text |
| Find commits touching a symbol | `find_commit` | Git-aware, by function/file |
| Extract functions from diff | `diff_functions` | Parse unified diffs |
| Search lore.kernel.org | `lore_search` | Mailing list archives |
| Find lore for a commit | `dig` | Commit → email thread |

## Tool Reference

```
find_function <name> [--path <pattern>] [--git <range>] [--limit <n>]
  Find functions/macros by name (case-insensitive regex).
  Example: find_function "btrfs_submit_bio"

find_type <name> [--path <pattern>] [--git <range>] [--limit <n>]
  Find structs, unions, enums, typedefs.
  Example: find_type "struct task_struct"

find_callers <function> [--path <pattern>] [--git <range>] [--limit <n>]
  Find all call sites of a function.
  Example: find_callers "mutex_lock"

find_calls <function> [--path <pattern>] [--git <range>] [--limit <n>]
  Find all functions called by a function.
  Example: find_calls "do_mount"

find_callchain <function> [--depth <n>] [--direction forward|reverse|both]
  Build forward/reverse call chain.
  Example: find_callchain "submit_bio" --depth 3 --direction both

grep_functions <pattern> [--path <pattern>] [--git <range>] [--limit <n>]
  Regex search through function bodies.
  Example: grep_functions "dma_alloc_coherent" --path "drivers/net/"

vgrep_functions <query> [--path <pattern>] [--limit <n>]
  Semantic/vector search (requires --vectors index).
  Example: vgrep_functions "allocate DMA memory for network device"

find_commit [--message <pattern>] [--symbol <name>] [--path <pattern>]
            [--git <range>] [--limit <n>]
  Search commit history.
  Example: find_commit --symbol "kselftest" --path "tools/testing/"

diff_functions <diff_text>
  Extract function names and types from a unified diff.
  Pipe git diff output directly.

lore_search <query> [--limit <n>]
  Search lore.kernel.org mailing list archives.
  Example: lore_search "KASAN slab-out-of-bounds networking"

dig <commit_sha>
  Find lore.kernel.org email threads discussing a commit.

indexing_status
  Show database statistics (functions, types, commits indexed).

list_branches
  List indexed branches in the database.

compare_branches <branch1> <branch2> [--path <pattern>]
  Compare functions/types between two indexed branches.
```

## Index Management

```bash
semcode-index -s .                    # Full index of current directory
semcode-index -s . --git HEAD~20..    # Index last 20 commits only
semcode-index -s . --vectors          # Include vector embeddings (needs model)
```

Re-index after pulling significant kernel changes. The MCP server auto-detects uncommitted changes to tracked files and overlays them on the indexed DB — no re-index needed for minor edits.

## No semcode Available?

If the semcode MCP tools are not listed (run `indexing_status` to check), the agent needs to restart in the project directory after `.mcp.json` is created. The MCP server is loaded at startup from `.mcp.json` in the working directory.
