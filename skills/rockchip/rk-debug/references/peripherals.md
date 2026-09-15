# Peripheral Diagnosis

Start with passive runtime evidence on the verified target:

```sh
cat /proc/device-tree/model
uname -a
ip -br address
ls /sys/bus/i2c/devices
cat /sys/kernel/debug/gpio
cat /sys/kernel/debug/regulator/regulator_summary
```

Debugfs files depend on kernel configuration and mount state; missing files are not proof of absent hardware. Inspect the running DT, driver binding, kernel config, and probe logs before changing registers or rebuilding.

## I2C, GPIO, and power

Map Linux I2C adapter numbers through sysfs/of_node and DT aliases. Bus numbers and addresses in board notes are examples, not defaults. Enumerate bound devices and driver-exposed attributes first. Broad `i2cdetect`/`i2cdump` operations generate bus transactions; choose a known bus/device and a datasheet-supported operation when probing is necessary. Avoid forced access to a bound device.

Check regulator enable state, supply relationships, pinmux, reset polarity, and probe errors. Consult available schematics/datasheets when wiring or register semantics matters; request missing documentation only when it blocks the next diagnostic step. Do not unbind drivers, instantiate devices, or change power settings as routine discovery.

## Switch and PTP

Discover actual network interfaces and bound drivers before using board-specific names such as `lan1`. Compare link state, counters, DT status, and probe logs. Use `ethtool <iface>`, `ethtool -S <iface>`, and `ethtool -T <iface>` as supported.

Map `/sys/class/ptp/ptp*/clock_name` to the intended device before checking its PHC. Clock reads and capability checks are distinct from `phc_ctl set` or frequency changes, which alter clock state and can disturb running synchronization. Match testing to the requested diagnosis.

If a DT change is absent at runtime, verify which DTB/resource artifact the boot path loaded before concluding the driver is broken.
