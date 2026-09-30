# Security Test Case Generator

Generates OWASP-aligned security test cases for a web feature or screen that you own or are authorized to test, delivered as an Excel workbook. Every case runs with the browser UI, browser DevTools, or a proxy such as Burp Suite or OWASP ZAP — no exploit code.

## Use it when

- "Generate security test cases for our checkout flow."
- "OWASP test the user profile settings screen."
- "Pen test checklist for this login form."

For HTTP API endpoint contracts, use `api-test-case-generator`.

## What you get

`<feature-slug>-sec-tests.xlsx`, saved to `./outputs/` locally (`/mnt/user-data/outputs/` on Claude.ai).

Each row is one test case, with 11 columns: Test Case ID, Vulnerability Category, OWASP Category, Attack Scenario / Objective, Prerequisites, Steps to Execute, Payload / Manipulation, Expected Secure Behavior, Verification Method, Severity, Notes.

Covers 9 categories: injection, authentication and session management, access control and IDOR, sensitive data exposure, business logic flaws, file upload, CSRF, clickjacking, and security headers. Each case maps to the OWASP Top 10 (2021), and severity follows CVSS ranges. Payloads are standard QA test strings — enough to verify a defense, nothing more.

## What Claude asks for

Just the feature or screen name. Roles, inputs, and behavior are inferred from context and flagged `(assumed — verify)`.

## Requirements

Python 3.8 or later with `openpyxl` (`pip install openpyxl`). The bundled converter uses it to build the workbook.

## Install

Copy this folder into `~/.claude/skills/` (available in all your projects) or into `<your-project>/.claude/skills/` (shared with your team through that repo). Then describe your task, or run `/security-test-case-generator`.

## Optional: project context

Copy `assets/PROJECT_CONTEXT.md` to the root of the project you're testing and fill it in. The skill reads it before asking questions, so you don't have to repeat product details, user roles, or domain terms each time.

## Files

| Path | What it is |
|---|---|
| `SKILL.md` | The instructions Claude follows |
| `references/PHASE1_GUIDE.md` | Rules shared by all the QA skills: project context, when to ask vs. infer, table formatting, converter errors |
| `scripts/md_table_to_xlsx.py` | Converts the generated markdown table into the `.xlsx` workbook |
| `assets/PROJECT_CONTEXT.md` | Blank project-context template |
