# AGENTS.md

This repo hosts embedded-development agent skills, one directory per skill
under `skills/<category>/<name>/` (categories: `rockchip`, `allwinner`,
`devtools`).

## Conventions

- Every skill has `SKILL.md` with frontmatter `name` + `description` (extra
  fields such as `license`/`metadata` are allowed). Supporting files live in
  `references/` (deep-dive docs loaded on demand), `scripts/` (executable
  helpers, keep the executable bit), `assets/` (config templates, may be
  dotfiles).
- Skills are self-contained. Reference another skill by name only ("use the
  `rk-build` skill") — never by a relative path across skill directories, and
  never assume sibling layout.
- No SoC or board-model hard binding inside skills. Enumerate supported
  chips/boards from the checkout at runtime, parameterize per-board values
  (`<bus>`, `<controller>`, …), and teach resolution from the running system.
  Board-specific case notes (I2C maps, DTS chains, onboard parts) belong in
  the repo-root `boards/` directory, never inside a skill.
- Keep SKILL.md bodies harness-neutral: no `${CLAUDE_SKILL_DIR}`, no
  client-specific tool names. Harness-specific setup belongs in the setup
  scripts and must degrade gracefully when the harness is absent (see
  `skills/devtools/semcode/setup-semcode.sh`).
- Supported harnesses and their discovery paths are documented in
  [README.md](README.md) and encoded in `install.sh`. `npx skills` is the
  preferred install path once the repo is on GitHub; `install.sh` covers
  offline use and project-scoped profiles (`linux` / `android` / `allwinner`).

## Useful commands

```bash
./install.sh --list                          # inventory: skills, profiles, harnesses
./install.sh --project . --profile linux     # install into this project (copy mode)
./install.sh --uninstall --project .         # remove what install.sh put down
```

Technical claims in skill content (build commands, upgrade_tool operations,
register maps, board data) are audited against the IMA knowledge base;
`docs/review-report.md` records the verdicts. Re-check and update the report
whenever you change such claims.
