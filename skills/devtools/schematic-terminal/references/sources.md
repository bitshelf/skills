# Design references and provenance

This skill is independently written. The sources below informed its workflow and validation approach; community text is not vendored verbatim.

## OpenAI

- OpenAI API Skills: https://developers.openai.com/api/reference/python/resources/skills/methods/create
  - Current API accepts a skill directory upload or a ZIP archive.
- OpenAI Responses API: https://developers.openai.com/api/reference/cli/resources/responses/methods/create
  - Responses accept text, image, and file inputs.
- OpenAI model guidance: https://developers.openai.com/api/docs/guides/latest-model
  - Keep instruction priority explicit; user instructions take precedence over skill guidance.
- OpenAI Codex-capable model pages: https://developers.openai.com/api/docs/models/gpt-5.3-codex
  - Codex-family models support image input.

## Community

- Takazudo / claude-resources — `ascii-circuit-diagram-creator`
  https://github.com/Takazudo/claude-resources/tree/main/skills/ascii-circuit-diagram-creator
  - Design ideas adopted: connection-list-first workflow; Unicode box drawing; avoid ambiguous crossings; preview/re-trace the rendered monospaced diagram.

- Keitark / pcba-design-skills — `schematic-humanizer`
  https://github.com/Keitark/pcba-design-skills/tree/main/.agents/skills/schematic-humanizer
  - Design ideas adopted: distinguish visual readability from electrical proof; preserve source-of-truth evidence; inspect whole pages and dense crops; do not claim equivalence when only PDF/image evidence exists.
