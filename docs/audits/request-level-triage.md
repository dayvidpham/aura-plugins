# REQUEST-level pre-move triage

- **Generated:** 2026-06-06T01:44:51-07:00
- **Method:** dynamic Workflow — 1 Opus agent per open REQUEST; each traced the full bd chain (ELICIT→URD→PROPOSALs→IMPL_PLAN→slices→reviews), identified the **ratified PROPOSAL**, and judged delivered-status against the **Go `pasture` source of truth** + verified claims in code.
- **Premise:** Python is being removed wholesale ([`aura-plugins-4s5zt`](beads://aura-plugins-4s5zt)); Go `pasture` is the SoT and development is moving to the standalone `~/codebases/dayvidpham/pasture`. The question per REQUEST is *"does Go cover it / did the design move on"* — not *"is the Python done"*.
- **Why REQUEST-level:** a closeable REQUEST cascades its whole subtree (the way `j2k` closed 10 nodes in one decision), instead of triaging hundreds of leaf review-tasks individually. Supersedes the 205-leaf close-list in `qzr8a-stale-work-triage.md`.
- **Standalone REQUEST already closed this pass:** `63f` (standing research team — deprecated/abandoned).
- **⚠️ Nothing here is closed yet — recommendations pending sign-off.**

## Summary

**7 open REQUESTs profiled** — dispositions: `close-chain` × 7.

| REQUEST | Status | Ratified proposal | Disposition | Go equivalence (short) |
|---|---|---|---|---|
| `cgwc1` REQUEST: Port hand-authored skill body | **DONE** | aura-plugins-ygkp0 | close-chain | pasture/skills/ — bodies present: architect/SKILL.md (530L, was 313L w/0 hand-au… |
| `18zp` REQUEST: Un-skip 25 skipped tests (4 T | **DONE** | aura-plugins-fl5p | close-chain | none / N/A — this is pure Python test-infrastructure work in scripts/aura_protoc… |
| `v3yv` REQUEST: Fix intree mode creating new  | **DONE** | none ratified | close-chain | none / N/A — this is Python CLI orchestration tooling in bin/aura-swarm (tmux se… |
| `kqtf` REQUEST: Refactor aura-parallel + aura | **DONE** | none ratified | close-chain | The unified design landed: bin/aura-swarm (Python) implements --swarm-mode, --tm… |
| `ckg0` REQUEST: auractl rename + daemon conce | **DONE** | aura-plugins-r75e | close-chain | All 8 covered by Go pasture SoT: R1 worker→aurad daemon → pasture/cmd/pastured; … |
| `ai2x` REQUEST: Package aura-release as Nix f | **DONE** | none ratified | close-chain | pasture/cmd/pasture-release + pasture/internal/release (Cobra-based Go release t… |
| `220` REQUEST: Multi-agent orchestration sch | **SUPERSEDED_BY_GO** | aura-plugins-mg6h | close-chain | pasture/internal/codegen/{schema.go,skills.go,context.go,agents.go,markers.go,va… |

## Per-REQUEST detail

### `cgwc1` — REQUEST: Port hand-authored skill body content from Python to Go SKILL.md files

- **Status:** DONE → **close-chain**
- **Ratified proposal:** aura-plugins-ygkp0 — PROPOSAL-3: Port skill bodies + protocol docs to Go SKILL.md files (supersedes PROPOSAL-2 yiela / PROPOSAL-1 dukw0; RATIFIED per its comment: all 3 reviewers ACCEPT round 3)
- **Asked:** Port the ~1,621 lines of hand-authored body content (Beads 12-phase templates, phase/stage hierarchy, /aura:* invocation, reviewer-spawning, handoff templates) plus the 17 protocol docs from the Python SKILL.md files into their Go pasture counterparts, and fix the generated Workflows section conflation of phases vs stages.
- **Go equivalence:** pasture/skills/ — bodies present: architect/SKILL.md (530L, was 313L w/0 hand-authored), supervisor/SKILL.md (990L incl 'Ride the Wave — Operational Detail' + severity groups + handoff template), worker/SKILL.md (473L), reviewer/SKILL.md (297L), supervisor-plan-tasks/SKILL.md (462L), supervisor-spawn-worker/SKILL.md (304L), impl-review/SKILL.md (418L). All 17 protocol docs present in pasture/skills/protocol/ (PROCESS.md, HANDOFF_TEMPLATE.md, CONSTRAINTS.md, etc.). Phase/stage hierarchy resolved (distinct phase tables + 'Stage 7: Handoff' sections). Go went further: renamespaced aura:->pasture: (commit 6288681) and EPIC x5071 ported all ~30 skills.
- **Reason:** Go pasture skills now contain the full hand-authored bodies (architect 530L vs prior 313L) and all 17 protocol docs; ratified PROPOSAL-3 fully delivered in Go SoT, phase/stage conflation resolved — nothing remains for the soon-deleted Python side.
- **Open chain nodes (3):** `cgwc1` `xh675` `ygkp0`

### `18zp` — REQUEST: Un-skip 25 skipped tests (4 Temporal sandbox + 21 constraint violation combinatorial)

- **Status:** DONE → **close-chain**
- **Ratified proposal:** aura-plugins-fl5p — PROPOSAL-2: Un-skip 25 tests — Temporal sandbox + constraint violation combinatorial (supersedes PROPOSAL-1 nkx7; plan-UAT aura-plugins-70yh = ACCEPT on both components)
- **Asked:** Stop skipping the 25 previously-skipped Python tests: fix the 4 Temporal sandbox tests (search-attribute registration) and make the 21 constraint-violation combinatorial tests runnable instead of skipped.
- **Go equivalence:** none / N/A — this is pure Python test-infrastructure work in scripts/aura_protocol Python tests (tests/test_workflow.py start_local() switch; tests/test_protocol_combinatorial.py + tests/fixtures/protocol.yaml violation_method dispatch). No Go counterpart exists or is needed; the work product disappears when Python is removed (aura-plugins-4s5zt).
- **Reason:** REQUEST's own final comment confirms Phase 12 landing complete (commits b8b38af + f08f99c verified in git log; start_local() and violation_method dispatch verified present in code; full suite 1431 passed/1 skipped; impl-UAT szw8 'Matches expectations' ACCEPTED); both SLICE-1/SLICE-2 and all leaf tasks closed; remaining open nodes are unclosed scaffolding/MINOR follow-ups on Python tests being deleted wholesale.
- **Open chain nodes (26):** `18zp` `e1z2` `iv5j` `prs2` `fl5p` `nkx7` `szw8` `70yh` `q413` `ul1o` `lybp` `at57` `lvsy` `m0gg` `g6yl` `oa70` `msfq` `fs7g` `kez2` `1gqh` `ni3n` `2wzn` `2onu` `moot` `tmjs` `1mll`

### `v3yv` — REQUEST: Fix intree mode creating new session instead of new window

- **Status:** DONE → **close-chain**
- **Ratified proposal:** none ratified — lightweight bug fix REQUEST with no ELICIT/URD/PROPOSAL/IMPL_PLAN chain (single-node dep tree, classified scope=module complexity=low-medium, fixed directly)
- **Asked:** aura-swarm intree mode was spawning a new detached tmux session instead of a new window within the current session; the request is to make intree default to creating a window in the existing tmux session.
- **Go equivalence:** none / N/A — this is Python CLI orchestration tooling in bin/aura-swarm (tmux session/window management), not protocol-engine logic; it has no Go counterpart in pasture/. The fix lives at /home/minttea/codebases/dayvidpham/aura-plugins/worktree/aura-protocol/bin/aura-swarm lines 719-740 (intree + inside-TMUX + no explicit --tmux-dest -> TmuxDest.Window) and the argparse default change to None at line 1722.
- **Reason:** Fix verified live in bin/aura-swarm: lines 724-734 auto-detect the current tmux session and set tmux_dest=TmuxDest.Window for intree mode when --tmux-dest is unset, and argparse default is None (line 1722) — exactly matching the "Fix applied" comment; bd dep tree shows v3yv is a single READY node with no open subtree.
- **Open chain nodes (1):** `v3yv`

### `kqtf` — REQUEST: Refactor aura-parallel + aura-swarm into unified aura-swarm

- **Status:** DONE → **close-chain**
- **Ratified proposal:** none ratified — chain never progressed past ELICIT (aura-plugins-mvfw); no PROPOSAL-N or IMPL_PLAN task was ever created. The unified aura-swarm was implemented ad-hoc and shipped outside the formal protocol chain.
- **Asked:** Merge bin/aura-parallel and bin/aura-swarm into a single unified aura-swarm script with --swarm-mode {worktree,intree}, --tmux-dest {session,window} (window default), XDG state dir, bypassPermissions inheritance to children, merged skills/parallel into skills/swarm, updated Nix/HM/CLAUDE.md, and removal of aura-parallel.
- **Go equivalence:** The unified design landed: bin/aura-swarm (Python) implements --swarm-mode, --tmux-dest with window default, bypassPermissions inheritance, and ~/.local/state-style state dir; bin/aura-parallel is now a thin deprecation wrapper delegating to `aura-swarm start --swarm-mode intree`; skills consolidated to a single skills/swarm/. The design is carried forward canonically in pasture/skills/swarm/SKILL.md (documents --swarm-mode worktree|intree, "replaces aura-parallel"). The aura-swarm orchestration script itself is host-side tooling not ported to a Go binary by design (Go pasture covers daemon/CLI/release, not the swarm launcher). Since Python is being deleted wholesale (aura-plugins-4s5zt) and pasture is SoT, the Python deliverable's fate is governed by the Python-removal epic; the unified concept is preserved in the pasture swarm skill.
- **Reason:** Unified aura-swarm fully implemented (bin/aura-swarm has --swarm-mode/--tmux-dest/bypass inheritance; aura-parallel is a deprecation wrapper; skills merged to skills/swarm) and the design is preserved in pasture/skills/swarm/SKILL.md; bd chain stalled at ELICIT with no proposal/impl-plan, and remaining Python is owned by the wholesale-removal epic 4s5zt — nothing actionable remains under this REQUEST.
- **Open chain nodes (2):** `kqtf` `mvfw`

### `ckg0` — REQUEST: auractl rename + daemon concept + UAT follow-ups

- **Status:** DONE → **close-chain**
- **Ratified proposal:** aura-plugins-r75e — PROPOSAL-2: aurad rename + aura-msg stub (review fixes). Ratified at plan-UAT aura-plugins-qm3u (ACCEPT with dbPath-option amendment); supersedes PROPOSAL-1 aura-plugins-oz82. Impl-UAT aura-plugins-6kl3 also ACCEPT.
- **Asked:** New epoch for 8 Impl-UAT follow-ups: rename worker→aurad + daemon concept, persistent SQLite default, aurad in packages.default, doc restructure, aura-msg stub (4 subcommands), signal-based slice progress, ReviewAxis/VoteType-typed review votes, and constraint-violation test fixtures. (Title says auractl but the ratified plan and delivery used aurad.)
- **Go equivalence:** All 8 covered by Go pasture SoT: R1 worker→aurad daemon → pasture/cmd/pastured; R5 aura-msg stub → pasture/cmd/pasture-msg fully implemented (epoch/start, signal/vote, query/state, phase/advance, session/register) — surpasses the Python stub; R7 signal slice progress → internal/types/signals.go SliceProgressSignal + internal/temporal/workflow_slice.go (signals parent EpochWorkflow via slice_progress using input.ParentWorkflowId); R8 ReviewAxis/VoteType typing → internal/temporal/workflow_review.go votes map[types.ReviewAxis]types.VoteType + internal/types/enums.go; R9 constraint-violation fixtures → internal/temporal/{workflow.go,activities.go} + internal/types/queries.go; R2/R3/R4/R6 packaging+docs → pasture Nix packaging + docs. Python artifacts removed wholesale via aura-plugins-4s5zt.
- **Reason:** Both plan-UAT (qm3u) and impl-UAT (6kl3) ACCEPTED the Python delivery of all 8 items; Go pasture covers every requirement and surpasses several (pasture-msg full CLI vs planned stub; pastured daemon; SliceProgressSignal + ReviewAxis-typed votes + constraint fixtures in internal/temporal & internal/types), so remaining open Python review nits are moot under wholesale Python removal.
- **Open chain nodes (22):** `ckg0` `vjsk` `r75e` `oz82` `82gp` `xqed` `9lqe` `v1ak` `p4fb` `6m2m` `cyyk` `nno9` `ip41` `ta1k` `qrgx` `zldt` `zwty` `oqw9` `6btj` `ltcs` `2kv1` `qz5b`

### `ai2x` — REQUEST: Package aura-release as Nix flake output

- **Status:** DONE → **close-chain**
- **Ratified proposal:** none ratified — standalone REQUEST with no URE/PROPOSAL/IMPL_PLAN subtree (bd dep tree shows ai2x alone, no children); delivered directly per the two completion comments dated 2026-02-23.
- **Asked:** Expose the existing Python bin/aura-release tool (version bump, changelog, git tag) as a Nix flake package output so it can be installed via Nix alongside the other aura CLI tools.
- **Go equivalence:** pasture/cmd/pasture-release + pasture/internal/release (Cobra-based Go release tool) packaged as a Nix flake output via pasture/flake.nix:49-51 (pasture-release = pkgs.buildGoModule, subPackages = ["cmd/pasture-release"]). This is the Go equivalent of the Python aura-release.
- **Reason:** REQUEST was delivered (Python aura-release packaged: verified flake.nix:58 writeScriptBin + default at :90, hm-module.nix:176, REPO_ROOT via git rev-parse at bin/aura-release:63), but bin/aura-release is a Python script (#!/usr/bin/env python3) explicitly in the deletion scope of aura-plugins-4s5zt, and Go pasture-release already provides the same capability as its own flake output — so the packaged artifact is moot post-Python-removal.
- **Open chain nodes (1):** `ai2x`

### `220` — REQUEST: Multi-agent orchestration schema-as-runtime with generation pipeline and constraint enforcement

- **Status:** SUPERSEDED_BY_GO → **close-chain**
- **Ratified proposal:** aura-plugins-mg6h — PROPOSAL-3 [RATIFIED]: Schema-driven protocol engine v2 (3/3 ACCEPT + Plan UAT ACCEPT w/ 6 revisions). Ratified under dependency REQUEST w115; REQUEST 220 itself is an umbrella/investigation request with no proposal of its own. (v1 engine ratified via aura-plugins-gmv under dep REQUEST bj1.)
- **Asked:** Solve the N-file schema-drift problem: a single strict schema as source of truth (roles, constraints, shared/floating context), a generation pipeline from schema to downstream files (SKILL.md/PROCESS.md/etc.), and runtime constraint enforcement — informed by how LangGraph/Agents SDK/AgentSpec do it.
- **Go equivalence:** pasture/internal/codegen/{schema.go,skills.go,context.go,agents.go,markers.go,validate.go} = the schema→downstream generation pipeline; pasture/schema.xml (pasture-protocol v2.0) = schema-as-runtime SoT; pasture/pkg/protocol/{context_kind.go (ContextKind: shared vs free-floating git/context),types.go} + internal/types = roles/shared/floating context; constraint enforcement + 12-phase lifecycle in pasture/internal/temporal/{workflow.go,activities.go} + pkg/protocol. Python deliverables (scripts/aura_protocol gen_schema/gen_skills/context_injection/constraints) being removed wholesale per aura-plugins-4s5zt.
- **Reason:** Request's two dep REQUESTs (bj1 v1, w115 v2) are closed and delivered the schema engine; Go pasture now owns it (internal/codegen pipeline, schema.xml v2.0, pkg/protocol context_kind, internal/temporal constraint enforcement). All open subtree items are stale Python-era review nits/BLOCKERs against scripts/aura_protocol code being deleted wholesale (4s5zt), so the whole subtree can close together.
- **Open chain nodes (45):** `220` `5n2l` `3tfg` `sfr0` `3zs8` `msfr` `rgos` `bl50` `3xe` `xui` `r8f` `7d2` `hls` `ngd` `sk6` `68o` `bnr` `jwb` `dvi` `qqf` `4u1` `5zf` `0yd` `yno` `1ic` `4hu` `tcn` `ipj` `v1b` `o83` `8jy` `gdx` `x36` `3m4` `utj` `eqy` `947` `in8` `pxo` `lkk` `295` `don` `r8m` `h7x` `n0n`

## Appendix — combined cascade close-list (after sign-off)

All open nodes across the 7 `close-chain` REQUESTs (100 unique). Closing these clears the bulk of the open backlog; the remaining open work is the audit-residual chain (`ow0pq`/`rk2su`/`x5071`/`6l5yo`), the migrate-to-pasture set, and genuine Go follow-ups.

```
cgwc1 xh675 ygkp0 18zp e1z2 iv5j prs2 fl5p nkx7 szw8 70yh q413 ul1o lybp at57 lvsy m0gg g6yl oa70 msfq fs7g kez2 1gqh ni3n 2wzn 2onu moot tmjs 1mll v3yv kqtf mvfw ckg0 vjsk r75e oz82 82gp xqed 9lqe v1ak p4fb 6m2m cyyk nno9 ip41 ta1k qrgx zldt zwty oqw9 6btj ltcs 2kv1 qz5b ai2x 220 5n2l 3tfg sfr0 3zs8 msfr rgos bl50 3xe xui r8f 7d2 hls ngd sk6 68o bnr jwb dvi qqf 4u1 5zf 0yd yno 1ic 4hu tcn ipj v1b o83 8jy gdx x36 3m4 utj eqy 947 in8 pxo lkk 295 don r8m h7x n0n
```
