#!/usr/bin/env python3
"""Reject retired tracker/orchestrator recipes in Aura's active doc owners.

This is intentionally stricter than a semantic command classifier: a bare
retired tracker token in active prose, fences, inline code or quoted payloads
fails. It never rewrites documents. Historical protocol transcripts are allowed
only at exact, visibly framed, SHA-256-pinned identities; changing one requires
review of the whole exception. Only README's exact retired-swarm section is
historical; its live instructions are checked. Every Markdown owner under docs/
is checked, including dated records unless explicitly hash-pinned. CHANGELOG,
saved root transcripts, .agents.local/ and llm/ session archives, and deprecated
implementation code are outside the operational instruction-owner scope.
"""
import hashlib
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "scripts/active-docs-history.json"
HISTORICAL_OWNERS = frozenset({
    "skills/protocol/MIGRATION_v1_to_v2.md",
    "skills/protocol/user-request-revamp-v2.md",
    "skills/protocol/RESEARCH_EXAMPLE-nix-openclaw-req-ure-proposal.md",
    "README.md",
    "docs/adr/0001-pasture-toolkit-integration-architecture.md",
    "docs/audits/3iz51-sibling-epic-placement.md",
    "docs/audits/fzctk-supervisor-worker-fidelity.md",
    "docs/audits/mh4ek-constraint-coverage.md",
    "docs/audits/qzr8a-stale-work-triage.md",
    "docs/audits/request-level-triage.md",
    "docs/impl-plans/IMPL_PLAN-PROPOSAL-2-pasture-workflow-record.md",
    "docs/proposals/PROPOSAL-1-audit-3iz51.md",
    "docs/proposals/PROPOSAL-1-audit-5wbhm.md",
    "docs/proposals/PROPOSAL-1-audit-execution-plan.md",
    "docs/proposals/PROPOSAL-1-audit-mh4ek.md",
    "docs/proposals/PROPOSAL-1-audit-qzr8a.md",
    "docs/proposals/PROPOSAL-1-pasture-workflow-record.md",
    "docs/proposals/PROPOSAL-2-audit-execution-plan.md",
    "docs/proposals/PROPOSAL-2-pasture-workflow-record.md",
    "docs/proposals/ROADMAP-COMPLETENESS-AUDIT.md",
    "docs/research/schema-extension-code-examples.md",
})
HISTORICAL_RANGES = {"README.md": ("### Manual (deprecated script)", "## Marketplace")}
RETIRED_TRACKER = re.compile(r"(?<![\w.-])bd(?![\w.-])")
RETIRED_SWARM = re.compile(
    r"(?<![\w.-])(?:bin/)?aura-swarm\s+(?:start|status|attach|send|stop|list|resume|merge|review|cleanup)\b"
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def recipe_findings(text):
    # Scan the entire text, not just starts of shell lines: wrappers, heredocs,
    # inline guidance and quoted command arrays must not evade the gate.
    return [
        (text.count("\n", 0, match.start()) + 1, match.group())
        for pattern in (RETIRED_TRACKER, RETIRED_SWARM)
        for match in pattern.finditer(text)
    ]


def active_files(root):
    # Linked copies of AGENTS.md are checked through their canonical owner.
    archived_root = {"CHANGELOG.md", "improvements.md", "improvements-2.md",
                     "CLAUDE.md", "GEMINI.md"}
    paths = {path for path in root.glob("*.md") if path.name not in archived_root}
    for owner in ("skills", "agents", ".claude/skills", ".claude/agents",
                  ".opencode/skill", ".opencode/agent", ".agents/skills", "docs"):
        paths.update((root / owner).rglob("*.md"))
    return sorted(path for path in paths if path.is_file())


def check(root, history):
    failures = []
    for path in active_files(root):
        relative = str(path.relative_to(root))
        try:
            text = path.read_bytes().decode("utf-8")
        except (OSError, UnicodeError) as error:
            failures.append(f"{relative}: cannot read UTF-8 document during validation: {error}")
            continue
        if relative in history:
            historical = text
            if relative in HISTORICAL_RANGES:
                start, end = HISTORICAL_RANGES[relative]
                if text.count(start) != 1 or text.count(end) != 1:
                    failures.append(f"{relative}: historical range delimiters changed")
                    continue
                begin, finish = text.index(start), text.index(end)
                if begin >= finish:
                    failures.append(f"{relative}: historical range order changed")
                    continue
                historical = text[begin:finish]
            identity = hashlib.sha256(historical.encode()).hexdigest()
            if identity != history[relative]:
                failures.append(f"{relative}: historical content identity changed")
            if "historical" not in historical.lower() or "non-operational" not in historical.lower():
                failures.append(f"{relative}: historical exception lacks visible framing")
            if relative not in HISTORICAL_RANGES:
                continue
            # Keep line coordinates intact while excluding only the pinned range.
            text = text[:begin] + "\n" * historical.count("\n") + text[finish:]
        for line, rejected in recipe_findings(text):
            failures.append(f"{relative}:{line}: retired operational token {rejected!r}")
    for relative in history:
        if not (root / relative).is_file():
            failures.append(f"{relative}: pinned historical owner is missing")
    return failures


def main():
    try:
        history = json.loads(MANIFEST.read_text())
        if not isinstance(history, dict) or not all(
            isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value)
            for value in history.values()
        ):
            raise ValueError("expected an object mapping historical owner paths to SHA-256 strings")
    except (OSError, UnicodeError, ValueError) as error:
        print(f"active-doc gate: cannot load {MANIFEST.name} during documentation validation: "
              f"{error}. Publication is withheld; restore the reviewed historical identity "
              "manifest at scripts/active-docs-history.json and rerun the gate.", file=sys.stderr)
        return 1
    if set(history) != HISTORICAL_OWNERS:
        print("active-doc gate: historical owner set changed; review the closed exception "
              "inventory in scripts/check-active-docs.py before updating hashes.", file=sys.stderr)
        return 1
    failures = check(ROOT, history)
    if failures:
        for failure in failures:
            print(f"active-doc gate: {failure}", file=sys.stderr)
        print("During documentation validation, retired recipes or changed history were found. "
              "Publication is withheld. Migrate the owning active document to supported "
              "Pasture task commands; do not add an active workflow to historical exceptions. "
              "For intentional historical edits, review visible non-operational framing and "
              "refresh the exact SHA-256 in scripts/active-docs-history.json.", file=sys.stderr)
        return 1
    print(f"active-doc gate: PASS ({len(active_files(ROOT))} owners; "
          f"{len(history)} exact historical documents)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
