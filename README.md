# Test Document Skills

Nine AI skills that write QA documentation for you — test cases, test data, security, performance and usability test suites, backend smoke and E2E (API → DB) test suites, and bug reports — and deliver each one as a formatted Excel workbook. They work with **Claude Code** and **GitHub Copilot**.

## Overview

Describe what you're testing (paste a Jira ticket, an endpoint, a bug observation, a list of fields) and the matching skill turns it into an execution-ready `.xlsx` file in minutes instead of hours.

Every skill follows the same three-phase workflow:

1. **Validate inputs** — asks only for what's missing and can't be inferred; everything else is inferred and flagged `(assumed — verify)` so you can review it.
2. **Write the tables** — builds the markdown tables and saves them to a temp file (not your project). The tables aren't echoed to chat.
3. **Convert to XLSX** — runs the skill's bundled `md_table_to_xlsx.py` to produce the workbook in `./outputs/` (or `/mnt/user-data/outputs/` on Claude.ai), then tells you the path.

The two backend skills (`backend-smoke-test-case-generator` and `backend-e2e-test-case-generator`) add a **Phase 0 — Gather context** before Phase 1: they read `PROJECT_CONTEXT.md`, introspect the database through an MCP connection if one is available, and fetch your Swagger/OpenAPI spec, Postman collection, or docs page. What they find sets the context mode (Full, DB-Full, API-Full, or Generic), which decides how much of the output is cited from your real schema.

## Installation

### Requirements

- Claude Code and/or GitHub Copilot (VS Code, agent mode)
- Python 3.8+ with `openpyxl` — the skills use it to build the `.xlsx`. The installer checks for it and offers to install it.

### Quick install

**macOS / Linux / Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.sh | bash
```

**Windows PowerShell**

```powershell
irm https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.ps1 | iex
```

The installer walks you through three choices:

1. **Assistant** — Claude Code, GitHub Copilot, or both
2. **Scope** — *Global* (your user account, every project) or *Project* (one repo; commit it to share with your team)
3. **Skills** — pick any or all of the nine

It shows a plan, asks for confirmation, copies the skills, and checks for `openpyxl`.

### Install locations

| Assistant | Global | Project |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `<project>/.claude/skills/` |
| GitHub Copilot | `~/.copilot/skills/` | `<project>/.github/skills/` |

### Non-interactive install

Every option you pass skips its prompt.

```bash
# All skills, Claude Code, global, no prompts
curl -fsSL https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.sh | bash -s -- --agent claude --scope global --all -y

# Two skills into the current project for both assistants
./install.sh --agent claude,copilot --scope project --skills test-case-generator,bug-report-generator
```

```powershell
# All skills, Claude Code, global, no prompts
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.ps1))) -All -Agent claude -Scope global -Yes

# Two skills into the current project for both assistants
.\install.ps1 -Agent claude,copilot -Scope project -Skills test-case-generator,bug-report-generator
```

| `install.sh` | `install.ps1` | What it does |
|---|---|---|
| `--agent LIST` | `-Agent` | `claude`, `copilot`, or `claude,copilot` |
| `--scope SCOPE` | `-Scope` | `global` or `project` |
| `--project-dir PATH` | `-ProjectDir` | Project root for project scope (default: current directory) |
| `--skills LIST` | `-Skills` | Comma-separated skill names |
| `--all` | `-All` | Select every skill |
| `--link` | `-Link` | Symlink (bash) or junction (PowerShell) instead of copying — needs a local clone |
| `--uninstall` | `-Uninstall` | Remove the selected skills |
| `--list` | `-List` | Show available skills and where they're installed |
| `--dry-run` | `-DryRun` | Show the plan without changing anything |
| `-y`, `--yes` | `-Yes` | Don't ask for confirmation |
| `--ref REF` | `-Ref` | Branch or tag to download (default: `main`) |
| `--no-tui` | `-NoTui` | Numbered prompts instead of the arrow-key menu |

### From a clone

```bash
git clone https://github.com/ambigin/test-document-skills.git
cd test-document-skills
./install.sh          # or .\install.ps1 on Windows
```

Run from a clone, the installer uses the local `skills/` folder instead of downloading. Add `--link` / `-Link` to link the skills rather than copy them, so a `git pull` updates them in place.

### Updating and removing

Run the installer again: skills whose files have changed are marked **update available** in the picker and plan. Use `--list` / `-List` to see what's installed where, and `--uninstall` / `-Uninstall` to remove skills.

### Manual install

Each folder under `skills/` is self-contained. Copy it into one of the install locations above.

## Using the skills

**Claude Code** — start a new session, then describe your task ("write test cases for this Jira ticket: …") or call a skill directly with `/test-case-generator`, `/bug-report-generator`, and so on.

**GitHub Copilot** — reload VS Code and use Copilot Chat in **agent mode**. If the skills don't show up, turn on the `chat.useAgentSkills` setting.

### Example

```
You: Generate test cases for this endpoint:
POST /api/users/register
Body: { email, password, name, dob }
Response: 201 Created or 400 Bad Request
Auth: Public

Claude: Test cases saved to ./outputs/post-api-users-register-api-tests.xlsx
```

## Skills included

| Skill | What it produces | Say something like |
|---|---|---|
| `test-case-generator` | Functional test cases from a Jira ticket's acceptance criteria — Test Cases, Summary, and Coverage sheets | "Create test cases for PROJ-123" |
| `api-test-case-generator` | REST/GraphQL API test suite: auth, validation, business logic, errors, idempotency, rate limits, security | "Write API tests for POST /v1/orders" |
| `test-data-generator` | 50+ rows of valid, invalid, boundary, missing, special, and duplicate test data | "Give me test data for a registration form" |
| `security-test-case-generator` | OWASP-aligned security tests executable from the browser, DevTools, or Burp/ZAP | "Security test cases for our login screen" |
| `performance-test-case-generator` | Load, stress, spike, soak, scalability, concurrency, and failover scenarios with SLA limits and k6/JMeter/Gatling/Locust/Artillery stubs | "Load test plan for our checkout API" |
| `usability-test-case-generator` | Task-based scenarios for moderated or unmoderated user research | "Usability test scenarios for onboarding" |
| `backend-smoke-test-case-generator` | Post-deployment go/no-go checks: API health, DB connectivity, DB objects, trigger and FK state, integrations, and deployment version — Smoke Tests and Summary sheets | "Post-deployment smoke checks for our backend" |
| `backend-e2e-test-case-generator` | API → Service → DB test cases for a feature: payload persistence, type contracts, and business-rule transformations, each with a SQL assertion — Test Cases, Summary, and Coverage sheets | "Backend E2E test cases for POST /orders" |
| `bug-report-generator` | Developer-ready bug report from raw observations and logs — one sheet per bug | "Turn this into a bug report: …" |

> **Bug reports use a different table shape.** Instead of one row per test case, each sheet is a three-column `Section / Field / Value` table (one row per report field) that maps directly onto Jira's bug fields.

> **The backend skills work best with real context.** Connect an MCP database tool and/or provide a Swagger/OpenAPI URL or Postman collection, and every check cites its source (`[DB: MCP …]`, `[API: …]`). Without either, they produce generic template rows marked `[Generic: no context]` and warn you.

Each skill folder has its own `README.md` with its columns, coverage rules, and inputs. For the full reference, see [qa_skills_documentation.md](qa_skills_documentation.md).

## Optional: project context

Every skill ships a blank template at `assets/PROJECT_CONTEXT.md`. Copy it to the root of the project you're testing and fill it in once:

```bash
cp skills/test-case-generator/assets/PROJECT_CONTEXT.md /path/to/your-project/PROJECT_CONTEXT.md
```

It covers product background, business goal, user roles, key features, and a domain glossary. The skills read it before asking questions, skip anything it already answers, and use your terminology in the output.

## Project structure

```
test-document-skills/
├── README.md
├── qa_skills_documentation.md     # Detailed per-skill reference
├── CLAUDE.md                      # Context for Claude Code when working on this repo
├── install.sh                     # Installer for macOS, Linux, Git Bash
├── install.ps1                    # Installer for Windows PowerShell 5.1 / 7
└── skills/
    └── <skill-name>/              # One self-contained folder per skill (9 total)
        ├── SKILL.md               # Instructions the assistant follows — source of truth
        ├── README.md              # Human-readable summary of the skill
        ├── references/
        │   └── PHASE1_GUIDE.md    # Shared Phase 1 rules (ask vs. infer, formatting, errors)
        ├── scripts/
        │   └── md_table_to_xlsx.py  # Markdown → XLSX converter
        └── assets/
            └── PROJECT_CONTEXT.md   # Blank project-context template
```

`PHASE1_GUIDE.md`, `md_table_to_xlsx.py`, and `PROJECT_CONTEXT.md` are bundled into every skill so each folder can be installed on its own. They're meant to be identical, so when you change one, copy it to all nine skills.

## The converter

`scripts/md_table_to_xlsx.py` turns markdown tables into a formatted workbook: frozen, styled header row, alternating row colours, auto-width columns, wrapped text, and row heights that fit the content.

- One sheet per `## Sheet: <name>` heading (one table per sheet)
- `\n` inside a cell becomes a real line break in Excel
- Prints `{"status": "success", "file": "..."}` or `{"status": "error", "message": "..."}`

You can run it yourself:

```bash
python3 skills/test-case-generator/scripts/md_table_to_xlsx.py input.md outputs/output.xlsx
```

## Development

### Setup

```bash
git clone https://github.com/ambigin/test-document-skills.git
cd test-document-skills
pip install openpyxl pytest
```

### Running tests

```bash
pytest tests/test_converter.py
```

Tests are parameterised over every skill's converter and will catch any divergence between copies.

### Running the converter manually

```bash
mkdir -p outputs
python3 skills/test-case-generator/scripts/md_table_to_xlsx.py input.md outputs/output.xlsx
# Expected: {"status": "success", "file": "outputs/output.xlsx"}
```

`outputs/` is gitignored.

## Contributing

To add a skill:

1. Create `skills/<skill-name>/` with a `SKILL.md` (YAML frontmatter with `name` and `description`) and a `README.md`.
2. Copy `references/PHASE1_GUIDE.md`, `scripts/md_table_to_xlsx.py`, and `assets/PROJECT_CONTEXT.md` from an existing skill.
3. Follow the three-phase workflow. Phase 3 must call the bundled converter via `${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py` — no skill-specific XLSX code.
4. Add the skill to this README and to [qa_skills_documentation.md](qa_skills_documentation.md).

The installers pick up any folder under `skills/` that contains a `SKILL.md`, so no installer changes are needed.

## Documentation

| Document | Purpose |
|---|---|
| **README.md** | This file — overview and installation |
| [qa_skills_documentation.md](qa_skills_documentation.md) | Beginner guide, cheat sheet, and full per-skill reference (columns, coverage rules, ID formats, taxonomies) |
| `skills/<name>/SKILL.md` | The instructions the assistant follows — source of truth for skill behaviour |
| `skills/<name>/README.md` | Short per-skill summary |
| [CLAUDE.md](CLAUDE.md) | Context for Claude Code when working on this repo |

## License

[Add your license here]

---

**Last updated**: October 2026
**Skills available**: 9
