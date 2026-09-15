# BQ25792 Charger Debug

> Custom-driver case notes for the TI BQ25792 charger, not tied to a specific SoC or board. Verify paths, bus numbering, register semantics, and electrical limits against the current board before using commands below.

Resolve `<controller>`/`<bus>` for this board from sysfs: `readlink /sys/class/i2c-adapter/i2c-<N>/of_node`, `ls /sys/bus/i2c/devices`, and the driver bind logs. `006b` is the BQ25792 7-bit address 0x6B.

## Quick Diagnostic Commands

```bash
# 1. Driver probe status
dmesg | grep -i bq257

# 2. Full register dump (v6 register map, 16-bit registers)
cat /sys/devices/platform/<controller>.i2c/i2c-<bus>/<bus>-006b/registers

# 3. Key status registers only
cat /sys/devices/platform/<controller>.i2c/i2c-<bus>/<bus>-006b/registers | \
    grep -E 'STAT0|STAT1|ICHG\(|IINDPM\(|IBAT_ADC|CTRL0|FAULT'
```

## Sysfs Control Interface

```bash
# Set charge current (uA) — controls ICHG register
echo 800000 > /sys/class/power_supply/bq25792-charger/constant_charge_current

# Set input current limit (uA) — controls IINDPM register
echo 1500000 > /sys/class/power_supply/bq25792-charger/input_current_limit

# Set input voltage limit (uV) — controls VINDPM register
echo 4200000 > /sys/class/power_supply/bq25792-charger/input_voltage_limit

# Read back
cat /sys/class/power_supply/bq25792-charger/current_max          # ICHG setting (uA)
cat /sys/class/power_supply/bq25792-charger/constant_charge_current # IBAT actual (uA)
cat /sys/class/power_supply/bq25792-charger/input_current_limit    # IINDPM (uA)
cat /sys/class/power_supply/bq25792-charger/voltage_max            # VREG (uV)
cat /sys/class/power_supply/bq25792-charger/status                 # Charging/Full/Not charging
cat /sys/class/power_supply/bq25792-charger/online                 # 1=power present
```

## Charging Anomaly Detection

Check these in order:

### Step 1: Verify driver probed
```bash
dmesg | grep bq257
# Expected: "hw_init v2: REG0F=0xa2" (EN_CHG=1, EN_HIZ=0)
```

### Step 2: Check STAT0 register — Power Good and VBUS
```bash
cat /sys/devices/platform/<controller>.i2c/i2c-<bus>/<bus>-006b/registers | grep STAT0
# STAT0=0x8f → PG=1, VBUS=1, AC present → power OK
# STAT0=0x07 → PG=0, VBUS=1 → chip fault, needs REG_RST or power cycle
```

### Step 3: Check STAT1 register — Charge state
```bash
cat /sys/devices/platform/<controller>.i2c/i2c-<bus>/<bus>-006b/registers | grep STAT1
# CHG_STAT=3 → Fast Charge (CC mode), normal
# CHG_STAT=0 → Not Charging (even with PG=1)
# CHG_STAT=7 → Charge complete / full
```

### Step 4: Compare ICHG setting vs IBAT actual
```bash
ICHG=$(cat /sys/class/power_supply/bq25792-charger/current_max)
IBAT=$(cat /sys/class/power_supply/bq25792-charger/constant_charge_current)
echo "ICHG=$ICHG uA, IBAT=$IBAT uA"
# IBAT << ICHG: input current limited by IINDPM or source capability
# IBAT ≈ ICHG: charging correctly
# IBAT = 0: not charging (check PG, CHG_STAT above)
```

### Step 5: Check for faults
```bash
cat /sys/devices/platform/<controller>.i2c/i2c-<bus>/<bus>-006b/registers | grep FAULT
# FAULT0=0x00 → no faults
# VBAT_OVP=1 → battery overvoltage
# IBAT_OCP=1 → battery overcurrent
```

## Common Issues

| Symptom | Check | Fix |
|---------|-------|-----|
| PG=0, VBUS=1, no faults | Chip in latched state | REG_RST (reg 0x09 bit6) or power cycle |
| PG=1, CHG_STAT=0 | Battery full or TS out of range | Check VBAT vs VREG, check TS pin |
| PG=1, CHG_STAT=3, IBAT near 0 | IINDPM too low for input | Raise input_current_limit via sysfs |
| IBAT << ICHG | Input current limited | Raise IINDPM to match charge current + system power |
| EN_CHG=0 or EN_HIZ=1 | Driver init failed | Re-probe driver |

## Driver Init Sequence (hw_init)

The driver writes registers in this order:
1. **REG_RST** (0x09 bit6) — reset all registers to defaults
2. **REG10** — disable watchdog
3. **REG14** — charger control 5 (EN_IBAT, EN_IINDPM, IBAT range)
4. **ICHG** (0x03) — charge current from DTS `ti,charge-current`
5. **VREG** (0x01) — charge voltage from DTS `ti,max-charge-voltage`
6. **VINDPM** (0x05) — input voltage from DTS `ti,minimum-sys-voltage`
7. **IINDPM** (0x06) — input current from DTS `ti,input-current-sdp`
8. **VOTG, IOTG** — OTG settings from DTS
9. **ADC** (0x2E, 0x2F, 0x30) — enable ADC
10. **CTRL0** (0x0F) — EN_CHG=1, clear HIZ and FORCE_IBATDIS

## BQ25792 Correct Register Map (v6 / Datasheet)

All register addresses are 8-bit I2C offsets. Multi-byte registers use big-endian byte order.

| Address | Name | Bits | Description |
|---------|------|------|-------------|
| 0x00 | VSYSMIN | 5:0 | Min system voltage (250mV step, 2.5V base) |
| 0x01 | VREG | 10:0 | Charge voltage limit (10mV step) |
| 0x03 | ICHG | 8:0 | Charge current limit (10mA step) |
| 0x05 | VINDPM | 7:0 | Input voltage limit (100mV step, 3.6V base) |
| 0x06 | IINDPM | 8:0 | Input current limit (10mA step) |
| 0x08 | IPRECHG | 5:0 | Precharge current (40mA step) |
| 0x09 | ITERM/REG_RST | 4:0/bit6 | Termination current / Register reset |
| 0x0A | VRECHG/CELL | 3:0/7:6 | Recharge offset / Cell count |
| 0x0B | VOTG | 10:0 | OTG voltage (10mV step) |
| 0x0D | IOTG | 6:0 | OTG current (40mA step) |
| 0x0F | CTRL0 | 7:0 | EN_CHG(5), EN_HIZ(2), EN_TERM(1), etc. |
| 0x10 | CTRL1 | 7:0 | WATCHDOG(2:0), EN_TIMER(7), etc. |
| 0x11 | CTRL2 | 7:0 | Input detection control |
| 0x12 | CTRL3 | 7:0 | EN_OTG(6), OTG control |
| 0x13 | CTRL4 | 7:0 | PWM_FREQ(5), STAT_DIS(4) |
| 0x14 | CTRL5 | 7:0 | EN_IBAT(5), EN_IINDPM(2), IBAT_REG(4:3) |
| 0x1B | STAT0 | 7:0 | PG_STAT(3), VBUS_PRESENT(0) |
| 0x1C | STAT1 | 7:5 | CHG_STAT(7:5), VBUS_STAT(4:1) |
| 0x20 | FAULT0 | 7:0 | VBUS_OVP(6), VBAT_OVP(5), IBUS_OCP(4), IBAT_OCP(3) |
| 0x21 | FAULT1 | 7:0 | VSYS_SHORT(7), VSYS_OVP(6), OTG_OVP(5) |
| 0x2E | ADC_CTRL | 7:0 | ADC_EN(7), ADC_RATE(6) |
| 0x2F | ADC_DIS0 | 7:0 | Per-channel ADC disable (0=enable) |
| 0x31 | IBUS_ADC | 15:0 | Input current ADC (1mA LSB) |
| 0x33 | IBAT_ADC | 15:0 | Battery current ADC (1mA LSB) |
| 0x35 | VBUS_ADC | 15:0 | Input voltage ADC (1mV LSB) |
| 0x3B | VBAT_ADC | 15:0 | Battery voltage ADC (1mV LSB) |
| 0x48 | PART_INFO | 5:3 | Part number (1=BQ25792) |

## Key Bit Definitions

### STAT0 (0x1B)
- bit 7: IINDPM_STAT — 1 = in input current regulation
- bit 6: VINDPM_STAT — 1 = in input voltage regulation
- bit 3: PG_STAT — 1 = power good
- bit 0: VBUS_PRESENT — 1 = VBUS detected

### STAT1 (0x1C)
- bits 7-5: CHG_STAT — 0=Not Charging, 1=Trickle, 2=Pre-charge, 3=Fast Charge, 4=Taper, 7=Full
- bits 4-1: VBUS_STAT — input source type

### CTRL0 (0x0F)
- bit 6: FORCE_IBATDIS — 1 = force battery discharge (disable charging)
- bit 5: EN_CHG — 1 = enable charging
- bit 2: EN_HIZ — 1 = high-impedance mode (disable converter)
- bit 1: EN_TERM — 1 = enable charge termination

## Big-Endian Byte Order

BQ25792 stores 16-bit registers in **big-endian** byte order:
- Lower I2C address = MSB (bits 15:8)
- Higher I2C address = LSB (bits 7:0)

The driver uses `cpu_to_be16()` for writes and `be16_to_cpu()` for reads to handle this.
