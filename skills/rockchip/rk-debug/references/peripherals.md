# 外设诊断

先在已核实 DUT 上收集被动运行证据：

```sh
cat /proc/device-tree/model
uname -a
ip -br address
ls /sys/bus/i2c/devices
cat /sys/kernel/debug/gpio
cat /sys/kernel/debug/regulator/regulator_summary
```

debugfs 文件取决于内核配置及挂载，缺失不证明硬件不存在。写寄存器或重编译前检查运行设备树、驱动绑定、内核配置及 probe 日志。

## I2C、GPIO 与电源

用 sysfs/of_node 和 DT alias 映射 Linux I2C 编号，板级笔记中的总线和地址只是案例。先枚举已绑定设备和驱动属性。`i2cdetect`/`i2cdump` 会发起总线事务，确有需要时选定总线/设备并按数据手册操作，不强制访问已绑定设备。

IMA 的 Rockchip I2C 指南区分 `i2c-rk3x.c` 与旧 `i2c-rockchip.c`；先按当前芯片和内核确认驱动及对应 DTS 绑定，不能把一套配置用于全部版本。

检查 regulator 使能、供电依赖、pinmux、复位极性和 probe 错误。涉及接线/寄存器语义时查原理图、手册；仅在阻碍下一诊断步骤时请求补充资料。不把解绑驱动、动态创建设备或改电源当普通探测。

## 交换机和 PTP

先枚举实际网卡和驱动，不套用 `lan1`。比较链路、计数器、DT 状态及日志，按支持情况用 `ethtool <iface>`、`ethtool -S <iface>`、`ethtool -T <iface>`。

通过 `/sys/class/ptp/ptp*/clock_name` 确定目标 PHC。时钟读取/能力检查与 `phc_ctl set`、调频不同，后者会改变时钟并干扰同步；按诊断请求选择测试。

DT 修改未在运行时出现时，先验证启动路径实际加载的 DTB/resource，再判断驱动。
