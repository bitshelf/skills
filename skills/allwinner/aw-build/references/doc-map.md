# SDK Documentation Map

All paths are relative to the SDK's `docs/` directory (complete inventory:
`docs/docs_list.txt`; version history: `docs/AIOT_Linux_SDK_Note.md`).
Chip-specific hardware docs (datasheet, user manual, pinout, schematic
checklists) live under `docs/<chip>/`.

| Question area | Read |
|---|---|
| SDK layout, environment setup, build/pack/flash, FAQ | `Software 软件类文档/基础组件开发指南/AW_AIOT_Linux_Software_Development_Guide_CN.pdf` |
| Tina 5.0 system software architecture | `Software 软件类文档/基础组件开发指南/Allwinner_Developer_Guide_Tina5.0_Linux_zh.pdf` |
| Packing internals (sys_partition.fex, update_mbr, boot_package) | `Software 软件类文档/基础组件开发指南/Sundry/Tina_Linux_打包流程_使用指南.pdf` |
| Storage / partitioning | `…/Sundry/Tina_Linux_存储_开发指南.pdf` |
| System tailoring (buildroot package trimming) | `…/Sundry/Tina_Linux_系统裁剪_开发指南.pdf` |
| sys_config / configuration system | `…/Sundry/Tina_Linux_配置_开发指南.pdf` |
| syslog | `…/Sundry/Tina_Linux_syslog_使用指南.pdf` |
| Buildroot usage | `…/Buildroot/Tina_Linux_buildroot_使用指南.pdf` |
| Debian / Docker on Debian | `…/Debian/AW_AIOT_Linux_debian_开发指南.pdf`, `AW_Developer_Guide_Debian_Docker_CN.pdf` |
| OTA / recovery | `…/Recovery/Tina_Linux_OTA_开发指南.pdf` |
| Secure boot / security | `…/SECURE/Tina_Linux_安全_开发指南.pdf`, `Linux_安全_开发指南.pdf` |
| Wi-Fi / BT porting and debugging | `…/Wifibt/Tina_Linux_Wi-Fi_开发指南.pdf` etc. |
| Camera, graphics, multimedia, ROS2 | `…/Camera/`, `…/Graphics/`, `…/Multimedia/`, `…/ROS2/` |
| U-Boot development | `Software 软件类文档/SDK模块开发指南/UBOOT/Allwinner_Developer_Guide_U-Boot_zh.pdf` |
| Peripheral / module drivers (TWI, UART, GPIO, PWM, DMA, CCU, PMIC, NAND/NOR, USB, thermal, standby, AMP…) | `Software 软件类文档/SDK模块开发指南/<subsystem>/` (one guide per module) |
| Device tree usage | `…/SDK模块开发指南/Others/Linux_Device_Tree_使用指南.pdf` |
| NPU toolchain and deployment | `…/SDK模块开发指南/NPU模块开发指南/` |
| Crash / hang analysis | `Product 量产指导文档/产线指南/Crashdump_使用指南.pdf` |
| Production-line issue triage (display, IO, interfaces, stability, security) | `Product 量产指导文档/产线指南/*_排查指南.pdf` |
| Flashing / mass-production tools (APST, 量产工具中心) | `Tools工具类文档/全志工具包介绍.pdf`, `全志量产工具中心_使用指南.pdf`; offline burning: `…/MMC/Allwinner_Developer_Guide_Linux_MMC_Offline_Programming_zh.pdf` |

`…` = `Software 软件类文档/基础组件开发指南`. When a doc references another
guide by 《title》, locate it with `find docs -name "<title>*.pdf"` rather than
guessing the path.
