from __future__ import annotations

import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRODUCER = ROOT / "bin" / "aura-aggregate-release"
VERIFY_HELPER = ROOT / "tests" / "aggregate_contract_verify.go"
PASTURE_REVISION = "f5cbf4f92bb458eb0baff64f6adec603bcf0d74f"
AURA_REVISION = "b8e467d5d31f98f503f05f703890f9a2dcfb704c"
CELLS = tuple(
    f"{harness}/{extension}"
    for harness in ("claude-code", "opencode", "codex")
    for extension in ("skills", "agents", "hooks")
)


class AggregateReleaseProducerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        components = []
        for index, cell in enumerate(CELLS, 1):
            artifact = self.root / f"input-{index}.tgz"
            artifact.write_bytes(f"exact bytes for {cell}\n".encode())
            components.append(
                {
                    "id": cell,
                    "artifact": artifact.name,
                    "bundle_id": f"artifact.bundle.v1:sha256:{index:064x}",
                }
            )
        self.component_set = self.root / "components.json"
        self.component_set.write_text(
            json.dumps({"schema": "aura.aggregate-components/v1", "components": components}), encoding="utf-8"
        )

    def run_producer(self, version: str = "1.2.0", output_name: str = "release") -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                str(PRODUCER),
                "--version", version,
                "--installer-min", "1.0.0",
                "--installer-max", "1.9.9",
                "--pasture-revision", PASTURE_REVISION,
                "--aura-revision", AURA_REVISION,
                "--components", str(self.component_set),
                "--output-dir", str(self.root / output_name),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_production_cli_freezes_exact_closed_contract(self) -> None:
        completed = self.run_producer()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        output = self.root / "release"
        manifest_bytes = (output / "pasture-aggregate-manifest.json").read_bytes()
        manifest = json.loads(manifest_bytes)
        self.assertEqual(manifest["schema"], "pasture.aggregate-release/v1")
        self.assertEqual(manifest["version"], "1.2.0")
        self.assertEqual(manifest["channel"], "final")
        self.assertEqual(manifest["revisions"], {"pasture": PASTURE_REVISION, "aura": AURA_REVISION})
        self.assertEqual({item["id"] for item in manifest["components"]}, set(CELLS))
        self.assertEqual(len(manifest["components"]), 9)
        for item in manifest["components"]:
            content = (output / item["asset"]).read_bytes()
            self.assertEqual(item["digest"], f"sha256:{hashlib.sha256(content).hexdigest()}")
            self.assertNotIn("pasture-stable", item["asset"])
        checksum = hashlib.sha256(manifest_bytes).hexdigest()
        self.assertEqual(
            (output / "pasture-aggregate-manifest.json.sha256").read_text(),
            f"{checksum}  pasture-aggregate-manifest.json\n",
        )

    def test_prerelease_classification_is_derived_not_mutable_input(self) -> None:
        completed = self.run_producer("1.2.0-rc.1", "candidate")
        self.assertEqual(completed.returncode, 0, completed.stderr)
        manifest = json.loads((self.root / "candidate" / "pasture-aggregate-manifest.json").read_bytes())
        self.assertEqual(manifest["channel"], "prerelease")

    def test_moving_alias_version_is_rejected_without_output(self) -> None:
        completed = self.run_producer("pasture-stable")
        self.assertEqual(completed.returncode, 2)
        self.assertIn("not canonical SemVer", completed.stderr)
        self.assertFalse((self.root / "release").exists())

    def test_incomplete_or_unknown_component_contract_is_rejected_without_output(self) -> None:
        document = json.loads(self.component_set.read_text())
        document["components"].pop()
        document["moving_alias"] = "pasture-stable"
        self.component_set.write_text(json.dumps(document))
        completed = self.run_producer()
        self.assertEqual(completed.returncode, 2)
        self.assertIn("expected only schema", completed.stderr)
        self.assertFalse((self.root / "release").exists())

    def test_existing_aggregate_is_never_overwritten(self) -> None:
        first = self.run_producer()
        self.assertEqual(first.returncode, 0, first.stderr)
        manifest_before = (self.root / "release" / "pasture-aggregate-manifest.json").read_bytes()
        second = self.run_producer()
        self.assertEqual(second.returncode, 2)
        self.assertIn("will not be mutated", second.stderr)
        self.assertEqual((self.root / "release" / "pasture-aggregate-manifest.json").read_bytes(), manifest_before)

    def test_output_is_accepted_by_pasture_typed_verifier_without_adapter(self) -> None:
        pasture = os.environ.get("PASTURE_CONTRACT_SOURCE")
        if pasture is None:
            self.skipTest("set PASTURE_CONTRACT_SOURCE to the accepted Pasture contract checkout")
        pasture_path = Path(pasture)
        self.assertEqual(
            subprocess.run(["git", "rev-parse", "HEAD"], cwd=pasture_path, text=True, capture_output=True, check=True).stdout.strip(),
            PASTURE_REVISION,
        )
        completed = self.run_producer()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        subprocess.run(
            [
                "nix", "develop", "--command", "go", "run", str(VERIFY_HELPER),
                str(self.root / "release"), "1.2.0", "1.5.0",
                PASTURE_REVISION, AURA_REVISION, "final",
            ],
            cwd=pasture_path,
            check=True,
        )


if __name__ == "__main__":
    unittest.main()
