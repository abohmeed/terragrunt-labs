#!/usr/bin/env bash
# Turn report.json and plan.log into the pull request comment body.
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
import json
import re
from pathlib import Path

rows = json.loads(Path("report.json").read_text())
log = Path("plan.log").read_text(errors="replace")
log = re.sub(r"\x1b\[[0-9;]*m", "", log)

lines = [
    "## Terragrunt plan",
    "",
    "| Unit | Result | Command |",
    "| --- | --- | --- |",
]
for row in sorted(rows, key=lambda item: item["Name"]):
    lines.append(f"| `{row['Name']}` | {row['Result']} | {row.get('Cmd', '')} |")

lines.extend(["", "### Plan", "", "```text"])
for raw in log.splitlines():
    if "Plan:" in raw:
        lines.append(raw.strip())
lines.extend(["```", ""])
Path("plan-comment.md").write_text("\n".join(lines) + "\n")
PY
