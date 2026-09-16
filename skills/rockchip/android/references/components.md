# 原生组件与打包

## 内核和 U-Boot

确认已选产品的内核版本、源码/输出目录、defconfig/fragment、设备树、工具链及厂商构建入口。优先使用提供这些参数的封装脚本，仅在本地流程支持且参数已明确时直接构建组件。

不要假设所有 Android 内核使用同一 Clang、都支持 `make compile_commands.json`，或每次内核编译都会生成完整启动镜像。持久配置应写入 SDK 实际消费的 defconfig/fragment，单独生成 `savedefconfig` 未必更新这些文件。

请求 clangd 支持时检查内核编译数据库目标或 `scripts/clang-tools/gen_compile_commands.py --help`，使用实际对象输出目录。保留已有 `.clangd`，检查相关源文件，不批量压制诊断。

<a id="bundled-kernel-helper"></a>
## 随附内核助手

保留 [scripts/kernel.sh](../scripts/kernel.sh)。从 SDK 根目录运行；需要项目副本且尚不存在时可复制到根目录，不覆盖已有定制。

| 参数 | 操作 |
|---|---|
| 无参数 | 构建配置的内核/设备树镜像 |
| `uboot` | 构建 U-Boot |
| `menuconfig` | 配置内核并生成 savedefconfig |
| `compile_commands` | 生成内核编译数据库 |

脚本面向特定 SDK 布局。执行前核对 Clang 路径、架构、产品变量、内核目录和镜像目标位置。在同一 shell 明确完成所选目标的 lunch，不依赖首个输出目录回退逻辑。假设不匹配时适配项目副本或使用 SDK 入口。

U-Boot 分支会执行 clean/mrproper/distclean，使用前检查本地配置和清理范围。后续成功命令可能掩盖早先构建失败，应检查编译输出及产物新旧，不能仅看最终退出码。这些是现有助手的限制，不是其他构建流程的要求。

## Android 模块

在同一 shell 初始化和 lunch 后，对源码声明的模块使用 `m` 或本分支支持的 `mmm` 等目录构建助手。验证命令可用性，选择与行为变更相关的测试，区分编译、部署与执行。

## 固件打包

检查 SDK 脚本，确定组件依赖、输入/输出路径与签名步骤。`./build.sh -A -u` 只是部分 SDK 示例，不是通用接口。增量操作前确认脚本是否执行 `installclean` 或重建其他组件。

使用解析后的产品输出，SDK 使用 `rockdev` 时检查链接。所有输入应匹配所选产品、变体和本次构建。按设备实际情况考虑 boot/vendor_boot/init_boot/DTBO、AVB、动态分区和槽位；不能假设改内核只需写 boot。

仅在请求或交付流程需要时生成 `update.img`、OTA、target-files。保留项目签名密钥与校验配置，不以构建故障为由关闭验证或换钥。

## 失败处理

核对封装脚本退出码及其日志。即使助手返回成功，也应先解决日志中的编译失败再打包。保留有用中间产物，只在证据支持时清理受影响输出，不反复盲跑全量构建。

官方背景需结合当前版本解释：[Android 构建](https://source.android.com/docs/setup/build/building)、[内核构建](https://source.android.com/docs/setup/build/building-kernels)。
