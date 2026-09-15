# Terminal diagram golden rules

The connection ledger is the specification. The diagram must satisfy the ledger, not the other way around.

## Core rules

1. Never create a line crossing that visually implies an unverified connection.
2. Never draw a wire through text, component names, values, or pin labels.
3. Use explicit junction characters only where the ledger says nets join.
4. Prefer Unicode box drawing: `┌ ┐ └ ┘ ├ ┤ ┬ ┴ ─ │`.
5. Do not use `+` as an electrical junction.
6. Keep vertical wires in exactly one text column; no “flying” or shifted bars.
7. Show shunt/parallel components as vertical branches when practical.
8. Show series components inline on the path.
9. Preserve exact net/reference/pin/value text from the source.
10. Split a complicated circuit into multiple named blocks instead of adding ambiguous crossings.
11. Re-trace every final route against the connection ledger.

## Main flow

Prefer left-to-right flow:

```text
SOURCE ── R12 22R ──> DEST
```

Use a vertical branch for a pull-down:

```text
CTRL ─────────┬────> EN(4)
              │
            R15 10K
              │
             GND
```

Use vertical branches for bypass capacitors:

```text
VOUT ─────────┬────────────> LOAD
              │
           C20 10uF
              │
             GND
```

## IC and connector boxes

When several pins matter:

```text
                    ┌────────────────────┐
VIN ───────────────>│ 5 IN         OUT 1 ├────> VOUT
EN_NODE ───────────>│ 4 EN        ILIM 3 ├─R7─> GND
GND ───────────────>│ 2 GND              │
                    │ U52  SGM2576        │
                    └────────────────────┘
```

Keep at least one space between text and box borders.

## Distant connections

Prefer exact net labels over long routes:

```text
BLOCK A                         BLOCK B
USB3_TX1_P ──> U33             USB3_TX1_P ──> SoC
```

This is safer than drawing a wire through unrelated blocks.

## Differential pairs

Keep P/N adjacent and preserve polarity:

```text
TX_P ── C1 ──> TX1_P
TX_N ── C2 ──> TX1_N
```

Do not swap vertical order merely for cosmetic symmetry if it risks hiding polarity.

## Protection devices

Make the topology explicit.

Series path:

```text
SIGNAL ── R 22R ──> CONNECTOR
```

Shunt ESD path:

```text
SIGNAL ───────────────> CONNECTOR
          │
        ESD
          │
         GND
```

Multi-line ESD arrays can be shown as a separate named block if an inline drawing becomes ambiguous.

## Dense interfaces

Split by function:

```text
[Power / enable]
[USB2 D+/D-]
[SuperSpeed TX]
[SuperSpeed RX]
[Protection]
```

A set of short diagrams is better than a single diagram that exceeds normal terminal width or introduces crossings.

## Validation pass

Check the final text for:

- false junctions;
- missed branches;
- wrong series/parallel representation;
- wrong pin number/name;
- lost active-low or differential suffix;
- line/text collisions;
- shifted vertical columns;
- component boxes whose borders touch content;
- routes that cannot be traced unambiguously.

The included linter catches presentation smells only. Visual/electrical validation still requires comparing the final diagram with the ledger.
