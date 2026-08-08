---
report_kind: authentic-harness-capture-evidence
created: 2026-08-03
status: four-raw-candidates-user-cleared
implementation_authorized: false
raw_fixture_commit_cleared: true
cleared_fixture_count: 4
redaction_status: not-required-for-cleared-candidates
pasture_commit: 0414ad9a7455905c6f865468fe0f2c23222d11b7
opencode_version: 1.18.10
opencode_source_commit: 7902e04c3a67f7c69726bc955efb46e29214c797
codex_version: 0.146.0
codex_source_commit: d6407d735942c7cfc996aa2bc7d0f97fc8f0e4bf
beads_ure: aura-plugins-a6h3d
---

# OpenCode And Codex Authentic Capture Evidence

## Purpose

This report records the isolated OpenCode and Codex exploration captures requested
for M2/M3 requirements work. It identifies what was observed, how it was captured,
what may be useful as a fixture, and which raw payloads the user cleared for Git.

The report is evidence for elicitation and proposal design. It is not a ratified
proposal, implementation plan, fixture import, or authorization to change Pasture.

## Evidence Rule

"Authentic" means the payload was observed during an actual installed-harness run.
It does not mean that every capture is an exact native wire representation:

- OpenCode invokes an in-process JavaScript plugin with objects. The capture is the
  exact JSONL bytes written by that plugin after `JSON.stringify`; it is an
  authentic runtime observation, but there is no separate native wire byte stream.
- Codex invokes command hooks with JSON on stdin. The capture writes those stdin
  bytes unchanged and records their SHA-256 digest and size in a sidecar.
- A transformed fixture remains derived from authentic evidence, but it must be
  labeled redacted and must not claim exact equality with the raw capture bytes.

## Baselines

| Component | Runtime or source | Provenance |
|---|---|---|
| Pasture | Detached safe worktree | `0414ad9a7455905c6f865468fe0f2c23222d11b7` |
| OpenCode runtime | Installed `1.18.10` | Isolated temporary config/data state |
| OpenCode source | Tag `v1.18.10` | `7902e04c3a67f7c69726bc955efb46e29214c797` |
| Codex runtime | Installed `codex-cli 0.146.0` | Isolated temporary `CODEX_HOME` and hook config |
| Codex source | Shallow inspected revision | `d6407d735942c7cfc996aa2bc7d0f97fc8f0e4bf` |

The Codex source revision supports contract inspection. This report does not claim
that the revision is the exact source tag used to build the installed binary.

## Prompt And Safety Boundary

Both sessions were prompted to inspect the detached Pasture worktree and return a
Markdown architecture report without changing the repository. The exact prompts
remain in the private session streams and are intentionally not copied here; this
report records only their non-sensitive intent.

OpenCode used an explicit deny-by-default permission map. Only `read`, `glob`,
`grep`, and `list` were allowed. Editing, shell execution, subagents, external
directories, and network tools were denied.

Codex used an isolated hook configuration and a read-only exploration instruction.
Its seven `PreToolUse` observations were all `Bash`, so the prompt and detached
worktree boundary, rather than a tool-name allowlist, constrained the run. The
Pasture worktree was clean at `0414ad9` after both sessions. This proves no tracked
worktree change; it does not claim that every possible filesystem side effect was
mechanically impossible.

No Git hook was installed, enabled, or modified.

## Capture Storage

The private capture root is `/tmp/opencode/harness-capture-20260803`. The root,
provider directories, and Codex output directory are mode `0700`. Reviewed capture
files are mode `0600`.

Temporary authentication files, SQLite databases, caches, model catalogs, and
plugin caches are operational harness state. They are excluded from fixture scope
and were not inspected for this report.

## OpenCode Observation

The JavaScript capture plugin recorded only `session.created` and
`tool.execute.before`. The capture itself is 15,546 bytes.

| Event | Count | Scope-relevant shape |
|---|---:|---|
| `session.created` | 1 | `event.type`, `event.id`, `properties.info.*`, and `properties.sessionID` |
| `tool.execute.before` | 39 | `input.tool`, `input.sessionID`, `input.callID`, and mutable `output.args` |

Observed tool distribution:

| Tool | Count |
|---|---:|
| `read` | 30 |
| `grep` | 5 |
| `glob` | 4 |

The authentic `session.created` observation contains both
`properties.info.id` and `properties.sessionID`. That resolves the source/type
ambiguity for this installed version, but only for the observed callback shape.

OpenCode evidence digests:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `opencode/lifecycle.jsonl` | 15,546 | `cf1bb44424ef4bf1d3b3f39041474aa4ef986c95dc3aaa5deaab69614e588a47` |
| `opencode/session.jsonl` | 543,087 | `98e3ad078f027d0fdaa35db3c67d82620aa162f0ee778af78ab7b88f22897bec` |
| `opencode/stderr.log` | 0 | Empty |

The session stream is provenance support, not a candidate lifecycle fixture.

## Codex Observation

The command hook wrote exact stdin bytes to one file per invocation. Every sidecar
digest and byte count was checked against its corresponding payload.

| Event | Count | Total bytes | Minimum | Maximum |
|---|---:|---:|---:|---:|
| `SessionStart` | 1 | 291 | 291 | 291 |
| `PreToolUse` | 7 | 6,051 | 507 | 1,055 |
| `PostToolUse` | 7 | 254,494 | 19,538 | 44,115 |
| `Stop` | 1 | 6,261 | 6,261 | 6,261 |
| `SessionEnd` | 1 | 227 | 227 | 227 |

All seven `PreToolUse` events used `tool_name: Bash`. `PreToolUse` carried the
common pre-execution fields needed for M3 research: session, turn, tool-use,
tool name/input, model, permission mode, and current working directory.

Codex supporting evidence digests:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `codex/session.jsonl` | 555,753 | `def1b315b19c923f34628c178bb6c5f761ecd2288da85f5f35f53be0e2ddd071` |
| `codex/last-message.md` | 5,852 | `769452971686f4f15f0327c7ed918b8d17d6edbe3a237f354b5264ba9d436460` |
| `codex/stderr.log` | 251 | Non-empty operational warning; not fixture input |

The session stream, final response, and stderr are provenance support only.

## Privacy Review

The review inspected payload schemas, field paths, counts, permissions, sizes,
and digests without copying raw values into this report. A high-confidence scan
for common API-key, bearer-token, GitHub-token, Slack-token, and private-key
signatures found zero matches in the OpenCode lifecycle capture and Codex hook
payloads. This is useful negative evidence, not a proof that arbitrary secrets are
absent.

The broader captures are not cleared for exact-byte commit:

| Corpus | Privacy-bearing data found structurally |
|---|---|
| OpenCode lifecycle | 40 absolute user-home path values; session/call/project identifiers; title and slug; permission patterns; tool paths and search patterns |
| Codex hook payloads | 18 absolute user-home path values; session/turn/tool-use identifiers; shell commands; model and permission state; tool responses; final assistant text |

`PostToolUse` and `Stop` have the largest content-exposure surface because they
carry tool responses or assistant text. They are not needed for the currently
selected M2 path or the strongest M3 pre-execution equivalence candidate and
should not be imported merely because they were captured.

After reviewing the candidate-specific field inventory and negative credential
scan, the user first responded `Don't redact these right now` and then clarified:
`We can commit the four raw candidate fixtures. They don't need to stay private.`
The four candidates named below are therefore cleared for exact-byte import in a
later authorized implementation slice. This clearance does not apply to any other
payload, transcript, tool response, final message, database, cache, or credential
file under the capture root.

If redaction is later selected, any committed derivative needs deterministic
value-only transformation with:

- raw source digest and observed harness version;
- derivative digest and transformation tool/version;
- an explicit list of fields transformed or omitted;
- stable placeholders for worktree/home paths and correlated identifiers;
- review of commands, search patterns, titles, and other free text;
- `origin: authentic-capture-derived` or an equally unambiguous marker;
- a declaration that the derivative is not exact raw-byte evidence.

## Candidate Fixtures

No candidate has been extracted or added to Git. These are source selections for a
later authorized implementation slice.

| Milestone | Candidate | Local source selector | Why | Disposition |
|---|---|---|---|---|
| M2 | OpenCode session smoke | `opencode/lifecycle.jsonl`, record 1 | Smallest authentic `session.created` proof; confirms observed identity shape | User-cleared exact raw fixture |
| M2 | OpenCode gate | `opencode/lifecycle.jsonl`, record 6 | First authentic `read` `tool.execute.before`; includes correlation and mutable args | User-cleared exact raw fixture |
| M3 | Codex session smoke | `1785755740434994199-2327240-SessionStart.json` | Small authentic configured session hook | User-cleared exact raw fixture |
| M3 | Codex gate | `1785755744328519447-2328094-PreToolUse.json` | Smallest authentic `PreToolUse`; strongest OpenCode gate counterpart | User-cleared exact raw fixture |

Codex candidate integrity:

| Candidate | Bytes | Raw SHA-256 |
|---|---:|---|
| `SessionStart` | 291 | `69f56b0b3f98e7739828d64f1af6749931b750895eec433fa037600a623c7a04` |
| `PreToolUse` | 507 | `77ea0aa2a208418a2883db0cdb003e6fcf2c62856af515027dbe46270b7812e1` |

`SessionStart` is only a session-ingress smoke candidate. It is not semantically
equivalent to OpenCode's persisted `session.created` aggregate. `PreToolUse` and
`tool.execute.before` share a useful pre-execution gate core, but provider-specific
authority, failure, ordering, and mutation facts must remain visible.

## Existing Corpus Inventory

Read-only source inspection found no source-controlled, provenance-backed authentic
OpenCode `session.created` or `tool.execute.before` payload. Relevant OpenCode tests
construct synthetic objects.

Codex contains generated schemas and synthetic integration tests that write
ephemeral runtime logs. No committed provenance-backed authentic hook payload was
found. Its snapshots render synthetic hook messages rather than raw hook inputs.

Pasture's Claude `session_start_2_1_210.json` plus provenance sidecar remains the
only inspected repository fixture explicitly marked authentic. It supports exact
byte replay, but its `redaction: none` payload includes a user-specific path. The
new M2/M3 fixtures should not repeat that privacy posture by default.

Useful source anchors:

- OpenCode production hook shape: `packages/opencode/src/session/tools.ts`
- OpenCode synthetic event tests: `packages/opencode/test/session/session.test.ts`
  and `packages/opencode/test/tool/code-mode.test.ts`
- Codex generated hook schemas: `codex-rs/hooks/schema/generated/`
- Codex synthetic/runtime integration tests: `codex-rs/core/tests/suite/hooks.rs`
- Pasture authentic Claude fixture controls:
  `internal/lifecycle/ingress/claude/testdata/fixtures/` and
  `internal/lifecycle/ingress/claude/capture_test.go`

## Conclusions

1. Authentic installed-version evidence now exists for the selected OpenCode M2
   events and for several Codex M3 candidates.
2. OpenCode `tool.execute.before` and Codex `PreToolUse` are suitable for testing a
   minimal common post-L2 gate intent only if provider-specific facts are retained.
3. The four named raw candidates are user-cleared for exact-byte import without
   redaction. No broader capture artifact inherits that clearance.
4. The four named records are sufficient fixture candidates for an MVP proposal;
   importing every captured event would add privacy and test scope without serving
   the selected vertical.
5. Fixture extraction, transformation, provenance sidecars, tests, and production
   wiring remain subject to URE completion, proposal review, Plan UAT, ratification,
   and an implementation plan.
