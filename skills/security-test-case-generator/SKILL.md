---
name: security-test-case-generator
description: >
  Generates a comprehensive, execution-ready security test case suite for a web feature/screen as
  an XLSX workbook — covering injection, auth/session, access control/IDOR, sensitive data
  exposure, business logic flaws, file upload security, CSRF, clickjacking, and security headers.
  Every test case is executable via browser UI, browser DevTools, or a proxy tool (Burp Suite/
  OWASP ZAP) — no exploit code or compiled tooling. Use whenever the user wants security test
  cases, a pen test checklist, OWASP-aligned QA coverage, or vulnerability test scenarios for a
  feature they own or are authorized to test. Trigger for "generate security test cases for X",
  "security QA this feature", "OWASP test this screen", "pen test checklist for our checkout
  flow", or "find security gaps in this login form." A defensive QA skill for testing one's own
  application's security controls — not for building exploits or attacking third-party systems.
---

# Security Test Case Generator Skill

## Purpose

Act as an Expert Application Security QA Engineer and Senior Penetration Tester, generating a comprehensive security test case suite for a feature a QA team is authorized to test (their own application, in a test/staging environment they control). Every test case is executable by a QA engineer using browser UI, browser DevTools, or a proxy tool — no custom exploit code or compiled tooling required. Output is an XLSX workbook produced by the bundled converter script (`md_table_to_xlsx.py`).

## Scope Boundary (Read Before Generating)

This skill produces **defensive QA test cases**: structured checks a QA engineer runs against a feature they own, to confirm the application correctly rejects or neutralizes malicious-shaped input. It does not produce:
- Exploit code, shellcode, or working malware
- Tooling intended to attack systems the requester doesn't own or doesn't have explicit authorization to test
- Guidance for attacking production systems, third-party services, or systems where authorization is unclear

The payloads in this skill's output (XSS strings, SQLi probes, path traversal strings, etc.) are standard, widely-published QA test strings used to verify input sanitization — the same class of string found in OWASP Testing Guide and security scanner default payload lists. If a request shifts from "test my feature's defenses" toward targeting a system the user doesn't appear to own or control, or toward weaponizing a payload beyond what's needed to verify a defense, stop and reconsider scope rather than continuing to generate.

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

> **Read [references/PHASE1_GUIDE.md](references/PHASE1_GUIDE.md) before starting Phase 1.** It covers project context (`PROJECT_CONTEXT.md`), when to ask vs. infer, multi-item handling, assumption flagging, table formatting rules, and converter error recovery.

Before generating any output, you MUST gather the following. If an item is missing, **do not block on it** — infer a reasonable value from the feature description and flag the assumption `(assumed — verify)` in that test case's Notes field. Only stop and ask if the feature/screen itself is unspecified (you cannot generate meaningful security tests without knowing what's being tested).

| Item | Required to Proceed? | If Missing |
|------|----------------------|------------|
| Feature / Screen Name | Yes — ask if absent | "What feature or screen is this testing? (e.g. 'User Profile Settings', 'Checkout Flow')" |
| Feature Description | No | Infer key actions/data from the screen name and any context given; flag inferences in Notes |
| User Roles | No | Infer standard roles (Unauthenticated, Standard User, Admin) if none given; flag in Notes |
| UI Elements / Inputs | No | Infer typical inputs for a feature of this type; flag in Notes |
| Jira / Requirements Link | No | Use "None" in Notes/reference where relevant |
| Multiple Features Detected | Detect | "I see multiple features/screens here. One combined suite, or a separate table per feature?" |

Once the feature/screen is identified, proceed to Phase 2 — infer the rest rather than stalling on a fully complete spec.

### PHASE 2: Generate and Write the Test Suite

Build all rows per the structure below. **Do NOT echo the table to chat.** Write directly to a temp file in the session scratchpad directory (or the system temp directory if your environment has no scratchpad) — never inside the user's project. Confirm with: "✓ N test cases written — running converter..."

### PHASE 3: Convert Markdown Table to XLSX

1. Call the bundled converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py" "<scratchpad>/sec-tests-<feature-slug>.md" "<output>/<feature-slug>-sec-tests.xlsx"
   ```
   The script is in `scripts/` next to this SKILL.md; if the command's path wasn't filled in with this skill's folder, use that folder's full path. If `python3` fails or isn't found (on Windows it's often a Microsoft Store placeholder that prints "Python was not found"), use `python` or `py -3` instead. The script needs `openpyxl`.
   Replace `<scratchpad>` with the temp directory from Phase 2. For `<output>`, use `/mnt/user-data/outputs` on Claude.ai or `./outputs` when running locally.
2. Confirm the script printed `"status": "success"` with no `warnings` — a warning means cells or lines were dropped, so fix the temp file (see PHASE1_GUIDE.md → Standard Converter Error Recovery) and re-run. If it errors, check that the temp file
   contains valid pipe-delimited markdown table syntax, fix if needed, and re-run.
3. Tell the user the full output path and confirm the file is ready to open in Excel or import into Google Sheets. State the path in a single line — no preamble, no trailing summary.

## Coverage Requirements — All 9 Attack Vector Categories

1. **Input validation & injection (INJECT)** — XSS (Reflected, Stored, DOM-based) · SQL injection · NoSQL injection · HTML injection · Template injection (SSTI) · Command injection via filename or metadata fields.
2. **Authentication & session management (AUTH)** — Session timeout UI enforcement · Session fixation · Concurrent login behavior · Token/cookie theft via XSS · Forced browsing past auth flows · MFA bypass via direct URL navigation.
3. **Broken access control & IDOR (AC)** — Horizontal privilege escalation (user A accessing user B's data) · Vertical privilege escalation (standard user reaching admin-only UI/endpoints) · Hidden field manipulation · URL parameter tampering · Mass assignment via intercepted request body modification.
4. **Sensitive data exposure (DATA)** — PII in client-side storage (cookies, LocalStorage, SessionStorage, IndexedDB) · Sensitive data in console logs or JS source · Verbose error messages leaking stack traces/DB names/internal paths · Sensitive data in URL query strings · Autocomplete enabled on password/sensitive fields.
5. **Business logic flaws (BIZ)** — Client-side validation bypass (disable JS, intercept & modify request) · Price/quantity/limit manipulation via proxy · Multi-step flow sequence tampering (skip/replay steps) · Negative value injection · Race condition on double-submit.
6. **File upload security (FILE)** — Upload of disallowed file types (PHP, SVG with script, HTML) · MIME type spoofing (change Content-Type in proxy) · Oversized file upload · Filename injection (path traversal) · Polyglot files (valid image + embedded script).
7. **Cross-site request forgery (CSRF)** — State-changing requests missing CSRF token · CSRF token not validated server-side · Same-site cookie policy not enforced · JSON endpoint accepting text/plain Content-Type (CSRF via form).
8. **Clickjacking & UI redress (CJ)** — Feature renderable inside an iframe (missing X-Frame-Options or CSP frame-ancestors) · UI overlay attacks on high-value buttons (approve, delete, transfer).
9. **Security headers & client-side controls (HDR)** — Missing/misconfigured Content-Security-Policy · Missing X-Content-Type-Options · Subresource integrity not enforced on third-party scripts · HTTPS not enforced/mixed content · Certificate validity.

**Minimum row counts:** 2 cases per injection type present in the UI; 1 case per role transition for access control; 1 case per file type for file upload; 3 cases total for session management. Generate more if feature complexity warrants it.

**UI element coverage rule:** Every UI element/input listed must appear in at least one test case as the target — no listed element goes untested.

**Stored XSS verification rule:** For every Stored XSS test case, also generate the corresponding verification step confirming the payload fires for a *different* user/session viewing the stored content — not just the submitting user.

**Chaining rule:** Where a finding can be chained with another (e.g. Stored XSS → CSRF token theft → account takeover), document the chain explicitly in Notes rather than treating each as isolated.

## Table Structure — Exactly 11 Columns, In This Order

| Test Case ID | Vulnerability Category | OWASP Category | Attack Scenario / Objective | Prerequisites | Steps to Execute | Payload / Manipulation | Expected Secure Behavior | Verification Method | Severity | Notes |


## Column Rules

| Column | Rule |
|---|---|
| Test Case ID | `SEC-[PREFIX]-[NNN]`, sequential within each category, e.g. `SEC-INJECT-001`, `SEC-AC-003` |
| Vulnerability Category | Specific type, e.g. "Stored XSS", "IDOR — Horizontal", "CSRF — Missing Token" |
| OWASP Category | Map to the relevant OWASP Top 10 (2021) entry, e.g. "A03:2021 – Injection" |
| Attack Scenario / Objective | One sentence: what the attacker is attempting to achieve |
| Prerequisites | Account type, system state, or tool setup required before executing |
| Steps to Execute | Numbered, tool-specific, with `\n` between steps (one cell, no real line breaks). Name the exact tool and UI path for each action, e.g. "In Burp Suite: Proxy → HTTP History → right-click request → Send to Repeater" |
| Payload / Manipulation | Exact string, modified request snippet, or intercepted value — copy-paste ready. Never write "use an XSS payload"; write the literal string. Escape any pipe as `\|` and write line breaks in request snippets as `\n` |
| Expected Secure Behavior | What the system does **when secure** — an observable outcome, not just "attack fails" |
| Verification Method | Exactly how the tester confirms the result: what to check, where, what to look for |
| Severity | `Critical` (CVSS 9.0–10.0) / `High` (7.0–8.9) / `Medium` (4.0–6.9) / `Low` (0.1–3.9) — see taxonomy below |
| Notes | **Never blank** unless genuinely "Not applicable." Chain risk, assumption flag `(assumed — verify)`, remediation hint, or follow-up test reference |

## Severity Taxonomy (CVSS-Aligned)

| Severity | CVSS Range | Example |
|---|---|---|
| Critical | 9.0–10.0 | Remote code execution, authentication bypass, mass data breach |
| High | 7.0–8.9 | Stored XSS, IDOR exposing PII, vertical privilege escalation |
| Medium | 4.0–6.9 | Reflected XSS, CSRF on low-impact action, verbose error messages |
| Low | 0.1–3.9 | Missing security header, autocomplete on non-password field, info leakage in JS source |

## Writing Standards

- Steps must be executable by a QA engineer without prior security expertise — name the exact tool, menu path, and action.
- Payloads are exact, copy-paste-ready, standard QA test strings (the kind published in the OWASP Testing Guide) — sufficient to verify a defense, not weaponized beyond that purpose.
- Expected Secure Behavior describes what a *secure* system does — never describe only what a broken one does.
- Verification Method specifies precisely how the tester confirms the outcome.
- Never leave a field blank; use "Not applicable" only when genuinely correct.
- Escape every `|` inside a cell (payloads such as `; ls \| cat`, steps) as `\|`, and write line breaks as `\n` — see PHASE1_GUIDE.md → Table Formatting Rules.

## Self-Check Before Finalizing

Before writing the temp file, verify:
- [ ] All 9 categories have coverage (or are explicitly marked "Not applicable" with reasoning in Notes, if genuinely out of scope for this feature)
- [ ] Minimum row counts are met (2/injection type, 1/role transition, 1/file type, 3 total for session management)
- [ ] Every listed UI element appears as a target in at least one row
- [ ] Every Stored XSS row has a paired cross-session/cross-user verification step
- [ ] Chainable findings are documented together in Notes, not isolated
- [ ] No payload is more destructive or weaponized than needed to verify the defense (e.g. a proof-of-concept alert/log payload, not a payload designed for real exfiltration or persistence)
- [ ] Severity ratings align with the CVSS taxonomy above
- [ ] No Notes field is blank without "Not applicable" being genuinely correct

