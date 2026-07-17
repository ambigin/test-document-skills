#!/usr/bin/env python3
"""
json_to_xlsx.py — shared converter

Turns a generic "workbook spec" JSON file into a formatted .xlsx workbook
using openpyxl. Intended to be reused by ANY skill that needs to hand off
tabular data to a spreadsheet (test-case-generator, test-data-generator,
bug-report-generator, etc.) instead of each skill writing its own openpyxl
code.

USAGE
    python json_to_xlsx.py <input.json> <output.xlsx>

INPUT JSON SCHEMA
{
  "sheets": [
    {
      "name": "Test Cases",                 # required, <=31 chars, unique per workbook
      "blocks": [                           # one or more stacked tables on this sheet
        {
          "title": "Summary Counts",        # optional. If present, rendered as a bold
                                             # title row above this block's header row.
          "columns": [
            {
              "header": "Test Case ID",     # required, also the dict key rows use
              "width": 16,                  # optional column width in characters
              "wrap": false                 # optional, default false. Set true for
                                             # long free-text columns (steps, notes).
            }
            // ... more columns
          ],
          "rows": [
            { "Test Case ID": "TC-PROJ-123-001", "Test Case Name": "..." }
            // one dict per row, keyed by column header. Missing keys -> blank cell.
          ],
          "freeze_header": true             # optional, default true for the first
                                             # block on a sheet, false otherwise.
                                             # Freezes just below this block's header row.
        }
        // additional blocks are stacked vertically, separated by one blank row
      ]
    }
    // additional sheets
  ]
}

DESIGN NOTES
- This script produces STATIC values only (no formulas). If a future skill needs
  live formulas, write them as strings in the cell value (e.g. "=SUM(B2:B9)") and
  run this repo's xlsx-skill scripts/recalc.py afterward — this script does not
  do that recalculation itself.
- Font/fill choices follow the shared xlsx skill conventions: a professional font
  (Calibri) throughout, bold + light-fill header rows, frozen header panes.
- Kept dependency-light (openpyxl only) so it can be dropped into any skill's
  scripts/ folder or imported as a module (see convert() below).
"""

import json
import sys
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

FONT_NAME = "Calibri"
HEADER_FILL = PatternFill(start_color="D9E1F2", end_color="D9E1F2", fill_type="solid")
HEADER_FONT = Font(name=FONT_NAME, bold=True)
TITLE_FONT = Font(name=FONT_NAME, bold=True, size=12)
BODY_FONT = Font(name=FONT_NAME)


def _write_block(ws, start_row, block, is_first_block):
    """Writes one block (optional title + header + rows) starting at start_row.
    Returns the row number just after this block (before the blank separator)."""
    row = start_row
    columns = block["columns"]
    headers = [c["header"] for c in columns]

    if block.get("title"):
        ws.cell(row=row, column=1, value=block["title"]).font = TITLE_FONT
        row += 1

    header_row = row
    for col_idx, col in enumerate(columns, start=1):
        cell = ws.cell(row=header_row, column=col_idx, value=col["header"])
        cell.font = HEADER_FONT
        cell.fill = HEADER_FILL
        width = col.get("width")
        if width:
            ws.column_dimensions[get_column_letter(col_idx)].width = width
    row += 1

    for record in block.get("rows", []):
        for col_idx, col in enumerate(columns, start=1):
            value = record.get(col["header"], "")
            cell = ws.cell(row=row, column=col_idx, value=value)
            cell.font = BODY_FONT
            if col.get("wrap"):
                cell.alignment = Alignment(wrap_text=True, vertical="top")
        row += 1

    freeze = block.get("freeze_header", is_first_block)
    if freeze:
        ws.freeze_panes = f"A{header_row + 1}"

    return row, headers


def convert(spec: dict, output_path: str):
    wb = Workbook()
    wb.remove(wb.active)  # drop the default blank sheet

    for sheet_spec in spec["sheets"]:
        name = sheet_spec["name"][:31]  # Excel sheet name limit
        ws = wb.create_sheet(title=name)
        row = 1
        for i, block in enumerate(sheet_spec.get("blocks", [])):
            row, _ = _write_block(ws, row, block, is_first_block=(i == 0))
            row += 1  # blank separator row between stacked blocks

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    wb.save(output_path)


def main():
    if len(sys.argv) != 3:
        print("Usage: python json_to_xlsx.py <input.json> <output.xlsx>", file=sys.stderr)
        sys.exit(1)

    input_path, output_path = sys.argv[1], sys.argv[2]

    with open(input_path, "r", encoding="utf-8") as f:
        spec = json.load(f)

    if "sheets" not in spec or not spec["sheets"]:
        print("Error: JSON must contain a non-empty 'sheets' array.", file=sys.stderr)
        sys.exit(1)

    convert(spec, output_path)
    print(json.dumps({"status": "success", "output": output_path,
                       "sheets": [s["name"] for s in spec["sheets"]]}))


if __name__ == "__main__":
    main()
