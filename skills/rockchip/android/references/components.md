# Native Components and Packaging

## Kernel and U-Boot

Read the selected product's kernel version, source/output directories, defconfig/fragments, DT selection, toolchain, and vendor wrapper. Use the wrapper that supplies those values. Direct component commands are appropriate only when the local workflow supports them and their required arguments are established.

Do not assume all Android kernels use the same Clang revision, all trees support `make compile_commands.json`, or every board's kernel build produces a complete boot image. Preserve persistent kernel configuration in the defconfig/fragments actually consumed by the SDK; `savedefconfig` output alone may not update them.

For requested clangd support, inspect the kernel's compilation-database targets or `scripts/clang-tools/gen_compile_commands.py --help`, and use the actual object output directory. Preserve existing `.clangd` settings and check a relevant source file; avoid blanket diagnostic suppression.

## Bundled kernel helper

Keep [scripts/kernel.sh](../scripts/kernel.sh) available for the Rockchip Android fast-build workflow. Run it from the SDK root, or copy it there when the requested workflow needs a local helper and no project copy exists. Do not overwrite an existing project script.

| Argument | Operation |
|---|---|
| No argument | Build the configured kernel/DT image |
| `uboot` | Build U-Boot |
| `menuconfig` | Open kernel configuration and generate savedefconfig |
| `compile_commands` | Generate the kernel compilation database |

This helper targets a particular SDK layout. Before execution, verify its Clang path, architecture, product variables, kernel directory, and image destination against this checkout. Establish the requested lunch target explicitly in the same shell before invoking it; do not rely on its first-output-directory fallback. If those assumptions do not match, adapt the project copy or use the SDK wrapper.

The U-Boot branch performs clean/mrproper/distclean, so inspect local configuration and confirm that cleanup fits the requested build before using that mode. The script can mask a failed build with a later successful command; check compiler output and artifact freshness rather than treating its final exit status alone as success. These are existing helper limitations, not requirements for other build workflows.

## Android modules

After setup and lunch in the same shell, use a module name declared by the tree with `m`, or a supported directory-build helper such as `mmm`. Verify helper availability in this branch. Choose focused tests appropriate to the changed behavior, and distinguish compilation from deployment and execution.

## Firmware packaging

Inspect the SDK's wrapper and packaging scripts to determine component dependencies, source image paths, output paths, and signing steps. Flags such as `./build.sh -A -u` are examples from some Rockchip SDKs, not a portable command contract. Check whether a wrapper performs `installclean` or rebuilds components before using it for an incremental request.

Use the resolved product output and inspect `rockdev` links if this SDK uses them. Check that the packaged inputs belong to the selected product/variant and current build. Android boot layouts vary: account for the board's boot/vendor_boot/init_boot/DTBO images, AVB metadata, dynamic partitions, and slots only where applicable. Do not infer that a kernel change can always be deployed by writing boot alone.

Only create `update.img`, OTA packages, or target-files archives when requested or needed by the established delivery workflow. Preserve the project's keys and signing configuration; a build issue does not justify disabling verification or changing keys.

## Failure handling

Read the wrapper exit status and its referenced logs. If a pipeline or helper reports success despite a failed compiler command, diagnose that failure before packaging. Preserve useful intermediates and logs; clean only the affected output when evidence supports stale state. Do not retry a full build repeatedly without addressing the observed failure.

Official background, interpreted for the checkout's version:

- [Build Android](https://source.android.com/docs/setup/build/building)
- [Build kernels](https://source.android.com/docs/setup/build/building-kernels)
