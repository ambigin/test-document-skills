"""
Tests for md_table_to_xlsx.py — run with: pytest tests/test_converter.py
"""

import json
import subprocess
import sys
from pathlib import Path

import openpyxl
import pytest

CONVERTER = Path(__file__).parent.parent / ".claude/skills/shared/md_table_to_xlsx.py"
SCRATCHPAD = Path(__file__).parent


def run(input_md: str, tmp_path: Path) -> tuple[dict, Path]:
    """Write input_md to a temp file, run the converter, return (json_result, xlsx_path)."""
    md_file = tmp_path / "input.md"
    xlsx_file = tmp_path / "output.xlsx"
    md_file.write_text(input_md, encoding="utf-8")
    result = subprocess.run(
        [sys.executable, str(CONVERTER), str(md_file), str(xlsx_file)],
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout), xlsx_file


# ── Parsing and basic output ───────────────────────────────────────────────────

def test_single_table_produces_success(tmp_path):
    md = "| A | B |\n|---|---|\n| 1 | 2 |\n"
    result, xlsx = run(md, tmp_path)
    assert result["status"] == "success"
    assert xlsx.exists()


def test_single_table_default_sheet_name(tmp_path):
    md = "| A | B |\n|---|---|\n| 1 | 2 |\n"
    _, xlsx = run(md, tmp_path)
    wb = openpyxl.load_workbook(xlsx)
    assert wb.sheetnames == ["Sheet1"]


def test_multi_sheet_produces_correct_sheet_names(tmp_path):
    md = "## Sheet: Alpha\n| X |\n|---|\n| v |\n\n## Sheet: Beta\n| Y |\n|---|\n| w |\n"
    _, xlsx = run(md, tmp_path)
    wb = openpyxl.load_workbook(xlsx)
    assert wb.sheetnames == ["Alpha", "Beta"]


def test_header_row_values(tmp_path):
    md = "| ID | Name | Status |\n|---|---|---|\n| 1 | Foo | Pass |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert [ws.cell(1, c).value for c in range(1, 4)] == ["ID", "Name", "Status"]


def test_data_row_values(tmp_path):
    md = "| ID | Name |\n|---|---|\n| 42 | Bar |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert ws.cell(2, 1).value == "42"
    assert ws.cell(2, 2).value == "Bar"


def test_row_count_matches_input(tmp_path):
    rows = "\n".join(f"| {i} | val{i} |" for i in range(1, 11))
    md = f"| ID | Val |\n|---|---|\n{rows}\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert ws.max_row == 11  # 1 header + 10 data


# ── Newline unescape (fix #2) ──────────────────────────────────────────────────

def test_backslash_n_becomes_real_newline(tmp_path):
    md = "| Steps |\n|---|\n| 1. Open\\n2. Click\\n3. Submit |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    cell_value = ws.cell(2, 1).value
    assert "\n" in cell_value, "literal \\n should be converted to real newline"
    assert "\\n" not in cell_value, "raw \\n string should not remain in cell"
    assert cell_value.count("\n") == 2


# ── Column widths (fix #3) ────────────────────────────────────────────────────

def test_column_width_uses_longest_line_not_total_length(tmp_path):
    # Three short lines joined with \n — total length >> longest single line
    md = "| Steps |\n|---|\n| 1. A\\n2. B\\n3. C |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    width = ws.column_dimensions["A"].width
    # Longest line is "1. A" = 4 chars; with header "Steps" = 5 chars
    # Total joined string is ~14 chars — width should be well under 20
    assert width < 20, f"width {width} should reflect longest line (~5 chars), not total length"


# ── Row heights (fix #4) ──────────────────────────────────────────────────────

def test_single_line_row_uses_minimum_height(tmp_path):
    md = "| A |\n|---|\n| short |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert ws.row_dimensions[2].height == 55  # DATA_ROW_HEIGHT minimum


def test_multiline_row_height_scales_up(tmp_path):
    # 6 lines — should exceed the minimum 55pt height
    steps = "\\n".join(f"{i}. Step" for i in range(1, 7))
    md = f"| Steps |\n|---|\n| {steps} |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert ws.row_dimensions[2].height > 55, "6-line cell should push row height above minimum"


# ── Edge cases ────────────────────────────────────────────────────────────────

def test_short_row_padded_to_header_width(tmp_path):
    # Data row has fewer columns than the header
    md = "| A | B | C |\n|---|---|---|\n| 1 |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    # openpyxl returns None for empty cells (empty string written == None on read)
    assert ws.cell(2, 2).value in (None, "")
    assert ws.cell(2, 3).value in (None, "")


def test_long_row_trimmed_to_header_width(tmp_path):
    md = "| A | B |\n|---|---|\n| 1 | 2 | extra | columns |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert ws.max_column == 2


def test_separator_row_not_written_as_data(tmp_path):
    md = "| A |\n|---|\n| val |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert ws.max_row == 2  # header + 1 data row, no separator row


def test_sheet_name_truncated_to_31_chars(tmp_path):
    long_name = "A" * 40
    md = f"## Sheet: {long_name}\n| X |\n|---|\n| v |\n"
    _, xlsx = run(md, tmp_path)
    wb = openpyxl.load_workbook(xlsx)
    assert all(len(name) <= 31 for name in wb.sheetnames)


def test_no_tables_returns_error(tmp_path):
    md = "Just some prose, no tables here.\n"
    result, _ = run(md, tmp_path)
    assert result["status"] == "error"
    assert "No markdown tables" in result["message"]


def test_missing_input_file_returns_error(tmp_path):
    xlsx_file = tmp_path / "output.xlsx"
    result = subprocess.run(
        [sys.executable, str(CONVERTER), str(tmp_path / "nonexistent.md"), str(xlsx_file)],
        capture_output=True,
        text=True,
    )
    out = json.loads(result.stdout)
    assert out["status"] == "error"
    assert result.returncode == 1


def test_header_is_frozen(tmp_path):
    md = "| A | B |\n|---|---|\n| 1 | 2 |\n"
    _, xlsx = run(md, tmp_path)
    ws = openpyxl.load_workbook(xlsx).active
    assert ws.freeze_panes == "A2"


def test_sample_fixture_converts_successfully(tmp_path):
    """Smoke test using the checked-in sample fixture."""
    sample = Path(__file__).parent / "sample-input.md"
    xlsx_file = tmp_path / "sample-output.xlsx"
    result = subprocess.run(
        [sys.executable, str(CONVERTER), str(sample), str(xlsx_file)],
        capture_output=True,
        text=True,
    )
    out = json.loads(result.stdout)
    assert out["status"] == "success"
    wb = openpyxl.load_workbook(xlsx_file)
    assert "Test Cases" in wb.sheetnames
    assert "Summary" in wb.sheetnames
