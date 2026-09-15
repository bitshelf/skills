---
name: schematic-terminal
description: Read electronic schematics from images or PDFs with multimodal vision, reconstruct evidence-backed electrical connectivity, and redraw the requested circuit as a clear Unicode terminal diagram. Use for schematic tracing, power/reset/enable analysis, USB/PCIe/HDMI/MIPI/SD/eMMC paths, component/net lookup, and image/PDF-to-text schematic conversion.
---

# Schematic Terminal

Read the schematic visually, reconstruct only the connectivity supported by evidence, then render the requested part as a compact terminal diagram.

**User instructions override this skill.** If the user asks for a different scope or output, follow the user while preserving electrical accuracy and clearly marking uncertainty.

## Inputs

Treat both as first-class inputs:

- images: PNG, JPEG/JPG, WebP, screenshots, exported schematic regions;
- PDFs: vector/native PDFs, scanned PDFs, multi-page board schematics.

Optional targeting hints include page/sheet, component reference, net name, connector, subsystem, or an engineering question. Do not require all of them.

## Read these references only when needed

- `references/evidence-model.md` — image/PDF routing, zoom strategy, evidence levels, uncertainty.
- `references/terminal-golden-rules.md` — terminal drawing and validation rules.
- `references/interface-checklists.md` — USB, PCIe, HDMI/eDP/DP, MIPI, SD/eMMC, Ethernet checks.
- `references/examples.md` — worked output patterns.
- `references/sources.md` — OpenAI and community design references.

## Workflow

### 1. Locate the target

**Image:** inspect the original image directly with multimodal vision. Start wide enough to identify the block and any wires leaving it.

**PDF, page known:** inspect the requested page visually. If labels/pins/junctions are small, render the page at 240–320 DPI.

**PDF, page unknown:** use embedded text only to locate candidate pages, then visually inspect the page. When local shell tools are available:

```bash
scripts/locate_pdf.sh board.pdf 'SDMMC0_PWREN_H|VCC3V3_SD|U52'
scripts/render_pdf_page.sh board.pdf 6 /tmp/board-p6.png 280
```

Do not treat PDF text extraction or OCR order as proof of connectivity.

### 2. Perform a global → local → global visual pass

1. Whole sheet/image: identify subsystem boundaries and off-page/global net labels.
2. Local crop/zoom: read pin numbers, pin names, component values, net labels, junction dots, and symbol orientation.
3. Wider re-check: verify every connection that leaves the local region.

For dense differential interfaces, inspect each lane independently.

### 3. Build an evidence-backed connection ledger

Before drawing, create an internal ledger. Each connection should be one of:

- **OBSERVED** — directly visible topology;
- **LABEL-LINKED** — same explicit net label joins distant points;
- **INFERRED** — behavior derived from the topology or datasheet, not directly drawn;
- **UNKNOWN** — evidence is insufficient.

Example:

```text
[OBSERVED] VDD_5V -> U34 pin 5 (IN)
[OBSERVED] GPIO0_D3_d -> R274 22R -> EN_NODE
[OBSERVED] EN_NODE -> R275 10K -> GND
[OBSERVED] EN_NODE -> U34 pin 4 (EN)
[OBSERVED] U34 pin 1 (VOUT) -> USB_VBUS
```

The final diagram must not contain electrical connections that are absent from the ledger.

### 4. Trace topology, not text proximity

Use visual geometry to decide connectivity:

- continuous wire = same local net;
- explicit junction/T-connection = connected;
- crossing without junction = not connected unless the source notation explicitly indicates otherwise;
- identical explicit net labels may join distant points;
- preserve active-low suffixes exactly (`_N`, `_L`, `#`, `/EN`);
- preserve differential polarity exactly (`P/N`, `TXP/TXN`, `RXP/RXN`);
- distinguish series parts from shunt-to-ground protection or bypass parts;
- do not invent “typical” connections that are not shown.

### 5. Verify twice

Trace requested paths in both directions:

```text
source -> destination
destination -> source
```

Then check:

- every branch and junction;
- IC pin number/name association;
- series vs parallel placement;
- differential-pair P/N polarity;
- active-low notation;
- off-page/global net links;
- whether a protection device is series, shunt, or multi-line array.

If any small dot, pin label, or suffix is ambiguous, zoom again instead of guessing.

### 6. Draw from the ledger

Follow `references/terminal-golden-rules.md`.

Prefer:

- main signal/power flow left to right;
- pull-ups/pull-downs/decoupling/protection as vertical branches;
- ICs/connectors as boxes when multiple pins matter;
- exact schematic identifiers and values;
- several small diagrams for complex interfaces rather than one tangled 180-column drawing.

For example, split USB3 into:

```text
VBUS / enable
USB2 D+ / D-
USB3 TX differential pair
USB3 RX differential pair
ESD / common-mode / AC-coupling details
```

### 7. Validate the terminal rendering

The **connection ledger is the electrical specification**; the terminal drawing is only a representation.

When a diagram is non-trivial, run:

```bash
python3 scripts/validate_terminal_diagram.py diagram.txt
python3 scripts/preview_terminal.py diagram.txt /tmp/diagram.html
```

`validate_terminal_diagram.py` is only a presentation linter. It cannot prove electrical correctness. Re-trace the rendered diagram against the ledger after linting.

### 8. Answer the engineering question

Separate evidence from reasoning:

- **Observed:** directly visible in the schematic.
- **Inferred:** electrical behavior derived from the observed circuit or a verified datasheet.
- **Unknown:** requires another sheet, datasheet, board measurement, or software/runtime state.

Do not claim a signal is high/low from its name alone. Do not claim “EN 没高电平 = 没供电” until the enable polarity, pull network, default state, and device truth table are verified.

## Default output

Unless the user asks otherwise:

1. short conclusion;
2. source location: image name, or PDF page/sheet;
3. `Connections` ledger for non-trivial circuits;
4. fenced `text` terminal diagram;
5. brief operation explanation;
6. uncertainty/next evidence only when needed.

When the user writes Chinese, answer in Chinese while preserving net names, reference designators, pin names, and part numbers exactly.

## Hard reliability rules

- Never reconstruct connectivity from OCR/extracted-text order alone.
- Never merge nearby wires because they look close.
- Never silently “correct” an unusual value, reference, or net name.
- Never lose a `_N`, `_L`, `#`, `P`, or `N` suffix.
- Never represent a shunt component as series, or a series component as shunt.
- Never introduce a junction in the terminal drawing that is not in the ledger.
- If only PDF/image evidence exists, call the result a visual reconstruction, not netlist-equivalent proof.
- If two readings remain plausible, state both and identify exactly what visual detail is unresolved.
