# Test Data Generator

Generates at least 50 rows of test data for the fields you describe — valid, invalid, boundary, missing, special, and duplicate values — delivered as an Excel workbook, ready to drive manual, automated, or API testing.

## Use it when

- "Give me test data for a banking onboarding form: name, email, date of birth, phone, national ID."
- "Boundary values for a password field that allows 8–64 characters."
- "What data should I use to test my registration API?"

This skill produces input values. For pass/fail test scenarios, use `test-case-generator` or `api-test-case-generator`.

## What you get

`<domain-slug>-test-data.xlsx`, saved to `./outputs/` locally (`/mnt/user-data/outputs/` on Claude.ai).

Each row is one data set, with 8 columns: Data Set ID, Category, Field, Sub-field / Type, Value, Expected Behavior, Purpose, Notes.

Values come from equivalence partitioning, boundary value analysis (min, max, and one step beyond), and negative testing. They look realistic for the domain, and every row states why it exists. Leading or trailing spaces that matter are shown as `␣`.

## What Claude asks for

The domain or system, the fields to cover, and their validation rules. If you don't have a field list or rules, Claude can infer realistic fields and industry-standard rules, flagging them in the Notes column.

## Requirements

Python 3.8 or later with `openpyxl` (`pip install openpyxl`). The bundled converter uses it to build the workbook.

## Install

Copy this folder into `~/.claude/skills/` (available in all your projects) or into `<your-project>/.claude/skills/` (shared with your team through that repo). Then describe your task, or run `/test-data-generator`.

## Optional: project context

Copy `assets/PROJECT_CONTEXT.md` to the root of the project you're testing and fill it in. The skill reads it before asking questions, so you don't have to repeat product details, user roles, or domain terms each time.

## Files

| Path | What it is |
|---|---|
| `SKILL.md` | The instructions Claude follows |
| `references/PHASE1_GUIDE.md` | Rules shared by all the QA skills: project context, when to ask vs. infer, table formatting, converter errors |
| `scripts/md_table_to_xlsx.py` | Converts the generated markdown table into the `.xlsx` workbook |
| `assets/PROJECT_CONTEXT.md` | Blank project-context template |
