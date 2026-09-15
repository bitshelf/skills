---
name: writing-bash-scripts
description: Create and refactor Bash scripts following conventions (strict mode, fct_ naming, quoting). Includes shellcheck linting. Use when creating shell scripts, refactoring existing scripts, debugging shell errors, or linting scripts.
---

# Bash

**Bundled paths:** Resolve relative paths from the directory containing this SKILL.md, while keeping build and target commands in the requested project directory.

Use this skill whenever the user asks to create/update/refactor a Bash script (`.sh`) or lint shell scripts.

## Defaults

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -Eeuo pipefail`
- Functions: `fct_<descriptive_snake_case>() { ... }`
- Variables: quote expansions like `"${var}"`, prefer `printf`, use `readonly` for constants and `local` inside functions

## Workflow

### Creating/Refactoring Scripts

1. Copy `scripts/pref_bash_script_template.sh` to the target path and rename it.
2. Update the SCRIPT INFO / USAGE header blocks.
3. Implement behavior in `fct_execute_this`, keep `fct_main` + `trap` structure.
4. Follow the detailed conventions in `references/pref_bash.md`.
5. Run shellcheck linting (see below).

### Linting Scripts

Run `shellcheck` on scripts:

```bash
shellcheck script.sh

# Lint all .sh files in a directory
find . -name "*.sh" -exec shellcheck {} +
```

For reproducible results use `shellcheck -x -o all`.

See `references/pref_bash.md` section 14 for shellcheck integration details.

`references/google-shell-style-guide.md` is the vendored Google shell style guide
(Google LLC, CC BY 3.0) for general guidance; where it disagrees, `references/pref_bash.md`
wins — notably Google advises against `set -e`, while this skill mandates `set -Eeuo pipefail`.
