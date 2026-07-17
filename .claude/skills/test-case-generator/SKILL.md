---
name: test-case-generator
description: >
  Generates comprehensive Test Case Documents as an XLSX spreadsheet from Jira tickets.
  Use this skill when the user asks to generate test cases, create a test case document,
  produce test cases for acceptance criteria, design test scenarios for a feature, or validate
  test coverage for a Jira ticket. Trigger for requests like "create test cases for X",
  "generate test cases from this Jira ticket", "I need test cases for these acceptance criteria",
  or "design test scenarios for this feature". If the user mentions a Jira ticket, acceptance
  criteria, or test coverage needs, use this skill.
---

# Test Case Document Generation Skill

## Purpose

Generate a comprehensive Test Case Document as an XLSX spreadsheet from a Jira ticket. The final
output is a `.xlsx` file (not markdown) so it can be opened directly or copy-pasted into Google
Sheets. Internally, the workbook is produced in two steps: this skill first writes an
intermediate JSON file describing the workbook's contents, then hands that JSON to a shared
converter script that does the actual openpyxl work. This keeps the "what data goes in the
spreadsheet" logic (skill-specific) separate from the "how to build a formatted .xlsx"
logic (shared), so other skills that also produce spreadsheets can reuse the same converter.

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

Before generating any output, you MUST validate the following. If any item is missing or unclear, ask the specified question and wait for the user's answer.

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Jira Ticket ID | Yes | Must include title, description, and ticket ID | "Please provide the Jira ticket ID, title, and full description." |
| Acceptance Criteria | Yes | Must be clear and non-conflicting; list them numbered | "Please provide the numbered acceptance criteria. If any conflict, clarify now." |
| Multiple Tickets/Features | Detect | Scan input for multiple distinct Jira tickets or features | "I detected multiple features/tickets. Do you want: (A) One table for the primary ticket, or (B) Separate tables per feature/ticket?" |
| Screenshots/Evidence | Detect | Note whether attachments or descriptions exist | Not required; proceed with TBD if missing |

**Mandatory Rule:** Do NOT proceed to Phase 2 until the user confirms all required items are ready, OR the user explicitly says "Proceed with inference" (then flag assumptions in Comments column).

### PHASE 2: Generate Intermediate JSON (Only After Phase 1 Completes)

Do not generate the JSON until Phase 1 is complete.

1. Build the test case rows in memory first (one row per test case), following the Column
   Format Reference and Coverage Rules below.
2. Assemble a single JSON object conforming to the **shared workbook-spec schema** (see
   `shared/json_to_xlsx.py` docstring for the authoritative schema — do not invent your own
   shape). At a high level:
   - `sheets` is a list. This skill always produces two sheets: `Test Cases` and `Summary`
     (plus one extra sheet per additional ticket if the user chose separate tables — see
     "Handling Multiple Jira Tickets" below).
   - The `Test Cases` sheet has exactly one block: the 14-column table described in
     "Table Structure and Column Rules", with `wrap: true` set on any column whose values may
     span multiple lines (Test Steps, Description, Expected Result, Comments) and
     `width` set per the "Suggested Column Widths" table.
   - Each row is a **positional array**, not a dict — values in the same order as that block's
     `columns` list, e.g. `["TC-PROJ-123-001", "User can reset password...", ...]`. Do not
     repeat the column headers on every row; the converter maps array position to column.
   - For **Test Steps**, write each step on its own line within the same string value using
     `\n` — not HTML `<br>` tags, and not multiple array entries — since `\n` is what the
     converter turns into an in-cell line break when `wrap` is true.
   - The `Summary` sheet has two blocks, stacked in this order: `"Summary Counts"` (title +
     two columns, `Category`/`Count`) and `"Coverage Mapping"` (title + two columns,
     `Acceptance Criterion`/`Covered By`). See "Summary & Coverage Sheet" below for content.
3. Write this JSON to a scratch file, e.g. `/home/claude/test-cases-<TICKET-ID>.json`. This
   file is intermediate — it is never shown to the user and never placed in
   `/mnt/user-data/outputs/`.

### PHASE 3: Convert JSON to XLSX (Only After Phase 2 Completes)

1. Call the shared converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python .claude/skills/shared/json_to_xlsx.py /home/claude/test-cases-<TICKET-ID>.json /mnt/user-data/outputs/<TICKET-ID>-test-cases.xlsx
   ```
   This is a single shared script other skills also invoke (test-data-generator,
   bug-report-generator, etc.) — never copy it into this skill's own folder.
2. Confirm the script printed `"status": "success"`. If it errors, the JSON likely doesn't
   match the schema (check for missing `columns`/`rows` keys, or a row array whose length or
   order doesn't line up with that block's `columns`) — fix the JSON in Phase 2 and re-run; do
   not patch the output XLSX by hand.
3. Present the resulting file to the user with `present_files` (or equivalent) so they can
   download it or upload/copy it into Google Sheets.

**Do not skip straight from Phase 1 to an XLSX file.** The JSON intermediate is mandatory even
for small ticket sets — it's what keeps this skill's output compatible with the shared
converter and easy to diff/debug if a column looks wrong.

## Table Structure and Column Rules (do not alter these specs)

**Exactly 14 columns, in this order:**

| Test Case ID | Test Case Name | Description | Prerequisites | Test Steps | Input Data | Expected Result | Actual Result | Status | Labels | Comments | References | Screenshot / Evidence | Executed Date |

**One row per test case.** In the JSON, this is one array per test case in the `Test Cases`
block's `rows` list, with values in the exact order of the 14 columns above; the converter
renders each array as a single spreadsheet row. For multi-line content within a cell (e.g.,
Test Steps), use `\n` inside that column's string value — never split one test case across
multiple rows, and never reorder values within a row relative to the column list.

#### Suggested Column Widths and Wrap Settings

| Column | Width | Wrap |
|---|---|---|
| Test Case ID | 16 | false |
| Test Case Name | 30 | false |
| Description | 35 | true |
| Prerequisites | 28 | true |
| Test Steps | 40 | true |
| Input Data | 25 | true |
| Expected Result | 35 | true |
| Actual Result | 25 | true |
| Status | 14 | false |
| Labels | 22 | false |
| Comments | 30 | true |
| References | 18 | false |
| Screenshot / Evidence | 22 | false |
| Executed Date | 14 | false |

## Column Format Reference

| Column | Format Rule | Examples | Default/Placeholder |
|--------|-------------|----------|---------------------|
| Test Case ID | TC-<JIRA-ID>-<NNN> where NNN is 001, 002, etc. | TC-PROJ-123-001 | N/A (required) |
| Test Case Name | Short title describing the test | "User can reset password with valid email" | N/A (required) |
| Description | 1–2 sentences describing what is tested | "Tests that password reset email is sent after user requests it." | (required) |
| Prerequisites | Conditions that must be true before test runs | "User account exists; email is verified" | "None" if not applicable |
| Test Steps | Numbered list: one action per line, joined with `\n` in that row's array element for this column's position | "1. Click \"Forgot Password\"\n2. Enter email\n3. Click Submit" | (required) |
| Input Data | Test data values used (usernames, emails, passwords, etc.) | "Email: test@example.com; New PW: SecureP@ss123" | "N/A" if not applicable |
| Expected Result | What should happen if test passes | "Password reset email sent within 2 minutes" | (required) |
| Actual Result | (leave blank for initial generation) | (empty until test is executed) | TBD (placeholder) |
| Status | Exactly one of: `Not Executed` \| `Pass` \| `Fail` \| `Blocked` | "Not Executed" | "Not Executed" (default) |
| Labels | Comma-separated keywords; no spaces after commas | "positive-flow,security,email" | (optional; leave blank if none apply) |
| Comments | Notes about test; include inferred assumptions here | "Assumed token expiry is 30min per AC#2" | (optional; use only if needed) |
| References | Links to related docs, acceptance criteria, or design | "AC#1, design-doc-link" | (optional; leave blank if none) |
| Screenshot / Evidence | Filename, link, or placeholder | "screenshot-01.png" or "TBD" or "Not attached - user login page mockup" | TBD (if no screenshot provided) |
| Executed Date | ISO 8601 date format YYYY-MM-DD, or TBD | "2026-06-01" or "TBD" | TBD (placeholder) |

## Test Case Coverage Rules (Mandatory)

You must generate between 5 and 20 test cases per ticket. Each test case must satisfy one of these types; ensure you cover all that apply:

- **Always include:** At least 1 positive flow (happy path), 1 negative flow (error handling), 1 edge/boundary condition
- **If ticket touches authentication, authorization, input validation, or data handling:** Include at least 1 security test case
- **If ticket affects UI layout, text rendering, visual components, or styling:** Include at least 1 UX/visual test case
- **Coverage rule:** At least 1 test case per acceptance criterion

## Summary & Coverage Sheet

The `Summary` sheet (second tab) is built from two blocks in the Phase 2 JSON:

1. **Summary Counts block** — rows of `Category`/`Count`: total test cases, plus a breakdown by
   category (positive flow, negative flow, edge/boundary, security, accessibility,
   performance/UX — only include categories that apply to the ticket).
2. **Coverage Mapping block** — rows of `Acceptance Criterion`/`Covered By`, listing each AC
   and the Test Case IDs that cover it (comma-separated if more than one).

## Error Handling & Edge Cases

### Handling Incomplete or Conflicting Acceptance Criteria
If acceptance criteria are unclear or conflict after Phase 1:
- List the conflicts explicitly
- Ask the user: "Should I infer and proceed (flagging assumptions in Comments), or do you want to clarify first?"
- Only proceed if user says yes; flag all inferred details in the Comments column

### Handling Screenshots
- If attachment provided: Use filename or link in the "Screenshot / Evidence" cell
- If no attachment: Use "TBD"
- If described but not attached: Use "Not attached - [description]"

### Handling Multiple Jira Tickets
- Default behavior: Process only the primary ticket
- If multiple distinct features detected: Ask user to choose (one table vs. separate tables)
- If the user chooses separate tables, add one additional `sheets` entry per ticket to the same
  Phase 2 JSON (e.g. sheet names `VAS-359`, `VAS-360`), each with its own `Test Cases` block,
  and add a corresponding `Summary Counts`/`Coverage Mapping` block pair per ticket to the
  `Summary` sheet — still a single JSON file and a single workbook, not separate files, unless
  the user asks for separate files.

### Handling JSON/Converter Errors
- If `json_to_xlsx.py` fails or produces an unexpected layout, do not hand-edit the resulting
  XLSX. Re-check the Phase 2 JSON against the schema in the converter's docstring (most common
  issues: a row array that's shorter/longer than that block's `columns` list, values in the
  wrong position relative to `columns` order, or a missing `rows`/`columns` key on a block)
  and re-run Phase 3.

## Example Invocation

**User Input:**
"Jira Ticket PROJ-456: Add password reset flow to user settings. Users should be able to request a reset email, verify a token, and set a new password. ACs: (1) User can request password reset email, (2) Reset token expires after 30min, (3) New password must meet complexity rules."

**Your Response (Phase 1):**
"I have the Jira ticket and three acceptance criteria. Do you have design screenshots or descriptions? If not, I'll use 'TBD' for the Screenshot/Evidence column. Ready to proceed?"

**After User Confirms (Phase 2):**
Build the JSON workbook spec (`Test Cases` sheet: 14-column table, 5–20 test cases covering
positive, negative, edge, security, and UX scenarios as applicable; `Summary` sheet: Summary
Counts + Coverage Mapping blocks) and write it to a scratch file.

**Phase 3:**
Run `shared/json_to_xlsx.py` against that JSON to produce the `.xlsx`, save it to
`/mnt/user-data/outputs/`, and present it to the user.