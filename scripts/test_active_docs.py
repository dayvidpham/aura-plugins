"""Regression tests for the actual active-document gate (stdlib only)."""
import importlib.util
import hashlib
from contextlib import redirect_stderr
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "active_docs", Path(__file__).with_name("check-active-docs.py")
)
GATE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GATE)


class ActiveDocsTests(unittest.TestCase):
    def test_prose_mandates_in_active_documents(self):
        fixtures = json.loads((Path(__file__).parent / "test-data/active-docs-prose.json").read_text())
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "docs/ROADMAP.md"
            path.parent.mkdir(parents=True)
            for case in fixtures:
                with self.subTest(name=case["name"]):
                    path.write_text(case["text"] + "\n")
                    findings = GATE.check(root, {})
                    self.assertEqual(case["reject"], bool(findings), findings)
                    if findings:
                        self.assertTrue(all(item.startswith("docs/ROADMAP.md:") for item in findings))

    def test_command_shapes_fail_conservatively(self):
        cases = [
            "bd ready", "Use `bd show URI` now", "env X=y command bd ready",
            'sudo "bd" close URI', "['bd', 'ready']", '{"command":"bd ready"}',
            "bd \\\nready", "cat <<'EOF'\nbd ready\nEOF", "`bd` is the tracker",
            "aura-swarm start --epic URI", "bin/aura-swarm status",
            "aura-swarm merge URI", "aura-swarm cleanup --done",
        ]
        for text in cases:
            with self.subTest(text=text):
                self.assertTrue(GATE.recipe_findings(text))

    def test_supported_and_packaging_text_passes(self):
        cases = [
            "pasture task ready", "bd-retirement audit", ".beads/issues.jsonl",
            "nix build .#aura-swarm --no-link", "nix run .#aura-swarm -- --help",
            "bin/aura-swarm is deprecated; do not use it for orchestration.",
        ]
        for text in cases:
            with self.subTest(text=text):
                self.assertFalse(GATE.recipe_findings(text))

    def test_new_document_joins_scope(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "skills/new-owner/SKILL.md"
            path.parent.mkdir(parents=True)
            path.write_text("bd ready\n")
            self.assertEqual([path], GATE.active_files(root))
            self.assertTrue(GATE.check(root, {}))
            root_doc = root / "NEW-WORKFLOW.md"
            root_doc.write_text("Use `bd ready`\n")
            self.assertIn(root_doc, GATE.active_files(root))

    def test_exact_history_cannot_authorize_new_recipe(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "skills/protocol/old.md"
            path.parent.mkdir(parents=True)
            path.write_text("Historical; non-operational.\n```sh\nbd ready\n```\n")
            history = {str(path.relative_to(root)): GATE.digest(path)}
            self.assertFalse(GATE.check(root, history))
            path.write_text(path.read_text() + "bd create new-work\n")
            self.assertTrue(GATE.check(root, history))

    def test_history_requires_visible_framing(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "AGENTS.md"
            path.write_text("bd ready\n")
            self.assertTrue(GATE.check(root, {"AGENTS.md": GATE.digest(path)}))

    def test_readme_exception_is_an_exact_range_not_a_file_escape(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "README.md"
            historical = ("### Manual (deprecated script)\n"
                          "Historical, non-operational.\nbd ready\n")
            path.write_text("Active setup\n" + historical + "## Marketplace\npasture task ready\n")
            history = {"README.md": hashlib.sha256(historical.encode()).hexdigest()}
            self.assertFalse(GATE.check(root, history))
            path.write_text(path.read_text() + "bd ready\n")
            self.assertTrue(GATE.check(root, history))
            path.write_text("Active setup\n" + historical.replace("ready", "create")
                            + "## Marketplace\n")
            self.assertTrue(GATE.check(root, history))

    def test_cli_rejects_missing_manifest_and_new_history_owner(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            manifest = root / "history.json"
            with patch.object(GATE, "ROOT", root), patch.object(GATE, "MANIFEST", manifest):
                errors = io.StringIO()
                with redirect_stderr(errors):
                    self.assertEqual(1, GATE.main())
                self.assertIn("Publication is withheld", errors.getvalue())
                manifest.write_text(json.dumps({"AGENTS.md": "0" * 64}))
                errors = io.StringIO()
                with redirect_stderr(errors):
                    self.assertEqual(1, GATE.main())
                self.assertIn("historical owner set changed", errors.getvalue())


if __name__ == "__main__":
    unittest.main()
