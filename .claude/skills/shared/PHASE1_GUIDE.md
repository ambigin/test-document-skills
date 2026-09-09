# Phase 1 Validation — Shared Reference

All skills follow the same three-phase workflow. This guide captures the common Phase 1 rules so skills stay consistent as they evolve.

---

## Project Context — Read First

Before running Phase 1 for any skill, check whether a `PROJECT_CONTEXT.md` file exists in the project root.

- **If it exists:** read it in full. Treat its contents as ground truth. Do not ask Phase 1 questions that are already answered there (user roles, domain terms, key features, business goal).
- **If it does not exist:** proceed with normal Phase 1 questioning as defined below.

QA engineers copy the template from this repo into their own project repo and fill it in once. See `PROJECT_CONTEXT.md` at the repo root for the template.

---

## When to Ask vs. When to Infer

| Situation | Action |
|-----------|--------|
| Required item is completely absent and cannot be reasonably inferred | Stop and ask the specific question listed in Phase 1 |
| Required item is inferrable from context | Infer it; flag the assumption with `(assumed — verify)` in the output |
| Optional item is missing | Use the placeholder or default specified in the column rules; never ask |

**Rule:** Never ask about optional items. Never block on inferrable required items. Ask only when you genuinely cannot produce meaningful output without the answer.

---

## Validation Table Column Styles

Skills use one of two column layouts — use whichever the skill already defines; prefer Style B for new skills.

**Style A** (test-case-generator, test-data-generator, usability-test-case-generator):
```
| Item | Required? | Validation Rule | Question to Ask if Missing |
```

**Style B** (api-test-case-generator, security-test-case-generator, performance-test-case-generator):
```
| Item | Required to Proceed? | If Missing |
```

Style B is more concise and preferred for new skills.

---

## Standard Multi-Item Detection Rule

All skills must detect when the input contains multiple distinct items (tickets, endpoints, features, bugs). When detected:

1. Ask: "I detected multiple [X]. Do you want: (A) One [output] covering all, or (B) Separate [outputs] per [X]?"
2. If the user chooses **(B)**: use `## Sheet: <name>` headings in the Phase 2 temp file — one block per item, single file, single Phase 3 call producing one workbook.
3. Only produce separate files if the user **explicitly** requests separate files.

---

## Standard Inference Flagging

- **In table cells:** append `(assumed — verify)` to the value.
- **In Comments/Notes columns:** write the assumption as a full sentence, e.g. `Assumed token expiry is 30 min per AC#2`.
- Never silently infer — every inferred value must be flagged.

---

## Standard Converter Error Recovery

If `md_table_to_xlsx.py` fails:
1. Do **not** edit the `.xlsx` output by hand.
2. Check the temp `.md` file:
   - Every data row must start and end with `|`.
   - The separator row uses only `-`, `:`, `|`, and spaces.
   - `## Sheet: <name>` headings must appear before each table when there are multiple tables.
   - Pipe characters inside cell values must be escaped as `\|`.
3. Fix the temp file and re-run Phase 3.
4. Never copy converter code into a skill's own folder — always call the shared script.

---

## File Path Rules

| Path type | Rule |
|-----------|------|
| Temp `.md` file | Write to the **session scratchpad directory** (provided in system context). Never use `/tmp/` or other system temp paths. |
| Output `.xlsx` file | Use `/mnt/user-data/outputs/` on Claude.ai; use `./outputs/` when running locally. Create the directory if it does not exist. |
