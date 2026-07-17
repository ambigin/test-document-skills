---
name: test-data-generator
description: >
  Generates comprehensive, Excel-ready Test Data Documents for QA and data validation.
  Use this skill whenever the user asks to generate test data, create a test data document,
  produce test cases for a system or domain, validate field coverage for QA, or design
  test data for ETL, onboarding, registration, checkout, or any other data-driven system.
  Trigger even for casual requests like "give me test data for X", "help me test this form",
  "generate test cases for these fields", or "I need data to test my API". If the user
  mentions fields, validation rules, a Jira ticket, acceptance criteria, or a domain with
  data inputs, use this skill.
---

# Test Data Generator

## Purpose

Generate a comprehensive, traceable, Excel-ready Test Data Document from minimal inputs.
The output is a single markdown table of ≥50 rows covering all required data quality categories.

## Workflow: Two Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

Before generating any output, you MUST validate the following. If any item is missing or unclear, ask the specified question and wait for the user's answer.

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Domain / System | Yes | Must identify the system being tested (e.g., banking onboarding, healthcare patient records, e-commerce checkout) | "What system or domain is this test data for?" |
| Fields to Cover | Yes | Must list the specific fields, or confirm inference from domain is acceptable | "Which fields should I cover (e.g., Name, Email, DOB, Phone, NID)? If you don't have a list, I can infer realistic fields from the domain — confirm to proceed that way." |
| Validation Rules / Requirements | Yes | Must capture constraints, formats, or acceptance criteria per field, or confirm industry-standard rules are acceptable | "Do you have a Jira ticket, requirements doc, or specific validation rules (lengths, formats, ranges)? If not, I'll apply industry-standard rules for the domain — confirm to proceed that way." |
| Multiple Domains/Systems | Detect | Scan input for multiple distinct domains or systems | "I detected multiple domains/systems. Do you want: (A) One table covering all of them, or (B) Separate tables per domain?" |
| Volume / Row Count | Detect | Note whether a specific row count or distribution was requested | Not required; default to 50 rows minimum at standard distribution if missing |

**Mandatory Rule:** Do NOT proceed to Phase 2 until the user confirms all required items are ready, OR the user explicitly says "Proceed with inference" (then flag assumptions in the Notes column).

### PHASE 2: Generate Markdown Table (Only After Phase 1 Completes)

Generate exactly one markdown table with the structure and rules below. Do not generate the table until Phase 1 is complete.

## Error Handling & Edge Cases

### Handling Incomplete or Conflicting Requirements
If fields or validation rules are unclear or conflict after Phase 1:
- List the conflicts explicitly
- Ask the user: "Should I infer and proceed (flagging assumptions in Notes), or do you want to clarify first?"
- Only proceed if user says yes; flag all inferred details in the Notes column

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

- **Always include:** Valid, Invalid, Boundary, Missing, Special, and Duplicate rows for every field
- **Valid** — correct, realistic inputs the system should accept
- **Invalid** — wrong format, out-of-range values, type mismatches, constraint violations
- **Boundary** — exact min, max, and one-below/one-above for every constrained field
- **Missing** — blank strings, nulls, whitespace-only, omitted required fields
- **Special** — unicode, emojis, SQL/script injection strings, non-ASCII names
- **Duplicate** — intentional duplicates to verify uniqueness enforcement (IDs, emails, national IDs)
- **Coverage rule:** Every documented validation rule (from Phase 1) must map to at least one explicit row

## Volume & Distribution

Generate a **minimum of 50 rows** distributed as:

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
| Value | The exact value to input | "NULL", "EMPTY STRING", "WHITESPACE ONLY" for null/empty cases | Never leave blank |
| Expected Behavior | What the system should do; include error message key where applicable | "Reject with error (ERR_EMAIL_FORMAT)" | N/A (required) |
| Purpose | One sentence: why this specific value is being tested | "Verifies email format validation rejects missing @ symbol" | N/A (required) |
| Notes | Assumptions, source of rule, or clarification on edge case behavior | "Assumed max length 254 per RFC 5321 — no explicit rule provided" | "None" if not applicable |

## Taxonomies

**Category:** Valid | Invalid | Boundary | Missing | Special | Duplicate

**Expected Behavior:** Accept | Reject | Reject with error | Flag for review | Trigger duplicate warning

## Example Invocation

**User Input:**
"Give me test data for an e-commerce checkout form."

**Your Response (Phase 1):**
"Got it — e-commerce checkout. To build accurate coverage, could you share: (1) the specific fields to test (e.g., Card Number, Expiry, CVV, Shipping Address, Promo Code), and (2) any validation rules or a Jira ticket for those fields? If you don't have these handy, I can infer standard checkout fields and apply industry-standard validation rules — just confirm and I'll proceed that way."

**After User Confirms (Phase 2):**
Generate the 8-column markdown table with ≥50 rows covering Valid, Invalid, Boundary, Missing, Special, and Duplicate categories for every field, per the Volume & Distribution targets above.

## Output Rules

- Do not generate the table until Phase 1 is complete.
- Do not truncate the table. Generate all rows before outputting.
- Do not add explanatory prose before or after the table.
- The Value column must never be blank — always use `NULL`, `EMPTY STRING`, or `WHITESPACE ONLY` for empty cases.
- For boundary rows, always generate the pair: valid boundary + one-step-beyond (invalid boundary).
- State all assumptions in the Notes column, never as prose outside the table.