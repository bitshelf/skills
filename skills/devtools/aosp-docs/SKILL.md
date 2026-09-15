---
name: aosp-docs
description: Research Android platform and AOSP architecture, build systems, HALs, security, kernel integration, and compatibility using official documentation and version-matched source. Use for platform explanations, requirement checks, and documentation-backed diagnosis, rather than ordinary Android app SDK questions or routine local builds.
---

# AOSP Documentation and Source Research

## Establish the version and question

Identify the platform topic and relevant Android release, source branch/tag, device/vendor fork, or launch level when it affects the answer. Use available checkout/configuration evidence first; ask only for missing context that materially changes the conclusion. A general conceptual explanation need not wait for a device model.

Distinguish upstream behavior, vendor implementation, compatibility requirements, and recommended practice. Current documentation can describe APIs or build commands absent from an older vendor tree.

## Find authoritative evidence

Use `source.android.com` for platform documentation and release-specific CDD requirements. For implementation details, inspect the local checkout or the corresponding revision on `android.googlesource.com` / `cs.android.com`. Local source is the primary evidence for what this checkout actually does; do not replace it with a current documentation example.

Use the available browser/search tools; do not depend on client-specific tool names. Start with a directly relevant page or a domain-limited search containing the subsystem and version. Read [references/source-map.md](references/source-map.md) when choosing a documentation area or source repository. Follow relevant links rather than loading the entire map's destinations.

Check live sources for moving branches such as `android-latest-release`, release cadence, support/EOL claims, current kernel branches, and toolchain requirements. Do not embed their current values as permanent skill rules. Preserve a project's pinned manifest; a documentation recommendation to use a newer branch does not authorize switching or syncing the checkout.

## Apply the evidence

For HALs, verify the release's supported interface type, stability/versioning, and vendor compatibility constraints before proposing AIDL/HIDL changes. For kernels, establish whether the device uses GKI or a vendor kernel and which requirements apply. For build files, inspect this branch's Soong/Make support instead of requiring a broad migration. For SELinux, diagnose the denial and intended access rather than defaulting to permissive mode.

For compatibility questions, select the CDD and CTS/VTS material matching the release and device category. Quote requirement language narrowly and retain its conditions; a passing test is not by itself proof of complete compatibility.

Answer with the conclusion, version/scope, supporting source links, and any relevant local code evidence. Label inferences and unresolved conflicts. If authoritative material is unavailable, state what remains unverified instead of inventing a citation or silently applying current behavior to an older release.

A research request does not itself authorize source sync, builds, device changes, or migration. When the user requests implementation, carry out the authorized work using the checkout's workflow. Rockchip Android build execution belongs to the available `android` skill; this skill supplies the documentation evidence when needed.
