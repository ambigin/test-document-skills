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

Generate a comprehensive Test Case Document from a Jira ticket. Output is an XLSX workbook
produced by the shared converter script (`md_table_to_xlsx.py`), with both a Test Cases sheet
and a Summary sheet.

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

Before generating any output, you MUST validate the following. If any item is missing or unclear, ask the specified question and wait for the user's answer.

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Jira Ticket ID | Yes | Must include title, description, and ticket ID | "Please provide the Jira ticket ID, title, and full description." |
| Acceptance Criteria | Yes | Must be clear and non-conflicting; list them numbered | "Please provide the numbered acceptance criteria. If any conflict, clarify now." |
| Multiple Tickets/Features | Detect | Scan input for multiple distinct Jira tickets or features | "I detected multiple features/tickets. Do you want: (A) One table for the primary ticket, or (B) Separate tables per feature/ticket?" |
| Screenshots/Evidence | Detect | Note whether attachments or descriptions exist | Not required; proceed with TBD if missing |

**Mandatory Rule:** If all required items are clearly present in the user's message, proceed directly to Phase 2. Only pause if something is missing or genuinely ambiguous. When inferring, flag assumptions in the Comments column rather than asking.

### PHASE 2: Generate and Write Tables (Only After Phase 1 Completes)

Do not generate the tables until Phase 1 is complete.

1. Build all test case rows following the Column Format Reference and Coverage Rules below.
2. **Do NOT echo the tables to chat.** Write both `## Sheet:` blocks directly to a temp file using the Write tool (session scratchpad path) or Bash (`/tmp/test-cases-<TICKET-ID>.md`). The file must contain:
   - `## Sheet: Test Cases` — the 14-column table
   - `## Sheet: Summary` — the Summary Counts table followed by the Coverage Mapping table
   For multiple tickets, include one `## Sheet: <TICKET-ID>` block per ticket in the same file.
3. Confirm with a single line: "✓ N test cases written — running converter..."

### PHASE 3: Convert Markdown Tables to XLSX (Only After Phase 2 Completes)

1. Call the shared converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python .claude/skills/shared/md_table_to_xlsx.py /tmp/test-cases-<TICKET-ID>.md /mnt/user-data/outputs/<TICKET-ID>-test-cases.xlsx
   ```
   This is the same shared script all test-generation skills call — never copy it into this
   skill's own folder.
2. Confirm the script printed `"status": "success"`. If it errors, check that the temp file
   contains valid pipe-delimited markdown tables with `## Sheet:` headings, fix if needed, and
   re-run. Do not patch the output XLSX by hand.
3. Present the resulting file to the user with `present_files` (or equivalent) so they can
   download it or copy it into Google Sheets.

## Table Structure and Column Rules (do not alter these specs)

**Exactly 14 columns, in this order:**

| Test Case ID | Test Case Name | Description | Prerequisites | Test Steps | Input Data | Expected Result | Actual Result | Status | Labels | Comments | References | Screenshot / Evidence | Executed Date |

**One row per test case.** In the JSON, this is one array per test case in the `Test Cases`
block's `rows` list, with values in the exact order of the 14 columns above; the converter
renders each array as a single spreadsheet row. For multi-line content within a cell (e.g.,
Test Steps), use `\n` inside that column's string value — never split one test case across
multiple rows, and never reorder values within a row relative to the column list.

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
- If multiple distinct features detected: Ask user to choose (one combined table vs. separate tables)
- If the user chooses separate tables, add one `## Sheet: <TICKET-ID>` block per ticket in the
  Phase 2 markdown output — still a single temp file and a single workbook, not separate files,
  unless the user asks for separate files.

### Handling Converter Errors
- If `md_table_to_xlsx.py` fails, do not hand-edit the resulting XLSX. Re-check the temp file
  for valid pipe-delimited markdown syntax (each row starts and ends with `|`, header separator
  row uses `---`, `## Sheet:` headings are present if multiple tables) and re-run Phase 3.

