# Phase 1 Validation — Common Reference

All QA test document skills follow the same three-phase workflow: validate inputs, write a markdown table to a temp file, then convert it to XLSX with the bundled `scripts/md_table_to_xlsx.py`. This guide captures the rules every skill shares so they stay consistent as they evolve.

---

## Project Context — Read First

Before running Phase 1, look for a `PROJECT_CONTEXT.md` file in the current working directory, then at the root of the repository that contains it. The system being tested doesn't have to be in that folder — this is the team's project workspace. Don't look in this skill's folder.

- **If it exists:** read it in full. Treat its contents as ground truth. Do not ask Phase 1 questions that are already answered there (user roles, domain terms, key features, business goal).
- **If it does not exist:** proceed with normal Phase 1 questioning as defined below.

This skill ships a blank template at `assets/PROJECT_CONTEXT.md` in its own folder. The template is not project context — never treat its contents as facts about the project. If the user wants to set up project context, copy the template to their project root and help them fill it in.

---

## When to Ask vs. When to Infer

| Situation | Action |
|-----------|--------|
| Required item is completely absent and cannot be reasonably inferred | Stop and ask the specific question listed in Phase 1 |
| Required item is inferrable from context | Infer it; flag the assumption with `(assumed — verify)` in the output |
| Optional item is missing | Use the placeholder or default specified in the column rules; never ask |

**Rule:** Never ask about optional items. Never block on inferrable required items. Ask only when you genuinely cannot produce meaningful output without the answer.

---

## Standard Multi-Item Detection Rule

All skills must detect when the input contains multiple distinct items (tickets, endpoints, features, bugs). When detected:

1. Ask: "I detected multiple [X]. Do you want: (A) One [output] covering all, or (B) Separate [outputs] per [X]?"
2. If the user chooses **(B)**: use `## Sheet: <name>` headings in the Phase 2 temp file — one block per item, single file, single Phase 3 call producing one workbook.
3. Only produce separate files if the user **explicitly** requests separate files.

---

## Standard Inference Flagging

- **Where:** in the row's Notes or Comments column, write `(assumed — verify)` followed by the assumption as a full sentence, e.g. `(assumed — verify) Token expiry is 30 min per AC#2.`
- **Skills without a Notes or Comments column** (such as the bug report) append `(assumed — verify)` to the inferred value itself.
- **Never** add the flag to fixed-value columns — IDs, categories, status codes, severity, priority, status. Those hold exactly one allowed value; explain the assumption in Notes instead.
- Never silently infer — every inferred value must be flagged.

---

## Table Formatting Rules (Phase 2)

The converter reads the temp file line by line, so every table must follow these rules:

- **One table row per line.** Never put a real line break inside a cell: the converter ignores any line that doesn't start with `|`, so everything after the break is lost. Write each line break inside a cell as `\n` (backslash + n) — the converter turns it into a real line break in Excel. This applies to numbered steps, stack traces, logs, JSON bodies, and code or config snippets.
- **Escape literal pipes.** Write every `|` inside a cell as `\|` — pipe-separated lists, payloads such as `; ls \| cat`, and code such as `a \|\| b`. An unescaped `|` starts a new cell and shifts the rest of the row.
- **Name every sheet.** Put a `## Sheet: <name>` heading immediately before each table — even when there's only one, or the sheet is named "Sheet1". Name it after what the table covers (endpoint, feature, flow, domain, bug), 31 characters max. One table per heading.
- Every row starts and ends with `|`, and the second line of each table is the separator row (`|---|---|`).

---

## Standard Converter Error Recovery

Run the converter with `python3`. If `python3` fails or isn't found — on Windows it's often a Microsoft Store placeholder that prints "Python was not found" — use `python` or `py -3` instead.

If `md_table_to_xlsx.py` prints `"status": "error"`, or prints `"status": "success"` together with a `warnings` list:
1. Do **not** edit the `.xlsx` output by hand.
2. Fix the temp `.md` file. Each warning names the sheet and the problem:
   - A row has more cells than the header → an unescaped `|` inside a cell; escape it as `\|`.
   - A second table was merged in → add a `## Sheet: <name>` heading before that table.
   - Lines inside the table were ignored → a cell contained a real line break; rewrite it on one line using `\n`.
   - For errors, check the table syntax rules above.
3. Re-run Phase 3.
4. If the error says `openpyxl` is not installed, ask the user before installing it (`pip install openpyxl`).
5. Never write ad-hoc XLSX code — always call this skill's `scripts/md_table_to_xlsx.py`.

---

## File Path Rules

| Path type | Rule |
|-----------|------|
| Temp `.md` file | Write to the **session scratchpad directory** if your environment provides one (Claude Code lists it in the system context). Otherwise use the system temp directory. Never write temp files into the user's project. |
| Output `.xlsx` file | Use `/mnt/user-data/outputs/` on Claude.ai; use `./outputs/` when running locally. Create the directory if it does not exist. |
