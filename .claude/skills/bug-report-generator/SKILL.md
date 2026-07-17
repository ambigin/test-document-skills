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
can act on immediately — with zero back-and-forth for clarification. The final output is a
`.xlsx` workbook (one sheet per bug), not plain text, so it can be opened directly, filed
alongside other QA artifacts, or copy-pasted into Jira/Confluence. Internally, the workbook is
produced in two steps: this skill first writes an intermediate JSON file describing the
workbook's contents, then hands that JSON to a shared converter script that does the actual
openpyxl work. This is the same JSON-intermediary pattern used by `test-case-generator` and
`api-test-case-generator` — the "what goes in the report" logic here stays skill-specific, while
"how to build a formatted .xlsx" stays in the one shared script every generator skill calls.

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

Before generating any output, you MUST validate the following. If any item is missing or unclear,
ask the specified question and wait for the user's answer — unless the user has already supplied
enough detail to make a confident, flagged inference (see Mandatory Rule below).

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Raw Observation | Yes | Must describe what was seen, even informally — grammar/structure don't matter | "Please paste the raw observation, screen recording description, or note describing the bug." |
| Screenshot / Log | Detect | Note whether a screenshot, console error, stack trace, or network response was provided | Not required; proceed with "none provided" if missing |
| Linked Jira / Test Case | Detect | Note the Jira ticket ID or Test Case ID if this bug was found during a specific test run | Not required; proceed with "None" if missing |
| Multiple Distinct Bugs | Detect | Scan input for more than one distinct symptom or failure | "I detected what looks like multiple distinct bugs. Do you want: (A) One combined report, or (B) Separate sheets per bug in the same workbook?" |
| Environment Details | Detect | OS, browser, app/API version, test environment, user role | Not required; mark as "(assumed — please verify)" or "Unknown — needs investigation" if missing |

**Mandatory Rule:** Do NOT proceed to Phase 2 until the user confirms all required items are ready,
OR the available detail is sufficient to make a reasonable inference. When inferring, flag every
assumed field inline with "(assumed — please verify)" rather than asking — the goal is zero
back-and-forth, not interrogation. Only stop and ask when the raw observation itself is missing,
ambiguous between multiple bugs, or too thin to support any reasonable inference.

### PHASE 2: Generate Intermediate JSON

Do not generate the JSON until Phase 1 is complete.

1. Build the report content in memory first — one bug's worth of field/value pairs per sheet —
   following the Report Structure and Field Format Reference below.
2. Assemble a single JSON object conforming to the **shared workbook-spec schema** (see
   `json_to_xlsx.py`'s docstring for the authoritative schema — do not invent your own shape).
   At a high level for this skill:
   - `sheets` is a list with **one sheet per bug**. For a single-bug or combined report, that's
     one sheet; for separate reports on multiple distinct bugs, add one sheet per bug (see
     "Handling Multiple Distinct Bugs" below).
   - Each sheet has **six stacked blocks**, in this order, mirroring the original report's
     sections. Blocks 1, 2, 4, and 5 use two columns, `Field` and `Value` — every row is a
     `[field name, value]` pair, so a field is never silently omitted:
     1. `"Summary"` — rows for Bug ID, Title, Severity, Priority, Frequency, Status
     2. `"Environment"` — rows for OS & version, Browser & version, App / API version,
        Test environment, User role / account
     3. `"Steps to Reproduce"` — **two columns, `Step #` and `Description`**, one row per
        reproduction step, numbered starting at 1
     4. `"Behavior"` — rows for Expected Behavior, Actual Behavior
     5. `"Impact & Analysis"` — rows for Impact, Root Cause Hypothesis,
        Suggested Fix / Investigation Starting Point, Workaround, Regression Risk
     6. `"Evidence & Links"` — rows for Screenshots / Logs / Evidence, Linked Test Case,
        Linked Jira Ticket, Reported By, Reported Date
   - Each row is a **positional array**, e.g. `["Severity", "High"]` or `["2", "Enter a valid
     email and a password under 8 characters"]`. Do not use dicts.
   - Set `wrap: true` on the `Value` / `Description` column of every block (long free text) and
     `wrap: false` on `Field` / `Step #`. See widths table below.
   - Never leave a `Value` cell blank — use "Not observed", "Not applicable", "none provided",
     "None", or "Unknown — needs investigation" per the Field Format Reference, exactly as the
     plain-text version did.
3. Write this JSON to a scratch file, e.g. `/home/claude/bug-report-<slug>.json`. This file is
   intermediate — it is never shown to the user and never placed in `/mnt/user-data/outputs/`.

### PHASE 3: Convert JSON to XLSX

1. Call the shared converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python .claude/skills/shared/json_to_xlsx.py /home/claude/bug-report-<slug>.json /mnt/user-data/outputs/<slug>-bug-report.xlsx
   ```
   This is the same shared script `test-case-generator` and `api-test-case-generator` use —
   never copy it into this skill's own folder.
2. Confirm the script printed `"status": "success"`. If it errors, the JSON likely doesn't
   match the schema (check for a row array whose length doesn't match its block's `columns`,
   a missing `rows`/`columns` key on a block, or an invalid/duplicate sheet name) — fix the
   JSON in Phase 2 and re-run; do not patch the output XLSX by hand.
3. Present the resulting file to the user with `present_files` (or equivalent).

## Report Structure (What Each Sheet Must Contain)

Every field below must map to a `[Field, Value]` row in the matching block. Nothing is optional
to include — only its *value* may be a placeholder like "None" or "Unknown — needs investigation".

**Summary block:**
- Bug ID → "Leave blank — to be assigned by Jira on creation"
- Title → `Component › Action › Symptom` format
- Severity, Priority, Frequency, Status ("Open")

**Environment block:**
- OS & version, Browser & version, App / API version, Test environment, User role / account

**Steps to Reproduce block:**
- One row per step, numbered from 1, atomic and deterministic — one action per step. Append
  "(needs verification)" to the end of any step's Description that can't be made fully
  deterministic from the observation given.

**Behavior block:**
- Expected Behavior, Actual Behavior — observable system states, not opinions. Include exact
  error text, HTTP status codes, or visual symptoms verbatim in Actual Behavior.

**Impact & Analysis block:**
- Impact, Root Cause Hypothesis (required even if uncertain — never optional), Suggested Fix /
  Investigation Starting Point, Workaround ("None identified." if none), Regression Risk

**Evidence & Links block:**
- Screenshots / Logs / Evidence (transcribe console errors/stack traces/network responses
  verbatim if provided; "Not attached - [description]" if described but not attached; "none
  provided" if unavailable), Linked Test Case, Linked Jira Ticket, Reported By (blank), Reported
  Date (blank — auto-filled on Jira creation)

## Field Format Reference

| Field | Format Rule | Examples | Default/Placeholder |
|-------|-------------|----------|---------------------|
| Title | Component › Action › Symptom | "Checkout › Place Order › Payment spinner never resolves on slow 3G" | N/A (required) |
| Severity | Exactly one of: `Critical` \| `High` \| `Medium` \| `Low` — see taxonomy below | "High" | N/A (required) |
| Priority | Exactly one of: `P1` \| `P2` \| `P3` \| `P4` — see taxonomy below | "P2" | N/A (required) |
| Frequency | `Always` \| `Intermittent (N of N attempts)` \| `Once` | "Intermittent (3 of 5 attempts)" | N/A (required) |
| Environment fields | Use exact version strings when known | "Chrome 124.0.6367" | "(assumed — please verify)" if inferred; "Unknown — needs investigation" if not |
| Steps to Reproduce | Atomic, deterministic, one action per step | "Click 'Forgot Password'" | Append "(needs verification)" to any step that can't be made fully deterministic |
| Expected/Actual Behavior | Observable system states, not opinions | "the modal closes without saving form data" (not "it doesn't work") | (required) |
| Root Cause Hypothesis | A reasoned guess — never optional | "Race condition between token refresh and submit API call" | (required, even if uncertain) |
| Workaround | Concrete workaround or explicit absence | "Refresh the page and resubmit" | "None identified." |
| Screenshot / Evidence | Description, filename, or verbatim log/stack trace | "console error: TypeError at auth.service.ts:42" | "none provided" |
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
found in an unreachable code path may not be P1.

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
  every assumed field's Value with "(assumed — please verify)"

### Handling Screenshots / Logs
- If attached or pasted: transcribe console errors, stack traces, and network responses verbatim
  into the Evidence & Links block's "Screenshots / Logs / Evidence" row
- If described but not attached: use "Not attached - [description]"
- If unavailable: use "none provided"

### Handling Multiple Distinct Bugs
- Default behavior: if the observation clearly describes more than one distinct symptom or
  failure, ask the user whether they want one combined report or separate sheets per bug
- If the user confirms separate sheets: add one sheet per bug to the same Phase 2 JSON (sheet
  names like `Bug-1`, `Bug-2`, or a short slug of each Title, ≤31 characters) — still a single
  Phase 3 conversion call, producing one workbook with multiple sheets, not separate files,
  unless the user explicitly asks for separate files
- If the user confirms a combined report: document the primary symptom fully in one sheet, and
  note secondary symptoms within the Impact or Actual Behavior rows rather than adding sheets

## Example Invocation

**User Input:**
"On staging, when I try to check out with a saved card on mobile Safari, the payment spinner just spins forever and never resolves. Happened 3 times out of 3 tries. No console errors visible. This was found during TC-104."

**Your Response (Phase 1):**
"I have the raw observation, reproduction rate (3 of 3), and linked test case (TC-104). I don't
have a screenshot/log or full environment details (exact app version, OS version) — I'll mark
those as '(assumed — please verify)' / 'Unknown — needs investigation' where appropriate. Ready
to proceed?"

**After User Confirms (Phase 2):**
Build the JSON workbook spec — one sheet, six blocks (Summary, Environment, Steps to Reproduce,
Behavior, Impact & Analysis, Evidence & Links) — with Severity/Priority/Frequency assigned per
the taxonomies, Root Cause Hypothesis populated with a reasoned guess, and every environment row
explicitly marked as assumed or unknown rather than left blank. Write it to a scratch JSON file.

**Phase 3:**
Run `json_to_xlsx.py` against that JSON to produce the `.xlsx`, save it to
`/mnt/user-data/outputs/`, and present it to the user.

## Final Instructions

- Output only the workbook. Do not add a preamble, summary, or closing remarks once Phase 2
  begins, beyond what `present_files` shows.
- If the raw observation contains multiple distinct bugs and the user has chosen separate
  reports, add one sheet per bug to the same workbook rather than generating multiple files.
- If steps cannot be made fully deterministic from the observation provided, write the best
  possible steps and append "(needs verification)" to each uncertain step's Description.
- Flag any field where you had to make an assumption rather than omitting it silently.