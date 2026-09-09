# CLAUDE.md — Test Document Skills

## What this repo is

A library of seven Claude Code skills that generate QA documentation (test cases, test data, bug reports, security/performance/usability test suites) as formatted `.xlsx` workbooks. Every skill follows the same three-phase pattern and delegates XLSX conversion to one shared Python script.

## Directory layout

```
.claude/skills/
├── shared/
│   ├── md_table_to_xlsx.py   # The only XLSX converter — all skills call this, never copy it
│   └── PHASE1_GUIDE.md       # Common Phase 1 rules (ask vs infer, multi-item, file paths)
├── api-test-case-generator/SKILL.md
├── bug-report-generator/SKILL.md
├── performance-test-case-generator/SKILL.md
├── security-test-case-generator/SKILL.md
├── test-case-generator/SKILL.md
├── test-data-generator/SKILL.md
└── usability-test-case-generator/SKILL.md
tests/
└── sample-input.md           # Smoke-test fixture for the converter
requirements.txt              # pip install -r requirements.txt
```

## The three-phase pattern (every skill follows this)

1. **Phase 1 — Validate inputs.** Ask only when the required item is completely absent and cannot be inferred. Infer everything inferrable; flag every assumption with `(assumed — verify)` in the output. See `.claude/skills/shared/PHASE1_GUIDE.md` for the full decision rules.

2. **Phase 2 — Write the markdown table.** Build all rows in memory, write them to a temp file in the **session scratchpad directory** (never `/tmp/`), then confirm with a single line. Do NOT echo the full table to chat.

3. **Phase 3 — Convert to XLSX.** Call the shared converter:
   ```bash
   python3 .claude/skills/shared/md_table_to_xlsx.py <scratchpad>/<slug>.md <output>/<slug>.xlsx
   ```
   Use `/mnt/user-data/outputs/` on Claude.ai or `./outputs/` locally. Never write ad-hoc openpyxl code inside a skill.

## Key conventions

| Convention | Rule |
|---|---|
| Multi-line cell content | Use `\n` (literal backslash-n) inside cell values in the markdown table — the converter unescapes these into real newlines in Excel |
| Temp files | Always write to the session scratchpad directory; never `/tmp/` |
| XLSX output dir | `/mnt/user-data/outputs/` on Claude.ai; `./outputs/` locally |
| Converter errors | Fix the markdown temp file and re-run; never hand-edit the `.xlsx` |
| Multiple items | Use `## Sheet: <name>` headings in one temp file → one workbook with multiple sheets |
| `present_files` | Not a real tool — tell the user the output path directly |

## Bug report skill — different table shape

All skills produce one-row-per-test-case tables **except** `bug-report-generator`, which produces a flat `Section / Field / Value` table (one row per report field, one sheet per bug). This is intentional.

## Adding a new skill

1. Create `.claude/skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`).
2. Follow the three-phase pattern exactly. Link to `PHASE1_GUIDE.md` in Phase 1.
3. Phase 3 must call the shared converter — do not add skill-specific XLSX code.
4. Add a smoke-test row or table to `tests/sample-input.md` if the skill introduces a new table shape.
5. Add an entry to the README and `qa_skills_documentation.md`.

## Running the converter / smoke test

```bash
pip install -r requirements.txt
python3 .claude/skills/shared/md_table_to_xlsx.py tests/sample-input.md tests/sample-output.xlsx
# Expected: {"status": "success", "file": "tests/sample-output.xlsx"}
```

## Project context

Before invoking any skill, check whether a `PROJECT_CONTEXT.md` file exists in the project root. If it does, read it before Phase 1. Its contents (user roles, business goal, key features, domain glossary) are ground truth — do not ask questions already answered there.

`PROJECT_CONTEXT.md` in this repo is the unfilled template. QA engineers copy it into their own project repo and fill it in once per project.

## Which doc is authoritative?

- **README.md** — user-facing overview and quick-start guide
- **qa_skills_documentation.md** — detailed per-skill reference (triggers, columns, coverage rules) for contributors and integrators
- **SKILL.md files** — the actual skill instructions Claude follows at runtime; these are the source of truth for skill behaviour
- **PROJECT_CONTEXT.md** — project-specific context template; filled-in copy lives in the target project repo, not here
