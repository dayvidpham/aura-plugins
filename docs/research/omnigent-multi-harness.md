# Research: omnigent multi-harness architecture, compared with Pasture

- Date: 2026-08-06
- Question: How does omnigent handle multi-harness switching and translation?
  Is it different from what Pasture does?
- Sources examined:
  - `github.com/omnigent-ai/omnigent` @ `8a65a726` (local clone
    `~/codebases/omnigent`; Python monorepo, 24 harness ids)
  - Pasture @ `4679f0a` (read via the `aura-plugins` submodule; Go, 3 harness
    ids)
- Method: four explore agents (one on omnigent, three on Pasture: dispatch,
  translation, truth). All findings carry file:line evidence from those runs.
- Related: Pasture design authority
  `llm/research/hooks-ir-compilers-architecture-lessons.md`; Stage-2 refactor
  plan FOLLOWUP_PROPOSAL-6 (`aura-plugins-8uwuj`, ratified).

## Summary

Both projects move toward the same shape: one central registry, a
harness-neutral core, and thin per-harness edges. The differences are large in
five areas. Pasture is closed, typed, generated, and evidence-gated. Omnigent
is open, plugin-based, handwritten at its edges, and probe-verified. Omnigent
also solves a streaming-durability problem that Pasture does not have.

## Omnigent findings

### Harness model
- Central dataclass registry: `HarnessContribution`
  (`omnigent/harness_plugins.py:108`) with `valid_harnesses`,
  `harness_modules` (id → module path), `native_agents`, `native_providers`,
  `capabilities`, `install_specs`.
- `NativeHarnessProvider` (`harness_plugins.py:79`) stores dotted import
  STRINGS, not callables. Reason: building the registry must not import the
  runner stack (`native_dispatch.py:1-12`).
- Typed capability enums: `IntegrationMode` (SDK_IN_PROCESS / CLI_SUBPROCESS /
  ACP_SUBPROCESS / NATIVE_TUI / NATIVE_SERVER), `Elicitation`, `Resume`,
  `AuthModel` (`harness_capabilities.py:80`).
- Closed builtin list: `_BUILTIN_CONTRIBUTION` = 24 ids
  (`harness_plugins.py:603-756`). Runtime extension: Python entry-point group
  `omnigent.community.harness` with namespace and collision validation
  (`harness_plugins.py:45, 813-884`). The model is hybrid: static table plus
  optional plugins.

### Dispatch
- One merged registry with lazy resolution:
  `native_dispatch.resolve_hook_for_key` (`native_dispatch.py:52`).
- Interface-per-harness: `Executor` ABC (`inner/executor.py:518`);
  per-harness subprocess servers with a `create_app() -> FastAPI` contract
  (`runtime/harnesses/_runner.py:146-154`).
- Residual scatter: ~49 `is_native_harness` / `harness ==` branch sites remain
  in `runner/app.py` (for example L2969, L3009, L3756, L8405), plus a legacy
  `_HARNESS_MODULES` dict that the registry overwrites
  (`runtime/harnesses/__init__.py:36-152`). The registry migration is
  deliberately phased and only partially complete
  (`designs/harness-modular-registry-proposal.md`).
- New harness: add `<key>_native.py` with a uniform function layout
  (`harness_plugins.py:252-271`) and one registry entry, or ship a plugin
  package.

### Translation in (ingress)
- Per-harness bridge and forwarder files parse vendor artifacts into typed
  dataclasses: `ClaudeTranscriptItem`, `ClaudeHookRecord`
  (`claude_native_bridge.py:303/364`). The forwarders are large (claude 230KB,
  codex 276KB) and each holds its own polling and parsing logic.
- Durability machinery: byte-offset cursors, dead-letter queues, replay with
  "may-have-been-delivered" handling (`_native_post_delivery.py:85-150`).
- Runner-owned vendor servers for codex/opencode with version checks
  (`OPENCODE_MIN_VERSION = "1.17.7"`, `native_server_harness.py:45`).
- Narrow waist, loosely: an `ExecutorEvent` stream (TextChunk /
  ToolCallRequest / TurnComplete / ExecutorError, `inner/executor.py:534`)
  plus an internal SSE vocabulary. No single shared verifier; each bridge
  validates its own input.

### Translation out (egress)
- Shared harness-neutral converter for policy hooks:
  `native_policy_hook.py` maps native PreToolUse / PostToolUse /
  UserPromptSubmit payloads to `EvaluationRequest/Response` and back.
- Per-harness entrypoints write native verdicts to stdout
  (`claude_native_hook.py`, `codex_native_hook.py`).

### Artifact generation
- Handwritten per-harness config mutation, scattered: `.claude/settings.json`
  statusLine override (`claude_native_bridge.py:92, 1349-1363`), `~/.pi` and
  `~/.qwen` settings merges, per-session private `CODEX_HOME` copies
  (`inner/codex_executor.py:780-822`). No shared generator. No drift checks.

### Truth and verification
- Declared truth: the capability table (`harness_plugins.py:313-600`).
- The bench DERIVES its expected verdicts from that table and live-probes
  streaming and interrupt behavior to catch drift
  (`tests/harness_bench/manifest.py:39`;
  `designs/harness-capabilities-bench-seam.md`).
- Version pinning: `HarnessInstallSpec.min_version / max_version_exclusive`
  enforced at onboarding (`onboarding/harness_install.py:699-716`).

## Pasture findings

### Harness model
- `type HarnessID string` with exactly three constants (`claude-code`,
  `opencode`, `codex`) — `internal/codegen/ir/ids.go:13-18`; canonical array
  and `IsValid()` switch (`ids.go:21-39`). No plugin mechanism. Constructors
  reject unknown harnesses at run time (`ids.go:57-63`).
- Defect: three parallel id spellings exist — `ir.HarnessID`,
  `codegen.HarnessName` (`codegen/harness.go:15-21`), and
  `acceptance.HarnessKind` (`acceptance/schema.go:62-69`).

### Dispatch
- About 12 static sites: 4 switches (for example `dispatchLifecycle`,
  `handlers/hook_lifecycle.go:160-192`; `nativeresponse.go:86-115`),
  3 maps/registries (for example `codegen/harness.go:75-79`
  `harnessRegistry`), 4 per-harness function families
  (`runtime/lifecycle_profiles.go:514-526`, activation and registration
  files), one generator loop (`hostcontractgen/main.go:19-28`), plus explicit
  struct fields in install (`install/selection/selection.go:100-143`).
- All sites are compile-time. Adding a harness today changes 20+ files; the
  M3 Codex addition changed 75 files (+2715/-974).
- The ratified Stage-2 refactor (FOLLOWUP_PROPOSAL-6) folds the two hottest
  sites (lifecycle dispatch and native encode) into one static registry map
  and adds an authoring-side inventory table keyed
  `(harness, kind, id)`.

### Translation in (ingress)
- Uniform shape across the three harnesses: `Parse(raw, event,
  observedVersion, envelope) Capture`; digest before decode; byte-exact body
  copy (`ingress/claude/capture.go:19-31`, opencode, codex).
- Bounded read: `MaxNativePayloadBytes = 1 << 20`
  (`handlers/hook_lifecycle.go:117-123`, `model/bounds.go:13`).
- One verified waist: `BindEvent[E]` → L1 → `NewEvent` → verified L2;
  `verifyIdentities` enforces constructor-built identities, declared names,
  kind match, no duplicates, required present (`waist/event.go:164-367`).
- Provider-specific code stops at the per-host `Bind`
  (claude 83 lines, opencode 29, codex 59). Downstream is neutral:
  `middleend.Derive` = legalize → interpret → optional consultation
  (`middleend/evaluate.go:24-61`).

### Translation out (egress)
- Canonical `backend.HostResponse` → per-harness mechanical bytes:
  Codex `{"continue":true}` / `{}`; Claude/OpenCode
  `{"decision":"proceed"}` / no stdout (`nativeresponse.go:66-115`).
- Commit-before-stdout: the receipt commits inside the handler; the CLI
  writes stdout only after (`cmd/pasture/hook_lifecycle.go:52-67`). Stage 2
  makes this structural (`handlers.HookLifecycleNative`).

### Artifact generation
- One generator emits all foreign artifacts from pinned contracts: Claude
  `hooks/hooks.json`, OpenCode `.opencode/plugins/pasture-lifecycle.ts`,
  Codex `.codex/hooks.json` + shell runners (`codegen/claude_hooks.go:220`,
  `opencode_hooks.go:149`, `codex_manifest.go:270`).
- The generated foreign code passes only `--harness X --event <static>`.
  It selects no operation. Decisions arrive as stdout JSON.
- Drift gates: committed artifacts; `make generate` twice with zero diff;
  CI `codegen-drift` job regenerates on a clean checkout and fails on any
  dirty status (`ci.yml:119-146`).

### Truth and verification
- Exact-version pinned host contracts are the single generated truth:
  claude 2.1.210 (observed through 2.1.222, 30 events), opencode 1.18.10
  (47 events), codex 0.146.0 (10 events)
  (`ingress/internal/hostcontract/*.go`, `registration/*.gen.go`,
  `runtime/profiles.go:313-315`).
- Activation is deny-by-default. An event becomes Enabled only with TWO
  proofs: an authentic capture fixture with a provenance sidecar (digests,
  observed runtime, clearance authority) AND a shipped production-path test
  (`activation/types.go:69-178, 283-303`). Current state: claude 8/30,
  opencode 2/47, codex 2/10 enabled.
- Re-derive tests compare committed artifacts against live catalogs with no
  golden literals (`hook_lifecycle_production_test.go:1278-1314`;
  `fixture_digest_test.go:35-81`).

## Comparison table

| Dimension | Omnigent | Pasture |
|---|---|---|
| Harness set | 24 ids; static table + runtime plugins | 3 ids; closed, compile-time; no plugins |
| Id discipline | One id set, alias table | Three parallel spellings (defect; Stage 2 shrinks) |
| Dispatch | One lazy registry (import strings) + ~49 residual branches | ~12 static sites; Stage 2 folds the two hottest into one map |
| Ingress | Heavy per-harness bridges (50–276KB), own parsers, stream cursors + replay | Thin uniform Parse/Capture, digests, one verified waist |
| Egress | Shared neutral hook converter + per-harness stdout writers | Canonical response + mechanical per-harness bytes, after durable commit |
| Artifacts | Handwritten config mutation, no drift checks | Generated from pinned contracts, zero-diff CI gate |
| Truth | Capability table + bench that derives verdicts and probes live | Exact-version contracts + dual-proof activation, deny-by-default |

## The five important differences

1. Open set against closed set. Omnigent accepts community harnesses at run
   time through entry points. Pasture rejects unknown harnesses at compile
   time and in constructors. This is a product decision on both sides.
2. Heavy edges against thin edges. Omnigent's bridges hold parsing, polling,
   and replay together. Pasture's foreign adapters hold zero semantics; the
   authority document requires this (§5: adapters are "mechanical projections
   of the pinned contract table").
3. Evidence bar. Omnigent probes capability booleans live. Pasture gates each
   event on captured payload bytes with digests, provenance, and clearance,
   plus a production-path test. Pasture's bar is higher.
4. Artifact drift. Omnigent mutates settings files by hand in many places
   with no drift checks. Pasture generates all artifacts from one truth and
   CI rejects drift. Pasture is clearly stronger here.
5. Different durability problems. Omnigent needs stream durability (cursors,
   dead-letter, replay) because it observes long transcript streams. Pasture
   handles discrete hook invocations with durable receipts and
   commit-before-stdout ordering. The problems differ; the solutions do not
   transfer directly.

## Convergences and lessons

- Both projects converge on: registry over scattered branches; a
  harness-neutral core; per-harness thin(ner) edges; a declared table as
  truth with derived verification.
- Both registry migrations are incomplete. Omnigent keeps ~49 residual branch
  sites after its registry landed. Pasture keeps ~12 sites, and Stage 2
  removes only the two largest. Warning from their history: a half-finished
  registry migration collects stragglers. A future Pasture stage can add a
  check that counts dispatch sites, so new switches cannot appear unseen
  (possible M5-adjacent follow-up; not scheduled).
- Their bench pattern (derive expected verdicts from the table, then probe)
  is the same idea as Pasture's derived-content report tests. The two
  projects validated the same mechanism independently.
- Their entry-point namespace validation (`harness_plugins.py:813-884`) is a
  good model if Pasture ever opens its harness set. Today that is a
  non-goal.

## Decisions this research does not change

- The Pasture harness set stays closed (three harnesses).
- The Stage-2 refactor scope stays as ratified (FOLLOWUP_PROPOSAL-6).
- The no-live-Codex program rider stays in force.
