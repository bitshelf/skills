# Interface-specific tracing checklists

These are tracing checklists, not electrical-design approval rules. Report only what the schematic shows; use datasheets/specifications for functional claims.

## USB 2.0 / USB 3.x

Trace separately:

- VBUS source, load switch/regulator, EN/OC pins, current-limit resistor, bulk/bypass capacitors;
- USB2 `D+` and `D-` including series resistors, common-mode choke, ESD;
- SuperSpeed TX pair and RX pair, preserving `P/N`;
- AC-coupling capacitors and which pair they are actually on;
- connector shield/shell and chassis/earth network separately from signal GND when shown;
- VBUS detect/ID/CC/control nets separately from the power rail.

Do not infer USB role (host/device/OTG) from a connector title alone if the control/ID/CC path is not established.

## PCIe

Trace separately:

- REFCLK `P/N`;
- TX `P/N` and RX `P/N`;
- `PERST#`, `CLKREQ#`, `WAKE#` or vendor-equivalent nets;
- AC-coupling capacitors and lane direction from source/endpoint labels;
- power rails and reset/power sequencing signals.

Do not infer negotiated link speed from the schematic.

## HDMI / eDP / DisplayPort

Keep high-speed lanes, AUX/DDC, HPD, CEC, and power/control paths separate. Preserve lane polarity and mux/alternate-function labels exactly.

## MIPI D-PHY / C-PHY

Trace clock/data/trio lanes independently. Preserve lane index and polarity. When SoC balls are multiplexed between D-PHY/C-PHY or CSI/DSI functions, keep the full visible signal name rather than shortening it to a guessed mode.

## SD / microSD / eMMC

Trace:

- card/device power rail (`VCC`/`VDD`);
- I/O rail (`VCCQ`, `VCCIO_*`) if present;
- `CLK`, `CMD`, data lines;
- card-detect/write-protect if present;
- power-enable/load-switch control (`PWREN`);
- pull-ups/pull-downs and series resistors;
- ESD/protection branches.

Do not equate SoC `PWREN` signal level with actual card supply until the load-switch enable polarity/default state is established.

## Ethernet / RGMII / RMII

Trace clock, MDIO/MDC, TX/RX data/control, PHY reset, PHY power rails, magnetics/connector, and reference-clock direction separately. Do not infer clock direction from a generic `REF_CLK` label alone when the PHY/SoC mode is configurable.

## Power / reset / enable chains

For any rail or reset question, identify:

```text
source rail -> switch/regulator -> output rail -> load
control source -> series/pull network -> EN/RESET pin
```

Then separately determine whether behavior is active-high/active-low from a verified part definition or datasheet.
