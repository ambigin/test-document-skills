# Test Case Generator

Turns a Jira ticket and its acceptance criteria into a functional test case document, delivered as an Excel workbook.

## Use it when

- "Generate test cases for PROJ-123." *(paste the ticket and its acceptance criteria)*
- "I need test cases for these acceptance criteria."
- "Design test scenarios for the password reset feature."

For API endpoints, performance, or usability testing, use the dedicated skills.

## What you get

`<TICKET-ID>-test-cases.xlsx`, saved to `./outputs/` locally (`/mnt/user-data/outputs/` on Claude.ai), with three sheets:

- **Test Cases**: 14 columns — Test Case ID, Test Case Name, Description, Prerequisites, Test Steps, Input Data, Expected Result, Actual Result, Status, Labels, Comments, References, Screenshot / Evidence, Executed Date
- **Summary**: test case counts by category
- **Coverage**: each acceptance criterion and the test cases that cover it

It generates 5–20 test cases per ticket: at least one per acceptance criterion, always a positive, a negative, and an edge case, plus security and UX cases when the ticket calls for them. Execution columns (Actual Result, Status, Executed Date) start as placeholders for testers to fill in.

## What Claude asks for

The ticket ID, title, and description, plus numbered acceptance criteria. If the criteria conflict, Claude asks whether to clarify first or proceed with flagged assumptions.

## Requirements

Python 3.8 or later with `openpyxl` (`pip install openpyxl`). The bundled converter uses it to build the workbook.

## Install

Copy this folder into `~/.claude/skills/` (available in all your projects) or into `<your-project>/.claude/skills/` (shared with your team through that repo). Then describe your task, or run `/test-case-generator`.

## Optional: project context

Copy `assets/PROJECT_CONTEXT.md` to the root of the project you're testing and fill it in. The skill reads it before asking questions, so you don't have to repeat product details, user roles, or domain terms each time.

## Files

| Path | What it is |
|---|---|
| `SKILL.md` | The instructions Claude follows |
| `references/PHASE1_GUIDE.md` | Rules shared by all the QA skills: project context, when to ask vs. infer, table formatting, converter errors |
| `scripts/md_table_to_xlsx.py` | Converts the generated markdown tables into the `.xlsx` workbook |
| `assets/PROJECT_CONTEXT.md` | Blank project-context template |
