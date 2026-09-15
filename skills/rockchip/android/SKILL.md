---
name: android
description: Rockchip Android BSP/AOSP 系统开发、修改、排障与编译打包。Use inside a Rockchip Android SDK, including subdirectories, for framework/system services, HAL/AIDL, camera/audio/display, device/product/BoardConfig, init/SELinux, APK preinstall, kernel/DTS/GKI/ko, U-Boot, lunch/Soong builds, boot/vendor_boot/super/update.img and OTA. Trigger for SDK source changes and RKDocs questions even without an explicit build request. Excludes standalone Android app/Jetpack/Compose work and Rockchip Linux SDKs.
---

# Rockchip Android Platform Development

**Bundled paths:** Resolve relative paths from the directory containing this SKILL.md, while keeping build and target commands in the requested project directory.

## Recognize the SDK and route the task

Apply this workflow to source changes, diagnosis, configuration, documentation questions, and builds in a Rockchip Android checkout. A request such as “修 camera provider”, “改系统服务”, “预装 APK”, “加 sepolicy”, “更新驱动 ko”, or “重打 boot.img” can need it without mentioning Rockchip or compilation when the checkout establishes that context.

Starting from the working directory, locate the enclosing SDK with `build/envsetup.sh` and `device/rockchip/`. In a Repo checkout, a nested Git root such as `frameworks/base` or `hardware/rockchip` is not the SDK root; inspect ancestors rather than stopping at that Git root. A directory named `kernel/` alone does not identify the Android kernel source. Keep Rockchip Android kernel/U-Boot work here; use `rk-build` for a non-Android Linux SDK. Standalone app UI work belongs to upstream Android app skills.

Read the applicable project instructions and establish the Android/kernel revision. Use matching upstream AOSP documentation and source as the primary basis for platform behavior and requirements. Use [references/rkdocs.md](references/rkdocs.md) for upstream routing and dynamic discovery of Rockchip supplements when BSP differences matter. Locate the current SDK's documentation root and search by topic; do not depend on fixed vendor PDF names or versions. Corroborate execution paths and commands in the current checkout, and distinguish vendor behavior from upstream requirements.

For platform diagnosis or implementation, identify the affected source layer and deployment unit before editing:

- Resolve product/device inheritance in `device/rockchip/` and any vendor overrides. Do not infer the selected board from the directory name or a guide's example.
- Follow the actual module declarations (`Android.bp`/`Android.mk`), service/init registration, manifest and policy/configuration dependencies relevant to the issue. Trace framework ↔ HAL ↔ kernel boundaries only as needed by the evidence.
- For runtime failures, correlate the requested DUT's Android logs, service state and kernel evidence with that source path. Use the configured device selector; do not choose the first ADB device. Read-only investigation does not require a full build or a guessed lunch target.
- Make persistent changes in the source/configuration consumed by the product. Then validate the affected module or image at the scope the user requested. Preserve unrelated changes and avoid rebuilding the entire SDK for a focused source fix.

Use `aosp-docs` for deeper platform architecture or version-specific upstream research, and `rk-debug` for managed serial/boot evidence when needed. These supplement this SDK workflow.

## Resolve the checkout and target

Locate the SDK root, project instructions, Android branch, and vendor build scripts. Inspect the local wrapper's options before using flags such as `-A`, `-K`, `-U`, or `-u`; their meaning and side effects vary by SDK. Keep Android kernel/U-Boot builds in this workflow so they retain the product's toolchain and packaging configuration.

Use the target explicitly requested by the user or established in the current project. Otherwise inspect product declarations, `AndroidProducts.mk`, supported lunch choices, and project build instructions. Existing output directories and fingerprints are corroborating evidence, not authoritative target selection. Never select the first `out/target/product/` entry or silently default to `userdebug`. If multiple plausible targets remain, resolve the ambiguity before compiling.

## Preserve the build environment

Run `source build/envsetup.sh`, a successful `lunch`, and dependent build commands in the same Bash process. Separate tool calls do not preserve shell functions or exported variables; reinitialize in each new build shell. A persistent shell or script is also valid. Stop if setup or lunch fails.

Use the lunch syntax supported by this checkout, including a release configuration when required. The inspected Android15 tree requires `<product>-<release>-<variant>` and its wrapper checks `TARGET_RELEASE`; do not reuse a two-field Android14 example. Discover valid releases and products locally rather than forcing `ap4a`, `trunk_staging`, or a guide's board. After selection, inspect resolved product, release, variant, and product output using the branch's build-variable helpers. Do not derive the output path by appending `target/product` to `$OUT`, which may already identify the product directory.

For executable examples and the Android15 wrapper's side effects, read [references/components.md](references/components.md). Resolve `PRODUCT_KERNEL_PATH`/version, `PRODUCT_KERNEL_ARCH`, `PRODUCT_KERNEL_CONFIG`, `PRODUCT_KERNEL_DTS`, `PRODUCT_UBOOT_CONFIG`, `BOARD_BUILD_GKI`, and `BOARD_USES_AB_IMAGE` when relevant. A flag label alone does not establish the scope of the commands that follow it.

## Match the requested scope

| Request | Action |
|---|---|
| Diagnose / change platform behavior | Establish the upstream behavior, inspect local source/configuration, and consult vendor supplements for BSP differences; validate the affected service, HAL, policy, or product change |
| Compile one module | Use the branch-supported module build command for its actual module name or path |
| Compile Android/framework | Use the SDK's Android build path; package only when requested or required by the project's delivery workflow |
| Compile kernel or U-Boot | Use the SDK component wrapper and selected product configuration |
| Package existing output | Check component freshness and compatibility, then run the packaging operation |
| Build complete firmware | Follow the SDK's component dependencies and packaging order |

Prefer the checkout's established workflow after inspecting its full side effects. The bundled [scripts/kernel.sh](scripts/kernel.sh) is a direct-build alternative only when its [SDK assumptions](references/components.md#bundled-kernel-helper) hold. It does not perform the GKI module-copy and Android repack steps. Prefer an existing project copy when it already matches the SDK; preserve local customizations. Do not pin a compiler from another SDK or run clean/mrproper as routine setup.

For the Rust-enabled direct kernel/DT build that repacks an existing `boot.img`, read [references/kernel-boot.md](references/kernel-boot.md). Resolve Clang, Rust, bindgen, host tools, and configuration fragments from the selected SDK's actual kernel build path; never select compiler versions by copying an example or taking the newest installed prebuilt.

Check GKI before choosing an artifact: a driver `.ko`, vendor ramdisk, and generic kernel can belong to different images. For non-GKI, use the product's boot packing flow rather than treating `kernel.img` and `resource.img` as independently flashable. For GKI, trace module staging/loading lists and the image that consumes them. Direct kernel compilation alone does not refresh Android images.

## Verify and report

Preserve the build exit status when logging through a pipeline (`pipefail` in Bash). Inspect the first substantive failure before broadening the build or cleaning. Use the branch's expected JDK/toolchain and host setup; do not install a guessed system JDK based only on the Android release number.

Report the selected target, commands, exit result, and actual artifact paths. A module build does not establish a fresh system image; a packaged image does not establish device acceptance. Flashing, wiping, unlocking, and switching source branches are separate actions requiring the user's requested scope. For an authorized flash, use the board's Android flashing procedure and verify the intended DUT, image set, and boot result. A supported bootloader may handle power-on serial shortcuts (`ctrl+d` Loader, `ctrl+b` MASKROM, `ctrl+f` fastboot); confirm the selected checkout's handlers and secure-boot restrictions. These shortcuts require functioning startup code.
