# 内核 clangd 配置

仅在请求源码导航时使用。定位真实内核源码和对象输出目录，包括树外构建。

成功编译生成 `.cmd` 文件后，查看本地 `scripts/clang-tools/gen_compile_commands.py --help`，按内核版本支持的参数及实际对象目录生成 `compile_commands.json`。

保留已有 `.clangd`，目标架构匹配工具链，只移除已证实不被当前 clangd 接受的 GCC 参数。不全面关闭驱动诊断或用通用配置覆盖项目设置。

使用编译数据库运行 `clangd --check=<changed-source-file>`，区分数据库问题和源码错误。跨文件调用链可用语义索引，但普通构建不以此为前提。
