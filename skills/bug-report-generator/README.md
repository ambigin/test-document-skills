# Bug Report Generator

Turns a raw bug observation — rough notes, a console error, a stack trace, or a description of a screen recording — into a structured, developer-ready bug report, delivered as an Excel workbook.

## Use it when

- "Write a bug report for this: the payment spinner never resolves on slow 3G after tapping Place Order."
- "Turn these logs into a Jira-ready bug report." *(paste the logs)*
- "I found a bug, can you document it?"

## What you get

`<slug>-bug-report.xlsx`, saved to `./outputs/` locally (`/mnt/user-data/outputs/` on Claude.ai), with one sheet per bug.

Each sheet is a three-column **Section / Field / Value** table, one row per report field, which maps directly onto Jira's bug fields:

- **Summary**: title (`Component › Action › Symptom`), severity, priority, frequency, status
- **Environment**: OS, browser, app or API version, test environment, user role
- **Steps to Reproduce**: one atomic step per row
- **Behavior**: expected vs. actual, with exact error text
- **Impact & Analysis**: impact, root cause hypothesis, suggested fix, workaround, regression risk
- **Evidence & Links**: logs and stack traces verbatim, linked test case and Jira ticket

## What Claude asks for

Just the observation itself. Claude follows up only if it's missing, too thin to work from, or describes several bugs (you choose one combined report or one sheet per bug). Inferred details are flagged `(assumed — verify)`.

## Requirements

Python 3.8 or later with `openpyxl` (`pip install openpyxl`). The bundled converter uses it to build the workbook.

## Install

Copy this folder into `~/.claude/skills/` (available in all your projects) or into `<your-project>/.claude/skills/` (shared with your team through that repo). Then describe your task, or run `/bug-report-generator`.

## Optional: project context

Copy `assets/PROJECT_CONTEXT.md` to the root of the project you're testing and fill it in. The skill reads it before asking questions, so you don't have to repeat product details, user roles, or domain terms each time.

## Files

| Path | What it is |
|---|---|
| `SKILL.md` | The instructions Claude follows |
| `references/PHASE1_GUIDE.md` | Rules shared by all the QA skills: project context, when to ask vs. infer, table formatting, converter errors |
| `scripts/md_table_to_xlsx.py` | Converts the generated markdown table into the `.xlsx` workbook |
| `assets/PROJECT_CONTEXT.md` | Blank project-context template |
