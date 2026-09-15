# Kernel clangd Setup

Use only when source navigation is requested. Locate the actual kernel source and object output directories, including out-of-tree builds.

After a successful kernel compilation produces `.cmd` files, inspect the local `scripts/clang-tools/gen_compile_commands.py --help`. Use that script with the actual object directory to generate `compile_commands.json`; available options depend on the kernel version.

Preserve an existing `.clangd`. Set the target architecture to match the selected toolchain and remove only GCC flags that the installed clangd demonstrably rejects. Do not blanket-suppress driver diagnostics or overwrite project settings with a generic configuration.

Run `clangd --check=<changed-source-file>` using the generated compilation database. Distinguish compilation-database failures from real source errors. Use an available semantic index for cross-file call chains when useful; it is not required for ordinary builds.
