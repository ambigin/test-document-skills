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

Produces a comprehensive, traceable, Excel-ready Test Data Document from minimal inputs.
The output is a single markdown table of ≥50 rows covering all required data quality categories.

---

## Step 1 — Collect Inputs

Gather the following. If any are missing, proceed with assumptions and document them in the Notes column.

| Input | Description | Fallback if Omitted |
|---|---|---|
| **DOMAIN / SYSTEM** | The system being tested (e.g., banking onboarding, healthcare patient records, e-commerce checkout) | Default to a generic user registration system |
| **FIELDS TO COVER** | Specific fields to generate data for (e.g., Name, Email, DOB, Phone, NID) | Infer realistic fields from the domain |
| **JIRA TICKET / REQUIREMENTS** | Acceptance criteria, validation rules, or field constraints | Apply industry-standard validation rules for the domain |

Do not ask for clarification before generating. State assumptions in the Notes column of affected rows.

---

## Step 2 — Apply Design Techniques

Apply all three to every constrained field:

- **Equivalence Partitioning** — one representative value per valid/invalid class per field
- **Boundary Value Analysis** — min, max, min−1, max+1 for every field with a numeric or length constraint. Always generate the pair: valid boundary + one-step-beyond (invalid boundary)
- **Negative Testing** — malformed formats, wrong data types, values that violate business rules

---

## Step 3 — Coverage Requirements

Every test data document must include all six categories:

1. **Valid** — correct, realistic inputs the system should accept
2. **Invalid** — wrong format, out-of-range values, type mismatches, constraint violations
3. **Boundary** — exact min, max, and one-below/one-above for every constrained field
4. **Missing** — blank strings, nulls, whitespace-only, omitted required fields
5. **Special** — unicode, emojis, SQL/script injection strings, non-ASCII names
6. **Duplicate** — intentional duplicates to verify uniqueness enforcement (IDs, emails, national IDs)

Every field listed in the inputs must be covered across all applicable categories. If a field has documented validation rules (from the Jira ticket or requirements), map each rule to at least one test row explicitly.

---

## Step 4 — Volume & Distribution

Generate a **minimum of 50 rows** distributed as:

| Category | Target % |
|---|---|
| Valid | ~30% |
| Invalid | ~30% |
| Boundary | ~25% |
| Missing / Null | ~10% |
| Special + Duplicate | ~5% |

---

## Step 5 — Data Quality Standards

| Standard | Rule |
|---|---|
| **Accuracy** | Values must be realistic and plausible for the domain (real-looking names, valid-format IBANs, real phone patterns) |
| **Completeness** | Every field in the inputs must appear in at least one row per applicable category |
| **Consistency** | Values within a row must not contradict each other unless the row is intentionally testing an invalid state |
| **Uniqueness** | Do not repeat identical rows unless the purpose is specifically to test duplicate handling |
| **Reusability** | Data must be usable across multiple test scenarios without modification |
| **Traceability** | Every row must have a clear, specific Purpose — never use vague text like "test data" or "check field" |

---

## Step 6 — Output Format

Generate a **single markdown table** with exactly these 8 columns in this order:

| Column | Rules |
|---|---|
| **Data Set ID** | Sequential: TD_001, TD_002… Prefix by domain if multiple domains (e.g., REG_001, PAY_001) |
| **Category** | Valid / Invalid / Boundary / Missing / Special / Duplicate |
| **Field** | Exact field name as it appears in the system or requirements |
| **Sub-field / Type** | Clarify the field variant tested (e.g., Email → Disposable domain, DOB → Future date) |
| **Value** | The exact value to input. Use `NULL`, `EMPTY STRING`, or `WHITESPACE ONLY` for null/empty cases — never leave blank |
| **Expected Behavior** | What the system should do: Accept / Reject / Reject with error / Flag for review / Trigger duplicate warning. Include error message key where applicable (e.g., ERR_EMAIL_FORMAT) |
| **Purpose** | One sentence: why this specific value is being tested |
| **Notes** | Assumptions, source of rule, or clarification on edge case behavior |

---

## Taxonomies

**Category:** Valid | Invalid | Boundary | Missing | Special | Duplicate

**Expected Behavior:** Accept | Reject | Reject with error | Flag for review | Trigger duplicate warning

---

## Output Rules

- Do not truncate the table. Generate all rows before outputting.
- Do not add explanatory prose before or after the table.
- The Value column must never be blank — always use `NULL`, `EMPTY STRING`, or `WHITESPACE ONLY` for empty cases.
- For boundary rows, always generate the pair: valid boundary + one-step-beyond (invalid boundary).
- State all assumptions in the Notes column, never as prose outside the table.