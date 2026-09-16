# AOSP 来源索引

按问题选择入口并核对发布版本。链接不能代替阅读原文；页面迁移时按标题和子系统搜索官方域名。

| 问题 | 入口 | 核对内容 |
|---|---|---|
| 环境、lunch、构建 | [构建 Android](https://source.android.com/docs/setup/build/building) | 当前分支的目标语法与环境 |
| Manifest 与源码下载 | [下载源码](https://source.android.com/docs/setup/download) | 所选分支/tag 和 manifest，不隐式修改已有源码树 |
| 发布身份 | [源码 tag 和构建号](https://source.android.com/docs/setup/reference/build-numbers) | 版本、tag、构建号对应关系 |
| Soong 与 Android.bp | [构建概览](https://source.android.com/docs/setup/build) 及当前分支 `build/soong` 源码 | 该版本支持的模块类型/属性 |
| Framework、Binder、服务 | [架构](https://source.android.com/docs/core/architecture) | 平台约定与 frameworks 实现的区别 |
| HAL 接口 | [AIDL HALs](https://source.android.com/docs/core/architecture/aidl/aidl-hals) | 接口稳定性、版本与设备兼容性 |
| 内核构建 | [构建内核](https://source.android.com/docs/setup/build/building-kernels) | 匹配的内核分支及构建系统 |
| GKI | [通用内核镜像](https://source.android.com/docs/core/architecture/kernel/generic-kernel-image) | 对所选设备及内核的适用条件 |
| SELinux | [SELinux](https://source.android.com/docs/security/features/selinux) | 策略归属、拒绝上下文及版本限制 |
| 安全修复 | [安全公告](https://source.android.com/docs/security/bulletin) | 受影响版本、补丁级别和对应修复 |
| 兼容性要求 | [CDD](https://source.android.com/docs/compatibility/cdd) | 对应版本的规范条件 |
| 兼容性测试 | [CTS](https://source.android.com/docs/compatibility/cts), [VTS](https://source.android.com/docs/core/tests/vts) | 适用测试集、版本及证据 |
| 虚拟平台 | [Cuttlefish](https://source.android.com/docs/devices/cuttlefish) | 主机条件及分支匹配产物 |


音频、相机、图形、电源、OTA、车载等使用 `site:source.android.com <subsystem> <version> <question>` 检索。

精确行为查 [AOSP Git 仓库](https://android.googlesource.com/) 或 [Android Code Search](https://cs.android.com/) 对应版本。常用路径包括 `build/make`、`build/soong`、`frameworks/base`、`frameworks/native`、`hardware/interfaces`、`system/sepolicy`；厂商改动按本地 manifest 定位。

邮件讨论可提供线索和动机，但不是规范或已发布证据，应追溯到相关版本的文档、源码或已合入改动。
