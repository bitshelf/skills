# PowerShell Notes for Windows Remote

## Quoting Rules

| Context | Quote type | Variable expansion |
|---------|-----------|-------------------|
| `powershell -Command "..."` | Double quotes | `${VAR}` expanded by bash first |
| `powershell -Command '...'` | Single quotes | `${VAR}` NOT expanded, literal |
| Inside PS double-quotes `"..."` | PS double-quotes | `$env:VAR` expanded by PowerShell |

## Path Conventions

- Windows paths in bash: forward slashes — `D:/Users/foo/Documents`
- Windows paths in PS: backslashes — `D:\Users\foo\Documents`
- Escaping in bash: `\\` → literal `\` in PS command

## Common Patterns

### Resolve Desktop Path

```bash
DESKTOP=$(ssh user@host \
    "powershell -Command '[Environment]::GetFolderPath(\"Desktop\")'" \
    2>&1 | tr -d '\r')
```

The `tr -d '\r'` strips Windows CR from SSH output.

### Create Directory Recursively

```bash
ssh user@host "New-Item -ItemType Directory -Force -Path '${DESKTOP}\\remote_winspace'"
```

### Execute Tool with Arguments

```bash
./scripts/run.sh "& \"${PLATFORM_TOOLS}\\upgrade_tool.exe\" uf \"${DESKTOP}\\file.img\""
```

The `&` call operator is required when the executable path contains variables.
The `\"` escapes double quotes for bash → PS string.
