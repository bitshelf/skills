# Worked output patterns

These examples are synthetic and illustrate output structure only.

## Load switch / enable

Connections:

```text
[OBSERVED] VCC_5V -> U1 pin 5 (IN)
[OBSERVED] CTRL -> R1 22R -> EN_NODE
[OBSERVED] EN_NODE -> R2 10K -> GND
[OBSERVED] EN_NODE -> U1 pin 4 (EN)
[OBSERVED] U1 pin 1 (VOUT) -> VBUS_OUT
[OBSERVED] VBUS_OUT -> C1 10uF -> GND
```

Terminal diagram:

```text
VCC_5V ───────────────────────> 5 IN
                                ┌─────────────────┐
CTRL ── R1 22R ──┬───────────>│4 EN       OUT 1 ├──────┬──> VBUS_OUT
                 │              │ U1              │      │
               R2 10K           │             GND 2├─>GND C1 10uF
                 │              └─────────────────┘      │
                GND                                      GND
```

## Differential pair with protection

Connections:

```text
[OBSERVED] SOC_TX_P -> C10 -> CONN_TX_P
[OBSERVED] SOC_TX_N -> C11 -> CONN_TX_N
[OBSERVED] CONN_TX_P -> ESD array channel 1 -> GND reference
[OBSERVED] CONN_TX_N -> ESD array channel 2 -> GND reference
```

Prefer two blocks if showing the ESD inline would make the pair ambiguous:

```text
[TX pair]
SOC_TX_P ── C10 ──> CONN_TX_P
SOC_TX_N ── C11 ──> CONN_TX_N

[Protection]
CONN_TX_P ──> ESD ch1 ──> GND
CONN_TX_N ──> ESD ch2 ──> GND
```

## Source wording

Good:

> Observed: `CTRL` passes through `R1` to U1 `EN`, and the same node has `R2` to GND.  
> Inferred: whether CTRL must be high or low to enable U1 requires the EN truth table if it is not shown on the schematic.

Avoid:

> `CTRL` is clearly an active-high enable because the net is named CTRL.
