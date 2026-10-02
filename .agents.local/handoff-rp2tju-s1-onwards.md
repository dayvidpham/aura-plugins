# Handoff: adapter-to-IR coverage epic, S1 to S7

Date: 2026-09-04. Written in ASD-STE100. This is an internal handoff; Beads ids and slice
names are allowed here and nowhere in shipped files. Run `bd` from the repository root
`/home/minttea/codebases/dayvidpham/aura-plugins`. The code is the `pasture` submodule.

## 1. State at handoff

- pasture main is `d3edb79`. S0 (failure modes honoured) merged as PR #127. Two follow-ups
  merged after it: PR #128 (condition-driven abandonment proofs; cmd/pasture suite from 600 s
  to about 60 s under race) and PR #129 (a second daemon waits for a concurrent migrator instead
  of dying; eight scenario-numbered tests renamed). Push-to-main CI is green on `d3edb79`.
- The epic, its request, plan and slices S1 to S7 have NO GitHub issues. Beads is the only
  tracker. PR #127 is the only GitHub artefact linked to the chain. Two adjacent debt epics
  were filed on 2026-09-04: pasture #139 (raw ingestion in-process tests) and #140
  (process-reference sweep). File epic and slice issues with `/epic-composer` if you want them
  visible on GitHub.
- 2026-09-04: the user ruled how the leaves run: "let's run the A/B split. an opus
  orchestrator to handle each slice." Section 4a below is that plan. S1 has NOT started:
  two worktrees exist at d3edb79 (rp2tju-s1a--activation-chain on slice/rp2tju-s1-a,
  rp2tju-s1b--substrate on slice/rp2tju-s1-b), both clean, no worker dispatched, no
  integration worktree yet. S1 starts on the user's word.
- 2026-09-04, later: a new epoch lead took over and the user said "continue where we left
  off". S1 STARTED: supervisor-s1 (Opus) dispatched on section 4a. The running log is in
  `.agents.local/resume-claude.md`.
- 2026-09-05: S1 LANDED. pasture main is `d56bc90` (PR #141, head 0aead71; 31 commits, 98 files).
  Two review rounds (0/1/4 then ACCEPT 0/0/0 fix-free). The A/B split held: sixteen cherry-picks
  onto side A's head, zero conflicts, twice; authoritative regeneration drift 0. The three S1
  worktrees are removed; local branches slice/rp2tju-s1-a and -b remain for citation. gt001f
  carries `pasture:landed` and stays open only on the S0 spine (hc2jq3 -> wzencw -> S6-L9).
  New tasks from S1: S4-L9 bm1ci8 (CLAUDE_CODE_VERSION is undocumented; the shipped hook passes
  "unknown"), S2-L7 1uja39 (derive the generated-output inventory guard), bug nrmrwt (the
  installed pasture records no occurrence; identity bootstrap needs one write command; 14,490
  orphan blobs), bug 118f5p (two engine tests and one handlers test fail under load; barrier,
  not timeout). Rulings changed by measurement during S1 are on gt001f and s6k7mg; the
  standing-constraint additions are on o8z8pn (a moved ceiling falsifies claims at a distance;
  enumerations are derived like guard populations; condition wait plus atomic use; full-suite
  gate only; only the pull_request CI run fires on a slice/ branch, so confirm push-to-main).
  S2 (kthzht) is NEXT and is GATED ON A USER DECISION: its first leaf halts on pin drift, and
  on this machine `claude --version` is 2.1.261 (pin 2.1.251) and `opencode --version` fails
  ("postinstall script was not run"). Options: install the exact pinned versions, or re-freeze
  the pins (a D1 change). S2 also needs about 2 to 4 hours of the user's live sessions for the
  12 recaptures and 3 controls.
- 2026-09-05, later: USER RULINGS (verbatim): "it's okay, we can treat these pins as just a
  baseline floor. we'll continue with what we have." and "i fixed the installation now. it's no
  longer managed by home-manager." Confirmed by question: "PATH versions, floor admission" and
  "I can run them today". D1 is AMENDED on 1ubomy: S2 re-derives the contracts and captures at
  claude 2.1.261 / codex 0.153.0 / opencode 1.18.29 (opencode now via bun); admission becomes
  "at or above the contract version" for all three harnesses; the frozen numbers are retired.
  S2 DISPATCHED: worktree pasture/worktree/rp2tju-s2--pin-bump, branch slice/rp2tju-s2 from
  main d56bc90; supervisor-s2 (Opus); one Fable worker; budget three rounds.
- Wave 0 continues sequentially: S1 next, then S2, then S3. Wave 1 (S4, S5, S6) runs in parallel
  after S3, with capture campaigns allowed to start after S2. S7 re-pins the parent repository
  after the single release.

- **2026-09-05 S2 LANDED.** pasture main `0b33f07` (PR #143, head `0c5fc28`, 31 commits over `d56bc90`, 267 files). Hosts recorded at the PATH versions Claude Code 2.1.261 / Codex 0.153.0 / OpenCode 1.18.29 with FLOOR admission (D1 amendment). 12 enabled events recaptured from live sessions driven by agents at the user's instruction (kit 2, archive copy with roots moved), cleared and accepted verbatim by the user ("1. seems fine / 2. keep home-path-v1 / 3. sure, use tilde"). Catalogues 33/12/47 (Claude +PreModelSwitch gate, PostModelSwitch, DirectoryAdded; Codex +Interrupt, +SessionEnd pre-existing omission; OpenCode name installation.update-available corrected); enabled 8/2/2 held by a derived floor. OpenCode plugin loader fix (pasture #142). Three review rounds (0/4/3, 0/0/2, 0/0/1) then user override "A" (verified fix, no fourth round). Rules adopted: commit-as-green (no scratch-copy holds); text-only MINORs batched on aura-plugins-inamu5 (blocks S7); supervisors Fable, workers Opus/Sonnet, reviewers Opus. Carry-overs: C1 Claude proceed stdout shape -> S3 ectjb1; C-3 false refusal reason -> kqm151; 23-site process-reference class -> inamu5/#140. S1 worktree gone; S2 worktree removed; branch slice/rp2tju-s2 kept locally. NEXT: S3 (ectjb1) dispatch; S4/S5/S6 captures may start; S7 last (after inamu5).

## 2. Beads index

| Role | Id |
|---|---|
| EPIC | aura-plugins-rp2tju |
| REQUEST / ELICIT / URD | aura-plugins-pq9emr / aura-plugins-mrem8p / aura-plugins-9525lu |
| PROPOSAL-3 ratified (+ Amendment 1) | aura-plugins-86ezqj (base text aura-plugins-dhxn8s) |
| Plan-UAT (decisions D1 to D11) | aura-plugins-1ubomy |
| HANDOFF (binding constraints) | aura-plugins-x0i967 |
| IMPL_PLAN (waves, ownership, integration points, budget, deviations) | aura-plugins-o8z8pn |
| S0 landed, open on a carried spine only | aura-plugins-hc2jq3 |
| S1 / S2 / S3 | aura-plugins-gt001f / aura-plugins-kthzht / aura-plugins-ectjb1 |
| S4 / S5 / S6 | aura-plugins-4gm83b / aura-plugins-lqrtxd / aura-plugins-ok39i3 |
| S7 | aura-plugins-cl4soe |

Read `bd show aura-plugins-x0i967` and `bd show aura-plugins-o8z8pn` in full before you
dispatch anything. Section 6 of the IMPL_PLAN is the standing-constraints list.

## 3. The system, as C4

### 3.1 Model tables

Elements:

| Name | Type | Technology | Description |
|---|---|---|---|
| operator | Person | | Runs a coding host with pasture hooks installed and reads the hook diagnostics. |
| Claude Code, Codex, OpenCode | Software System, external | | Coding hosts that fire lifecycle hooks with native JSON payloads. |
| pasture | Software System | Go | Records and gates coding-host lifecycle events in one durable store. |
| pasture CLI | Container | Go | The `pasture` binary; a host runs `hook lifecycle` once per event. |
| pastured | Container | Go | The daemon that runs epochs and slices against the same store. |
| pasture store | Container | SQLite | One file: task tracker, lifecycle journal, audit trail. |
| Codex event runners | Container | sh | Ten generated scripts that Codex executes and that call the CLI. |
| OpenCode lifecycle plugin | Container | TypeScript on Bun | The generated plugin OpenCode loads; it calls the CLI per callback. |
| hook lifecycle command | Component | Go, cobra | Parses flags, reads stdin, owns the 5 s invocation deadline. |
| ingress and frontend | Component | Go | Binds a native payload through the pinned host contract into the waist IR. |
| registration tables | Component | Go, generated | The per-harness native event catalogue. |
| activation | Component | Go | Says whether a registered event is enabled or withheld for this build. |
| capture sink | Component | Go | Writes an authentic capture outside the repository when asked. |
| gate authority | Component | Go | Reads assignment and phase state from the task tracker on one snapshot. |
| gate policy | Component | Go | Pure decision: proceed, deny, or require a human, with a reason. |
| receipt journal | Component | Go | Commits the occurrence and the consultation record before any byte reaches stdout. |
| host exit and native response | Component | Go | The sole exit authority; encodes the decision into that host's bytes. |

Relationships:

| Source | Target | Intent | Technology |
|---|---|---|---|
| Claude Code | pasture CLI | runs the hook per event | exec, JSON on stdin |
| Codex | Codex event runners | runs the event script | exec |
| Codex event runners | pasture CLI | forwards the event | exec, JSON on stdin |
| OpenCode | OpenCode lifecycle plugin | invokes the callback | plugin API |
| OpenCode lifecycle plugin | pasture CLI | forwards the event | exec, JSON on stdin |
| pasture CLI | pasture store | commits the receipt and reads gate state | SQL |
| pastured | pasture store | runs epochs and writes assignments | SQL |
| operator | Claude Code, Codex, OpenCode | works in | terminal |

### 3.2 System Context

```c4
System Context diagram: pasture

+---------------------+
| operator            |
| [Person]            |
| Works in a coding   |
| host and reads the  |
| hook diagnostics.   |
+---------------------+
          |
          | works in (terminal)
          v
+-----------------------------+                          +---------------------+
| Claude Code, Codex, OpenCode|-- fire lifecycle hooks ->| pasture             |
| [Software System, external] |   (exec, JSON on stdin)  | [Software System]   |
| Coding hosts with pasture   |                          | Records and gates   |
| hooks installed.            |                          | lifecycle events.   |
+-----------------------------+                          +---------------------+

Key:
  Solid box = element. [Type] = C4 abstraction. "external" = outside the scope of this diagram.
  Arrow = one relationship, read as "source, label (technology), target".
```

### 3.3 Containers (two views)

```c4
Container diagram: pasture, hook transports

+----------------------------+                                          +----------------------------+
|Codex                       |                                          |OpenCode                    |
|[Software System, external] |                                          |[Software System, external] |
|Coding host.                |                                          |Coding host.                |
+----------------------------+                                          +----------------------------+
        |                                                                       |
        | runs the event script (exec)                                          | invokes the callback
        v                                                                       | (plugin API)
+----------------------------+                                                  v
|Codex event runners         |                                          +----------------------------+
|[Container: sh]             |                                          |OpenCode lifecycle plugin   |
|Ten generated scripts       |                                          |[Container: TypeScript, Bun]|
|that call the CLI.          |                                          |Generated plugin that       |
+----------------------------+                                          |calls the CLI.              |
        |                                                               +----------------------------+
        |                                                                       |
        +-- forwards the event (exec, JSON on stdin) ---------------------+     | forwards the event (exec, JSON on stdin)
                                                                          |     |
                                                                          v     v
+----------------------------+                                          +----------------------------+
|Claude Code                 |                                          |pasture CLI                 |
|[Software System, external] |-- runs the hook (exec, JSON on stdin) ->|[Container: Go]             |
|Coding host.                |                                          |Records and gates one       |
+----------------------------+                                          |event per invocation.       |
                                                                        +----------------------------+

Key:
  Solid box = element. [Type] = C4 abstraction. "external" = outside the scope of this
  diagram. Arrow = one relationship, read as "source, label (technology), target". The
  three containers here plus the two on the next diagram are the whole pasture system.
```

```c4
Container diagram: pasture, durable store

+----------------------------+
|pasture CLI                 |
|[Container: Go]             |
|Records and gates one       |
|event per invocation.       |
+----------------------------+
        |
        | commits receipts, reads gate state (SQL)
        v
+----------------------------+                                              +----------------------------+
|pasture store               |                                              |pastured                    |
|[Container: SQLite]         |<-- runs epochs, writes assignments (SQL) ----|[Container: Go]             |
|Task tracker, lifecycle     |                                              |Runs epochs and slices      |
|journal, audit trail.       |                                              |against the store.          |
+----------------------------+                                              +----------------------------+

Key:
  Solid box = element. [Type] = C4 abstraction. Arrow = one relationship, read as
  "source, label (technology), target".
```

### 3.4 Components of the pasture CLI lifecycle path, with the slice that changes each (two views)

```c4
Component diagram: pasture CLI, ingress side

+== pasture CLI [Container: Go] ===============================================================+
|                                                                                              |
|  +--------------------------+                           +--------------------------+          |
|  |hook lifecycle command    | -- captures (Go call) --> |capture sink              |          |
|  |[Component: Go, cobra]    |                           |[Component: Go]           |          |
|  |Flags, stdin, the 5 s     |                           |Writes an authentic       |          |
|  |deadline. S0 done; S3     |                           |capture outside the       |          |
|  |wires the gate.           |                           |repository. S1 new.       |          |
|  +--------------------------+                           +--------------------------+          |
|                |                                                                              |
|                | binds (Go call)                                                              |
|                v                                                                              |
|  +--------------------------+                           +--------------------------+          |
|  |ingress and frontend      | -- looks up (Go call) --> |registration tables       |          |
|  |[Component: Go]           |                           |[Component: Go, generated]|          |
|  |Binds the payload via     |                           |The per-harness native    |          |
|  |the pinned contract. S1   |                           |event catalogue. S2       |          |
|  |validate; S2 contracts.   |                           |regenerates; S4 S5 S6     |          |
|  +--------------------------+                           |add proofs.               |          |
|                                                         +--------------------------+          |
|                |                                                                              |
|                | consults (Go call)                                                           |
|                v                                                                              |
|  +--------------------------+                                                                 |
|  |activation                |                                                                 |
|  |[Component: Go]           |                                                                 |
|  |Enabled or withheld per   |                                                                 |
|  |build. S1 evaluator and   |                                                                 |
|  |targets; S4 S5 S6 enable. |                                                                 |
|  +--------------------------+                                                                 |
|                                                                                              |
+==============================================================================================+

Key:
  Solid box = element. Double-line box = boundary. [Type] = C4 abstraction.
  Arrow = one relationship, read as "source, label (technology), target".
```

```c4
Component diagram: pasture CLI, decision side

+== pasture CLI [Container: Go] ===============================================================+
|                                                                                              |
|  +--------------------------+                           +--------------------------+          |
|  |hook lifecycle command    | -- decides (Go call) ---> |gate policy               |          |
|  |[Component: Go, cobra]    |                           |[Component: Go]           |          |
|  |Owns the invocation; S3   |                           |Proceed, deny, or         |          |
|  |wires the gate in.        |                           |require a human, with a   |          |
|  +--------------------------+                           |reason. S3 new.           |          |
|                                                         +--------------------------+          |
|                |                                                      |                       |
|                | commits (Go call)                                    | reads (Go call)       |
|                v                                                      v                       |
|  +--------------------------+                           +--------------------------+          |
|  |receipt journal           |                           |gate authority            |          |
|  |[Component: Go]           |                           |[Component: Go]           |          |
|  |Commits the occurrence    |                           |Assignment and phase      |          |
|  |before stdout. S3         |                           |state on one snapshot.    |          |
|  |consultation v2.          |                           |S3 new.                   |          |
|  +--------------------------+                           +--------------------------+          |
|                |                                                      |                       |
|                | emits (Go call)                                      | reads (SQL)           |
|                v                                                      v                       |
|  +--------------------------+                           +--------------------------+          |
|  |host exit and native      |                           |pasture store             |          |
|  |response                  |                           |[Container: SQLite]       |          |
|  |[Component: Go]           |                           |Journal and task tracker. |          |
|  |Sole exit authority; that |                           +--------------------------+          |
|  |host's bytes. S0 done;    |                                                                 |
|  |S3 deny shapes.           |                                                                 |
|  +--------------------------+                                                                 |
|                                                                                              |
+==============================================================================================+

Key:
  Solid box = element. Double-line box = boundary. [Type] = C4 abstraction.
  Arrow = one relationship, read as "source, label (technology), target". The store is
  a separate container; it is drawn inside the boundary for layout only.
```

## 4. Slices, in order

Review budget (user decision): UNLIMITED rounds to a fix-free 0/0/0 for S1 and S3; THREE rounds
for S2, S4, S5, S6, S7, then surface open findings to the user. A slice starts when the slice
before it is review-clean and merged. Beads closure comes later, top-down.

### 4a. How the leaves run: one Opus orchestrator per slice, parallel leaves where the DAG allows

User ruling (2026-09-04): each slice gets its own Opus supervisor (`pasture:supervisor`, prompt
starting with `Skill(/pasture:supervisor)`). The supervisor dispatches the workers, tracks them
by Beads comments and read-only worktree peeks, folds the branches, runs one authoritative
regeneration on an archive copy, and drives the review wave to a fix-free 0/0/0 within the
slice's budget. It never pushes, merges or closes. The team lead is the integrator: independent
gate, push, PR, merge, push-to-main CI confirmation, top-down closure. Workers and reviewers run
on Fable, the tier the user chose for this epic's recent rounds, unless the user says otherwise.

Parallelism inside a slice is decided by the leaf DAG and by disjoint file sets, never by
optimism. Measured from the leaf tasks:

| Slice | Leaf DAG | Longest chain | Parallel plan |
|---|---|---|---|
| S1 | 5 roots: L1 -> L2 -> (L3, L8, L9); L4 -> L6; L5 -> L10; L7; L11 | 3 | TWO workers, A and B (below); about 2x |
| S2 | L1 -> L2 -> L6 -> L3 -> L4 -> L5 | 6 of 6 | ONE worker; sequential by nature (probe, re-derive, recipes, recapture, mappings, regenerate) |
| S3 | L1 -> L2 -> L3 -> L7 -> L8 -> L10 -> L11; L1 -> L4 -> (L9, L12); L12 -> L5 -> L10 | 7 of 12 | ONE worker holding the whole gate model; an optional second worker for L9 only (rebuild-index command, OpenCode kill timer) after L4 |
| S4, S5, S6 | one pipeline each: L1 recipes -> L2 capture -> L3 clearance -> L4 enable -> L5 prove -> L6/L7 report -> integrator leaf | all | THREE workers, one per harness (already the plan); leaves inside a harness are sequential and gated on the user's live sessions |
| S7 | L1 -> L2 | 2 of 2 | ONE worker, one day |

#### S1 split (the only Wave-0 slice that parallelises)

| Side | Worktree and branch | Leaves in order | Owns |
|---|---|---|---|
| Worker A | pasture/worktree/rp2tju-s1a--activation-chain, slice/rp2tju-s1-a | L1 5onrkf (with carried finding xw71qw) -> L2 gnhx6j -> L3 7fcvjf, L8 rlwt8r, L9 qg4fp7 | internal/acceptance/capture.go and test; internal/lifecycle/activation/{types.go, *_targets.go, proofs_*.gen.go, evaluator.go, corpus.go and tests}; internal/codegen/activation_report.go and the report emitters; .opencode/pasture-opencode-activation.json; the enum-sync helper; internal/codegen/no_change_guard_test.go. EVERY generated artefact. A is the only side that runs `make generate`, in its own worktree, staging only its own files. |
| Worker B | pasture/worktree/rp2tju-s1b--substrate, slice/rp2tju-s1-b | L4 8yrtxu -> L6 hqnytd; L5 gf4wdu -> L10 1vk1v7; L7 vywkkd; L11 s6k7mg | internal/handlers/capture_sink.go and test; internal/lifecycle/ingress/validate.go, validate_test.go, secretscan_test.go and the three per-harness capture.go call sites; the inventory report-mode test; CLEARANCE.md template; internal/runtime/lifecycle_profiles.go and the three new lifecycle_profiles_{claude,codex,opencode}.go plus profiles_test.go; internal/lifecycle/waist/l2_content_guard_test.go; the store open path that reclaims orphan blobs and its test. ALL AGENTS.md edits: if A needs a sentence, A sends it to the supervisor, who routes it to B. B never runs `make generate` and never touches a generated file. |

Rules of the split: file sets are disjoint and stay so; a leaf that needs a file outside its
side's set is a report to the supervisor, not an edit. Each commit carries an Ownership
paragraph naming exactly its files; the slice's ownership statement grows in the same commit.
Both sides gate their own SHA on an archive copy (B reports that generation is not its to run).

Fold and review: the supervisor creates a third worktree `pasture/worktree/rp2tju-s1--integration`
on branch `slice/rp2tju-s1` from A's head and cherry-picks B's commits onto it (disjoint files,
so a conflict is a report to the team lead, not a resolution). Six gates on an archive copy of
the integration head, including ONE authoritative `make generate` with an empty porcelain; a
drift belongs to A. Then ONE review wave (one Fable reviewer, all three axes; or the plan's three
reviewers if the user asks) on the integration head: every worker mutation re-driven, the hook
path byte-identical against a binary built from d3edb79 on the existing 8/2/2 enabled events
(the profile split and the validate dispatch must change no byte), every new guard's reach
attacked, six gates on the reviewer's own copy. Review -> fresh-worker fix (routed to the side
that owns the file) -> re-review, UNLIMITED, to a fix-free 0/0/0. Then "S1 READY: <sha>" to the
team lead.

#### S3 shape
One worker for the chain. If the user wants the optional second worker, it takes L9 only, in
its own worktree from the S3 branch after L4 lands, owning cmd/pasture/gate_rebuild_index.go and
its test and the kill-timer edit in internal/codegen/opencode_hooks.go; fold and review as for
S1. The spike L1 can STOP the slice; nothing else starts until L1 reports.

### S1, activation substrate (aura-plugins-gt001f), 9 to 11 worker-days, sequential, NOT STARTED
Makes Wave 1 parallel. Requirements R3, R7. Leaves in dependency order:
- 5onrkf L1 CaptureProvenance gains Event, Redaction, Clearance; clearance refusals; digest-rewrite rule.
- gnhx6j L2 per-harness activation targets and generated proof arms with ordinal ranges (claude 1-99, codex 100-199, opencode 200-299); two new WithheldReason arms.
- 7fcvjf L3 harness-parameterised activation Evaluator (today hard-wired to Claude).
- 8yrtxu L4 hardened in-binary capture sink (`PASTURE_CAPTURE_DIR`: absolute, outside the repo, numbered, one notice).
- gf4wdu L5 shared `ingress.Validate` dispatch and IdentityPolicy label with no waist effect.
- hqnytd L6 clearance procedure: inventory report mode, secret scan, CLEARANCE.md template, AGENTS.md.
- vywkkd L7 split `internal/runtime/lifecycle_profiles.go` into three harness files plus one integrator-only shared helper.
- rlwt8r L8 OpenCode activation report file; capability and evidence columns on all three reports.
- qg4fp7 L9 reusable enum-sync test helper; permanent ACP, Gemini, Antigravity no-change guard.
- 1vk1v7 L10 permanent structural L2-content guard: no tool args, tool output or prompt text in the IR.
- s6k7mg L11 bounded orphan-blob reclaim on the next successful invocation (activated from S0's orphan ruling; cap 64, older than one hook-invocation tier).
- xw71qw carried finding: the product persists a task-tracker id as a capture sidecar's ClearanceAuthority; replace it with a durable reference.
Open discrepancy recorded in the slice: the mirror-enum sync tests for `gateauthority` enums cannot run in S1 because those enums arrive in S3; S1 builds the helper and applies it to enums that exist.

### S2, pin bump x3 (aura-plugins-kthzht), 6 to 8 worker-days, sequential
Pins FROZEN (D1): claude-code 2.1.251, codex-cli 0.149.0, opencode 1.18.19. Leaf L1 re-probes
`--version` on the day S2 starts and STOPS the slice on any drift; nobody re-pins silently.
- rhpl01 L1 re-probe and halt rule.
- 2fyuvb L2 re-derive host contracts, catalogues, registration at the new pins with an upstream event diff.
- vwy7zt L6 publish the trigger-recipe list for the 12 recaptures and 3 controls with the user-time estimate (before L3).
- 462y6n L3 live recapture of the 12 enabled events plus 3 re-derived Claude controls; delete the old fixtures; main is never hook-free; enabled never below 8/2/2.
- oyy76i L4 complete the frontend eventMappings for all registered events; validating `EventByNativeName` reverse lookup (closes pasture #62).
- e5oh4w L5 regenerate all transports and reports; parity and drift green; S2 report with the withheld workload.
OpenCode has 47 activation rows already (32 SSE plus 15 named); S2 confirms they survive the bump.

### S3, real gate decisions (aura-plugins-ectjb1), 12 to 14 worker-days, sequential
The largest and most correctness-sensitive slice. Requirement R4. Wave 1 enabling waits for it.
- wivrye L1 feasibility spike: the gate read model must be reachable through pinned provenance v0.0.7. It CAN STOP S3; the fallback is a provenance release plus a pasture re-pin, a user decision with precedent.
- 78cal7 L2 `gateauthority` leaf package: value types, PhaseFromProvenance, mirror-enum sync tests.
- fj2d0l L3 published exhaustive legality tables (RoleActionTable, PhaseActionTable); an unlisted cell is refused.
- 1sg9v6 L4 started-episode index at ONE choke point (four raw writers plus the transfer path) with watermark and idempotent backfill.
- lwmdw3 L5 `gateauthority` Reader and Snapshot on one read transaction: catch-up, torn check, read-time governance.
- xmwel2 L6 `gatepolicy.Decide`: the ten-rule order with a constructor-owned Result.
- llt3k5 L7 ResponseCapability bound to evidence, generator derivation, three proof-event evidence rows. Warning: do not key the capability on `BlocksByExitCode` alone or every OpenCode gate derives CapabilityNone.
- ib8pu4 L8 decision arms and `nativeresponse.Encode` per harness (Claude proceed = empty stdout, D10); consultation v2. Carries finding 58ynqt (a committed Deny always reaches the host; the fail-open continuation only when nothing was committed). Carries the S0 ruling: under fail-closed a FAULT may use the refusal channel with its own reason `ReasonEvaluationFault`, never "denied by policy".
- h7cbzo L9 `pasture gate rebuild-index` command; the OpenCode plugin 8 s kill timer (moved here from S6).
- 4vsuum L10 wire the gate into the handler; prove a deny per harness through the real transport.
- 5f8d55 L12 session-claim write and catch-up persistence: the owner of every gate-path write.
- jojxa5 L11 per-gate cost with 64 episodes; the S3 report.
Forward note from S0: `hostexit.ForFault` ignores `Fault.Undeclared` when it chooses the exit, so an Undeclared plus evidenced plus fail-closed fault would block with a self-contradicting phase line; unreachable today; S3 decides the arm and pins it.

### Wave 1: S4 Claude (aura-plugins-4gm83b), S5 Codex (aura-plugins-lqrtxd), S6 OpenCode (aura-plugins-ok39i3), parallel
Each in its own worktree, one worker each, under the exclusive ownership table (section 5).
Targets: Claude 8 to 28 of 30 (Elicitation pair stays withheld, cite pasture #80 by URL);
Codex 2 to 10 of 10 with ten generated runners and twelve transport destinations; OpenCode 2 to
47 of 47 with the plugin generator emitting all 47 callbacks. Sizing 10-12, 5-7, 14-18 days;
S6 is the critical path.
Each harness slice has the same leaf shape: L1 publish the trigger-recipe list and raise
unreachable events to the user BEFORE capturing; L2 live capture campaign OUTSIDE the
repository (the user supplies about 2 to 4 hours of live sessions per harness, D11; re-estimate
per harness from the recipe list); L3 clear the batch (inventory, substitution, secret scan,
CLEARANCE.md); L4 enable with evidence rows and ordinal-ranged proofs; L5 regenerate the
transport and prove every enabled event through the REAL transport (Claude built binary, Codex
generated runner, OpenCode Bun plugin; a Go-only proof does not count); L6/L7 slice report and
Impl-UAT preparation; an INTEGRATOR leaf owned by the team lead (S4-L8 s9sghy, S5-L7 hlk83e,
S6-L8 uuyb96): authoritative `make generate`, drift, three-harness parity, ownership re-check
on an archive copy of the merge SHA. S5 has L0 1w7rkf first: re-derive the Codex catalogue from
the runtime profile. S4 also has L6 w39t7r: one role-denied and one phase-denied cell through
the real Claude transport, or report record-only. S6 has L9 u5ju80, carried from S0: make the
generated plugin's fault-record promise true (finding wzencw waits on it).
START RULE: L1 to L3 of each harness may start as soon as S2 merges, in parallel with S3; L4
onward waits for S3. One Impl-UAT per harness; the clearance approval IS that UAT; nothing
captured reaches a remote before it (private-first). Merge in completion order.
Carried findings: uieu0p and kqm151 (Claude "proceed" enum wording; the three-cause schema refusal) sit under S4.
Two divergence numbers exist and answer different questions: 20 rows where manifest and
runtime profile disagree; 19 rows the evidence rule demoted (Claude 11, Codex 8, OpenCode 0),
which is the evidence workload. Do not conflate them.

### S7, aura-plugins re-pin (aura-plugins-cl4soe), 1 worker-day, after the single release
Starts only after S4, S5, S6 merge and the architect cuts ONE patch release (D6). Repository:
the PARENT repo, not the submodule. Leaves 0z1ry4 L1 re-pin the submodule gitlink, flake.lock
node and marketplace to the released tag; 0mcxr2 L2 refresh
`nix/hm-module-test-data/pinned-destinations.txt` (Codex lifecycle destinations 4 to 12) and
verify the Home Manager layout table; `nix flake check --no-build` green. The release
workflow fires only on a `plugin.json` version change, so slice merges never release.

## 5. Wave-1 exclusive write ownership (who may write a path while S4, S5, S6 run at once)

| Path | S4 | S5 | S6 | Integrator |
|---|---|---|---|---|
| activation/claude_targets.go, proofs_claude.gen.go | W | | | |
| activation/codex_targets.go, proofs_codex.gen.go | | W | | |
| activation/opencode_targets.go, proofs_opencode.gen.go | | | W | |
| ingress/claude/testdata/** | W | | | |
| ingress/codex/testdata/** | | W | | |
| ingress/opencode/testdata/** | | | W | |
| runtime/lifecycle_profiles_claude.go / _codex.go / _opencode.go | W | W | W | |
| runtime/lifecycle_profiles.go (shared helpers after the S1 split) | | | | X |
| hostcontract/claude_2_1_251.go / codex_0_149_0.go / opencode_1_18_19.go | W | W | W | |
| hooks/hooks.json, hooks/pasture-activation.json | W | | | |
| .codex/hooks.json, .codex/hooks/events/*.sh, .codex/pasture-codex-activation.json | | W | | |
| internal/codegen/opencode_hooks.go, .opencode/plugins/pasture-lifecycle.ts, .opencode/*.json | | | W | |
| cmd/pasture/hook_lifecycle_production_{claude,codex,opencode}_test.go | W | W | W | |
| CHANGELOG.md, own section per harness under Unreleased | W | W | W | |
| SHARED generated: registration/*.gen.go, event_kinds.gen.go, metamodel.gen.go, inventory, payload_*.gen.go | | | | regen at merge |

This table answers one question only: who may write in parallel. It does not say an earlier
sequential slice never touched a path. A slice's own ownership statements record what it
touched; keep them current in the same commit that widens the set.

## 6. Integration points (contracts between slices)

I1 one `runtime.FailureMode` plus `FailureEvidence` plus the generator refusal (S0, done). I2
`hostexit.Outcome` as the sole exit authority (S0, done). I3 `HookEnvironment` seam (S0, done).
I4 the `HookInvocation` 5 s tier (S0, done). I5 `CaptureProvenance` with mandatory Clearance
and Redaction (S1). I6 per-harness targets, generated proofs with ordinal ranges, the
harness-parameterised Evaluator (S1). I7 the profile split (S1). I8 shared `ingress.Validate`
and `EventByNativeName`, the repo-wide secret-scan test (S1). I9 the clearance procedure,
private-first (S1). I10 the frozen pins and re-derived contracts (S2). I11 `gateauthority`,
`gatepolicy.Decide`, decision kinds and reasons, ResponseCapability, `nativeresponse.Encode`
per harness (S3). I12 the assignment index, choke point and `gate rebuild-index` (S3). I13 the
three enabled sets and their generated destinations (S4, S5, S6; consumed by S7).

## 7. Standing constraints, with the lessons S0 added

From the HANDOFF x0i967 and the IMPL_PLAN section 6, binding on every worker and reviewer:
- Prose in ASD-STE100 everywhere. No Git hooks, ever. `git agent-commit` only. Workers
  implement, validate, commit locally, report; they never push, never open a PR, never close
  a Beads task. The team lead is the integrator: gates an archive copy, pushes, opens the PR,
  merges, confirms CI, closes tasks top-down.
- Gates on an ARCHIVE COPY of the SHA, run from INSIDE the copy: `git archive` + `git init` +
  one commit + `git remote add origin git@github.com:dayvidpham/pasture.git`; then
  `nix develop <worktree> -c env GOFLAGS=-buildvcs=false CGO_ENABLED=1 go test -race -count=1 ./...`.
  The dev shell resets `CGO_ENABLED`, so pass it INSIDE with `env`. The shell prints one banner
  line to stdout; do not count it as a `gofmt -l` hit. A gate that names no packages did not run.
  The lead's script is `scratchpad/gate.sh <sha>` with `GATE_WT=<worktree>` (session-local;
  recreate it from these rules).
- Confirm the PUSH-TO-MAIN CI run after every merge, not only the PR runs; two workflow runs
  fire per PR push and can disagree under load.
- One test file per subject. No `time.Sleep` and no fixed-deadline dependence: a proof waits on
  a condition; a clock may only be a failure ceiling. Race-instrument the outer test process,
  never child binaries (one shared plain child; one race child only for the held-lock proof).
  Every test that reaches shared process state stays serial and says why in source; a derived
  pin enforces it in cmd/pasture.
- C-GUARD-REACH: a guard derives its population from the product's own source or states what it
  reads and what it does not; a derivation must be at least as wide as the list it replaced;
  every derived population has a non-vacuity control. Widen a fix along every axis of its
  class, not the one the reviewer probed.
- Operator text is a review axis: every sentence true of the input that produced it; no message
  contradicts itself; a count states its range; no claim without evidence in the tree.
- Mutation-RED evidence per new assertion, quoting the message text, never a line number.
- No internal references in shipped files (a file-sweep guard is planned as pasture #132).
- Ownership paragraph on every commit naming exactly the touched files; verify mechanically.
- Fresh worker per fix round; shut a worker down when its slice is accepted. Workers and
  reviewers idle while a background run executes: tell them to poll with a bounded loop.
- Captures: live sessions only; `~/.local/share/peasant` is READ-ONLY and not a fixture source.
  Nothing captured reaches a remote before the user's Impl-UAT ACCEPT for that harness.
- Review: the plan says a 3-reviewer wave per slice (host-contract, architecture, deliverability).
  The user ruled single Fable reviewers for S0's final rounds and for the two follow-ups. For
  S1 default to the plan's shape unless the user rules otherwise; a single reviewer must then
  cover all three axes explicitly.

## 8. Procedure per slice

1. Create a worktree from pasture main: `git -C pasture worktree add worktree/<name> -b slice/<name> origin/main`.
2. Dispatch one worker with `Skill(/pasture:worker)` first in the prompt, the slice and leaf ids,
   the worktree, the rules above, and the evidence to report. Record the dispatch on the slice.
3. On the worker's report: verify SHA, cleanliness, ownership (named == touched); run the lead
   gate on an archive copy; dispatch the review with eager severity groups; iterate
   review -> fresh-worker fix -> re-review to a fix-free 0/0/0 within the budget, else surface.
4. Push the branch, open the PR (no internal references in the body), wait for both CI runs,
   merge with a merge commit, confirm the push-to-main run, close leaves, review records and
   verified findings with reasons; keep deferred findings open and chained to their destination.
5. Update this file and `.agents.local/resume-claude.md` at every slice boundary.

## 9. Debt outside the epic, already filed

pasture #139 (raw ingestion handler has no in-process test) and #140 (409 lines of process
references in 81 files; guard with a shrinking baseline, five sweeps, retire). Beads mirrors
exist. Related open follow-ups: aura-plugins-f14cva (context-aware SQLite retry ceilings,
under wmi6ep), aura-plugins-o2b024, aura-plugins-2z5dn (re-homed under #140).
