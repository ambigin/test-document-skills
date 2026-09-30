---
name: bug-report-generator
description: >
  Generates a complete, developer-ready bug report from unstructured QA observations, logs, and
  evidence, delivered as an XLSX workbook (one sheet per bug). Use this skill when the user
  needs a structured bug report with title, reproduction steps, environment, severity/priority,
  root cause hypothesis, and suggested fix guidance. Trigger for requests like "write a bug
  report for this", "turn this observation into a bug report", "I found a bug, can you document
  it", or "create a Jira-ready bug report from these logs". If the user pastes a raw bug
  observation, console error, stack trace, or screen recording description and wants it turned
  into something a developer can act on, use this skill.
---

# Bug Report Generation Skill

## Purpose

Act as a Senior QA Engineer with 10+ years of experience writing developer-ready bug reports.
Transform a raw, unstructured observation into a complete, structured bug report that a developer
can act on immediately. Output is an XLSX workbook produced by the bundled converter script
(`md_table_to_xlsx.py`). The report is a flat three-column table — Section, Field, Value — with
one row per field across all six sections.

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs

> **Read [references/PHASE1_GUIDE.md](references/PHASE1_GUIDE.md) before starting Phase 1.** It covers project context (`PROJECT_CONTEXT.md`), when to ask vs. infer, multi-item handling, assumption flagging, table formatting rules, and converter error recovery.

Before generating any output, you MUST validate the following. If any item is missing or unclear,
ask the specified question and wait for the user's answer — unless the user has already supplied
enough detail to make a confident, flagged inference (see Mandatory Rule below).

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Raw Observation | Yes | Must describe what was seen, even informally — grammar/structure don't matter | "Please paste the raw observation, screen recording description, or note describing the bug." |
| Screenshot / Log | Detect | Note whether a screenshot, console error, stack trace, or network response was provided | Not required; proceed with "none provided" if missing |
| Linked Jira / Test Case | Detect | Note the Jira ticket ID or Test Case ID if this bug was found during a specific test run | Not required; proceed with "None" if missing |
| Multiple Distinct Bugs | Detect | Scan input for more than one distinct symptom or failure | "I detected what looks like multiple distinct bugs. Do you want: (A) One combined report, or (B) Separate sheets per bug in the same workbook?" |
| Environment Details | Detect | OS, browser, app/API version, test environment, user role | Not required; mark as "(assumed — verify)" or "Unknown — needs investigation" if missing |

**Mandatory Rule:** If the raw observation is present and sufficient to make reasonable inferences, proceed directly to Phase 2 — flag every assumed field with "(assumed — verify)". Only stop and ask when the raw observation itself is missing, ambiguous between multiple bugs, or too thin to support any inference.

### PHASE 2: Generate Markdown Table

Do not generate the table until Phase 1 is complete.

1. Build the report content following the Report Structure and Field Format Reference below.
   The report is a **single markdown table with three columns: Section, Field, Value**.
   Every field from all six sections maps to one row. Steps to Reproduce: one row per step
   (Field = `Step 1`, `Step 2`, etc.). For multiple bugs (separate sheets), prefix each table
   with `## Sheet: <bug-slug>`.
2. Never leave a Value cell blank — use "Not observed", "Not applicable", "none provided",
   "None", or "Unknown — needs investigation" per the Field Format Reference.
3. **Do NOT echo the table to chat.** Write directly to a temp file in the session scratchpad directory (or the system temp directory if your environment has no scratchpad) — never inside the user's project.
4. Confirm with a single line: "✓ Bug report written — running converter..."

### PHASE 3: Convert Markdown Table to XLSX

1. Call the bundled converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py" "<scratchpad>/bug-report-<slug>.md" "<output>/<slug>-bug-report.xlsx"
   ```
   The script is in `scripts/` next to this SKILL.md; if the command's path wasn't filled in with this skill's folder, use that folder's full path. If `python3` fails or isn't found (on Windows it's often a Microsoft Store placeholder that prints "Python was not found"), use `python` or `py -3` instead. The script needs `openpyxl`.
   Replace `<scratchpad>` with the temp directory from Phase 2. For `<output>`, use `/mnt/user-data/outputs` on Claude.ai or `./outputs` when running locally.
2. Confirm the script printed `"status": "success"` with no `warnings` — a warning means cells or lines were dropped, so fix the temp file (see PHASE1_GUIDE.md → Standard Converter Error Recovery) and re-run. If it errors, check that the temp file
   contains valid pipe-delimited markdown tables with the Section/Field/Value header row and
   a separator row of `---`, fix if needed, and re-run. Do not patch the output XLSX by hand.
3. Tell the user the full output path and confirm the file is ready to open in Excel or import into Google Sheets. State the path in a single line — no preamble, no trailing summary.

## Report Structure (What Each Sheet Must Contain)

Every field below must map to one row of the single Section / Field / Value table, with Section
set to the block name (e.g. `Summary`, `Environment`) — never a separate table per block. Nothing is optional
to include — only its *value* may be a placeholder like "None" or "Unknown — needs investigation".

**Summary block:**
- Bug ID → "TBD — assigned by Jira on creation"
- Title → `Component › Action › Symptom` format
- Severity, Priority, Frequency, Status ("Open")

**Environment block:**
- OS & version, Browser & version, App / API version, Test environment, User role / account

**Steps to Reproduce block:**
- One row per step, numbered from 1, atomic and deterministic — one action per step. Append
  "(needs verification)" to the end of any step's Value that can't be made fully
  deterministic from the observation given.

**Behavior block:**
- Expected Behavior, Actual Behavior — observable system states, not opinions. Include exact
  error text, HTTP status codes, or visual symptoms verbatim in Actual Behavior.

**Impact & Analysis block:**
- Impact, Root Cause Hypothesis (required even if uncertain — never optional), Suggested Fix /
  Investigation Starting Point, Workaround ("None identified." if none), Regression Risk

**Evidence & Links block:**
- Screenshots / Logs / Evidence (transcribe console errors/stack traces/network responses
  verbatim if provided, writing each line break as `\n`; "Not attached - [description]" if
  described but not attached; "none provided" if unavailable), Linked Test Case, Linked Jira
  Ticket, Reported By ("TBD"), Reported Date ("TBD — auto-filled on Jira creation")

## Field Format Reference

| Field | Format Rule | Examples | Default/Placeholder |
|-------|-------------|----------|---------------------|
| Title | Component › Action › Symptom | "Checkout › Place Order › Payment spinner never resolves on slow 3G" | N/A (required) |
| Severity | Exactly one of: `Critical` \| `High` \| `Medium` \| `Low` — see taxonomy below | "High" | N/A (required) |
| Priority | Exactly one of: `P1` \| `P2` \| `P3` \| `P4` — see taxonomy below | "P2" | N/A (required) |
| Frequency | `Always` \| `Intermittent (N of N attempts)` \| `Once` | "Intermittent (3 of 5 attempts)" | N/A (required) |
| Environment fields | Use exact version strings when known | "Chrome 124.0.6367" | "(assumed — verify)" if inferred; "Unknown — needs investigation" if not |
| Steps to Reproduce | Atomic, deterministic, one action per step | "Click 'Forgot Password'" | Append "(needs verification)" to any step that can't be made fully deterministic |
| Expected/Actual Behavior | Observable system states, not opinions | "the modal closes without saving form data" (not "it doesn't work") | (required) |
| Root Cause Hypothesis | A reasoned guess — never optional | "Race condition between token refresh and submit API call" | (required, even if uncertain) |
| Workaround | Concrete workaround or explicit absence | "Refresh the page and resubmit" | "None identified." |
| Screenshot / Evidence | Description, filename, or verbatim log/stack trace (line breaks written as `\n`) | "console error: TypeError at auth.service.ts:42" | "none provided" |
| Linked Test Case / Jira Ticket | ID or explicit "None" | "TC-104" | "None" |

Do not leave any `Value` cell blank. Use "Not observed", "Not applicable", or "Unknown — needs
investigation" when data is genuinely unavailable.

## Severity Taxonomy

| Severity | Definition |
|----------|------------|
| Critical | System crash, data loss, security breach, complete feature failure with no workaround |
| High | Core functionality broken, workaround exists but is unreasonable for end users |
| Medium | Non-core functionality broken or degraded, reasonable workaround exists |
| Low | Cosmetic issue, minor UX inconsistency, no functional impact |

## Priority Taxonomy

| Priority | Definition |
|----------|------------|
| P1 | Block release / fix before any other work |
| P2 | Fix in current sprint |
| P3 | Fix in next sprint or upcoming release |
| P4 | Fix when capacity allows / backlog |

Severity and Priority are separate concerns — assign both independently. A Low-severity bug can
still be P1 (e.g., a cosmetic issue on the homepage of a launch-day release), and a Critical bug
found in an unreachable code path may not be P1. Each holds exactly one value from its taxonomy —
never add an assumption flag to it; put the reasoning, and any assumption behind it, in the Impact row.

## Frequency Taxonomy

| Frequency | Definition |
|-----------|------------|
| Always | 100% reproducible with the steps provided |
| Intermittent | Reproducible <100% of the time — note observed reproduction rate if known (e.g., "3 of 5 attempts") |
| Once | Observed once, could not reproduce — note exact conditions |

## Error Handling & Edge Cases

### Handling Missing or Ambiguous Observations
If the raw observation is too thin to support any reasonable inference after Phase 1:
- State explicitly what's missing (e.g., no described symptom, no indication of which feature)
- Ask the user for the missing detail before proceeding
- Only proceed once the user supplies it, or explicitly says "proceed with inference" — then flag
  every assumed field's Value with "(assumed — verify)"

### Handling Screenshots / Logs
- If attached or pasted: transcribe console errors, stack traces, and network responses verbatim
  into the Evidence & Links block's "Screenshots / Logs / Evidence" row — all in that one cell,
  with each line break written as `\n` (a real line break would cut the log off)
- If described but not attached: use "Not attached - [description]"
- If unavailable: use "none provided"

### Handling Multiple Distinct Bugs
- Default behavior: if the observation clearly describes more than one distinct symptom or
  failure, ask the user whether they want one combined report or separate sheets per bug
- If the user confirms separate sheets: prefix each bug's table with a `## Sheet: <bug-slug>`
  heading (e.g. `## Sheet: Bug-1`) in the Phase 2 markdown — still a single temp file and
  a single Phase 3 call, producing one workbook with multiple sheets, not separate files,
  unless the user explicitly asks for separate files
- If the user confirms a combined report: document the primary symptom fully in one table, and
  note secondary symptoms within the Impact or Actual Behavior rows rather than adding sheets

