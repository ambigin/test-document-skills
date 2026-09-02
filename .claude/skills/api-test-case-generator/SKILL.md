---
name: api-test-case-generator
description: >
  Generates a complete, execution-ready API test suite (REST or GraphQL) as an XLSX
  spreadsheet, covering authentication, request/response validation, business logic, error
  handling, idempotency, rate limiting/performance, and security — ready to open directly or
  copy-paste into Postman, Jira, or Google Sheets. Use this skill whenever the user wants API
  test cases, an API test plan, an endpoint test suite, contract tests, or security test cases
  for an endpoint, even if they only paste a Swagger/OpenAPI snippet, a Postman collection, or a
  raw endpoint description without asking by name. Trigger for "generate test cases for this
  endpoint", "write API tests for X", "test this POST/GET/PUT/DELETE route", "QA this API", "I
  need test coverage for this Swagger spec", or "security test this endpoint." Distinct from
  UI/usability test case generation and from functional QA test cases for application features
  — this skill is specifically for HTTP API endpoints (request/response contracts, auth, status
  codes, payload-level security).
---

# API Test Case Generator Skill

## Purpose

Act as a Senior API QA Engineer and generate a complete, execution-ready API test suite for a
single endpoint — covering functional, non-functional, security, and edge-case scenarios.
Output is an XLSX workbook produced by the shared converter script (`md_table_to_xlsx.py`).

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

> See [PHASE1_GUIDE.md](../shared/PHASE1_GUIDE.md) for common validation rules, multi-item detection, inference flagging, and file path conventions.

Before generating any output, you MUST gather the following. If an item is missing, **do not block on it** — infer a reasonable value and flag the assumption in that row's Notes column as `(assumed — verify)`. Only stop and ask if the endpoint itself, method, or auth type is completely unspecified (you cannot meaningfully infer test cases without knowing what is being tested).

| Item | Required to Proceed? | If Missing |
|------|----------------------|------------|
| Endpoint URL + Method | Yes — ask if absent | "What's the endpoint and HTTP method? (e.g. `POST /v1/users/login`)" |
| Auth Type | Yes — ask if absent | "What auth does this endpoint use — Bearer/JWT, API key, OAuth 2.0, Basic, or none?" |
| Request Schema | No | Infer from method + business rules; flag inferred fields in Notes |
| Response Schema | No | Infer from business rules; flag as "(assumed — verify)" |
| Business Rules | No | Proceed with standard CRUD/validation assumptions if none given; flag in Notes |
| Jira/Docs Link | No | Use "None" in Linked Requirement column |
| Multiple Endpoints Detected | Detect | "I see multiple endpoints here. One combined workbook (sheet per endpoint), or a separate file per endpoint?" |

Once endpoint, method, and auth type are known, proceed to Phase 2 — don't over-interrogate the user for a fully execution-ready spec; this skill is built to infer and flag rather than stall.

### PHASE 2: Generate Markdown Table

Do not generate the table until Phase 1 is complete.

1. Build all test case rows following the Coverage Requirements and Column Rules below.
2. **Do NOT echo the table to chat.** Write directly to a temp file in the session scratchpad directory using the Write tool — never use `/tmp/` or other system temp paths:
   - Single endpoint: one table, no `## Sheet:` heading needed.
   - Multiple endpoints (one workbook): prefix each table with `## Sheet: <endpoint-slug>` (replace `/` with `-`, drop query strings, truncate to 31 chars).
3. Confirm with a single line: "✓ N test cases written — running converter..."

### PHASE 3: Convert Markdown Table to XLSX

1. Call the shared converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python3 .claude/skills/shared/md_table_to_xlsx.py <scratchpad>/api-tests-<endpoint-slug>.md <output>/<endpoint-slug>-api-tests.xlsx
   ```
   Replace `<scratchpad>` with the session scratchpad path from your system context. For `<output>`, use `/mnt/user-data/outputs` on Claude.ai or `./outputs` when running locally.
   This is the same shared script all test-generation skills call — never copy it into this
   skill's own folder.
2. Confirm the script printed `"status": "success"`. If it errors, check that the temp file
   exists and contains valid pipe-delimited markdown table syntax (header row, separator row
   of `---`, data rows), fix if needed, and re-run. Do not patch the output XLSX by hand.
3. Tell the user the full output path and confirm the file is ready to open in Excel or import into Google Sheets. No preamble, no closing summary — the workbook is the deliverable, unless the user asked a question alongside the request.

## Coverage Requirements — All 8 Categories

1. **Authentication & authorization (AUTH)** — valid tokens, expired tokens, missing tokens, wrong roles, insufficient scope, cross-tenant access attempts.
2. **Request validation (VAL)** — missing required fields, wrong data types, malformed JSON, extra/unexpected fields, empty string vs. null vs. missing, length/format violations.
3. **Response validation (VAL)** — correct status codes, schema matches spec, required headers present, no sensitive data leaked.
4. **Business logic (BIZ)** — every rule in the inputs verified, correct state transitions, data persisted accurately, side-effects confirmed.
5. **Error handling (ERR)** — meaningful error messages, correct error codes, no stack traces or internal paths exposed, consistent error schema across failures.
6. **Idempotency & duplicate handling (IDEM)** — repeated identical requests produce the expected result (safe methods return same data; POST idempotency depends on design).
7. **Rate limiting & performance (PERF)** — 429 with `Retry-After` on limit breach; p95 response time under threshold; payload size limits enforced.
8. **Security (SEC)** — SQL/NoSQL injection, XSS strings in body fields, IDOR, mass assignment, sensitive data not returned in responses or logs.

**Minimum row counts:** 3 AUTH rows; 1 VAL row per request field; 1 BIZ row per business rule; 2 ERR rows; 1 IDEM row; 1 PERF row; 3 SEC rows. Generate more if endpoint complexity warrants it. Every business rule supplied must map to at least one dedicated row — no exceptions.

**Paired baseline rule:** For every invalid-input row (VAL or SEC), generate the corresponding valid baseline row immediately above or below it in the `rows` array, so a reviewer can confirm the negative test is meaningful against a known-good control.

**Field-level granularity:** If one field has multiple constraints (e.g. a length limit AND a format constraint), generate a separate row per rule — never combine two assertions about different constraints into one row.

## Table Structure — Exactly 14 Columns, In This Order

| Test Case ID | Test Case Name | Category | Priority | Preconditions | Request Headers | Request Body | Expected Status Code | Expected Response Body | Expected Headers | Assertions | Test Data | Notes | Linked Requirement |

## Column Rules

| Column | Rule |
|---|---|
| Test Case ID | `API-TC-[PREFIX]-[NNN]` — sequential within each category, e.g. `API-TC-AUTH-001`, `API-TC-SEC-003` |
| Test Case Name | Concise: Auth type/Field/Rule + expected outcome |
| Category | Exactly one of: `AUTH` \| `VAL` \| `BIZ` \| `ERR` \| `IDEM` \| `PERF` \| `SEC` |
| Priority | `P1` (blocks release) / `P2` (fix before next release) / `P3` (fix when capacity allows) |
| Preconditions | Required system state, user role, seed data, or tool setup. For multi-step, use a numbered list separated by semicolons: `1. … ; 2. … ; 3. …` |
| Request Headers | Complete JSON object as plain text, e.g. `{"Authorization": "Bearer <token>", "Content-Type": "application/json"}` |
| Request Body | Complete JSON object (valid or intentionally invalid) as plain text. Use `—` for GET/DELETE with no body |
| Expected Status Code | Exact code from the taxonomy below — no other values permitted |
| Expected Response Body | Key fields and values the response must contain (partial schema acceptable) |
| Expected Headers | Required response headers, e.g. `Content-Type: application/json`, `Retry-After: present` |
| Assertions | Pipe-separated, independently verifiable, exact field paths and values — never "response is correct." Format: `Status = 401 \| Response time < 500ms \| Field error.code = "TOKEN_EXPIRED" \| Schema valid \| No sensitive data exposed` |
| Test Data | Specific accounts, tokens, resource IDs, seed data. Use "Standard test user sufficient" if nothing special is needed |
| Notes | **Never blank.** Edge case rationale, security consideration, chain risk, assumption flag `(assumed — verify)`, or follow-up test reference |
| Linked Requirement | Jira ticket ID, business rule reference, or "None" |

## Status Code Taxonomy — Use Exactly These

`200 OK` \| `201 Created` \| `204 No Content` \| `400 Bad Request` \| `401 Unauthorized` \| `403 Forbidden` \| `404 Not Found` \| `405 Method Not Allowed` \| `409 Conflict` \| `413 Payload Too Large` \| `422 Unprocessable Entity` \| `429 Too Many Requests` \| `500 Internal Server Error` \| `503 Service Unavailable`

## Formatting Rules (Mandatory)

- JSON in Request Headers and Request Body: valid, readable, copy-paste ready into Postman or a test framework.
- Assertions cell: pipe (`\|`) separated list (escape the pipe inside a markdown cell), each clause independently checkable.
- Multi-step preconditions: numbered list, semicolon-separated, in a single cell.
- Use `—` (em dash) as the placeholder for intentionally empty cells — never leave a cell truly blank.
- Do not truncate output — generate every row before writing the temp file.

## Handling Multiple Endpoints

- Default behavior: process only the primary endpoint into a single sheet.
- If multiple distinct endpoints are detected, ask the user to choose: one workbook with a
  sheet per endpoint, or a separate file per endpoint.
- If the user chooses one workbook, add one additional `sheets` entry per endpoint to the same
  Phase 2 JSON (sheet name = the slugified route) rather than generating separate JSON files —
  still a single Phase 3 conversion call, producing a single `.xlsx`.
- If the user asks for separate files, run Phase 2 and Phase 3 once per endpoint independently.

## Self-Check Before Writing Temp File (Phase 2 → Phase 3)

Before writing the markdown to the temp file, verify:
- [ ] Every business rule supplied has at least one BIZ row
- [ ] Every request field has at least one VAL row
- [ ] Minimum row counts per category are met
- [ ] Every invalid-input row has a paired valid baseline row
- [ ] No Notes value is blank (use `—` if truly nothing applies)
- [ ] No Assertions value uses vague language ("works correctly", "as expected") instead of exact field paths/values
- [ ] All status codes used appear in the taxonomy above
- [ ] All assumed/inferred values are flagged `(assumed — verify)` in Notes
- [ ] The table has exactly 14 columns in the correct order
- [ ] Pipe characters inside cell values are escaped as `\|` so markdown parsing stays correct

