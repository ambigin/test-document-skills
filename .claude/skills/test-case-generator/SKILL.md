---
name: test-case-generator
description: >
  Generates comprehensive Test Case Documents in markdown table format from Jira tickets.
  Use this skill when the user asks to generate test cases, create a test case document,
  produce test cases for acceptance criteria, design test scenarios for a feature, or validate
  test coverage for a Jira ticket. Trigger for requests like "create test cases for X",
  "generate test cases from this Jira ticket", "I need test cases for these acceptance criteria",
  or "design test scenarios for this feature". If the user mentions a Jira ticket, acceptance
  criteria, or test coverage needs, use this skill.
---

# Test Case Document Generation Skill

## Purpose

Generate a comprehensive Test Case Document in markdown table format from a Jira ticket.

## Workflow: Two Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

Before generating any output, you MUST validate the following. If any item is missing or unclear, ask the specified question and wait for the user's answer.

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Jira Ticket ID | Yes | Must include title, description, and ticket ID | "Please provide the Jira ticket ID, title, and full description." |
| Acceptance Criteria | Yes | Must be clear and non-conflicting; list them numbered | "Please provide the numbered acceptance criteria. If any conflict, clarify now." |
| Multiple Tickets/Features | Detect | Scan input for multiple distinct Jira tickets or features | "I detected multiple features/tickets. Do you want: (A) One table for the primary ticket, or (B) Separate tables per feature/ticket?" |
| Screenshots/Evidence | Detect | Note whether attachments or descriptions exist | Not required; proceed with TBD if missing |

**Mandatory Rule:** Do NOT proceed to Phase 2 until the user confirms all required items are ready, OR the user explicitly says "Proceed with inference" (then flag assumptions in Comments column).

### PHASE 2: Generate Markdown Table (Only After Phase 1 Completes)

Generate exactly one markdown table with the structure and rules below. Do not generate the table until Phase 1 is complete.

## Table Structure and Column Rules

**Exactly 14 columns, in this order:**

| Test Case ID | Test Case Name | Description | Prerequisites | Test Steps | Input Data | Expected Result | Actual Result | Status | Labels | Comments | References | Screenshot / Evidence | Executed Date |

**One row per test case. Each cell must remain a single row (use HTML `<br>` for multi-line content within cells).**

## Column Format Reference

| Column | Format Rule | Examples | Default/Placeholder |
|--------|-------------|----------|---------------------|
| Test Case ID | TC-<JIRA-ID>-<NNN> where NNN is 001, 002, etc. | TC-PROJ-123-001 | N/A (required) |
| Test Case Name | Short title describing the test | "User can reset password with valid email" | N/A (required) |
| Description | 1–2 sentences describing what is tested | "Tests that password reset email is sent after user requests it." | (required) |
| Prerequisites | Conditions that must be true before test runs | "User account exists; email is verified" | "None" if not applicable |
| Test Steps | Numbered list: one action per line; use `<br>` between steps | 1. Click "Forgot Password"<br>2. Enter email<br>3. Click Submit | (required) |
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

## Example Invocation

**User Input:**
"Jira Ticket PROJ-456: Add password reset flow to user settings. Users should be able to request a reset email, verify a token, and set a new password. ACs: (1) User can request password reset email, (2) Reset token expires after 30min, (3) New password must meet complexity rules."

**Your Response (Phase 1):**
"I have the Jira ticket and three acceptance criteria. Do you have design screenshots or descriptions? If not, I'll use 'TBD' for the Screenshot/Evidence column. Ready to proceed?"

**After User Confirms (Phase 2):**
Generate the 14-column markdown table with 5–20 test cases covering positive, negative, edge, security, and UX scenarios as applicable.
