# API Test Case Generator

Turns an HTTP API endpoint — a Swagger/OpenAPI snippet, a Postman request, or just `POST /v1/users/login` — into an execution-ready API test suite, delivered as an Excel workbook.

## Use it when

- "Generate API test cases for `POST /v1/users/login` — Bearer auth, body `{ email, password }`."
- "Write API tests for this Swagger spec." *(paste the spec)*
- "Security test this endpoint."

For load and performance testing, use `performance-test-case-generator`.

## What you get

`<endpoint-slug>-api-tests.xlsx` (e.g. `post-v1-orders-api-tests.xlsx`), saved to `./outputs/` locally (`/mnt/user-data/outputs/` on Claude.ai). Several endpoints can share one workbook, one sheet each.

Each row is one test case, with 14 columns: Test Case ID, Test Case Name, Category, Priority, Preconditions, Request Headers, Request Body, Expected Status Code, Expected Response Body, Expected Headers, Assertions, Test Data, Notes, Linked Requirement.

Coverage spans authentication and authorization, request and response validation, business logic, error handling, idempotency, rate limiting and performance, and security. Every negative test is paired with a valid baseline, and every business rule you supply gets at least one test.

## What Claude asks for

Only the endpoint and method, and the auth type. Everything else (schemas, business rules) is inferred and flagged `(assumed — verify)` in the Notes column.

## Requirements

Python 3.8 or later with `openpyxl` (`pip install openpyxl`). The bundled converter uses it to build the workbook.

## Install

Copy this folder into `~/.claude/skills/` (available in all your projects) or into `<your-project>/.claude/skills/` (shared with your team through that repo). Then describe your task, or run `/api-test-case-generator`.

## Optional: project context

Copy `assets/PROJECT_CONTEXT.md` to the root of the project you're testing and fill it in. The skill reads it before asking questions, so you don't have to repeat product details, user roles, or domain terms each time.

## Files

| Path | What it is |
|---|---|
| `SKILL.md` | The instructions Claude follows |
| `references/PHASE1_GUIDE.md` | Rules shared by all the QA skills: project context, when to ask vs. infer, table formatting, converter errors |
| `scripts/md_table_to_xlsx.py` | Converts the generated markdown table into the `.xlsx` workbook |
| `assets/PROJECT_CONTEXT.md` | Blank project-context template |
