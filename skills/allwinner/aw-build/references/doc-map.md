# SDK 文档索引

以下路径相对 SDK 的 `docs/`。先核对当前版本目录；完整清单可能在 `docs/docs_list.txt`，版本记录可能在 `docs/AIOT_Linux_SDK_Note.md`。芯片硬件资料通常位于 `docs/<chip>/`。

| 问题领域 | 阅读资料 |
|---|---|
| SDK 布局、环境、构建/打包/烧写、常见问题 | `Software 软件类文档/基础组件开发指南/AW_AIOT_Linux_Software_Development_Guide_CN.pdf` |
| Tina 5.0 系统软件架构 | `Software 软件类文档/基础组件开发指南/Allwinner_Developer_Guide_Tina5.0_Linux_zh.pdf` |
| 打包内部流程（sys_partition.fex、update_mbr、boot_package） | `Software 软件类文档/基础组件开发指南/Sundry/Tina_Linux_打包流程_使用指南.pdf` |
| 存储与分区 | `…/Sundry/Tina_Linux_存储_开发指南.pdf` |
| 系统裁剪（Buildroot 包） | `…/Sundry/Tina_Linux_系统裁剪_开发指南.pdf` |
| sys_config 与配置系统 | `…/Sundry/Tina_Linux_配置_开发指南.pdf` |
| syslog | `…/Sundry/Tina_Linux_syslog_使用指南.pdf` |
| Buildroot 使用 | `…/Buildroot/Tina_Linux_buildroot_使用指南.pdf` |
| Debian 与 Docker | `…/Debian/AW_AIOT_Linux_debian_开发指南.pdf`, `AW_Developer_Guide_Debian_Docker_CN.pdf` |
| OTA 与恢复 | `…/Recovery/Tina_Linux_OTA_开发指南.pdf` |
| 安全启动与安全机制 | `…/SECURE/Tina_Linux_安全_开发指南.pdf`, `Linux_安全_开发指南.pdf` |
| Wi-Fi/蓝牙移植与调试 | `…/Wifibt/Tina_Linux_Wi-Fi_开发指南.pdf` 等 |
| 相机、图形、多媒体、ROS2 | `…/Camera/`, `…/Graphics/`, `…/Multimedia/`, `…/ROS2/` |
| U-Boot 开发 | `Software 软件类文档/SDK模块开发指南/UBOOT/Allwinner_Developer_Guide_U-Boot_zh.pdf` |
| 外设/模块驱动（TWI、UART、GPIO、PWM、DMA、CCU、PMIC、NAND/NOR、USB、温控、待机、AMP 等） | `Software 软件类文档/SDK模块开发指南/<subsystem>/` （按模块查阅） |
| 设备树使用 | `…/SDK模块开发指南/Others/Linux_Device_Tree_使用指南.pdf` |
| NPU 工具链与部署 | `…/SDK模块开发指南/NPU模块开发指南/` |
| 崩溃与卡死分析 | `Product 量产指导文档/产线指南/Crashdump_使用指南.pdf` |
| 产线排查（显示、IO、接口、稳定性、安全） | `Product 量产指导文档/产线指南/*_排查指南.pdf` |
| 烧写/量产工具（APST、量产工具中心） | `Tools工具类文档/全志工具包介绍.pdf`, `全志量产工具中心_使用指南.pdf`; 离线烧录： `…/MMC/Allwinner_Developer_Guide_Linux_MMC_Offline_Programming_zh.pdf` |


`…` 表示 `Software 软件类文档/基础组件开发指南`。SDK 模块开发指南相关行应从 `Software 软件类文档/SDK模块开发指南/` 查找。路径只是定位线索，使用 `rg --files docs` 按文档标题查实际路径，不机械拼接省略号。
