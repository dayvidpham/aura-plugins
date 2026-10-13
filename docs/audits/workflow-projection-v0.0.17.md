# Aura workflow and projection verification — 2026-10-11

Scope: aura-plugins issue #34; Pasture issue #43. This report records checks,
not a Home Manager activation or a claim that private harness trust was changed.
The installed-surface cleanup and fresh OpenCode session proof belong to the
separate Pasture deployment owner.

## Source and projection

- Base: aura-plugins `origin/main` at `954dd54` (isolated issue worktree).
- Pasture input: release `v0.0.17`, revision
  `888d07d06098f60601184d7bc5871232f32e78c9`.
- This change moves the Home Manager flake input, not every shipping channel.
  The development submodule gitlink and marketplace channel remain at `0.0.16`
  deliberately: neither controls Home Manager's generated source, the requested
  scope does not bump the marketplace channel, and no dirty source checkout is
  moved. The release producer also consumes the flake input, never the gitlink.
- Destination derivation:
  `nix eval --raw .#checks.x86_64-linux.hm-module-test.pinnedDestinations`.
  Comparing that result with the committed snapshot is identical. The sole
  removed destination is `.claude/hooks/bd-prime.md`; no destinations were added.
  The derivation consumes the existing `hm-lib.nix` layout/module evaluation,
  not a parallel handwritten layout.
- The existing OpenCode hooks cell still projects
  `.opencode/plugins/pasture-lifecycle.ts` as
  `.config/opencode/plugins/pasture-hooks.ts`. The pinned payload contains the
  `[pasture:task-recovery]` marker and composed `session.context` callback.
- The Home Manager test build passes every evaluation case and all nine-cell
  byte/mode comparisons for both fixtures and the pinned release. New assertions
  check retired Claude payload absence and embedded OpenCode recovery presence.
  The pre-refresh build failed on the exact one-line snapshot difference;
  the refreshed build passed.
- No module implementation, layout, source permissions, native installation
  inventory, private trust/configuration, marketplace pin, deprecated Python
  orchestration or Git hook configuration was changed.

## Workflow and gates

AGENTS.md now uses explicit Aura namespace and registered author, lowercase JSON
`id` capture, separate create/label writes, live recovery reads, full URI operands,
parent-blocked-by-child dependencies, frontmatter references and supervisor-only
closure. Git hook approval policy, source matrix, home containment, Codex layout
lock and source-mode rules remain. Landing records tracker evidence instead of a
tracker sync. Linked CLAUDE.md/GEMINI.md remain links to this authority.

The local epic-composer source and opt-in protocol docs use the Pasture workflow.
Marketplace descriptive copy now names Pasture task tracking and deprecates the
old orchestrator; its shipping-channel version remains `0.0.16` (not bumped).
Three retained protocol transcripts and seventeen dated ADR/audit/plan/research
records are visibly non-operational and protected by exact content hashes (their
historical bodies are unchanged). The document gate checks active root docs, skills,
agents and `docs/`; README's historical swarm examples are an exact pinned range,
not a whole-file exception. CHANGELOG and dated session/transcript archives are
not operational recipe sources. Unknown bare retired-tracker tokens in active
text reject conservatively, including wrappers, fences, inline guidance and
quoted command payloads. This is a document validator, not a protocol engine or
a runtime translator.

Passed commands:

```text
python3 scripts/test_active_docs.py
python3 scripts/check-active-docs.py
nix build .#checks.x86_64-linux.active-docs --no-link
nix flake check --no-build
nix flake check
nix build .#checks.x86_64-linux.hm-module-test --no-link
nix build .#checks.x86_64-linux.release-scripts .#aggregate-release --no-link
nix build .#aura-swarm --no-link
nix run .#aura-swarm -- --help
nix run nixpkgs#actionlint -- -color
nix shell nixpkgs#shellcheck --command shellcheck scripts/release/*.sh
git diff --check
```

The last two swarm commands are required packaging regressions only; they are
not endorsement or adoption of the deprecated orchestrator. Release helper
suites passed 69 grammar, 26 aggregate-verifier, 10 pin-reader and 13 release-tag
assertion checks; aggregate-release's Go suite also passed in its Nix build.
The final direct and Nix-sandbox document gates report 70 owners, 21 exact
historical identities and seven passing unit tests. The flake checks build on
x86_64-linux; aarch64-linux outputs were evaluated, not executed on this host.

## Upstream release build blocker

The existing release-chain CI step cannot pass at the requested pin:

```text
nix build github:dayvidpham/pasture/888d07d06098f60601184d7bc5871232f32e78c9#pasture --no-link --print-out-paths
hash mismatch in fixed-output derivation pasture-0.0.17-go-modules:
specified: sha256-Dv41FdDZhFHMkQoic6TBmJSLjF4NwGbR+dBa+BaQSNs=
got:       sha256-RiZgpfbBWF46TFHlneAVtrPiDF4kTs7YHEu4BQ+sdYc=
```

No local hash override or substitute pin hides this failure. The operator must
resolve the upstream release packaging and approve a shipping revision decision
before claiming the full existing release chain passes.

Command-contract evidence instead uses the authentic release asset
`pasture-linux-amd64`, checksum-verified against the published `checksums.txt`:
version `pasture version v0.0.17`, SHA-256
`ff6f8c8aeaa8084f4920c6766fd12e9f6ed75b1daf1134f050a20b1e3c02f038`.
This proves the release CLI behavior, not the failed Nix build.

The public `v0.0.17` release tag was also verified to resolve to the exact locked
revision through `scripts/release/assert-pasture-release-tag.sh`.

## Approved Aura tracker dogfood

On 2026-10-11 at 11:20 UTC, a verification supervisor ran both the isolated-store
and approved working-store loops using only the checksum-verified release CLI,
explicit Aura namespace and explicit registered system author. Each loop:

```text
create parent + child -> separate label -> update child in_progress
-> attributed comments -> parent blocked_by child -> blocked/tree read-back
-> supervisor close verification child -> parent ready read-back
-> supervisor close verification parent -> show/comments/tree/timeline read-back
```

All 20 steps per store exited 0, without retries. Only newly created verification
tasks were closed, with explicit smoke reasons; no program/slice/leaf task was
closed. Labels, comment author, full-URI edge direction and final `closed` states
were read back. The real namespace gained exactly the two verification tasks.

| Store | Task | Full returned URI |
|---|---|---|
| Isolated | parent | `https://github.com/dayvidpham/aura-plugins--01a12ab0-fc8a-74c7-b823-a7d070ce4d7e` |
| Isolated | child | `https://github.com/dayvidpham/aura-plugins--01a12ab0-fcb0-71b6-ae35-e429b3cec271` |
| Working | parent | `https://github.com/dayvidpham/aura-plugins--01a12ab1-164d-784c-b0cb-d84c8fd96797` |
| Working | child | `https://github.com/dayvidpham/aura-plugins--01a12ab1-1dc9-7d2d-be81-02a2d5fd8fc9` |

Both comment reads confirm author
`pasture-system--00000000-0000-0000-0000-000000000000`. Both timelines succeeded
but returned zero events: this release's timeline reads task-linked epoch audit
events, and plain task CRUD does not emit them. This is the observed surface,
not a claim of a populated CRUD audit timeline. Independent process read-backs
of task states, comments and blocker edges provide the durable-state evidence.

The retained `.beads/issues.jsonl` SHA-256 before and after both loops was
`43fe1700fe541959ed781a49bd29a6f10a243f27f609efc41a195a62fb11d75a`
(size 265101 bytes, modification time unchanged). This proves the Pasture-only
loops did not change it, not that the separate triage/freeze work is accepted.
Sanitized full step results were recorded locally at
`/tmp/opencode/s4-dogfood-evidence.json`; the committed-tree identity is supplied
in the slice's attributed handoff comment after this report is committed.

## Approved follow-up: v0.0.18

The user approved moving the Home Manager input to Pasture `v0.0.18`, revision
`540e66ce8b9d74b32c83c1c1236d720ffa47e02a`, after the vendorHash correction in
Pasture PR #188. The v0.0.17 failure above is retained historical evidence,
not a current worker blocker. The exact new pinned Pasture Nix build succeeds
without overrides:

```text
nix build github:dayvidpham/pasture/540e66ce8b9d74b32c83c1c1236d720ffa47e02a#pasture --no-link
```

Re-derivation through
`nix eval --raw .#checks.x86_64-linux.hm-module-test.pinnedDestinations` is
byte-identical to the v0.0.17 snapshot; its unchanged SHA-256 is
`e1b8b5ea3e4edc8b437402dfdd338a607903540342247a9f4d722d84544acb29`.
No snapshot content, layout, module, marketplace channel or gitlink edit is
needed. Only the flake input/lock move, with this evidence addendum.

The following reruns pass: `nix flake check --no-build`, the realized
`checks.x86_64-linux.hm-module-test` (all evaluation cases and nine-cell
fixture/pinned byte-and-mode comparisons), `nix build .#aura-swarm --no-link`,
and `nix run .#aura-swarm -- --help` (packaging only). The seven document-gate
unit tests and direct active-document gate also pass, as does the public
release-tag assertion against the locked revision. This is not a claim that
the entire separate release publication ceremony was rerun.

The first evaluation encountered invalid local store paths for unchanged
test fixtures. Re-importing the existing empty fixture and realizing the exact
existing protocol-fixture expression restored those paths without source
changes; the ordinary required gates then passed. No gate was weakened or
skipped. No outstanding worker blocker, push, activation or task closure.
