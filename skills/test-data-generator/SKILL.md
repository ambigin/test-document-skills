---
name: test-data-generator
description: >
  Generates ≥50-row, Excel-ready Test Data Documents covering valid, invalid, boundary, missing,
  special, and duplicate data categories — for any data-driven domain (registration, checkout,
  ETL, onboarding, healthcare, banking, etc.). Use when the user asks for test data, sample
  data, field coverage, or data sets to drive QA or API testing. Trigger for "give me test data
  for X", "generate data to test this form", "I need test data for these fields", "boundary
  values for this field", "what data should I use to test my API", or "help me test this
  validation rule." Distinct from test case generation (this produces input values, not
  pass/fail scenarios) and from API test case generation (this is data sets, not request/response
  contracts). Trigger whenever the user describes fields, validation rules, or data constraints
  and needs concrete values to use in testing.
---

# Test Data Generator

## Purpose

Generate a comprehensive, traceable Test Data Document from minimal inputs.
Output is an XLSX workbook of ≥50 rows covering all required data quality categories,
produced by the bundled converter script (`md_table_to_xlsx.py`).

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs

> **Read [references/PHASE1_GUIDE.md](references/PHASE1_GUIDE.md) before starting Phase 1.** It covers project context (`PROJECT_CONTEXT.md`), when to ask vs. infer, multi-item handling, assumption flagging, table formatting rules, and converter error recovery.

Before generating any output, you MUST validate the following. Ask the listed question only when a required item is missing and can't be reasonably inferred; otherwise infer it and flag the assumption (see PHASE1_GUIDE.md → When to Ask vs. When to Infer).

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Domain / System | Yes | Must identify the system being tested (e.g., banking onboarding, healthcare patient records, e-commerce checkout) | "What system or domain is this test data for?" |
| Fields to Cover | Yes | Use the listed fields; if none are given, infer realistic fields from the domain and flag them in Notes | Only if the domain is too vague to infer fields: "Which fields should I cover (e.g., Name, Email, DOB, Phone, NID)?" |
| Validation Rules / Requirements | Yes | Use the given constraints, formats, or acceptance criteria per field; where none are given, apply industry-standard rules for the domain and flag them in Notes | None — infer and flag instead of asking |
| Multiple Domains/Systems | Detect | Scan input for multiple distinct domains or systems | "I detected multiple domains/systems. Do you want: (A) One table covering all of them, or (B) Separate tables per domain?" |
| Volume / Row Count | Detect | Note whether a specific row count or distribution was requested | Not required; default to 50 rows minimum at standard distribution if missing |

**Mandatory Rule:** If all required items are clearly present or inferable, proceed directly to Phase 2. Flag all inferred values in the Notes column rather than asking for confirmation.

### PHASE 2: Generate and Write Table (Only After Phase 1 Completes)

Build all rows following the structure and rules below. **Do NOT echo the table to chat.**
Write directly to a temp file in the session scratchpad directory (or the system temp directory if your environment has no scratchpad) — never inside the user's project. Confirm with: "✓ N rows written — running converter..."

### PHASE 3: Convert Markdown Table to XLSX (Only After Phase 2 Completes)

1. Call the bundled converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py" "<scratchpad>/test-data-<domain-slug>.md" "<output>/<domain-slug>-test-data.xlsx"
   ```
   The script is in `scripts/` next to this SKILL.md; if the command's path wasn't filled in with this skill's folder, use that folder's full path. If `python3` fails or isn't found (on Windows it's often a Microsoft Store placeholder that prints "Python was not found"), use `python` or `py -3` instead. The script needs `openpyxl`.
   Replace `<scratchpad>` with the temp directory from Phase 2. For `<output>`, use `/mnt/user-data/outputs` on Claude.ai or `./outputs` when running locally.
2. Confirm the script printed `"status": "success"` with no `warnings` — a warning means cells or lines were dropped, so fix the temp file (see PHASE1_GUIDE.md → Standard Converter Error Recovery) and re-run. If it errors, check that the temp file
   contains valid pipe-delimited markdown table syntax, fix if needed, and re-run.
3. Tell the user the full output path and confirm the file is ready to open in Excel or import into Google Sheets. State the path in a single line — no preamble, no trailing summary.

## Error Handling & Edge Cases

### Handling Conflicting Requirements
If two or more rules contradict each other (e.g. a field is described as both required and optional):
- List the conflicts explicitly
- Ask the user: "Should I infer and proceed (flagging assumptions in Notes), or do you want to clarify first?"
- Proceed once the user answers; flag all inferred details in the Notes column

Missing or vague rules are not conflicts — see Handling Missing Validation Rules below.

### Handling Missing Validation Rules
- If a field has no documented constraint: apply industry-standard validation rules for that field/domain and note this in the Notes column
- If a constraint is ambiguous: state the assumed interpretation in the Notes column

### Handling Multiple Domains/Systems
- Default behavior: ask the user to choose (one table vs. separate tables) per the Phase 1 question
- Do not silently split or merge domains without confirmation

## Apply Design Techniques

Apply all three to every constrained field:

- **Equivalence Partitioning** — one representative value per valid/invalid class per field
- **Boundary Value Analysis** — min, max, min−1, max+1 for every field with a numeric or length constraint. Always generate the pair: valid boundary + one-step-beyond (invalid boundary)
- **Negative Testing** — malformed formats, wrong data types, values that violate business rules

## Test Data Coverage Rules (Mandatory)

Every test data document must include all six categories. Each field listed in Phase 1 must satisfy these types; ensure you cover all that apply:

- **Always include:** Valid, Invalid, Missing, and Special rows for every field; Boundary rows for every field with a length, range, or numeric constraint; Duplicate rows for every field that must be unique
- **Valid** — correct, realistic inputs the system should accept
- **Invalid** — wrong format, out-of-range values, type mismatches, constraint violations
- **Boundary** — exact min, max, and one-below/one-above for every constrained field
- **Missing** — blank strings, nulls, whitespace-only, omitted required fields
- **Special** — unicode, emojis, SQL/script injection strings, non-ASCII names
- **Duplicate** — intentional duplicates to verify uniqueness enforcement (IDs, emails, national IDs)
- **Coverage rule:** Every documented validation rule (from Phase 1) must map to at least one explicit row

## Volume & Distribution

Generate a **minimum of 50 rows**, aiming for roughly this distribution. The percentages are targets, not limits — the coverage rules above win (for example, Special and Duplicate rows may exceed ~5% when many fields need them):

| Category | Target % |
|---|---|
| Valid | ~30% |
| Invalid | ~30% |
| Boundary | ~25% |
| Missing / Null | ~10% |
| Special + Duplicate | ~5% |

## Data Quality Standards

| Standard | Rule |
|---|---|
| **Accuracy** | Values must be realistic and plausible for the domain (real-looking names, valid-format IBANs, real phone patterns) |
| **Completeness** | Every field in the inputs must appear in at least one row per applicable category |
| **Consistency** | Values within a row must not contradict each other unless the row is intentionally testing an invalid state |
| **Uniqueness** | Do not repeat identical rows unless the purpose is specifically to test duplicate handling |
| **Reusability** | Data must be usable across multiple test scenarios without modification |
| **Traceability** | Every row must have a clear, specific Purpose — never use vague text like "test data" or "check field" |

## Table Structure and Column Rules

**Exactly 8 columns, in this order:**

| Data Set ID | Category | Field | Sub-field / Type | Value | Expected Behavior | Purpose | Notes |

## Column Format Reference

| Column | Format Rule | Examples | Default/Placeholder |
|--------|-------------|----------|---------------------|
| Data Set ID | Sequential: TD_001, TD_002… Prefix by domain if multiple domains (e.g., REG_001, PAY_001) | "TD_001" | N/A (required) |
| Category | Exactly one of: `Valid` \| `Invalid` \| `Boundary` \| `Missing` \| `Special` \| `Duplicate` | "Boundary" | N/A (required) |
| Field | Exact field name as it appears in the system or requirements | "Email" | N/A (required) |
| Sub-field / Type | Clarifies the field variant tested | "DOB → Future date" | N/A (required) |
| Value | The exact value to input. Show each leading or trailing space that matters as `␣` and say so in Notes | "NULL", "EMPTY STRING", "WHITESPACE ONLY" for null/empty cases; "␣john@example.com" for a leading space | Never leave blank |
| Expected Behavior | What the system should do; include error message key where applicable | "Reject with error (ERR_EMAIL_FORMAT)" | N/A (required) |
| Purpose | One sentence: why this specific value is being tested | "Verifies email format validation rejects missing @ symbol" | N/A (required) |
| Notes | Assumptions, source of rule, or clarification on edge case behavior | "Assumed max length 254 per RFC 5321 — no explicit rule provided" | "None" if not applicable |

## Taxonomies

**Category:** Valid | Invalid | Boundary | Missing | Special | Duplicate

**Expected Behavior:** Accept | Reject | Reject with error | Flag for review | Trigger duplicate warning

## Output Rules

- Generate all rows before writing to the temp file — do not truncate.
- The Value column must never be blank — always use `NULL`, `EMPTY STRING`, or `WHITESPACE ONLY` for empty cases.
- Show each leading or trailing space that matters as `␣` and mention it in Notes — the converter trims spaces at the edges of a cell.
- For boundary rows, always generate the pair: valid boundary + one-step-beyond (invalid boundary).
- State all assumptions in the Notes column only.
- Escape any `|` inside a value as `\|` (common in SQL injection strings such as `' \|\| '`).