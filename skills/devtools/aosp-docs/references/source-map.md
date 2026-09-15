# AOSP Source Map

Choose the relevant area and verify the page's release applicability. URLs are entry points, not a substitute for reading the supporting page. If a page moves, search its title and subsystem on the official domain.

| Question | Starting source | What to establish |
|---|---|---|
| Setup, lunch, build | [Build Android](https://source.android.com/docs/setup/build/building) | Branch-supported target syntax and environment |
| Manifest and source download | [Download source](https://source.android.com/docs/setup/download) | Requested branch/tag and manifest; avoid changing an existing checkout implicitly |
| Release identity | [Source code tags and builds](https://source.android.com/docs/setup/reference/build-numbers) | Release/tag/build correspondence |
| Soong and Android.bp | [Build overview](https://source.android.com/docs/setup/build) and the branch's `build/soong` source | Supported module types/properties in this revision |
| Framework, Binder, services | [Architecture](https://source.android.com/docs/core/architecture) | Platform contract versus implementation in `frameworks/base` or `frameworks/native` |
| HAL interfaces | [AIDL HALs](https://source.android.com/docs/core/architecture/aidl/aidl-hals) | Interface stability, versioning, and device compatibility |
| Kernel builds | [Build kernels](https://source.android.com/docs/setup/build/building-kernels) | Matching kernel branch and build system |
| GKI | [Generic Kernel Image](https://source.android.com/docs/core/architecture/kernel/generic-kernel-image) | Applicability to the selected device and kernel |
| SELinux | [SELinux](https://source.android.com/docs/security/features/selinux) | Policy ownership, denial context, and release constraints |
| Security fixes | [Security bulletins](https://source.android.com/docs/security/bulletin) | Affected versions, patch level, and linked fixes |
| Compatibility requirements | [CDD](https://source.android.com/docs/compatibility/cdd) | Release-specific normative conditions |
| Compatibility testing | [CTS](https://source.android.com/docs/compatibility/cts), [VTS](https://source.android.com/docs/core/tests/vts) | Applicable suite/version and test evidence |
| Virtual platform | [Cuttlefish](https://source.android.com/docs/devices/cuttlefish) | Host requirements and branch-matched artifacts |

For audio, camera, graphics, power, OTA, automotive, and other subsystems, search `site:source.android.com <subsystem> <version> <question>` rather than maintaining a full site mirror here.

For exact behavior, use [AOSP Git repositories](https://android.googlesource.com/) or [Android Code Search](https://cs.android.com/), selecting the appropriate revision. Useful paths include `build/make`, `build/soong`, `frameworks/base`, `frameworks/native`, `hardware/interfaces`, and `system/sepolicy`; vendor changes may live elsewhere in the local manifest.

Platform mailing-list discussions can provide rationale or leads, but do not treat them as normative requirements or evidence that a change shipped. Trace claims to documentation, source, or a merged change for the relevant release.
