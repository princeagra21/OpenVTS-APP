#!/usr/bin/env python3
"""Classify updateLocalUiState usage for the OpenVTS Riverpod migration.

This is intentionally conservative. It does not decide correctness by line count;
it flags likely API/business-state mutations so they can be migrated to typed
Riverpod controllers while keeping tiny UI-only state local.
"""
from __future__ import annotations

import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEARCH_ROOTS = [ROOT / "lib" / "features", ROOT / "lib" / "shared"]

BUSINESS_KEYWORDS = (
    "loading",
    "saving",
    "submitting",
    "deleting",
    "refresh",
    "error",
    "result",
    "response",
    "data",
    "items",
    "users",
    "vehicles",
    "drivers",
    "documents",
    "tickets",
    "notifications",
    "payments",
    "transactions",
    "logs",
    "profile",
    "details",
    "statussubmitting",
    "uplo",  # upload/uploading
    "token",
    "session",
    "role",
    "permission",
    "socket",
    "telemetry",
)

UI_KEYWORDS = (
    "tab",
    "filter",
    "dropdown",
    "expanded",
    "collapse",
    "obscure",
    "visible",
    "hover",
    "focus",
    "zoom",
    "tile",
    "label",
    "theme",
    "direction",
    "unit",
    "searchquery",
    "query",
    "pagesize",
    "daterange",
    "selecteddate",
    "selectedrange",
    "selectedsocial",
    "selectedprefix",
    "selectedcountry",
    "selectedstate",
    "selectedcity",
    "selectedicon",
    "channel",
    "drawer",
    "sheet",
    "menu",
    "animation",
    "waypoints",  # temporary route drawing UI
    "route",      # temporary route drawing UI, still reviewed manually
)

CALL_RE = re.compile(r"\bupdateLocalUiState\s*\((?P<body>.*?)\);", re.DOTALL)
ASSIGN_RE = re.compile(r"\b(?P<name>_?[A-Za-z]\w*)\s*(?:=|\+=|-=|\.add\(|\.remove\(|\.clear\(|\[)")


def classify(snippet: str) -> tuple[str, tuple[str, ...]]:
    assigned = tuple(
        name
        for name in ASSIGN_RE.findall(snippet)
        if name not in {"updateLocalUiState", "this", "context", "ref"}
    )
    normalized = " ".join(assigned).lower()
    if any(keyword in normalized for keyword in BUSINESS_KEYWORDS):
        return "business_or_api_state", assigned
    if assigned and all(any(keyword in name.lower() for keyword in UI_KEYWORDS) for name in assigned):
        return "local_ui_state", assigned
    if "() {}" in snippet or "(){}" in snippet.replace(" ", ""):
        return "rebuild_signal_review", assigned
    return "manual_review", assigned


def main() -> int:
    rows: list[tuple[str, int, str, tuple[str, ...], str]] = []
    for root in SEARCH_ROOTS:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.dart")):
            text = path.read_text(encoding="utf-8", errors="ignore")
            for match in CALL_RE.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                snippet = " ".join(match.group(0).split())
                category, assigned = classify(snippet)
                rows.append((str(path.relative_to(ROOT)), line, category, assigned, snippet[:240]))

    counts = Counter(row[2] for row in rows)
    file_counts: dict[str, Counter[str]] = defaultdict(Counter)
    for rel, _line, category, _assigned, _snippet in rows:
        file_counts[rel][category] += 1

    out = ROOT / "reports_update_local_ui_state_classification.md"
    with out.open("w", encoding="utf-8") as fh:
        fh.write("# updateLocalUiState Classification Report\n\n")
        fh.write("This report classifies each `updateLocalUiState` usage for Riverpod migration.\n\n")
        fh.write("## Summary\n\n")
        fh.write(f"- Total calls: {len(rows)}\n")
        for category, count in counts.most_common():
            fh.write(f"- {category}: {count}\n")
        fh.write("\n## Highest-risk files\n\n")
        fh.write("| File | Business/API | Manual review | UI-only | Rebuild signal |\n")
        fh.write("|---|---:|---:|---:|---:|\n")
        for rel, counter in sorted(
            file_counts.items(),
            key=lambda item: (item[1]["business_or_api_state"], item[1]["manual_review"], sum(item[1].values())),
            reverse=True,
        )[:60]:
            fh.write(
                f"| `{rel}` | {counter['business_or_api_state']} | {counter['manual_review']} | "
                f"{counter['local_ui_state']} | {counter['rebuild_signal_review']} |\n"
            )
        fh.write("\n## Business/API-state candidates\n\n")
        fh.write("| File:line | Assigned state | Snippet |\n")
        fh.write("|---|---|---|\n")
        for rel, line, category, assigned, snippet in rows:
            if category != "business_or_api_state":
                continue
            assigned_text = ", ".join(assigned) if assigned else "—"
            fh.write(f"| `{rel}:{line}` | `{assigned_text}` | `{snippet.replace('|', '\\|')}` |\n")
    print(out.relative_to(ROOT))
    print(f"total={len(rows)}")
    for category, count in counts.most_common():
        print(f"{category}={count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
