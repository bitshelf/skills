# Upstream-first Android documentation routing

## Establish the upstream baseline

Identify the checkout's Android release, manifest revision, kernel branch and affected subsystem. Use upstream documentation and version-matched source as the primary basis for Android architecture, interfaces, build concepts, security and compatibility. Use the `aosp-docs` skill when deeper research is needed.

- Start with [AOSP documentation](https://source.android.com/) for platform guidance and the release's compatibility requirements.
- Resolve implementation details against the matching revision on [Android Git repositories](https://android.googlesource.com/) or [Android Code Search](https://cs.android.com/), and compare with the local checkout.
- For kernel mechanisms and U-Boot behavior outside Android-specific integration, use the corresponding upstream project's documentation and matching source revision.

Do not apply the newest upstream example to an older checkout without checking support. Upstream guidance establishes intended behavior and requirements; the local source establishes what this vendor branch actually implements. Distinguish a vendor extension or deviation from an upstream requirement instead of silently substituting one for the other.

## Add Rockchip-specific evidence when needed

Consult Rockchip documentation to explain BSP differences such as product configuration, vendor HAL integration, module staging, boot image repacking, firmware tools and board bring-up. Routine upstream questions do not require reading vendor guides first.

Discover vendor documents in the current SDK at runtime. `RKDocs/` is a candidate location, not a guaranteed directory contract: inspect project instructions, release notes and the checkout for its actual documentation root. Do not prescribe exact PDF names, version numbers, chapter numbers, capitalization or subsystem directory layouts.

Search by topic, for example after setting `DOC_ROOT` to the discovered directory:

```bash
rg --files "$DOC_ROOT" -g '*.[pP][dD][fF]' -g '*.md' -g '*.txt' |
    rg -i 'gki|kernel|camera|摄像|selinux|sepolicy|audio|音频|recovery'
```

Choose search terms for the actual task; do not load every match. If names are inconclusive, inspect a document index, contents or extracted text. Select documents by their stated applicability to the branch, product type and feature, rather than filename recency alone. Follow explicit cross-version references only after confirming that the referenced procedure still fits this checkout.

| Task | Upstream baseline | Rockchip supplement: search topics |
|---|---|---|
| Setup, build, products and modules | AOSP build setup, product configuration, Soong/Make | SDK release, wrapper, product, 编译, 产品配置 |
| GKI, modules and boot images | Android kernel/GKI, boot image format, module interfaces | GKI, kernel, ko, ramdisk, boot, 内核, 打包 |
| A/B OTA and recovery | AOSP OTA, update engine, recovery | A/B, OTA, recovery, 升级, 恢复 |
| APK preinstall | AOSP product modules, permissions, signing | preinstall, APK, 预装 |
| SELinux | AOSP SELinux policy and denial analysis | SELinux, sepolicy, 权限 |
| Camera and HDMI input | AOSP camera framework and HAL contracts | camera, HDMI, bridge, 摄像, 桥接 |
| Audio | AOSP audio framework and HAL contracts | audio, AIDL, 音频 |
| Display and graphics | AOSP graphics, SurfaceFlinger and composer HAL | display, HWC, DRM, 显示 |
| Logs and performance | AOSP debugging, tracing and performance tools | log, perf, 日志, 性能 |
| Bootloader | Matching upstream U-Boot documentation and source | U-Boot, loader, 启动, 烧录 |

## Corroborate before applying

Read only the relevant sections. For a PDF, extract text to a temporary file with an available PDF reader or `pdftotext -layout`; render pages when diagrams or tables matter. Report the title/version and section or page of the document actually found when evidence is needed; do not vendor full manuals into the skill.

Check vendor examples against current product configuration and the scripts that execute them. Resolve toolchain paths, config fragments, DTS, helper filenames and image outputs from this checkout. If upstream guidance, vendor documentation and local implementation differ, explain the discrepancy and use the supported local execution path without presenting it as an upstream rule. If a vendor document is missing, continue with upstream evidence and local source, stating any unresolved BSP-specific details rather than guessing a replacement filename.
