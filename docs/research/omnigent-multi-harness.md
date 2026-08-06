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

---

# Part 2 — bridges, ACP, collaboration, auth, self-hosting (2026-08-06)

- Added after a second investigation: five explore agents (omnigent bridge
  enumeration, omnigent collaboration, omnigent auth, omnigent self-host) plus
  a direct grep of the Pasture tree for ACP.
- Note: the omnigent auth/self-host/collaboration findings and the omnigent
  bridge enumeration carry file:line evidence from those runs. The Pasture ACP
  findings carry file:line evidence from a direct read at `4679f0a`.

## Correction: the "~6 bridges" number

The earlier scan said ~6 large per-harness files. That was a size filter.
Exactly six files exceed 1000 lines. The true count is **11 bespoke per-vendor
native bridges + 1 generic ACP adapter = 12**, reading 24 harness ids plus
unbounded `acp:<slug>` ids.

The count is far below 24 because 13 ids need no per-vendor transcript reader:
- 6 run in process (SDK_IN_PROCESS): claude-sdk, openai-agents, open-responses,
  cursor, antigravity, copilot — streams read inside the executor, no bridge.
- 4 are per-turn CLI (CLI_SUBPROCESS): codex, pi, kimi, hermes.
- 3 ride ACP (ACP_SUBPROCESS): `acp` (generic), goose, qwen.

The remaining 11 native ids (`*-native`) each carry exactly one bridge
(`harness_plugins.py:313-600` for the mode table; `acp_executor.py:233`,
`workflow.py:1527` for the ACP slug resolver).

## ACP — the corrected picture for both projects

Earlier notes guessed that omnigent's ACP path might cover Codex and OpenCode,
and that Pasture had no ACP. Both were wrong. Evidence:

### Omnigent
- ACP is one shared adapter. `AcpExecutor` drives `acp` plus unbounded
  `acp:<slug>` agents (`omnigent/inner/acp_harness.py`, `acp_executor.py:233`,
  `workflow.py:1527-1561`). Confirmed: one adapter, any number of ACP agents.
- Codex and OpenCode do NOT use ACP. Codex is CLI_SUBPROCESS with a loopback
  WebSocket JSON-RPC app-server (`codex_native_app_server.py`). OpenCode is
  NATIVE_SERVER via `opencode serve` over HTTP+SSE
  (`opencode_native_app_server.py`, `opencode_native_forwarder.py`).
- The ACP-mode ids are only `acp`, `goose`, `qwen`.

### Pasture — ACP exists now (not just a plan)
- `internal/acp/` is a full, tested package: an ACP CLIENT (`client.go` — parses
  `session/update` JSON-RPC), a static adapter registry with formats
  `"claude-jsonl"` and `"opencode-json"` (`adapter.go:41-44`), an indexer
  (`indexer.go`), and a session handler. So Pasture normalizes Claude and
  OpenCode transcripts INTO the ACP `SessionUpdate` model.
- Client, not a shipped server. The only ACP "server" is a test double,
  `cmd/pasture-test-agent/main.go` ("a fake ACP-compatible agent").
- The orchestration is legacy. `RunAgentSession` (which called `acp.NewClient`)
  lives under `legacy/temporal/`. The `internal/acp/` package itself is current.
- Design lineage: `llm/research/pasture-architecture.md:43` ("ACP adapter
  ingesting agent transcripts into audit sessions");
  `llm/research/opencode-codex-codegen-investigation.md:163` cites
  `internal/acp/adapter.go` as the compile-time-registry precedent for the
  lifecycle codegen registry. `pkg/protocol/session_entry.go` types are
  ACP-aligned.
- Two ingress surfaces exist and are separate: (1) the lifecycle hook path
  (claude/opencode/codex frontends → waist → middleend), which Stages 1-2
  refactor; (2) the ACP transcript-ingestion path (`internal/acp`). They solve
  different problems. The hook path handles single hook events. The ACP path
  ingests whole agent session transcripts.

Open provenance question (not yet traced): which planning doc or task first
introduced `internal/acp`, and why the Temporal-based runner became legacy.

## Omnigent collaboration model

- A session is one artifact with one owner. Table `SqlConversation`
  (`db_models.py:745-849`). No participant column; ownership is a grant.
- Access is a per-session ACL. `SqlSessionPermission` maps `(user, conversation)
  → level`: READ=1, EDIT=2, MANAGE=3, OWNER=4 (`auth.py:105-108`). Plus
  `can_approve` for approval delegation. `__public__` grant = anyone-with-link
  read (`db_models.py:554-558`).
- Transport: in-process pub/sub per conversation, snapshot then live-tail, no
  replay buffer (`session_stream.py`). Live SSE stream `GET
  /v1/sessions/{id}/stream` (needs READ). Presence shows viewers as circles
  (`presence.py`, `PresenceAvatars.tsx`).
- Multi-user participation: SUPPORTED, with limits. READ co-views; EDIT posts
  input to the live session (`routes_events.py:227-231`). But no invite flow (a
  user joins by grant + URL), input is one FIFO queue (not true concurrent
  edit), and native-terminal sessions funnel shared input into one vendor TUI
  via tmux injection.
- Session sharing: SUPPORTED. Grant/revoke (needs MANAGE), public link with a
  kill-switch, server-wide `SharingMode` (ON/READ_ONLY/RESTRICTED_READ_ONLY/OFF,
  `auth.py:111-143`). No org/team model.
- Pull transcript + continue locally: SUPPORTED, three paths. (1) Export/import
  JSONL — the portable cross-machine path: `omnigent session export` →
  `omnigent session import` recreates it on ANOTHER server (`cli.py:5144-5415`).
  (2) Fork — same server, forker becomes owner, needs READ
  (`routes_core.py:1910-2053`). (3) Resume — rebuilds the native transcript, but
  on the runner host only (`resume_dispatch.py`).

## Omnigent authentication and access control

- AuthN modes: header/proxy (default, `X-Forwarded-Email`, fail-closed,
  `auth.py:571-614`); OIDC (auth-code + PKCE, JWT cookie, `routes/auth.py:131-222`);
  built-in accounts (invites, magic links, first-admin setup,
  `routes/accounts_auth.py`); CLI login; device grants (RFC-8628,
  `routes/device_auth.py`); short-lived runner tokens
  (`routes/runner_tunnel.py:313-342`); loopback native servers
  trusted-by-locality plus generated basic-auth. No mTLS. Bind address sets the
  default posture: loopback → single-user; non-loopback → auth on.
- AuthZ is an ACL, not RBAC. Per-session level (READ/EDIT/MANAGE/OWNER). No org,
  team, or workspace roles. Resolution: admin bypass → conversation lookup →
  sub-agent parent delegation → grant check (`server/permissions.py:17-60`).
  Enforcement is manual helper calls, not decorators (`_auth_helpers.py`) — a
  drift risk.
- Policy-evaluate is a GUARDRAIL, not access control. It returns ALLOW/DENY/ASK
  over tool/LLM/prompt phases (`engine.py:42-102`); its own gate is only READ.
  Commit #3418 tightened per-phase schema validation, fixing a fail-open where a
  non-2xx policy plugin was treated as ALLOW.
- Secrets (#3479): `clean_agent_env` is deny-by-default; the launcher prunes env
  at exec. Before the fix a full environ made the allowlist a no-op, so vendor
  subprocesses inherited unrelated host secrets (`inner/agent_env.py:35-110`,
  `inner/sandbox.py:561-629`).
- Multi-tenancy: boundary is user identity + per-session ACL; per-user dirs. One
  documented risk: an owner-less runner is bindable by any tenant, mitigated by
  fail-closed owner resolution (`runner_tunnel.py:404-419`). WS defenses: Origin
  check, token-bound tunnels, gated terminal attach, verifying TLS.
- Maturity: a local single-user tool with a genuinely hardened thin hosted
  layer. Gaps: no org/team RBAC, no mTLS, header-mode trusts the proxy, manual
  per-route guards.

## Omnigent self-hosting

- Verdict: FULLY self-hostable. Apache-2.0 (`LICENSE`). One FastAPI + WebSocket
  app you run; that app IS the collaboration/sync server; no hosted relay.
  Runners connect to YOUR URL (`RUNNER_SERVER_URL`).
- Deploy: Docker compose (postgres + omnigent), Kubernetes manifests,
  Fly/Render/Railway, or bare `omnigent server` on `127.0.0.1:6767`.
- Storage: Postgres OR SQLite (`DATABASE_URL`); artifacts local dir OR
  S3/MinIO/R2. Models: bring your own key, every provider `base_url`
  overridable, no omnigent inference gateway. Auth backend: built-in accounts,
  your own OIDC, header SSO, or single-user mode.
- Required hosted dependency: none. Caveats (not blockers): usage telemetry is
  on by default but disableable (`OMNIGENT_ANALYTICS=0`) and self-disables if
  unreachable; prebuilt images default to `ghcr.io/omnigent-ai/*` but build
  locally from the same Dockerfile; some optional sandbox providers (Modal,
  Daytona) are third-party SaaS, while Kubernetes/local sandboxes need none.
- For air-gapped use: disable telemetry and build the image locally.

## The design axis this exposes (ownership vs augmentation)

- Omnigent OWNS the process. It spawns and drives the agent CLI as a subprocess,
  injects ephemeral per-session config pointing at its own servers, and forwards
  events out. It needs no durable projection; it needs stream durability
  (cursors, dead-letter, replay). The user runs omnigent.
- Pasture AUGMENTS the user's process. The user runs their own CLI. Pasture
  projects durable, opt-in config (install + codegen) and observes via installed
  hooks. It needs no stream durability for the hook path; it needs a generated,
  drift-checked projection.
- This single choice explains most differences: omnigent has forwarders and a
  hosted server; Pasture has install/codegen and a narrow verified waist.

---

# Part 3 — ACP provenance and ecosystem (2026-08-06)

## ACP provenance in Pasture (git history + design docs at 4679f0a)

ACP is a day-one feature, not a later plan. Timeline from the Pasture repo:

| Commit | Date | What |
|---|---|---|
| `ae114ac` | 2026-03-09 | Project scaffold (first commit) |
| `397661a` | 2026-03-09 | `feat(acp): SharedIndexer, Adapter interface, Claude-JSONL + OpenCode-JSON adapters` |
| `3b729ca` | 2026-03-10 | `feat(acp): IndexingSessionHandler + RunAgentSession activity + pastured wiring` |
| `ce80101` | 2026-03-11 | ACP ContentBlock tests |

- ACP landed the SAME day as the scaffold, with Claude and OpenCode transcript
  adapters from the start. It was foundational intent.
- The runner was a Temporal ACTIVITY (`3b729ca`; "activity" is Temporal's term).
  The ACP session runner was built on Temporal.
- Temporal went legacy for install weight. `docs/dbos-architecture.md`: Temporal
  "required a separate Temporal server process plus a Temporal-flavoured
  `pastured` worker"; DBOS "removes the external workflow server that made
  Temporal operationally heavy." Decisions D1 (embedded DBOS in one binary,
  SQLite) and D6 (`pasture status` replaces Temporal's web UI). Migration PRs
  #23 (`breaking--migrate-dbos`) and #25 (`dbos-cleanup`); planning in
  `docs/proposals/PROPOSAL-{1..5}-dbos-substrate-migration.md`.
- What survived vs went legacy: the substrate-free state machine moved
  `internal/temporal/` → `pkg/protocol` (a rename), and `internal/temporal/`
  was deleted; the Temporal `RunAgentSession` runner moved to
  `legacy/temporal/`; `internal/acp/` is substrate-free and stayed current.
- Two ACP surfaces: `internal/acp` is transcript INGESTION (client side:
  `session/update` → `SessionUpdate` → audit). The only "server" is the test
  double `cmd/pasture-test-agent`. A GATING ACP frontend (`request_permission`
  → L2 gate consultation → middle-end) would be new work, distinct from the
  ingestion adapter.

## ACP ecosystem support (web-sourced 2026-08; volatile — re-verify)

Source: agentclientprotocol.com + the ACP registry, via web search 2026-08.
Adoption moves fast; treat this as a dated snapshot.

Agents (harnesses):
- Native ACP: Gemini CLI (`gemini --acp`), OpenCode, Goose, Qwen Code.
- SDK / client bridge: Claude Code (Claude Agent SDK over ACP clients).
- Third-party adapter / extension: Codex (`codex-acp`), Pi (`pi-acp`
  extension; Pi = minimalist hackable terminal agent by Mario Zechner /
  Earendil Works, ACP via its extension ecosystem not its core).

Integration-path note: "can speak ACP via an adapter" is not the same as "an
integrator uses ACP for it." Example: omnigent does NOT integrate Pi over ACP —
it uses Pi's own file-inbox extension protocol (`pi_native_bridge.py`:
`enqueue_user_message` / `enqueue_interrupt`, CLI_SUBPROCESS, no forwarder),
even though Pi has an ACP extension. Native support and actual integration path
are distinct facts.

Editors / clients (not harnesses): Zed (reference client + agent registry),
VS Code (`vscode-acp`), Neovim (`CodeCompanion`, `avante.nvim`), JetBrains,
Emacs (`agent-shell`).

Correction to Part 2: an earlier note said Claude Code and Codex do not speak
ACP. As of 2026-08 that is outdated — Claude is reachable via its Agent SDK
over ACP clients, and Codex via the `codex-acp` adapter. Native vs bridge still
matters for a provenance system: native ACP (Gemini, OpenCode, Goose, Qwen)
gives cleaner evidence than an adapter/bridge (Codex, Claude).

## Implication for a Pasture ACP frontend

- Coverage is now broad. One `frontend/acp` could reach Gemini, OpenCode,
  Goose, Qwen (native), plus Claude (SDK bridge) and Codex (adapter). This is
  the omnigent `acp:<slug>` pattern: N agents collapse to one frontend, and a
  new ACP agent costs one registry row, not a vertical.
- Stage 2 is the enabler. `frontendRegistry` + generic `Bind` make an ACP
  frontend one row that serves many agents.
- Caveats stand: adapter/bridge fidelity (a translation layer for Codex/Claude);
  ACP carries only the common semantic subset (no harness-specific hook points);
  Pasture shifts to a DRIVE/ACP-client posture for ACP agents (unlike its
  install-a-hook augmentation model today); and it needs a new ACP-message
  evidence/provenance surface. It is an ADDITIONAL ingress, not a replacement
  for the native-hook frontends.
