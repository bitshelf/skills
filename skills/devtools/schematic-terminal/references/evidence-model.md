# Evidence model for schematic reading

## Evidence priority

For connectivity questions, prefer:

1. visual geometry of the original image or rendered PDF page;
2. exact visible labels/pin numbers/component values;
3. embedded PDF text for page location or spelling confirmation;
4. datasheet/manual evidence for behavior beyond what the schematic proves;
5. OCR only when direct reading/text extraction is insufficient.

Never let extracted text override visible wire geometry.

## Image route

For a native image:

1. inspect the original at whole-image scale;
2. identify the target block and any wires leaving it;
3. zoom/crop around small pin labels, junction dots, suffixes, or dense protection arrays;
4. re-check a wider region before closing the trace.

Avoid unnecessary rescaling/re-encoding because small junction dots and one-character P/N suffixes are easy to blur.

## PDF route

### Page known

Inspect the page visually. If dense, render it at 240–320 DPI:

```bash
scripts/render_pdf_page.sh board.pdf 6 /tmp/board-p6.png 280
```

### Page unknown

Locate candidate pages by exact references/nets first:

```bash
scripts/locate_pdf.sh board.pdf 'USB2_OTG0_VBUSDET|USB3_OTG0|GPIO0_D3_d'
```

Then inspect candidate page images. A text hit only proves that the string is present on that page.

### Scanned PDF

If `pdftotext` produces little/no useful text, render page thumbnails/pages and locate the circuit visually.

## Global → local → global pass

Use three visual scales:

1. **global** — sheet title, functional regions, off-page labels;
2. **local** — exact components, wires, junctions, pins;
3. **global again** — confirm where lines/net labels leaving the crop continue.

This second global pass prevents false conclusions from a crop that hides a branch or net label.

## Evidence classes

Use these concepts internally:

- `OBSERVED`: wire/symbol/pin relation directly visible.
- `LABEL-LINKED`: same explicit global/off-page net name connects distant regions.
- `INFERRED`: functional behavior derived from circuit topology or a verified datasheet.
- `UNKNOWN`: insufficient visual/source evidence.

Do not promote `INFERRED` to `OBSERVED` in the final answer.

## Common multimodal failure modes

Watch specifically for:

- mistaking a crossing for a junction;
- reading pin number from a neighboring pin;
- dropping `_N`, `_L`, `P`, or `N` suffixes;
- confusing resistor/0R/common-mode choke placement;
- interpreting ESD arrays as series devices when they are shunt/protection paths;
- following text proximity instead of the wire;
- confusing repeated/global net labels with independent local labels;
- missing a branch because the crop is too tight.

## Confidence language

Visible fact:

> 原理图显示 U13 pin 4 (EN) 连接到该控制节点。

Inference:

> 如果 ETA6027 的 EN 为高有效，则该节点为低时输出会关闭；EN 极性应再由器件 datasheet 确认。

Unknown:

> 仅凭该页无法确认 GPIO 当前运行时电平，需要设备树/驱动状态或实测电压。
