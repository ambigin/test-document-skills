# QA Skills Documentation

A comprehensive reference for all AI-powered QA skills available in this repository. Each skill follows a unified three-phase workflow: **Validate Inputs → Generate Markdown Table → Convert to XLSX**.

---

## Table of Contents

1. [API Test Case Generator](#1-api-test-case-generator)
2. [Test Case Generator](#2-test-case-generator)
3. [Test Data Generator](#3-test-data-generator)
4. [Security Test Case Generator](#4-security-test-case-generator)
5. [Bug Report Generator](#5-bug-report-generator)
6. [Performance Test Case Generator](#6-performance-test-case-generator)
7. [Usability Test Case Generator](#7-usability-test-case-generator)
8. [Shared Converter Script](#shared-converter-script)

---

## 1. API Test Case Generator

**Skill name:** `api-test-case-generator`
**File:** [.claude/skills/api-test-case-generator/SKILL.md](.claude/skills/api-test-case-generator/SKILL.md)

### Description

Generates a complete, execution-ready API test suite (REST or GraphQL) as an XLSX spreadsheet, covering authentication, request/response validation, business logic, error handling, idempotency, rate limiting/performance, and security. Output is ready to open directly or copy-paste into Postman, Jira, or Google Sheets.

### When to Use

- "Generate test cases for this endpoint"
- "Write API tests for X"
- "Test this POST/GET/PUT/DELETE route"
- "QA this API"
- "I need test coverage for this Swagger spec"
- "Security test this endpoint"
- User pastes a Swagger/OpenAPI snippet, a Postman collection, or a raw endpoint description

### Required Inputs

| Input | Required? | Notes |
|-------|-----------|-------|
| Endpoint URL + HTTP method | Yes | e.g. `POST /v1/users/login` |
| Auth type | Yes | Bearer/JWT, API key, OAuth 2.0, Basic, or none |
| Request schema | No | Inferred if absent; flagged `(assumed — verify)` |
| Response schema | No | Inferred if absent; flagged `(assumed — verify)` |
| Business rules | No | Standard CRUD assumptions used if absent |
| Jira/Docs link | No | Defaults to "None" |

### Coverage — 8 Test Categories

| Category | Code | What It Covers |
|----------|------|----------------|
| Authentication & authorization | AUTH | Valid/expired/missing tokens, wrong roles, cross-tenant access |
| Request validation | VAL | Missing fields, wrong types, malformed JSON, format violations |
| Response validation | VAL | Status codes, schema match, required headers, no data leakage |
| Business logic | BIZ | Business rules, state transitions, data persistence, side-effects |
| Error handling | ERR | Meaningful error messages, no stack trace exposure |
| Idempotency & duplicates | IDEM | Repeated requests produce expected result |
| Rate limiting & performance | PERF | 429 on limit breach, p95 response time, payload size limits |
| Security | SEC | SQL/NoSQL injection, XSS, IDOR, mass assignment |

**Minimum rows:** 3 AUTH · 1 VAL per request field · 1 BIZ per business rule · 2 ERR · 1 IDEM · 1 PERF · 3 SEC

### Output Table — 14 Columns

`Test Case ID` · `Test Case Name` · `Category` · `Priority` · `Preconditions` · `Request Headers` · `Request Body` · `Expected Status Code` · `Expected Response Body` · `Expected Headers` · `Assertions` · `Test Data` · `Notes` · `Linked Requirement`

### Test Case ID Format

`API-TC-[CATEGORY]-[NNN]` — e.g. `API-TC-AUTH-001`, `API-TC-SEC-003`

### Output Files

- Markdown table in chat
- XLSX workbook at `/mnt/user-data/outputs/<endpoint-slug>-api-tests.xlsx`

---

## 2. Test Case Generator

**Skill name:** `test-case-generator`
**File:** [.claude/skills/test-case-generator/SKILL.md](.claude/skills/test-case-generator/SKILL.md)

### Description

Generates comprehensive Test Case Documents as an XLSX spreadsheet from Jira tickets and acceptance criteria. Maps each acceptance criterion to executable test scenarios covering positive, negative, edge-case, security, and UX flows. Produces two sheets: a Test Cases sheet and a Summary/Coverage Mapping sheet.

### When to Use

- "Create test cases for X"
- "Generate test cases from this Jira ticket"
- "I need test cases for these acceptance criteria"
- "Design test scenarios for this feature"
- User mentions a Jira ticket, acceptance criteria, or test coverage needs

### Required Inputs

| Input | Required? | Notes |
|-------|-----------|-------|
| Jira Ticket ID + title + description | Yes | Must include all three |
| Acceptance criteria | Yes | Must be clear and non-conflicting; numbered list |
| Screenshots/evidence | No | Uses "TBD" if absent |

### Coverage Rules

- At least 1 positive flow (happy path)
- At least 1 negative flow (error handling)
- At least 1 edge/boundary condition
- At least 1 security test case if the ticket touches auth, authorization, input validation, or data handling
- At least 1 UX/visual test case if the ticket affects UI layout or visual components
- At least 1 test case per acceptance criterion

**Row count:** 5–20 test cases per ticket

### Output Tables — Two Sheets

**Sheet 1 — Test Cases (14 columns):**

`Test Case ID` · `Test Case Name` · `Description` · `Prerequisites` · `Test Steps` · `Input Data` · `Expected Result` · `Actual Result` · `Status` · `Labels` · `Comments` · `References` · `Screenshot / Evidence` · `Executed Date`

**Sheet 2 — Summary:**
- Summary Counts (total test cases, breakdown by type)
- Coverage Mapping (each acceptance criterion → test case IDs that cover it)

### Test Case ID Format

`TC-<JIRA-ID>-<NNN>` — e.g. `TC-PROJ-123-001`

### Status Values

`Not Executed` · `Pass` · `Fail` · `Blocked`

### Output Files

- Two markdown tables in chat (`## Sheet: Test Cases`, `## Sheet: Summary`)
- XLSX workbook at `/mnt/user-data/outputs/<TICKET-ID>-test-cases.xlsx`

---

## 3. Test Data Generator

**Skill name:** `test-data-generator`
**File:** [.claude/skills/test-data-generator/SKILL.md](.claude/skills/test-data-generator/SKILL.md)

### Description

Generates comprehensive, Excel-ready test data documents for data validation and QA. Applies equivalence partitioning, boundary value analysis, and negative testing to produce a minimum of 50 rows covering valid, invalid, boundary, missing, special, and duplicate data scenarios.

### When to Use

- "Give me test data for X"
- "Help me test this form"
- "Generate test cases for these fields"
- "I need data to test my API"
- User mentions fields, validation rules, a Jira ticket, or a domain with data inputs

### Required Inputs

| Input | Required? | Notes |
|-------|-----------|-------|
| Domain / system | Yes | e.g. banking onboarding, e-commerce checkout |
| Fields to cover | Yes | Specific list, or confirm inference from domain |
| Validation rules / requirements | Yes | Specific constraints or confirm industry-standard rules apply |

### Coverage — 6 Data Categories

| Category | Description |
|----------|-------------|
| Valid | Correct, realistic inputs the system should accept |
| Invalid | Wrong format, out-of-range, type mismatches, constraint violations |
| Boundary | Exact min, max, min−1, max+1 for every constrained field |
| Missing | Blank strings, nulls, whitespace-only, omitted required fields |
| Special | Unicode, emojis, SQL/script injection strings, non-ASCII names |
| Duplicate | Intentional duplicates to verify uniqueness enforcement |

### Volume & Distribution

| Category | Target % |
|----------|----------|
| Valid | ~30% |
| Invalid | ~30% |
| Boundary | ~25% |
| Missing / Null | ~10% |
| Special + Duplicate | ~5% |

**Minimum rows:** 50

### Output Table — 8 Columns

`Data Set ID` · `Category` · `Field` · `Sub-field / Type` · `Value` · `Expected Behavior` · `Purpose` · `Notes`

### Data Set ID Format

`TD_001`, `TD_002` … (prefix by domain if multiple: `REG_001`, `PAY_001`)

### Output Files

- Markdown table in chat
- XLSX workbook at `/mnt/user-data/outputs/<domain-slug>-test-data.xlsx`

---

## 4. Security Test Case Generator

**Skill name:** `security-test-case-generator`
**File:** [.claude/skills/security-test-case-generator/SKILL.md](.claude/skills/security-test-case-generator/SKILL.md)

### Description

Generates a comprehensive, OWASP-aligned security test case suite for a web feature or screen. Every test case is executable via browser UI, browser DevTools, or a proxy tool (Burp Suite/OWASP ZAP) — no exploit code or compiled tooling required. Designed for defensive QA: testing your own application's security controls in a staging/test environment.

### When to Use

- "Generate security test cases for X"
- "Security QA this feature"
- "OWASP test this screen"
- "Pen test checklist for our checkout flow"
- "Find security gaps in this login form"

### Required Inputs

| Input | Required? | Notes |
|-------|-----------|-------|
| Feature / screen name | Yes | e.g. "User Profile Settings", "Checkout Flow" |
| Feature description | No | Inferred from screen name if absent |
| User roles | No | Defaults to Unauthenticated/Standard User/Admin |
| UI elements / inputs | No | Inferred for feature type if absent |
| Jira / requirements link | No | Defaults to "None" |

### Coverage — 9 Attack Vector Categories

| Category | Code | What It Covers |
|----------|------|----------------|
| Input validation & injection | INJECT | XSS (Reflected/Stored/DOM), SQL/NoSQL injection, SSTI, command injection |
| Authentication & session management | AUTH | Session timeout, session fixation, concurrent login, token theft, MFA bypass |
| Broken access control & IDOR | AC | Horizontal/vertical privilege escalation, URL tampering, mass assignment |
| Sensitive data exposure | DATA | PII in client-side storage, verbose errors, sensitive data in URLs |
| Business logic flaws | BIZ | Client-side bypass, price manipulation, multi-step flow tampering, race conditions |
| File upload security | FILE | Disallowed file types, MIME spoofing, oversized files, filename injection, polyglots |
| Cross-site request forgery | CSRF | Missing CSRF tokens, same-site cookie policy, form-based CSRF |
| Clickjacking & UI redress | CJ | Missing X-Frame-Options/CSP, UI overlay on high-value buttons |
| Security headers & client-side controls | HDR | CSP, X-Content-Type-Options, HTTPS enforcement, certificate validity |

**Minimum rows:** 2 per injection type present · 1 per role transition (access control) · 1 per file type · 3 total for session management

### Output Table — 11 Columns

`Test Case ID` · `Vulnerability Category` · `OWASP Category` · `Attack Scenario / Objective` · `Prerequisites` · `Steps to Execute` · `Payload / Manipulation` · `Expected Secure Behavior` · `Verification Method` · `Severity` · `Notes`

### Test Case ID Format

`SEC-[PREFIX]-[NNN]` — e.g. `SEC-INJECT-001`, `SEC-AC-003`

### Severity Taxonomy (CVSS-Aligned)

| Severity | CVSS Range | Example |
|----------|------------|---------|
| Critical | 9.0–10.0 | RCE, auth bypass, mass data breach |
| High | 7.0–8.9 | Stored XSS, IDOR exposing PII, vertical privilege escalation |
| Medium | 4.0–6.9 | Reflected XSS, CSRF on low-impact action, verbose errors |
| Low | 0.1–3.9 | Missing security header, info leakage in JS source |

### Output Files

- Markdown table in chat
- XLSX workbook at `/mnt/user-data/outputs/<feature-slug>-sec-tests.xlsx`

---

## 5. Bug Report Generator

**Skill name:** `bug-report-generator`
**File:** [.claude/skills/bug-report-generator/SKILL.md](.claude/skills/bug-report-generator/SKILL.md)

### Description

Transforms unstructured QA observations, logs, console errors, and screen recording descriptions into developer-ready bug reports. Outputs a flat three-column table (Section / Field / Value) covering all six report sections, delivered as both a markdown table and an XLSX workbook.

### When to Use

- "Write a bug report for this"
- "Turn this observation into a bug report"
- "I found a bug, can you document it"
- "Create a Jira-ready bug report from these logs"
- User pastes a raw bug observation, console error, stack trace, or screen recording description

### Required Inputs

| Input | Required? | Notes |
|-------|-----------|-------|
| Raw observation | Yes | What was seen — grammar and structure don't matter |
| Screenshot / log | No | Uses "none provided" if absent |
| Linked Jira / test case | No | Uses "None" if absent |
| Environment details | No | Flagged `(assumed — please verify)` if inferred |

### Report Structure — 6 Sections

| Section | Fields |
|---------|--------|
| Summary | Bug ID, Title, Severity, Priority, Frequency, Status |
| Environment | OS & version, Browser & version, App/API version, Test environment, User role |
| Steps to Reproduce | Step 1, Step 2, … (one row per step) |
| Behavior | Expected Behavior, Actual Behavior |
| Impact & Analysis | Impact, Root Cause Hypothesis, Suggested Fix, Workaround, Regression Risk |
| Evidence & Links | Screenshots/Logs/Evidence, Linked Test Case, Linked Jira Ticket, Reported By, Reported Date |

### Output Table — 3 Columns

`Section` · `Field` · `Value`

### Title Format

`Component › Action › Symptom` — e.g. `Checkout › Place Order › Payment spinner never resolves`

### Severity & Priority Taxonomies

**Severity:**
| Value | Definition |
|-------|------------|
| Critical | System crash, data loss, security breach, complete feature failure with no workaround |
| High | Core functionality broken, unreasonable workaround |
| Medium | Non-core functionality broken, reasonable workaround exists |
| Low | Cosmetic issue, minor UX inconsistency, no functional impact |

**Priority:**
| Value | Definition |
|-------|------------|
| P1 | Block release / fix before any other work |
| P2 | Fix in current sprint |
| P3 | Fix in next sprint or upcoming release |
| P4 | Fix when capacity allows / backlog |

**Frequency:** `Always` · `Intermittent (N of N attempts)` · `Once`

### Output Files

- Markdown table in chat
- XLSX workbook at `/mnt/user-data/outputs/<slug>-bug-report.xlsx`
- Multiple bugs: one sheet per bug in the same workbook

---

## 6. Performance Test Case Generator

**Skill name:** `performance-test-case-generator`
**File:** [.claude/skills/performance-test-case-generator/SKILL.md](.claude/skills/performance-test-case-generator/SKILL.md)

### Description

Generates a complete, execution-ready performance and load test suite covering all seven performance test types. Includes script-ready traffic profiles, hard SLA pass/fail boundaries, and copy-paste tool config stubs for k6, JMeter, Gatling, Locust, and Artillery.

### When to Use

- "Design a load test for X"
- "Performance test this endpoint"
- "Stress test plan"
- "Capacity test before scaling"
- "Soak test this service"
- "Write k6/JMeter/Gatling scripts for this journey"

### Required Inputs

| Input | Required? | Notes |
|-------|-----------|-------|
| Target component / journey | Yes | e.g. "Checkout API", "End-of-month payroll job" |
| Baseline traffic | Yes (or at least one of baseline/peak) | Concurrent users, RPS, or jobs/hour |
| Peak traffic | Yes (or at least one of baseline/peak) | Maximum anticipated load + triggering event |
| Tech stack / infra | No | Inferred generically; flagged `(assumed — verify)` |
| SLA targets | No | Industry-standard inferred; flagged `(assumed — verify)` |
| Preferred tool | No | Best-fit tool recommended and stated in Notes |
| Jira / docs link | No | Defaults to "None" |

### Coverage — 7 Performance Test Types

| Type | Code | Description |
|------|------|-------------|
| Load | LOAD | Expected peak load to verify SLA targets (ramp up, steady state, ramp down) |
| Stress | STRESS | Beyond peak to find the breaking point and failure mode |
| Spike | SPIKE | Sudden extreme burst with near-zero ramp (flash sale, batch trigger) |
| Soak / Endurance | SOAK | Sustained 60–80% of peak for 2+ hours; monitors for memory leaks, connection exhaustion |
| Scalability | SCALE | Incremental load steps to identify linear vs. sub-linear scaling or a hard ceiling |
| Concurrency & contention | CONCUR | Concurrent access to shared resources to surface race conditions, deadlocks |
| Recovery & failover | RECOVER | Infrastructure failures under load to validate circuit breakers and failover |

**Minimum rows:** 2 LOAD (baseline + peak) · 1 each of STRESS, SPIKE, SOAK, SCALE, CONCUR, RECOVER

### Output Table — 14 Columns

`Test Case ID` · `Test Type` · `Priority` · `Objective` · `Traffic Profile` · `Data Profile` · `Tool & Config Snippet` · `Bottlenecks to Monitor` · `Acceptance Criteria / SLA` · `Failure Indicators` · `Expected Failure Mode` · `Post-Test Validation` · `Notes` · `Linked Requirement`

### Test Case ID Format

`PERF-[COMPONENT ABBREVIATION]-[NNN]` — e.g. `PERF-PAY-001`, `PERF-LOGIN-003`

### Priority

- `P1` — Must pass before release
- `P2` — Must pass before scaling event / capacity change
- `P3` — Investigate; fix before next major release

### Output Files

- Markdown table in chat
- XLSX workbook at `/mnt/user-data/outputs/<component-slug>-perf-tests.xlsx`

---

## 7. Usability Test Case Generator

**Skill name:** `usability-test-case-generator`
**File:** [.claude/skills/usability-test-case-generator/SKILL.md](.claude/skills/usability-test-case-generator/SKILL.md)

### Description

Generates task-based usability test scenarios for moderated or unmoderated user research sessions. Focuses on how real users experience, navigate, and succeed or struggle with a flow — not whether the system functionally passes acceptance criteria.

### When to Use

- "Create usability test cases for X"
- "Usability testing script for this flow"
- "Task scenarios for user testing"
- "Usability study plan from this Jira ticket"
- "Test the usability of this feature"
- User mentions usability testing, user research, task success, UX heuristics, SUS scores, or moderated/unmoderated sessions

### How Usability Tests Differ From Functional Tests

| Functional Test Cases | Usability Test Cases |
|-----------------------|----------------------|
| Verify system behavior against acceptance criteria | Verify real users can understand and complete tasks |
| Pass/Fail based on expected output | Task Success rated on a scale; qualitative observation |
| Written for QA engineers or automation | Written for moderators or unmoderated tools (UserTesting, Maze) |
| Focus: correctness, edge cases, security | Focus: discoverability, clarity, cognitive load, error recovery, satisfaction |

### Required Inputs

| Input | Required? | Notes |
|-------|-----------|-------|
| Feature / Jira ticket | Yes | Title, description, and ticket ID (or feature name) |
| User flow / tasks involved | Yes | Key tasks a user needs to accomplish |
| Target user / persona | Yes | e.g. first-time user, power user, accessibility-focused |
| Testing mode | Yes | Moderated (live facilitator) or Unmoderated (self-guided) |
| Success criteria / goals | Yes | Observable definition of success per task |
| Known UX risks / heuristics to probe | No | General heuristic coverage used if not specified |
| Screenshots / prototype link | No | Uses "TBD" if absent |

### Coverage Rules

- At least 1 first-touch/discoverability task
- At least 1 core happy-path task completion
- At least 1 error-recovery task
- At least 1 confirmation/trust task (for forms, multi-step, or irreversible actions)
- At least 1 cognitive load / visual clarity task (for dense content or competing CTAs)
- At least 1 accessibility-focused task (if accessibility was flagged or persona includes assistive-tech users)
- At least 1 task scenario per major flow/screen
- Always add a final "Post-Task Survey" row for overall satisfaction (SEQ or SUS-style)

**Row count:** 5–15 task scenarios per flow

### Output Table — 15 Columns

`Test Case ID` · `Task Scenario` · `Participant Instructions` · `Persona / User Type` · `Prerequisites` · `Success Criteria` · `UX Focus Area` · `Observed Behavior` · `Task Success Rating` · `Severity (if issue found)` · `Time on Task` · `Participant Quote / Feedback` · `Comments` · `References` · `Screenshot / Evidence`

### Test Case ID Format

`UT-<JIRA-ID>-<NNN>` — e.g. `UT-PROJ-456-001`

### UX Focus Areas

`Discoverability` · `Navigation/IA` · `Clarity of Language` · `Error Recovery` · `Feedback/System Status` · `Cognitive Load` · `Accessibility` · `Trust/Confidence` · `Satisfaction` · `Efficiency`

### Task Success Rating

`Not Run` · `Success` · `Success with Difficulty` · `Failure` · `Abandoned`

### Participant Instruction Writing Rules

- **Do not reveal the path** — frame as a goal, not step-by-step UI instructions
- **Do not use internal feature names** the user wouldn't know
- **Keep it short** — one to three sentences
- **Frame as a goal or motivation** — measures usability, not compliance

### Output Files

- Markdown table in chat
- XLSX workbook at `/mnt/user-data/outputs/<feature-slug>-usability-tests.xlsx`

---

## Shared Converter Script

**File:** [.claude/skills/shared/md_table_to_xlsx.py](.claude/skills/shared/md_table_to_xlsx.py)

All seven skills call this shared script in Phase 3. It is never copied into individual skill folders.

### What It Does

- Parses one or more pipe-delimited markdown tables from a `.md` temp file
- Supports multiple sheets via `## Sheet: <name>` headings before each table
- Writes a formatted `.xlsx` workbook (frozen header row, bold headers, alternating row colors, auto-width columns, wrapped text)
- Prints `{"status": "success", "file": "..."}` on success or `{"status": "error", "message": "..."}` on failure

### Usage

```bash
# Single-table conversion
python .claude/skills/shared/md_table_to_xlsx.py input.md output.xlsx

# Multi-sheet (input.md contains ## Sheet: headings)
python .claude/skills/shared/md_table_to_xlsx.py multi-sheet.md output.xlsx
```

### Prerequisites

```bash
pip install openpyxl
```

---

## Quick Reference

| Skill | Trigger Keywords | Output Columns | Min Rows | ID Format |
|-------|-----------------|----------------|----------|-----------|
| API Test Case Generator | "API tests", "endpoint test cases", "QA this API" | 14 | AUTH:3, SEC:3, PERF:1 | `API-TC-AUTH-001` |
| Test Case Generator | "test cases from Jira", "acceptance criteria", "feature test cases" | 14 + Summary sheet | 5–20 per ticket | `TC-PROJ-123-001` |
| Test Data Generator | "test data for X", "test this form", "data for my API" | 8 | 50 | `TD_001` |
| Security Test Case Generator | "security test cases", "OWASP test", "pen test checklist" | 11 | 2/injection, 3 session | `SEC-INJECT-001` |
| Bug Report Generator | "bug report", "document this bug", "Jira-ready bug report" | 3 (Section/Field/Value) | All 6 sections | N/A (Section-based) |
| Performance Test Case Generator | "load test", "stress test", "soak test", "k6 plan" | 14 | 2 LOAD + 1 each other type | `PERF-PAY-001` |
| Usability Test Case Generator | "usability test", "task scenarios", "user research script" | 15 | 5–15 + 1 survey row | `UT-PROJ-456-001` |

---

*Last updated: August 2026 | Skills available: 7*
