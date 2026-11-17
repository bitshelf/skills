#!/usr/bin/env bash
# Mock transports and compilers: no network, indexing, or target writes.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/project/.claude" "$TEST_DIR/project/.semcode.db"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$TEST_DIR/bin/semcode-mcp"
chmod +x "$TEST_DIR/bin/semcode-mcp"
printf '%s\n' '{"mcpServers":{"other":{"command":"existing"},"semcode":{"command":"custom-semcode"}},"extra":true}' > "$TEST_DIR/project/.mcp.json"
printf '%s\n' '{"permissions":{"deny":["Bash(rm:*)"]}}' > "$TEST_DIR/project/.claude/settings.local.json"
cp "$TEST_DIR/project/.mcp.json" "$TEST_DIR/expected.json"
cp "$TEST_DIR/project/.claude/settings.local.json" "$TEST_DIR/permissions.json"
PATH="$TEST_DIR/bin:$PATH" bash "$REPO_DIR/skills/devtools/semcode/setup-semcode.sh" --force "$TEST_DIR/project" >/dev/null
diff <(jq -S . "$TEST_DIR/expected.json") <(jq -S . "$TEST_DIR/project/.mcp.json")
cmp "$TEST_DIR/permissions.json" "$TEST_DIR/project/.claude/settings.local.json"
printf '%s\n' 'invalid-json' > "$TEST_DIR/project/.mcp.json"
if PATH="$TEST_DIR/bin:$PATH" bash "$REPO_DIR/skills/devtools/semcode/setup-semcode.sh" --force "$TEST_DIR/project" >/dev/null 2>&1; then exit 1; fi
[[ "$(cat "$TEST_DIR/project/.mcp.json")" == invalid-json ]]
# Remote SSH helper must forward all arguments, show stderr, and retain exit status.
printf '%s\n' 'WIN_HOST=test.invalid' 'WIN_USER=test' > "$TEST_DIR/win.conf"
cat > "$TEST_DIR/bin/ssh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
printf '%s\n' 'mock transport failure' >&2
exit 23
EOF
chmod +x "$TEST_DIR/bin/ssh"
rc=0
PATH="$TEST_DIR/bin:$PATH" WIN_CONF="$TEST_DIR/win.conf" bash "$REPO_DIR/skills/rockchip/win-remote/scripts/run.sh" dir 'C:\with spaces' > "$TEST_DIR/out" 2> "$TEST_DIR/err" || rc=$?
[[ "$rc" == 23 ]]
grep -qxF 'C:\with spaces' "$TEST_DIR/out"
grep -qxF 'mock transport failure' "$TEST_DIR/err"
# Kernel helper must reject a missing target and propagate a compiler failure.
mkdir -p "$TEST_DIR/sdk/build" "$TEST_DIR/sdk/kernel-test" "$TEST_DIR/toolchain"
cat > "$TEST_DIR/sdk/build/envsetup.sh" <<'EOF'
get_build_var() {
    case "$1" in
        PRODUCT_KERNEL_ARCH) printf arm64 ;;
        PRODUCT_KERNEL_VERSION) printf test ;;
        PRODUCT_KERNEL_DTS) printf board ;;
        *) return 1 ;;
    esac
}
EOF
cat > "$TEST_DIR/bin/make" <<'EOF'
#!/usr/bin/env bash
exit 42
EOF
chmod +x "$TEST_DIR/bin/make"
if (cd "$TEST_DIR/sdk" && env -u TARGET_PRODUCT -u TARGET_BUILD_VARIANT bash "$REPO_DIR/skills/rockchip/android/scripts/kernel.sh") >/dev/null 2>&1; then exit 1; fi
rc=0
(cd "$TEST_DIR/sdk" && PATH="$TEST_DIR/bin:$PATH" TARGET_PRODUCT=test TARGET_BUILD_VARIANT=userdebug KERNEL_TOOLCHAIN_BIN="$TEST_DIR/toolchain" KERNEL_MAKE_ARGS='LLVM=1 LLVM_IAS=1' BOOT_IMG='../boot.img' bash "$REPO_DIR/skills/rockchip/android/scripts/kernel.sh") >/dev/null 2>&1 || rc=$?
[[ "$rc" == 42 ]]
printf '%s\n' 'PASS: MCP config preservation, invalid JSON, SSH args/status/stderr, explicit Android target/build failure'
