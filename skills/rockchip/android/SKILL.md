---
name: android
description: Build and package Rockchip Android SDK components, including framework modules, kernel, U-Boot, and update.img. Use in an Android checkout with build/envsetup.sh and device/rockchip; use the Linux SDK workflow for non-Android Rockchip trees.
---

# Rockchip Android Builds

## Resolve the checkout and target

Locate the SDK root, project instructions, Android branch, and vendor build scripts. Inspect the local wrapper's options before using flags such as `-A`, `-K`, `-U`, or `-u`; their meaning and side effects vary by SDK. Keep Android kernel/U-Boot builds in this workflow so they retain the product's toolchain and packaging configuration.

Use the target explicitly requested by the user or established in the current project. Otherwise inspect product declarations, `AndroidProducts.mk`, supported lunch choices, and project build instructions. Existing output directories and fingerprints are corroborating evidence, not authoritative target selection. Never select the first `out/target/product/` entry or silently default to `userdebug`. If multiple plausible targets remain, resolve the ambiguity before compiling.

## Preserve the build environment

Run `source build/envsetup.sh`, a successful `lunch`, and dependent build commands in the same Bash process. Separate tool calls do not preserve shell functions or exported variables; reinitialize in each new build shell. A persistent shell or script is also valid. Stop if setup or lunch fails.

Use the lunch syntax supported by this checkout, including a release configuration when required. After selection, inspect resolved product, variant, and product output using the branch's build-variable helpers. Do not derive the output path by appending `target/product` to `$OUT`, which may already identify the product directory.

## Match the requested scope

| Request | Action |
|---|---|
| Compile one module | Use the branch-supported module build command for its actual module name or path |
| Compile Android/framework | Use the SDK's Android build path; package only when requested or required by the project's delivery workflow |
| Compile kernel or U-Boot | Use the SDK component wrapper and selected product configuration |
| Package existing output | Check component freshness and compatibility, then run the packaging operation |
| Build complete firmware | Follow the SDK's component dependencies and packaging order |

The bundled [scripts/kernel.sh](scripts/kernel.sh) is available for Rockchip Android kernel/U-Boot builds. Read its [usage and SDK assumptions](references/components.md#bundled-kernel-helper) before using or copying it. Prefer an existing project copy when it already matches the SDK; preserve local customizations. Do not pin a compiler from another SDK or run clean/mrproper as routine setup. For packaging and native components, read [references/components.md](references/components.md).

## Verify and report

Preserve the build exit status when logging through a pipeline (`pipefail` in Bash). Inspect the first substantive failure before broadening the build or cleaning. Use the branch's expected JDK/toolchain and host setup; do not install a guessed system JDK based only on the Android release number.

Report the selected target, commands, exit result, and actual artifact paths. A module build does not establish a fresh system image; a packaged image does not establish device acceptance. Flashing, wiping, unlocking, and switching source branches are separate actions requiring the user's requested scope. For an authorized flash, use the board's Android flashing procedure and verify the intended DUT, image set, and boot result. Boot-mode entry supports serial shortcuts held at power-on (`ctrl+d` Loader, `ctrl+b` MASKROM, `ctrl+f` fastboot) — the full key table lives in the `rk-debug` skill's remote-target-debug reference.
