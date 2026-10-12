# CLAUDE.md — Test Document Skills

## What this repo is

A library of nine skills for Claude Code and GitHub Copilot that generate QA documentation (test cases, test data, bug reports, security/performance/usability and backend smoke/E2E test suites) as formatted `.xlsx` workbooks. Every skill follows the same three-phase pattern and converts to XLSX with a bundled Python script. Users install the skills with `install.sh` / `install.ps1`.

## Requirements

- **Python 3.8+** with **`openpyxl`** (`pip install openpyxl`). The converter uses `from __future__ import annotations`, so it runs on 3.8; keep it 3.8-compatible (no `match`, no runtime `X | Y` unions, no 3.9+ stdlib APIs).
- The installers check for Python 3.8+ and offer to install `openpyxl`. If you raise the minimum, update both installers (`find_python` / the version check), `README.md`, `qa_skills_documentation.md`, and every `skills/*/README.md`.
- On Windows, `python3` is often a Microsoft Store placeholder; skills fall back to `python` or `py -3`.

## Directory layout

```
skills/
└── <skill-name>/                  # One self-contained folder per skill — installed as-is
    ├── SKILL.md                   # Instructions the assistant follows (source of truth)
    ├── README.md                  # Human-readable summary: output, inputs, requirements
    ├── references/PHASE1_GUIDE.md # Common Phase 1 rules (ask vs infer, multi-item, formatting, errors)
    ├── scripts/md_table_to_xlsx.py  # The markdown → XLSX converter
    └── assets/PROJECT_CONTEXT.md    # Blank project-context template
install.sh                         # Installer: macOS, Linux, Git Bash (bash 3.2 compatible)
install.ps1                        # Installer: Windows PowerShell 5.1 and PowerShell 7
```

The nine skills: `api-test-case-generator`, `backend-e2e-test-case-generator`, `backend-smoke-test-case-generator`, `bug-report-generator`, `performance-test-case-generator`, `security-test-case-generator`, `test-case-generator`, `test-data-generator`, `usability-test-case-generator`.

## Bundled files must stay identical

`PHASE1_GUIDE.md`, `md_table_to_xlsx.py`, and `PROJECT_CONTEXT.md` are duplicated in every skill so each folder can be installed on its own. When you change one, copy it to all nine skills. Verify with:

```bash
md5sum skills/*/scripts/md_table_to_xlsx.py skills/*/references/PHASE1_GUIDE.md skills/*/assets/PROJECT_CONTEXT.md | awk '{print $1}' | sort | uniq -c
# Expected: three lines, each with count 9
```

## The three-phase pattern (every skill follows this)

1. **Phase 1 — Validate inputs.** Ask only when the required item is completely absent and cannot be inferred. Infer everything inferrable; flag every assumption with `(assumed — verify)` in the Notes/Comments column (never in fixed-value columns like IDs, severity, or status). See `references/PHASE1_GUIDE.md` for the full decision rules.

2. **Phase 2 — Write the markdown table.** Build all rows in memory, write them to a temp file in the **session scratchpad directory** (or the system temp directory if there is none) — never inside the user's project. Confirm with a single line. Do NOT echo the full table to chat.

3. **Phase 3 — Convert to XLSX.** Call the skill's bundled converter:
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py" <scratchpad>/<slug>.md <output>/<slug>.xlsx
   ```
   `${CLAUDE_SKILL_DIR}` is a placeholder the assistant fills in with the installed skill's folder path — it is **not** a real shell environment variable and is not set by the installer. The SKILL.md files include a fallback: if the path isn't resolved, use the full path to the skill folder directly. Use `/mnt/user-data/outputs/` on Claude.ai or `./outputs/` locally. Never write ad-hoc openpyxl code inside a skill.

**Backend skills add a Phase 0.** `backend-smoke-test-case-generator` and `backend-e2e-test-case-generator` run a **Phase 0 — Context gathering** before Phase 1: read `PROJECT_CONTEXT.md`, introspect the DB through an MCP connection if available, and fetch the API contract (Swagger/OpenAPI, Postman, docs page). The result sets a context mode — Full / DB-Full / API-Full / Generic — and every row cites its source in References (`[DB: MCP <engine> <date>]`, `[API: <source> <date>]`, or `[Generic: no context]`). Phases 1–3 are otherwise the same.

## Key conventions

| Convention | Rule |
|---|---|
| Multi-line cell content | Use `\n` (literal backslash-n) inside cell values in the markdown table — the converter unescapes these into real newlines in Excel |
| Pipes in cells | Escape as `\|` |
| Temp files | Always the session scratchpad (or system temp); never the user's project |
| XLSX output dir | `/mnt/user-data/outputs/` on Claude.ai; `./outputs/` locally |
| Converter output | Must print `"status": "success"` with no `warnings`; a warning means content was dropped |
| Converter errors | Fix the markdown temp file and re-run; never hand-edit the `.xlsx` |
| Sheets | Put a `## Sheet: <name>` heading (≤31 chars) before every table, one table per sheet; multiple items → multiple sheets in one workbook |
| `present_files` | Not a real tool — tell the user the output path directly |

## Bug report skill — different table shape

All skills produce one-row-per-test-case tables **except** `bug-report-generator`, which produces a flat `Section / Field / Value` table (one row per report field, one sheet per bug). This is intentional.

## Installers

`install.sh` and `install.ps1` pick up every folder under `skills/` that contains a `SKILL.md` — adding a skill needs no installer changes. They read the first sentence of the SKILL.md `description` for the picker. They download `ambigin/test-document-skills` at `main` (override with `--ref` / `-Ref`) unless run from a clone, in which case they use the local `skills/` folder.

Install targets: Claude Code → `~/.claude/skills/` or `<project>/.claude/skills/`; GitHub Copilot → `~/.copilot/skills/` or `<project>/.github/skills/`.

Keep the two installers in feature parity. `.gitattributes` forces LF for `*.sh` and CRLF for `*.ps1` — don't change that.

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`) and a `README.md` matching the other skills' structure.
2. Copy `references/PHASE1_GUIDE.md`, `scripts/md_table_to_xlsx.py`, and `assets/PROJECT_CONTEXT.md` from an existing skill.
3. Follow the three-phase pattern exactly. Link to `references/PHASE1_GUIDE.md` in Phase 1.
4. Phase 3 must call `${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py` — do not add skill-specific XLSX code.
5. Add an entry to `README.md` and `qa_skills_documentation.md`.

## Running the converter manually

```bash
pip install openpyxl
python3 skills/test-case-generator/scripts/md_table_to_xlsx.py input.md outputs/output.xlsx
# Expected: {"status": "success", "file": "outputs/output.xlsx"}
```

`outputs/` is gitignored.

## Project context

Before invoking any skill, check for a `PROJECT_CONTEXT.md` in the current working directory, then at the root of the repository that contains it. If it exists, read it before Phase 1. Its contents (user roles, business goal, key features, domain glossary) are ground truth — do not ask questions already answered there.

`skills/*/assets/PROJECT_CONTEXT.md` is the unfilled template. QA engineers copy it into their own project repo and fill it in once per project.

## Which doc is authoritative?

- **README.md** — user-facing overview, installation, and quick start
- **qa_skills_documentation.md** — detailed per-skill reference (triggers, columns, coverage rules) for contributors and integrators
- **skills/\*/SKILL.md** — the actual skill instructions the assistant follows at runtime; source of truth for skill behaviour
- **skills/\*/README.md** — short per-skill summary shipped with each installed skill
- **skills/\*/assets/PROJECT_CONTEXT.md** — project-context template; the filled-in copy lives in the target project repo, not here
