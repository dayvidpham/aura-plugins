# qzr8a — Stale-work triage audit (FINAL LEDGER)

- **Audit:** [`aura-plugins-qzr8a`](beads://aura-plugins-qzr8a) · **ELICIT/UAT:** `aura-plugins-7a8nu`
- **Ratified plan:** `docs/proposals/PROPOSAL-1-audit-qzr8a.md` (Triage, all-18 pause)
- **Executed:** 2026-05-30, after the ratified **all-18 user pause** (verdict-only → single pause → user walkthrough/revision → sign-off → execute).
- **Note:** the coordinator worker's interim "18/18 close-superseded" was **overturned** by the user walkthrough. Final = **4 close-superseded + 14 extract-residual** across **6 residuals**.

## T-A1 — Final triage ledger

| Bucket | ID | Title | Verdict | Reason / Residual |
|---|---|---|---|---|
| A | oqhjg | REQUEST: Implement aurad + aura-msg | extract-residual | → R-A `40ujq` |
| A+B | bwfqm | URD: aurad + aura-msg implementation | extract-residual | → R-A `40ujq` |
| A | fw1cx | PROPOSAL-5: aurad+aura-msg review fixes | close-superseded | tf45a (PROPOSAL-10) |
| A | u3ae0 | IMPL_PLAN: aurad+aura-msg (7 slices) | extract-residual | → R-A `40ujq` |
| A | odasf | PROPOSAL-6: UAT revision | close-superseded | tf45a (PROPOSAL-10) |
| A | lczzv | PROPOSAL-7: UAT-2 revisions (stub) | close-superseded | tf45a (PROPOSAL-10) |
| A | ytj66 | PROPOSAL-8: UAT-2 revisions (fleshed) | close-superseded | tf45a (PROPOSAL-10) |
| A | 3ubig | REQUEST: Rework supervisor role | extract-residual | → R-B `0e7ej` |
| A | v2a51 | ELICIT: Rework supervisor role | extract-residual | → R-B `0e7ej` |
| A | q72mt | URD: Rework supervisor role | extract-residual | → R-B `0e7ej` |
| B | 2tj | EPIC/FOLLOWUP: aura_protocol v1 improvements | extract-residual | → R-C `2uauq` |
| B | o7i9 | URD: Un-skip 25 tests | extract-residual | → R-C `2uauq` |
| B | 7vtb | URD: aurad rename + aura-msg stub + protocol | extract-residual | → R-A `40ujq` (R1/R3/R5/R6) + R-C `2uauq` (R7-R9) |
| B | e28b | FOLLOWUP_URD: schema-driven engine v2 (empty stub) | extract-residual | → R-D `0ou9f` |
| B | s6i | FOLLOWUP_URD: aura_protocol v1 follow-up | extract-residual | → R-C `2uauq` |
| C | 1nla | URD: Unified aura-swarm | extract-residual | → R-E1 `1dos9` |
| C | 99q | URD: Release automation (aura-release) | extract-residual | → R-E2 `f89mx` |
| C | s7l0 | URD: aura-release wrong-directory bug | extract-residual | → R-E2 `f89mx` |

**Tally:** 4 close-superseded · 14 extract-residual · 0 special-attention · 0 keep-open. Coverage = 18/18.

## T-A3 — Execution log (2026-05-30, user-signed-off)

- **6 residuals filed** (`aura:residual,aura:audit`; `discovered-from:aura-plugins-qzr8a`; NOT ow0pq blockers):
  - **R-A** `aura-plugins-40ujq` — Verify aurad+aura-msg Go-coverage (bwfqm R1-R15 + tf45a + u3ae0 slices + 7vtb R1/R3/R5/R6) in pastured/pasture-msg.
  - **R-B** `aura-plugins-0e7ej` — Verify supervisor-rework (q72mt R1-R7) captured in Go codegen; anchored on `fzctk`.
  - **R-C** `aura-plugins-2uauq` — Verify Python aura_protocol v1 (state machine + Temporal + constraints) ported to Go; constraints sub-question → `mh4ek`.
  - **R-D** `aura-plugins-0ou9f` — Verify v2 schema-driven codegen (gen_schema/gen_skills/gen_agents) Go-coverage; → `5wbhm`/`fzctk`.
  - **R-E1** `aura-plugins-1dos9` — Verify aura-swarm URD R1-R11 deliverables present in Python aura-swarm (no Go side).
  - **R-E2** `aura-plugins-f89mx` — Verify aura-release URD (99q FR/NFR + s7l0 path-fix) in Python AND pasture-release Go has no path-bug.
- **18/18 closed** with per-verdict reasons + per-item bd comments citing the audit.
- **5 closures used `--force`** over stale-dep guards (fw1cx, odasf, 2tj, s6i, 99q): all blockers verified stale (same superseded Python-era epochs — j82qd IMPL_PLAN-2, j02 FOLLOWUP_URE, wux aura-release PROPOSAL-1, 2tj's 27 SLICE-REVIEW findings).
- **Discovered-work residual R-F** `aura-plugins-n19wo` — sweep the ~30 stale open sub-tasks orphaned by the force-closes (out of qzr8a's 18-item scope; surfaced during execution).

## T-A5 — R-row verdicts (UAT4 residuals-appendix)

> The user walkthrough overturned the coordinator's "R1/R2 DONE no residuals."

- **R1 "Port aurad" = DONE-WITH-RESIDUALS-FILED** — delivered-scope items carry Go-coverage verification residuals.
  - Appendix: `aura-plugins-40ujq` (R-A, aurad coverage) · `aura-plugins-2uauq` (R-C, aura_protocol port) — severity: follow-up/verification.
- **R2 "Port aura-msg" = DONE-WITH-RESIDUALS-FILED** — aura-msg stub (7vtb) + bwfqm coverage verification.
  - Appendix: `aura-plugins-40ujq` (R-A, aura-msg coverage) — severity: follow-up/verification.

Both R-rows DONE (delivered), with verification residuals tracked separately — they do **not** block `ow0pq`.

---

## Pre-repo-move staleness re-triage (2026-06-05)

> **Scope:** all **311** open + in_progress beads tasks, profiled ahead of moving `pasture` development to the standalone repo `~/codebases/dayvidpham/pasture` (after which this aura-plugins beads DB is abandoned for pasture work).

> **Method:** dynamic Workflow — 10 Haiku agents, ~32 tasks each; each ran `bd show` per task, cross-referenced the four audit ledgers in this folder, and spot-checked claims against the `pasture/` + `scripts/` code before judging.

> **⚠️ These are heuristic Haiku profiles — recommendations, not executed actions.** Review before any mass `bd close`. The original qzr8a FINAL LEDGER above is unchanged.


### Summary

| Action | Count |
|---|---:|
| close | 205 |
| migrate | 16 |
| verify | 18 |
| dedupe | 1 |
| keep | 71 |
| **total** | **311** |

| Category | Count | Meaning |
|---|---:|---|
| STALE | 109 | old / overtaken by events / Python-era → close |
| DONE | 83 | implemented in code but never closed → close |
| ACTIVE | 71 | genuine pending aura-plugins-side work → keep |
| NEEDS_VERIFY | 17 | verify/residual task — confirm target addressed |
| MIGRATE | 16 | real pasture-specific work → new repo tracker |
| SUPERSEDED | 14 | done by a later epoch / the Go port → close |
| DUPLICATE | 1 | covered by another task → dedupe |


### CLOSE — stale / superseded / done-but-open (recommend closing in this DB) (205)

| ID | Category | Title | Reason |
|---|---|---|---|
| `0fmy` | DONE | MINOR: VoteTestCase.votes is dict[str, str] — type bridge from YAML not documented at point of use in combinatorial tests | Test documentation/style finding. Python test suite. May be addressed via test refactoring or left as-is. Dated 2026-02-26, aura-plugins being abandoned. Never closed — DONE or left. |
| `1ma7` | DONE | IMPORTANT: docs/architecture.md stale after SLICE-4 additions (SliceInput + Signals table) | Review finding. Docs updated: architecture.md now has parent_workflow_id + slice_progress signal per SLICE-3 & SLICE-4. Code on main, task never closed — DONE. |
| `2kv1` | DONE | IMPORTANT: temporal-service.nix ExecStart for dbPath='' duplicates arg construction (DRY violation) | Review finding. Fixed per commit 79b1610 'Merge SLICE-1 review-1 fixes: baseArgs'. Code on main. Task never closed — DONE. |
| `2y3s` | DONE | MINOR: fixture_loader.py generate_forward_path_transition_cases hardcodes _CONSENSUS_GATED and _BLOCKER_GATED as local string literals instead of deriving from YAML | Code maintainability finding (DRY violation in test fixture generation). Dated 2026-02-26. May be fixed or left. Code review done, never closed — DONE or minor. |
| `6btj` | DONE | SLICE-1-REVIEW-A-1 BLOCKER | SLICE-1 BLOCKER review finding (temporal-service.nix dbPath description). Fixed per commit 79b1610 'Merge SLICE-1 review-1 fixes: dbPath description + baseArgs + aurad description'. Code on main, task never closed. |
| `8uc1` | DONE | MINOR: aura-msg.md --help example output doesn't match actual stub description | Review finding. aura-msg.md exists and was updated. Task dated 2026-02-27. Code review done but never closed — DONE. |
| `9g9r` | DONE | MINOR: ReviewPhaseWorkflow.submit_vote uses async def while EpochWorkflow signals use def — inconsistent Temporal signal handler style | Temporal workflow signal handler consistency finding (workflow.py). Dated 2026-02-26. Python aura-plugins being abandoned for Go pasture. Never closed — DONE or minor. |
| `aura-plugins-0qlw` | DONE | FOLLOWUP-REVIEW-C-1: Elegance review of FOLLOWUP epic z8ga | Aggregation container for v2 review findings (ACCEPT verdict recorded); epic z8ga implementation complete with 23/26 findings addressed; 1922 tests pass. |
| `aura-plugins-14lr` | DONE | PROPOSAL-2-REVIEW-C-2: aura-release dead code + test | Review artifact ACCEPT vote; code changes shipped (cuuw CLOSED 2026-02-26) |
| `aura-plugins-18zp` | DONE | REQUEST: Un-skip 25 skipped tests (4 Temporal sandbox + 21 constraint violation combinatorial) | REQUEST completed per commit 46ee681 (March 3, 2026). Test count improved from 1407+25 skipped to 1922+ passed, 3 skipped. Entire epoch delivered (ELICIT → PROPOSAL-2 → 3-reviewer → UAT → IMPL → handoff). Root of this batch's epoch. |
| `aura-plugins-1bm` | DONE | PROPOSAL-2: bin/aura-release — revised after review | Proposal revised and executed; implementation complete (bin/aura-release exists); awaiting sweep by residual n19wo |
| `aura-plugins-1ey` | DONE | PROPOSAL-1-REVIEW: Design review findings | Design review completed; PROPOSAL-2 executed; implementation complete; awaiting sweep by residual n19wo |
| `aura-plugins-1mll` | DONE | SLICE-1-REVIEW-A-1: Temporal sandbox start_local() switch | Review vote ACCEPT (2026-03-03). start_local() switch completed per commit 46ee681; all 4 Temporal tests passing with correct search attributes. Part of closed epoch aura-plugins-18zp. |
| `aura-plugins-2cl4` | DONE | UAT: Plan acceptance for aura-release dead code + test | UAT artifact; parent REQUEST (cuuw) closed 2026-02-26; code implementation verified |
| `aura-plugins-2onu` | DONE | SLICE-1-REVIEW-B-1: Temporal sandbox test quality | Review vote ACCEPT (2026-03-03). All 4 Temporal sandbox tests correctly un-skipped per commit 46ee681. Test quality verified. Part of closed epoch aura-plugins-18zp. |
| `aura-plugins-2wzn` | DONE | SLICE-1-REVIEW-C-1: Temporal sandbox — Elegance axis | Review vote ACCEPT (2026-03-03). Implementation completed in commit 46ee681; test_workflow.py successfully uses start_local() with correct SAs. Part of closed epoch aura-plugins-18zp — review documented but task never formally closed. |
| `aura-plugins-3dyw` | DONE | SLICE-1-REVIEW-A-2: Missing test_integration_points_via_structural | Test now present at test_constraints.py:1946; code review finding resolved |
| `aura-plugins-4gx1` | DONE | FOLLOWUP-REVIEW-B-1: Test Quality review of FOLLOWUP epic z8ga | Aggregation container for v2 review findings (ACCEPT verdict recorded); epic z8ga implementation complete; supporting evidence: z8ga comment + test suite (1922 passed). |
| `aura-plugins-59fg` | DONE | SLICE-1-REVIEW-B-1 IMPORTANT | FIX tasks (nzx3, mz34) implemented; check_integration_points wired + tested |
| `aura-plugins-5n2l` | DONE | IMPL_PLAN-REVIEW-B-1: Schema-driven protocol engine v2 — Test Quality | Review verdict: ACCEPT (all 4 slices). Supporting code exists (gen_schema.py ~75KB, gen_skills.py, context_injection.py); test suite 1922 passed. Verdict documented; can be closed. |
| `aura-plugins-5sn` | DONE | UAT-1: Plan acceptance for release automation PROPOSAL-2 | Plan accepted; implementation complete (bin/aura-release v0.10.2+); UAT passed; awaiting sweep by residual n19wo |
| `aura-plugins-6wqht` | DONE | URD: fzctk supervisor+worker SKILL.md fidelity audit | fzctk audit COMPLETE (docs/audits/fzctk-supervisor-worker-fidelity.md, executed 2026-05-30). URD asked for the audit to be conducted. Audit done, 18/19 fragments captured, 1 distorted (fix aura-plugins-9e42d filed). URD deliverable met. |
| `aura-plugins-6yr` | DONE | SLICE-2: Fix CLI UX error messages in bin/aura-release | Implemented in bin/aura-release (exists, functional; error messages improved); never closed in bd; awaiting sweep by residual n19wo |
| `aura-plugins-70yh` | DONE | UAT-1: Plan acceptance for un-skip 25 tests | UAT components reviewed and ACCEPTED by user (2026-03-02). Temporal sandbox approach (start_local) and YAML dispatch approach verified. Implementation shipped per commit 46ee681. |
| `aura-plugins-7iy2` | DONE | IMPL_PLAN: aura-release dead code + test | Dead code removed from bin/aura-release (lines 32-57 gone); REQUEST (cuuw) closed 2026-02-26 |
| `aura-plugins-82gp` | DONE | SLICE-5-REVIEW-A-1: constraint violation fixtures (protocol.yaml + fixture_loader.py) | Review vote ACCEPT (2026-02-27). Constraint violation fixture implementation correct and complete. All 26 C-* constraints present; 5 runnable + 21 skipped. Tests pass (1260+). Part of closed aurad+aura-msg epoch. |
| `aura-plugins-9m27` | DONE | PROPOSAL-2-REVIEW-B-2: aura-release dead code + test | Review artifact ACCEPT vote; code changes shipped (cuuw CLOSED 2026-02-26) |
| `aura-plugins-a6r9` | DONE | SLICE-1-REVIEW-A-2 MINOR | Dependent SLICE-1-REVIEW-A-2 (3dyw) resolved; review artifact |
| `aura-plugins-ai2x` | DONE | REQUEST: Package aura-release as Nix flake output | Implementation COMPLETE per 2026-02-23 comment: aura-release packaged in flake.nix via writeScriptBin + added to hm-module.nix; smoke test passed. Code verified at flake.nix lines 230+ and nix/hm-module.nix. |
| `aura-plugins-bch` | DONE | IMPL_PLAN: bin/aura-release implementation | Plan executed; bin/aura-release implemented and tested; awaiting sweep by residual n19wo |
| `aura-plugins-bl50` | DONE | BLOCKER: Missing prompt renderer in context_injection.py | render_role_context_as_text() and render_role_context_as_xml() exist; SLICE-4 (kg25) completed 2026-02-26 |
| `aura-plugins-ct01` | DONE | SLICE-1-REVIEW-C-1 IMPORTANT | Depends on nzx3 (now complete); check_integration_points properly wired into check_structural |
| `aura-plugins-e19` | DONE | SLICE-1: Implement bin/aura-release | SLICE-1 implemented (bin/aura-release exists v0.10.2+); awaiting sweep by residual n19wo |
| `aura-plugins-e1z2` | DONE | IMPL_PLAN: Un-skip 25 tests — Temporal sandbox + constraint violation combinatorial | Implementation plan executed per commit 46ee681 (March 3, 2026). All vertical slices delivered. Target achieved: 1922+ passed, 3 skipped (vs 1407+25 original). Part of closed epoch aura-plugins-18zp. |
| `aura-plugins-fl5p` | DONE | PROPOSAL-2: Un-skip 25 tests — Temporal sandbox + constraint violation combinatorial | Proposal ratified; supersedes PROPOSAL-1 (aura-plugins-nkx7). Implementation delivered per commit 46ee681. All reviewer findings addressed. Shipped to main. |
| `aura-plugins-fs7g` | DONE | SLICE-2-REVIEW-B-1: Constraint violation fixture test quality | Review vote ACCEPT (2026-03-03). Implementation completed in commit 46ee681; tests now pass 1922+, 3 skipped. Mark DONE with ACCEPT vote. Part of closed epoch aura-plugins-18zp (REQUEST) — implementation shipped, reviews documented but tasks never formally closed. |
| `aura-plugins-ghxm` | DONE | SLICE-4-UAT-BLOCKER BLOCKER | Dependent BLOCKER (bl50) resolved; SLICE-4 (kg25) closed 2026-02-26 |
| `aura-plugins-gyzs` | DONE | FOLLOWUP-REVIEW-A-1 IMPORTANT | Aggregation container for v2 review findings; epic z8ga comment (2026-02-23+) confirms 'FOLLOWUP implementation complete. 23/26 blocker tasks closed'. Remaining review tasks should be closed as work is delivered. |
| `aura-plugins-iv5j` | DONE | ELICIT: Un-skip 25 tests — Temporal sandbox + constraint violation combinatorial | URE/ELICIT completed; user gave clear answers (start_local, individual method dispatch). Implementation shipped per commit 46ee681. |
| `aura-plugins-j2k` | DONE | REQUEST: Automated release tagging and version bumping for aura-plugins | aura-release implemented and deployed (v0.10.0+); git history shows releases v0.9.x-v0.10.2; feature complete |
| `aura-plugins-jjo` | DONE | SLICE-1-REVIEW: Code review for bin/aura-release | Code review completed; implementation finalized; awaiting sweep by residual n19wo (orphaned by qzr8a closures) |
| `aura-plugins-lnce` | DONE | HANDOFF: Architect → Supervisor for aura-release dead code + test | Handoff artifact; parent REQUEST (cuuw) closed 2026-02-26 |
| `aura-plugins-lybp` | DONE | PROPOSAL-2-REVIEW-A-2: Un-skip 25 tests — Correctness axis | Review vote ACCEPT (2026-03-02). Correctness verified across all components: Temporal sandbox, constraint dispatch, audit constraints. Implementation shipped per commit 46ee681. |
| `aura-plugins-moot` | DONE | SLICE-1-REVIEW-B-1 MINOR | Umbrella MINOR findings task with dependency on tmjs. Implementation of asyncio.sleep magic number is complete per commit 46ee681. Part of closed epoch aura-plugins-18zp. |
| `aura-plugins-msfr` | DONE | BLOCKER: gen_skills.py must render ProcedureSteps into SKILL.md headers | ProcedureSteps render in skill_header.j2 Startup Sequence (L78-84); SLICE-3 (82ya) completed 2026-02-26 |
| `aura-plugins-mz34` | DONE | FIX: Add TestCheckStructural integration test for check_integration_points | Test added: test_integration_points_via_structural exists at test_constraints.py:1946 |
| `aura-plugins-n93g` | DONE | SLICE-1-REVIEW-A-1 IMPORTANT | Depends on x7k5 (resolved); review artifact on completed work |
| `aura-plugins-nfr` | DONE | UAT-2: Implementation testing — UX issues found | Implementation complete (bin/aura-release functional); UAT issues addressed; awaiting sweep by residual n19wo |
| `aura-plugins-ni3n` | DONE | SLICE-2-REVIEW-A-1: Constraint violation fixture extension | Review vote ACCEPT (2026-03-03). All 20 constraint violations correctly un-skipped per commit 46ee681; fixture_loader dispatch verified. Part of closed epoch aura-plugins-18zp. |
| `aura-plugins-nzx3` | DONE | FIX: Wire check_integration_points into check_structural | check_integration_points wired: parameter at L299, dispatch at L377-378, docstring at L334; test at L1946 |
| `aura-plugins-p2kp` | DONE | REVIEW-A: End-user alignment review for PROPOSAL-1 | Review completed (2026-03-01). End-user alignment criteria verified. Proposal addresses real user needs (single entry point, --swarm-mode flag, --tmux-dest window). Review documented. Part of aura-swarm refactor epoch. |
| `aura-plugins-pcs6` | DONE | PROPOSAL-2: aura-release reads pyproject.toml from wrong directory | Proposal artifact; implementation shipped (bin/aura-release verified complete), REQUEST (cuuw) closed 2026-02-26 |
| `aura-plugins-prs2` | DONE | HANDOFF: Architect → Supervisor for REQUEST aura-plugins-18zp | Handoff document prepared; implementation delivered per commit 46ee681. Both SLICE-1 and SLICE-2 completed and reviewed. Part of closed epoch aura-plugins-18zp. |
| `aura-plugins-q413` | DONE | PROPOSAL-2-REVIEW-C-2: Un-skip 25 tests — Elegance axis | Review vote ACCEPT (2026-03-02). Addresses all Round 1 concerns (removed _coerce_violation_args, removed _factory). Implementation shipped per commit 46ee681. |
| `aura-plugins-qkopt` | DONE | UAT-IMPL-REVIEW-A-1 MINOR | Phase 10 impl review findings (PROPOSAL-10 UAT revision); 2 MINORs documented and addressed. Old phase (created 2026-03-22), work appears done but never closed. |
| `aura-plugins-r5kx` | DONE | FOLLOWUP-REVIEW-A-1: Correctness review of FOLLOWUP epic z8ga | Aggregation container for v2 review findings (ACCEPT verdict recorded); epic z8ga implementation complete; 3 of 26 deferred to separate work (954g, ikgp, x6gb). |
| `aura-plugins-rgos` | DONE | BLOCKER: gen_skills.py needs --init mode to place markers | --init flag implemented in gen_skills.py L646; SLICE-3 (82ya) completed 2026-02-26 |
| `aura-plugins-sfr0` | DONE | SLICE-1-4-REVIEW-C-1: Elegance review of schema-driven protocol engine v2 (all 4 slices) | Review verdict: SLICE-1 REVISE (1 BLOCKER), SLICE-2/3/4 ACCEPT. Findings documented (aura-plugins-h369 blocker + 13 IMPORTANT/MINOR items). Verdict issued; underlying work tracked by findings. Can close. |
| `aura-plugins-thm2d` | DONE | x5071-REVIEW-r1 IMPORTANT (empty) | x5071 PORT COMPLETE (2026-05-31) per final comment. Review cycle finished; task has empty description but marks review completion. Close as DONE. |
| `aura-plugins-tmjs` | DONE | MINOR: asyncio.sleep(0.5) magic number in Temporal sandbox tests | Implementation completed in commit 46ee681; asyncio.sleep(0.5) hardcoded but ACCEPTED by reviewers as minimal accommodation. Code exists and is functioning. Part of closed epoch aura-plugins-18zp. |
| `aura-plugins-tt57` | DONE | ELICIT: aura-release reads pyproject.toml from wrong directory | Elicit artifact; user decisions captured and implementation shipped (REQUEST cuuw CLOSED) |
| `aura-plugins-udj3` | DONE | SLICE-1-REVIEW-C-2 IMPORTANT | Dependent FIX (mz34) resolved; integration test now present |
| `aura-plugins-ul1o` | DONE | PROPOSAL-2-REVIEW-B-2: Un-skip 25 tests | Review vote ACCEPT (2026-03-02). All Round 1 findings resolved (C-blocker-dual-parent kwarg fixed, _coerce_violation_args removed, _factory pattern removed). Implementation shipped. |
| `aura-plugins-umye` | DONE | PROPOSAL-2-REVIEW-A-2: aura-release dead code + test | Review artifact ACCEPT vote; code changes shipped (cuuw CLOSED 2026-02-26) |
| `aura-plugins-v3yv` | DONE | REQUEST: Fix intree mode creating new session instead of new window | Implemented per commit 27325b1 (March 2, 2026). Fixed intree mode to use current tmux session (WINDOW) instead of creating new session (SESSION). Code shipped to main. Part of older aura-swarm refactor epoch. |
| `aura-plugins-wqw` | DONE | ELICIT: Release automation requirements | Requirements elicited; all NFR/FR delivered via bin/aura-release (v0.10.2+); awaiting sweep by residual n19wo |
| `aura-plugins-wux` | DONE | PROPOSAL-1: bin/aura-release — version bump, changelog, tag | Initial proposal; superseded by PROPOSAL-2 which was executed (bin/aura-release implemented); qzr8a identified as stale-dep blocker; awaiting sweep by residual n19wo |
| `aura-plugins-x5071` | DONE | EPIC: Port remaining 30 Python skills to Go | PORT COMPLETE (2026-05-31). Commit pasture a23de20 (audit-done): 22/22 portable skills ported to Go codegen. Created IN_PROGRESS; work is done. Close and let ow0pq proceed if this was the only blocker. |
| `aura-plugins-x7k5` | DONE | SLICE-1-REVIEW-A-1: check_integration_points missing from check_structural | Now wired: constraints.py L299, L377-378, L334; integration test L1946 in test_constraints.py |
| `aura-plugins-yjwc` | DONE | SLICE-4-REVIEW-A-2: SliceWorkflow parent signal try/except fix | Review vote ACCEPT (2026-02-27). IMPORTANT finding aura-plugins-fdim resolved. workflow.py lines 647-665 wrap parent_handle.signal() in try/except. Non-fatal signal failure handled correctly. Part of closed aurad+aura-msg epoch. |
| `aura-plugins-zhre` | DONE | SLICE-1-REVIEW-A-2: temporal-service.nix dbPath description fix | Review vote ACCEPT (2026-02-27). BLOCKER aura-plugins-dzen resolved. temporal-service.nix dbPath description updated to correctly describe XDG auto-resolve behavior (persistent SQLite). Part of closed aurad+aura-msg epoch. |
| `aura-plugins-zn6o` | DONE | SLICE-3-UAT-BLOCKER BLOCKER | Dependent BLOCKERs (msfr, rgos) now implemented; SLICE-3 (82ya) closed 2026-02-26 |
| `ho6x` | DONE | MINOR: conftest.py exports _PROTOCOL_FIXTURE with leading underscore (private convention) but uses it as cross-module public singleton | Test infrastructure naming convention finding. Dated 2026-02-26. May be fixed (rename to PROTOCOL_FIXTURE) or left as-is. Code review done, never closed — DONE or minor. |
| `i491` | DONE | MINOR: SLICE-1 (__init__.py cleanups) has no regression test verifying alphabetical ordering or __all__ comment removal | Test infrastructure finding (missing regression test). Dated 2026-02-26. SLICE-1 completed on main (7f8f23c). May indicate test gap or acceptable risk. Never closed — DONE or minor debt. |
| `ishd` | DONE | MINOR: aurad-service.nix uses pkgs.stdenv.hostPlatform.system; hm-module.nix uses pkgs.system | Code review finding (Reviewer C - MINOR). Not clear if fixed, but dated 2026-02-27, implementation epoch ended, aura-plugins being abandoned for pasture. Python-era finding, DONE or superseded. |
| `jjy8` | DONE | MINOR: TestReviewPhaseWorkflowSignalLogic uses asyncio.new_event_loop() directly instead of @pytest.mark.asyncio | Temporal workflow test style finding. Dated 2026-02-26. May indicate test framework inconsistency or code smell. Never closed — DONE or minor. |
| `ltcs` | DONE | IMPORTANT: docs/aurad.md systemd section missing aurad-service.nix documentation | Review finding. aurad.md line 122+ now documents aurad-service.nix systemd section. Fixed, code on main, task never closed — DONE. |
| `mj69` | DONE | MINOR: epoch_states fixture in protocol.yaml not used in any active combinatorial test (fixture infrastructure gap) | Test infrastructure finding (unused fixture data). Dated 2026-02-26. May indicate test gap or deliberate reserve fixture set. Never closed — DONE or minor debt. |
| `oqw9` | DONE | MINOR: bin/aurad.py argparse description still says 'Temporal worker' | Review finding for bin/aurad.py description. Fixed: bin/aurad.py:76 now reads 'aurad — Temporal worker daemon for Aura Protocol v3' per SLICE-1 merge. Task left unclosed — DONE but not closed. |
| `qz5b` | DONE | IMPORTANT: temporal-service.nix dbPath option description contradicts new XDG-default behavior | Review BLOCKER finding. Fixed per commit 79b1610: dbPath description now correctly documents XDG auto-resolve behavior. Code on main, task never closed — DONE. |
| `rwg8` | DONE | MINOR: state_machine.py record_vote does redundant ReviewAxis(axis) canonicalization after already validating axis in _REVIEW_AXES | Code quality finding (state_machine.py). Issue may be fixed or may remain (low priority). Dated 2026-02-26, Python aura_protocol, aura-plugins being superseded by Go pasture. Task never closed — DONE or left. |
| `wrfs` | DONE | MINOR: flake.nix packages.worker is not included in packages.default — inconsistent with other bin/ packages | Nix packaging consistency finding. Dated 2026-02-26. Status: packages.worker may have been added to packages.default, unclear. Code review done but task never closed — likely DONE. |
| `6m2m` | STALE | SLICE-4-REVIEW-A-1: Workflow signals + ReviewAxis type fix | SLICE-4 review collector task. Code exists in workflow.py (ReviewAxis type, signals). Marked VOTE: ACCEPT. Implementation on main, review never formally closed — stale. |
| `83sn` | STALE | REVIEW-C-1 MINOR | Reviewer C (Elegance axis) MINOR findings collector for SLICE-1/2/3/4/5. Code implemented on main. Review never formally closed — stale. |
| `aura-plugins-0gns` | STALE | FOLLOWUP_IMPL_REVIEW-C-1 MINOR | Python epoch FOLLOWUP task (empty, no description). Part of Python aurad+aura-msg review cycle. Python work superseded by pasture Go port. |
| `aura-plugins-0hmi` | STALE | FOLLOWUP_IMPL_REVIEW-C-1: Elegance | Python epoch FOLLOWUP review task. Part of Python aurad+aura-msg FOLLOWUP epic (aurad epoch work). Python work superseded by pasture Go port. |
| `aura-plugins-0yd` | STALE | SLICE-3-REVIEW-B-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-0yuk` | STALE | FOLLOWUP: Non-blocking improvements from code review (aura-plugins-ckg0) | Python aurad+aura-msg code review follow-up (created 2026-02-27). Go Pasture port has superseded Python aurad; close as superseded by Pasture Go port. |
| `aura-plugins-192h` | STALE | FOLLOWUP-ALL-SLICES-REVIEW-A-1 MINOR | Review findings task for closed FOLLOWUP epic hgki (DONE). Parent epoch completed 2026-02-26. |
| `aura-plugins-1gqh` | STALE | MINOR: test_skipped_entries_have_no_violation_data missing violation_method check | Python test nit. aura_protocol test issue (constraint violation test). Minor, Python era. Close as superseded by Python deprecation. |
| `aura-plugins-1ic` | STALE | SLICE-2-REVIEW-A-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-295` | STALE | SLICE-1-REVIEW-B-1 IMPORTANT | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-2j4v.3` | STALE | SLICE-2-REVIEW-B-2 MINOR | Review task for closed SLICE-2 (aura-plugins-2j4v, CLOSED). Orphaned from 2026-02-23 epoch. |
| `aura-plugins-2j4v.3.1` | STALE | SLICE-2: Round-trip test for procedure_steps doesn't verify command/context/next_state (parent: aura-plugins-2j4v.3) | Test gap finding for closed SLICE-2 (aura-plugins-2j4v, CLOSED 2026-02-23). From ancient protocol v2 epoch. |
| `aura-plugins-3m4` | STALE | SLICE-5-REVIEW-C-1-F1: Workflow reassigns frozen TransitionRecord in transition_history list — breaks expected immutability guarantee | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-3tfg` | STALE | BLOCKER: gen_schema.py must emit procedure-steps section into schema.xml | Blocker for closed UAT (aura-plugins-6p9j, CLOSED 2026-02-26). From ancient protocol v2 epoch; superseded by pasture Go port. |
| `aura-plugins-3xe` | STALE | SLICE-5-REVIEW-A-1 IMPORTANT | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. Comment on task confirms addressed in 2tj; now extract to residual. |
| `aura-plugins-3zs8` | STALE | BLOCKER: ProcedureStep missing command and context fields | Blocker for closed UAT (aura-plugins-6p9j, CLOSED 2026-02-26). From ancient protocol v2 epoch; superseded by pasture Go port. |
| `aura-plugins-46yx` | STALE | UAT: Implementation acceptance — plugin registry + marketplace fix + test quality | UAT for closed PROPOSAL-2 (aura-plugins-iw89, CLOSED). Orphaned review task from 2026-02-26 epoch. |
| `aura-plugins-4hu` | STALE | SLICE-2-REVIEW-A-1 MINOR: EpochState.current_role type is str not RoleId | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-4u1` | STALE | SLICE-4-REVIEW-B-1 MINOR | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-5r4v` | STALE | PROPOSAL-2-REVIEW-B-2: Plugin registry + marketplace fix + test quality | Review task for closed PROPOSAL-2 (aura-plugins-iw89, CLOSED). Orphaned from 2026-02-26 epoch. |
| `aura-plugins-5zf` | STALE | SLICE-4-REVIEW-B-1 IMPORTANT | Python v1 code-review finding; parent epic 2tj closed 2026-05-30 (superseded); awaiting sweep by residual n19wo |
| `aura-plugins-68o` | STALE | SLICE-5-REVIEW-B-1 IMPORTANT | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-6lyb9` | STALE | REVIEW-B-2 MINOR | Placeholder title 'REVIEW-B-2 MINOR' with no context. Likely artifact from PROPOSAL-2 epic (ended 2026-05). No description visible. Stale review artifact. |
| `aura-plugins-6p08` | STALE | MINOR: EpochState docstring says keys are strings ('correctness', etc) but type is dict[ReviewAxis, VoteType] | Parent FOLLOWUP epic hgki (DONE). Python state_machine.py docstring cleanup from closed 2026-02-26 epoch. |
| `aura-plugins-6skbw` | STALE | Refactor: exploration_method str → ExplorationMethod StrEnum | Python-era tech debt (introduced cd88a86 v0.x); Go port has superseded this work. ExplorationMethod enum not needed in current aura-protocol Python codebase. |
| `aura-plugins-7d2` | STALE | SLICE-4-REVIEW-A-1 MINOR | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-7m29` | STALE | SLICE-3-L3: Impl — context population + template sections | Python aura_protocol epoch (shared-fragments L3 implementation). Part of Python-era shared-fragment epic (v2 schema-driven codegen). Dependencies show DONE. Python epoch superseded by Go pasture work. |
| `aura-plugins-7vzp` | STALE | FOLLOWUP-REVIEW-C-1 MINOR | Review task for closed FOLLOWUP epic hgki (DONE). Parent epoch completed 2026-02-26. |
| `aura-plugins-82ya.2` | STALE | SLICE-3-REVIEW-B-2 IMPORTANT | Review task for closed SLICE-3 (aura-plugins-82ya, CLOSED). Orphaned from 2026-02-23 epoch. |
| `aura-plugins-82ya.2.1` | STALE | SLICE-3: No test verifies command/context rendering in SKILL.md output (parent: aura-plugins-82ya.2) | Test gap finding for closed SLICE-3 (aura-plugins-82ya, CLOSED 2026-02-23). From ancient protocol v2 epoch. |
| `aura-plugins-8jy` | STALE | SLICE-1-REVIEW-B-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-90s0` | STALE | PROPOSAL-2-REVIEW-A-2: Plugin registry + marketplace fix + test quality | Review task for closed PROPOSAL-2 (aura-plugins-iw89, CLOSED). Orphaned from 2026-02-26 epoch. |
| `aura-plugins-947` | STALE | SLICE-3-REVIEW-C-1 IMPORTANT | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-9lqe` | STALE | MINOR: protocol.yaml C-review-consensus description references stale axis labels (A, B, C) | Audit finding from February 2026 (SLICE-4). References old A/B/C axis labels (now: CORRECTNESS, TEST_QUALITY, ELEGANCE). Minor doc cleanup. No code changes. Not prioritized; design is correct, docs can stay as-is. Audit qzr8a deemed this low-priority polish. |
| `aura-plugins-9mch` | STALE | PROPOSAL-1-REVIEW-B-1: Plugin registry + marketplace fix + test quality | Review task for closed PROPOSAL-1 (aura-plugins-7ome, CLOSED). Orphaned from 2026-02-26 epoch. |
| `aura-plugins-9suu.1` | STALE | SLICE-1-REVIEW-B-2 IMPORTANT | Review task for closed SLICE-1 (aura-plugins-9suu, CLOSED). Orphaned from 2026-02-23 epoch. |
| `aura-plugins-9suu.1.1` | STALE | SLICE-1: No test verifies ProcedureStep command/context field values (parent: aura-plugins-9suu.1) | Test gap finding for closed SLICE-1 (aura-plugins-9suu, CLOSED 2026-02-23). From ancient protocol v2 epoch. |
| `aura-plugins-a0x0` | STALE | UAT: Plan acceptance — plugin registry + marketplace fix + test quality | UAT for closed PROPOSAL-2 (aura-plugins-iw89, CLOSED). Orphaned review task from 2026-02-26 epoch. |
| `aura-plugins-ad8i1` | STALE | FOLLOWUP-2: Non-blocking improvements from UAT revision code review | 8 IMPORTANT findings target deprecated Python aura-plugins. Re-placed by 3iz51 Phase-11 as extract-residual; verification residual aura-plugins-fs107 filed (verify which apply to Go Pasture, file Go-side, close Python-obsolete). |
| `aura-plugins-bnr` | STALE | SLICE-3-REVIEW-A-1 IMPORTANT | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. Comment confirms addressed in 2tj. |
| `aura-plugins-cq1o` | STALE | HANDOFF: Architect → Supervisor for aura-plugins-0biw | Handoff task pointing to closed REQUEST aura-plugins-0biw (CLOSED). Orphaned from 2026-02-26 epoch. |
| `aura-plugins-cyc2` | STALE | FOLLOWUP-ALL-SLICES-REVIEW-A-1: FOLLOWUP epic aura-plugins-hgki correctness review | Review task for closed FOLLOWUP epic hgki (DONE). Parent epoch completed 2026-02-26. |
| `aura-plugins-don` | STALE | SLICE-2-REVIEW-C-1 IMPORTANT | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-dvi` | STALE | SLICE-3-REVIEW-A-1 MINOR | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-ehy0` | STALE | SLICE-1-UAT-BLOCKER BLOCKER | Orphaned UAT blocker from 2026-02-26 epoch with no parent context. From ancient protocol v2 epoch. |
| `aura-plugins-eqy` | STALE | SLICE-4-REVIEW-C-1-F1: DataPart.data and ToolCall dict fields unparameterized — should be dict[str, Any] | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-g6yl` | STALE | SLICE-2-REVIEW-C-1: Constraint violation fixture extension — Elegance axis | Python epoch code-review finding. Part of constraint-violation-fixture SLICE-2. Python aura_protocol work. Close as stale. |
| `aura-plugins-gdx` | STALE | SLICE-5-REVIEW-C-1 IMPORTANT | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-gtbu` | STALE | MINOR: __init__.py module docstring shows stale query_audit_events signature (missing role parameter) | Parent FOLLOWUP epic hgki (DONE). Python-era doc-cleanup from closed 2026-02-26 epoch. Superseded by pasture Go port. |
| `aura-plugins-h7x` | STALE | SLICE-1-REVIEW-C-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-hls` | STALE | SLICE-4-REVIEW-A-1 MINOR: FilePart uses file_uri field name instead of A2A spec file_with_uri | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-ib09` | STALE | MINOR: test_aura_msg.py aura_msg fixture uses scope="module" — deviates from per-test isolation convention | Minor test-isolation finding from February 2026. aura_msg fixture scope='module'. Impact is zero today (no mutable state). Future risk noted but not addressed. Audit qzr8a deemed low-priority polish. Code is functional. |
| `aura-plugins-in8` | STALE | SLICE-3-REVIEW-C-1-F1: check_severity_tree p10 | Python v1 code-review finding (C-severity-eager); parent epic 2tj closed 2026-05-30; awaiting sweep by n19wo |
| `aura-plugins-ip41` | STALE | MINOR: SliceWorkflow class docstring does not mention parent_workflow_id field | Minor doc finding from February 2026. SliceWorkflow.parent_workflow_id field exists and functions correctly (signals parent EpochWorkflow). Docstring omission is low-priority. Code is correct and shipped. No changes made; audit qzr8a classified as polish-level. |
| `aura-plugins-ipj` | STALE | SLICE-2-REVIEW-A-1 IMPORTANT: advance() timestamp | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo; coverage via residual R-C aura-plugins-2uauq |
| `aura-plugins-j02` | STALE | FOLLOWUP_URE: Scope follow-up for aura_protocol v1 improvements | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit with explicit blocker mention: 'force: stale children/blockers j02'. Superseded v1 epoch; coverage extracted to residual aura-plugins-2uauq. |
| `aura-plugins-j82qd` | STALE | IMPL_PLAN-2: UAT revisions — 5 slices | Python epoch IMPL_PLAN (aurad+aura-msg UAT revisions). qzr8a audit mentions j82qd as part of superseded Python epoch. All 5 slices show DONE dependencies. Python aura_protocol work is deprecated; aurad/aura-msg delivered to pasture as Go binaries. |
| `aura-plugins-jwb` | STALE | SLICE-3-REVIEW-A-1 IMPORTANT: check_severity_tree does not enforce C-severity-eager (p10 must have 3 groups) | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-kez2` | STALE | SLICE-2-REVIEW-B-1 MINOR | Python epoch code-review finding. Part of Python aura_protocol work. Close as stale. |
| `aura-plugins-klac` | STALE | FOLLOWUP: Non-blocking improvements from code review (aura-release test) | Python aura-release testing follow-up (created 2026-02-26). pasture-release Go binary supersedes Python aura-release; close as superseded. |
| `aura-plugins-kqtf` | STALE | REQUEST: Refactor aura-parallel + aura-swarm into unified aura-swarm | REQUEST from March 2026 for unified aura-swarm refactor. Dependency chain (mvfw URE) never progressed. No PROPOSAL or implementation shipped. Epoch abandoned in favor of pasture standalone plugin development. Focus shifted to pasture (REQUEST z7w20) per memory. |
| `aura-plugins-l1lk` | STALE | MINOR: flake.nix packages.worker not included in packages.default (symlinkJoin) | Parent FOLLOWUP epic hgki (DONE). Pre-pasture nix cleanup from 2026-02-26 epoch. |
| `aura-plugins-lkk` | STALE | SLICE-3-REVIEW-C-1-F1: _SAME_ACTOR local frozenset | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-loq9` | STALE | SLICE-3-L1: Types — RoleContext extensions | Python aura_protocol epoch shared-fragments L1 (types). Part of Python-era v2 codegen. Dependencies show DONE. Python epoch work; superseded by Go pasture codegen. |
| `aura-plugins-ltvf` | STALE | FOLLOWUP-REVIEW-B-1 MINOR | Review task for closed FOLLOWUP epic hgki (DONE). Parent epoch completed 2026-02-26. |
| `aura-plugins-lvm7` | STALE | SLICE-1-REVIEW-A-1 BLOCKER: Fixture and test case verification | Review task for closed REQUEST aura-plugins-0biw (CLOSED 2026-02-26). Orphaned from ancient epoch. |
| `aura-plugins-mdyr` | STALE | PROPOSAL-2-REVIEW-C-2: Plugin registry + marketplace fix + test quality | Review task for closed PROPOSAL-2 (aura-plugins-iw89, CLOSED). Orphaned from 2026-02-26 epoch. |
| `aura-plugins-msfq` | STALE | MINOR: Stale docstring on test_skipped_constraint_not_yet_state_testable | Python test nit (stale docstring). aura_protocol epoch work. Minor cleanup, Python era. Close as superseded by Python deprecation. |
| `aura-plugins-msfr` | STALE | BLOCKER: gen_skills.py must render ProcedureSteps into SKILL.md headers | Blocker for closed UAT (aura-plugins-6p9j, CLOSED 2026-02-26). From ancient protocol v2 epoch; superseded by pasture Go port. |
| `aura-plugins-mvfw` | STALE | ELICIT: Unified aura-swarm requirements elicitation | URE/ELICIT for aura-swarm refactor from March 2026. No implementation followed (no commits related to unified aura-swarm refactor on this branch). Subsequent work shifted to pasture Go port. Epoch abandoned in favor of pasture plugin work. |
| `aura-plugins-n0n` | STALE | SLICE-1-REVIEW-C-1-F1: AuditEvent.payload type safety | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-ngd` | STALE | SLICE-4-REVIEW-A-1 IMPORTANT | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. Comment confirms addressed in 2tj. |
| `aura-plugins-o83` | STALE | SLICE-2-REVIEW-B-1 IMPORTANT | Python v1 code-review finding (P10→P11 consensus split); parent epic 2tj closed 2026-05-30; awaiting sweep by n19wo |
| `aura-plugins-oa70` | STALE | SLICE-2-REVIEW-C-1 MINOR | Python epoch code-review finding. Part of SLICE-2 review cycle. Python aura_protocol work deprecated; close as stale. |
| `aura-plugins-odb3` | STALE | PROPOSAL-1-REVIEW-C-1: Plugin registry + marketplace fix + test quality | Review task for closed PROPOSAL-1 (aura-plugins-7ome, CLOSED). Orphaned from 2026-02-26 epoch. |
| `aura-plugins-p4fb` | STALE | ALL-SLICES-REVIEW-B-1 MINOR | Umbrella MINOR findings task from February 2026 (ALL-SLICES review round). Depends on aura-plugins-ib09 (module-scope fixture). No implementations made; review findings documented as low-priority polish. Part of closed aurad+aura-msg epoch. |
| `aura-plugins-pxo` | STALE | SLICE-3-REVIEW-C-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-qqf` | STALE | SLICE-3-REVIEW-A-1 MINOR: check_blocker_gate references C-worker-gates but semantically belongs to blocker resolution | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-qrm4` | STALE | PROPOSAL-1-REVIEW-A-1: Plugin registry + marketplace fix + test quality | Review task for closed PROPOSAL-1 (aura-plugins-7ome, CLOSED). Orphaned from 2026-02-26 epoch. |
| `aura-plugins-qy79` | STALE | FOLLOWUP-REVIEW-C-1: FOLLOWUP epic aura-plugins-hgki — Elegance review | Review task for closed FOLLOWUP epic hgki (DONE). Parent epoch completed 2026-02-26. |
| `aura-plugins-r8f` | STALE | SLICE-5-REVIEW-A-1 MINOR: SA_EPOCH_ID not updated in per-transition upsert_search_attributes call | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. Coverage verified in residual aura-plugins-2uauq (mh4ek constraint audit). |
| `aura-plugins-r8m` | STALE | SLICE-2-REVIEW-C-1-F1: EpochState.current_role type | Python v1 code-review finding (RoleId enum); parent epic 2tj closed 2026-05-30; awaiting sweep by n19wo |
| `aura-plugins-sk6` | STALE | SLICE-5-REVIEW-B-1 MINOR | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-szw8` | STALE | UAT: Implementation acceptance for un-skip 25 tests | Python aura_protocol epoch Phase-11 UAT. User decision recorded: ACCEPT. UAT completed (marked decision ACCEPT), but task never closed. Python epoch work (Temporal tests, constraint fixtures). Close as DONE. |
| `aura-plugins-tcn` | STALE | SLICE-2-REVIEW-A-1 IMPORTANT | Python v1 code-review finding (consensus enforcement); parent epic 2tj closed 2026-05-30; awaiting sweep by n19wo |
| `aura-plugins-ui9d` | STALE | SLICE-2-UAT-BLOCKER BLOCKER | Orphaned UAT blocker from 2026-02-26 epoch with no parent context. From ancient protocol v2 epoch. |
| `aura-plugins-utj` | STALE | SLICE-4-REVIEW-C-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-uvgb` | STALE | FOLLOWUP-REVIEW-B-1: Test quality review of aura-plugins-hgki (6 slices) | Review task for closed FOLLOWUP epic hgki (DONE). Parent epoch completed 2026-02-26. |
| `aura-plugins-v015` | STALE | SLICE-1-REVIEW-A-1 BLOCKER | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit with reason: 'stale...v1 epoch Go-port-coverage extracted to residual R-C (aura-plugins-2uauq)'. This is a review finding from the superseded v1 epoch. |
| `aura-plugins-v1b` | STALE | SLICE-2-REVIEW-B-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-wfhc` | STALE | FOLLOWUP_PROPOSAL-1: v3 follow-up cleanups + docs + test fixtures | Orphaned FOLLOWUP proposal from 2026-02-26 epoch. Depends on aura-plugins-q00q with no recent activity. Superseded by pasture Go port. |
| `aura-plugins-x36` | STALE | SLICE-5-REVIEW-C-1 MINOR | Python v1 code-review finding; parent epic 2tj closed 2026-05-30; awaiting sweep by residual n19wo |
| `aura-plugins-xqed` | STALE | SLICE-5-REVIEW-A-1 MINOR | Umbrella MINOR findings task from February 2026 (aura-plugins-82gp review round). Blocks on aura-plugins-9lqe (stale axis labels). No implementation changes; purely doc polish. Not pursued; epoch closed. |
| `aura-plugins-xui` | STALE | SLICE-5-REVIEW-A-1 MINOR | Parent epic aura-plugins-2tj force-closed 2026-05-30 during qzr8a audit; this is a review finding from the superseded v1 epoch. |
| `aura-plugins-y4l6` | STALE | SLICE-3-L2: Tests — template rendering for new sections | Python aura_protocol epoch shared-fragments L2 (tests). Part of Python-era v2 codegen work. Dependencies show DONE. Python epoch; superseded by Go pasture work. |
| `aura-plugins-yno` | STALE | SLICE-3-REVIEW-B-1 IMPORTANT | Python v1 code-review finding (check_all() incomplete); parent epic 2tj closed 2026-05-30; awaiting sweep by n19wo |
| `aura-plugins-z8ga` | STALE | FOLLOWUP: Non-blocking improvements from code review (aura-plugins-94yc Round 1) | 25+ findings from Python aura_protocol v2 schema-driven codegen review (created 2026-02-23). Go Pasture codegen has superseded Python codegen work; close as superseded. |
| `ckg0` | STALE | REQUEST: auractl rename + daemon concept + UAT follow-ups | REQUEST item for aurad-rename epoch. Implementation delivered (merged main 7f8f23c). Request never formally closed — stale Python-era work being abandoned for pasture. |
| `cyyk` | STALE | SLICE-4-REVIEW-A-1 IMPORTANT | SLICE-4 review finding (Reviewer A - IMPORTANT severity). Code implemented in workflow.py. SLICE-4 merged to main (7f8f23c). Review infrastructure artifact left unclosed — stale. |
| `nno9` | STALE | SLICE-4-REVIEW-A-1 MINOR | SLICE-4 review finding (Reviewer A - MINOR). Code implemented. Review task never closed after implementation — stale infrastructure. |
| `qrgx` | STALE | SLICE-2-REVIEW-A-1: aurad systemd service + aura-msg stub | SLICE-2 review collector task. Marked VOTE: ACCEPT. Code implemented (aurad-service.nix, aura-msg stub). Review done, task never closed — stale. |
| `r75e` | STALE | PROPOSAL-2: aurad rename + aura-msg stub (review fixes) | Ratified proposal (supersedes oz82). Implementation completed on main (7f8f23c). Proposal task never closed after delivery — stale. |
| `ta1k` | STALE | SLICE-3-REVIEW-A-1: Doc restructure (architecture + aurad + aura-msg) | SLICE-3 review collector task. Marked VOTE: ACCEPT. Docs updated (architecture.md, aurad.md, aura-msg.md exist on main). Review completed but task left open — stale. |
| `v1ak` | STALE | ALL-SLICES-REVIEW-B-1: aurad rename + aura-msg stub + protocol improvements | REVIEW collector task (Reviewer B) for SLICE-1/2/3/4/5 (aurad-rename epoch). Code implemented + merged to main (7f8f23c). All SLICE sub-tasks completed. Review work finished but never closed — Python era, superseded by Go pasture port per memory. |
| `vd4m` | STALE | REVIEW-C-1: aurad rename + aura-msg stub + protocol improvements | Reviewer C (Elegance axis) round-1 review for all 5 SLICE tasks. Code merged to main (7f8f23c). Review collector never closed — stale. |
| `vjsk` | STALE | IMPL_PLAN: aurad rename + aura-msg stub + protocol improvements | Implementation plan for aurad-rename epoch. All 5 SLICE tasks completed & merged to main (7f8f23c). Plan implementation finished but task left open — stale. |
| `wksc` | STALE | REVIEW-C-1 IMPORTANT | Reviewer C (Elegance axis) IMPORTANT findings collector for SLICE-1/2/3/4/5. Code implemented on main. Review never formally closed — stale. |
| `zldt` | STALE | SLICE-1-REVIEW-A-1: Rename worker→aurad + packaging + SQLite XDG | SLICE-1 review collector task. Marked VOTE: REVISE (but BLOCKER was fixed). Code implemented on main (7f8f23c). Review process done, task never formally closed — stale. |
| `zwty` | STALE | SLICE-1-REVIEW-A-1 MINOR | SLICE-1 review finding (MINOR). Code implemented. Review task left open — stale infrastructure. |
| `aura-plugins-220` | SUPERSEDED | REQUEST: Multi-agent orchestration schema-as-runtime | REQUEST delivered: aura_protocol v1 v0.4.3 (Python SoT) + pasture Go port v0.0.3; superseded by Go architecture; residuals R-A through R-E2 track verification |
| `aura-plugins-9wd6` | SUPERSEDED | PROPOSAL-1-REVIEW-A-1: aura-release dead code + test | Superseded by PROPOSAL-2 (pcs6); PROPOSAL-1 (po9n) replaced with ratified PROPOSAL-2 |
| `aura-plugins-at57` | SUPERSEDED | PROPOSAL-1-REVIEW-B-1: Un-skip 25 tests | Superseded by PROPOSAL-2 (aura-plugins-fl5p). Reviewer's REVISE finding (C-blocker-dual-parent kwarg) addressed in PROPOSAL-2 round. Epoch moved to PROPOSAL-2. |
| `aura-plugins-cgwc1` | SUPERSEDED | REQUEST: Port hand-authored skill body content from Python to Go SKILL.md files | REQUEST asks to port hand-authored body sections to Go SKILL.md. Work delivered in x5071 (PORT COMPLETE 2026-05-31); pasture/skills/* now contain full hand-authored sections (Beads Task Creation, etc.). REQUEST resolved by x5071 delivery. |
| `aura-plugins-f85gw` | SUPERSEDED | URD: Port skill bodies + protocol docs to Go (foundation) | Skill-body porting work superseded by x5071 (DONE 2026-05-31, 22/22 skills ported). Foundation 7-skill deliverable now consolidated into x5071 completion; f85gw split was tracking the 7+30 distinction but the 30-skill followup is already DONE. |
| `aura-plugins-lvsy` | SUPERSEDED | PROPOSAL-1-REVIEW-A-1: Un-skip 25 tests — Temporal sandbox + constraint violation combinatorial | Superseded by PROPOSAL-2 (aura-plugins-fl5p). PROPOSAL-1 findings addressed in PROPOSAL-2 revision round. Epoch moved to PROPOSAL-2. |
| `aura-plugins-m0gg` | SUPERSEDED | PROPOSAL-1-REVIEW-C-1: Un-skip 25 tests — Elegance axis | Superseded by PROPOSAL-2 (aura-plugins-fl5p). PROPOSAL-1 elegance concerns (_coerce_violation_args, _factory patterns) addressed in PROPOSAL-2. |
| `aura-plugins-nkx7` | SUPERSEDED | PROPOSAL-1: Un-skip 25 tests — Temporal sandbox + constraint violation combinatorial | Superseded by PROPOSAL-2 (aura-plugins-fl5p). PROPOSAL-1 received 3-reviewer findings requiring revision. Epoch continued to PROPOSAL-2, which was ratified and shipped. |
| `aura-plugins-oitf` | SUPERSEDED | PROPOSAL-1-REVIEW-B-1: aura-release dead code + test | Superseded by PROPOSAL-2 (pcs6); round-1 findings addressed in later proposal |
| `aura-plugins-po9n` | SUPERSEDED | PROPOSAL-1: aura-release reads pyproject.toml from wrong directory | Superseded by PROPOSAL-2 (pcs6); all PROPOSAL-1 findings addressed in ratified PROPOSAL-2 |
| `aura-plugins-ss87` | SUPERSEDED | PROPOSAL-1-REVIEW-C-1: aura-release dead code + test | Superseded by PROPOSAL-2 (pcs6); PROPOSAL-1 (po9n) replaced with ratified PROPOSAL-2 |
| `aura-plugins-xh675` | SUPERSEDED | ELICIT: Port skill bodies + protocol docs to Go | Child ELICIT of cgwc1 (REQUEST), superseded by x5071 delivery (2026-05-31). No ongoing work needed; architectural decisions codified in pasture codegen. |
| `aura-plugins-ygkp0` | SUPERSEDED | PROPOSAL-3: Port skill bodies + protocol docs to Go SKILL.md files | PROPOSAL-3 in cgwc1 chain, superseded by x5071 PORT COMPLETE (2026-05-31). Ratified proposal path completed via x5071's ported 22/22 skills. |
| `oz82` | SUPERSEDED | PROPOSAL-1: aurad rename + aura-msg stub + protocol improvements | Superseded by PROPOSAL-2 (r75e) which was ratified. Original proposal, replaced, never closed. |


### MIGRATE — real pasture-specific work → move to ~/codebases/dayvidpham/pasture tracker (16)

| ID | Category | Title | Reason |
|---|---|---|---|
| `aura-plugins-7p27w` | MIGRATE | SLICE-5-REVIEW-A-1 MINOR | Code review finding from pasture SLICE-5 (pasture/cmd/pasture-release). Review cycle findings should move to pasture repo for architectural/style decisions on that codebase. |
| `aura-plugins-awe1p` | MIGRATE | Pasture: dedupe flag-parsing block in cmd/pasture/task_crud.go | Pasture-specific code cleanup (handler refactoring); belongs in standalone pasture repo. |
| `aura-plugins-d2041` | MIGRATE | Flaky: TestRaceCrossSubsystem_FileBacked (internal/tasks) — SQLITE_BUSY/LOCKED under concurrency | Test flakiness in pasture/internal/tasks (SQLite concurrency race). Pasture-specific test infrastructure bug. Should move to pasture repo. |
| `aura-plugins-goz62` | MIGRATE | FOLLOWUP: Diff=true code path has zero test coverage | Pasture-specific test gap (internal/codegen/ Diff code path); belongs in standalone pasture repo. |
| `aura-plugins-gqzbv` | MIGRATE | q9sz9-MINOR-7: Consolidate specs_data_body_*.go into single file | Child of q9sz9 epic; pasture codegen consolidation (opposite of xzpnv file split); belongs in pasture repo tracker |
| `aura-plugins-i2n` | MIGRATE | FIX: Apply C-actionable-errors to all error messages in aura_protocol | IN_PROGRESS (P2). Targets Python aura_protocol (constraints.py, state_machine.py, interfaces.py, workflow.py). Go Pasture has its own error handling (StructuredError); migrate to pasture repo for Go-side work if applicable. |
| `aura-plugins-m656u` | MIGRATE | Pasture: replace hard-coded provenance replace path in go.mod | Pasture-specific work (go.mod dependency management); belongs in standalone pasture repo. This aura-plugins beads DB will be abandoned for pasture work. |
| `aura-plugins-oo359` | MIGRATE | Session hook: auto-load phase-context from Temporal SAs at session start | Real pasture feature work (session hook + Temporal SAs integration). Belongs in standalone pasture repo tracker, not aura-plugins. Development moved to ~/codebases/dayvidpham/pasture. |
| `aura-plugins-pc82r` | MIGRATE | Pasture: auto-resolve comment author from git config | Pasture-specific feature (pasture-msg CLI enhancement); belongs in standalone pasture repo. |
| `aura-plugins-punit` | MIGRATE | Unified 'where am I' status command (joins query state + events + timeline) | Real pasture feature work (status command spanning query/events/timeline). Belongs in standalone pasture repo tracker. Development moved to ~/codebases/dayvidpham/pasture. |
| `aura-plugins-qt23k` | MIGRATE | sync-versions marketplace writer alphabetizes/reorders JSON keys | Pasture-specific infrastructure bug (internal/release/version.go WritePluginVersion). Affects pasture marketplace.json handling. Should move to ~/codebases/dayvidpham/pasture. |
| `aura-plugins-tdmfw` | MIGRATE | IMPORTANT: x5071 introduced cross-skill ID collision rev-vote-options (divergent content) | Pasture codegen bug discovered during x5071 port (rev-vote-options behavior ID appears in both code-review + plan-review with different content). Root-cause design task is aoknb (local). Migrate this bug tracking + its linked design work (aoknb) to pasture repo. |
| `aura-plugins-tou3b` | MIGRATE | MINOR: Dead field, test helpers, documentation | 10 Go codegen MINORs (pasture/internal/codegen/); code cleanup belongs in standalone pasture repo. |
| `aura-plugins-xzpnv` | MIGRATE | chore: split golden 7 SkillBody vars out of specs_data_body.go for file-per-skill uniformity | Pasture codegen cleanup (specs_data_body.go refinement); x5071 follow-up in pasture/internal/codegen; belongs in standalone pasture repo tracker |
| `aura-plugins-yeym1` | MIGRATE | FOLLOWUP: Non-blocking improvements from pasture task CLI review | Real pasture CLI work (task CLI review findings). Belongs in standalone pasture repo tracker. Development moved to ~/codebases/dayvidpham/pasture. |
| `aura-plugins-z7k9l` | MIGRATE | Pre-existing: pasture flake.nix env.CGO_ENABLED vs derivation-arg conflict fails nix flake check | Pasture-specific infrastructure bug (pasture/flake.nix). Found during epoch work but orthogonal. Should move to ~/codebases/dayvidpham/pasture repo issue tracker. |


### VERIFY — audit/residual tasks whose target must be confirmed before closing (18)

| ID | Category | Title | Reason |
|---|---|---|---|
| `aura-plugins-ytzcl` | DONE | FOLLOWUP: Non-blocking improvements from Pasture code review | Work complete (all 8 child tasks done); placed §5-done. Pending verification task aura-plugins-0qrq1 filed; verify children addressed findings, then close. |
| `aura-plugins-0qrq1` | NEEDS_VERIFY | Verify ytzcl's 8 closed children addressed the Pasture-code-review findings, then close ytzcl | Residual from 3iz51 Phase-11 (ytzcl all 8 children done; verify-first pattern); ytzcl CANNOT close until verified; blocks ytzcl closure |
| `aura-plugins-3gxlt` | NEEDS_VERIFY | Verify C-frontmatter-refs is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: enforced at L2 (codegen metadata). Deferred to epic y5fps (CLI L4 machine-enforcement). Remains open. |
| `aura-plugins-41gqs` | NEEDS_VERIFY | Verify C-review-naming is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime. Deferred to epic y5fps (CLI L4 enforcement). Remains open pending implementation. |
| `aura-plugins-8giwl` | NEEDS_VERIFY | Verify C-dep-direction is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime. Deferred to epic y5fps (CLI L4 enforcement). Remains open pending implementation. |
| `aura-plugins-8mj6v` | NEEDS_VERIFY | Verify C-audit-never-delete is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime. Deferred to epic y5fps (CLI L4 enforcement). Remains open pending implementation. |
| `aura-plugins-c91i2` | NEEDS_VERIFY | Verify C-audit-dep-chain is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime. Deferred to epic y5fps (CLI L4 enforcement). Remains open pending implementation. |
| `aura-plugins-fkmwt` | NEEDS_VERIFY | Verify C-worker-gates is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed as verify-then-defer. Verdict: divergent (blocker gate present, quality gates absent). Deferred to epic y5fps (pasture#3). Remains open; close only when y5fps resolves enforcement approach. |
| `aura-plugins-gxdlh` | NEEDS_VERIFY | Verify C-clean-review-exit is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing (IMPORTANT gate not implemented). Deferred to epic y5fps (orchestrator FSM L5/L6). Remains open. |
| `aura-plugins-kfp41` | NEEDS_VERIFY | Verify C-supervisor-no-impl is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime, enforced at L1+L2 (codegen metadata). Deferred to epic y5fps. Remains open pending enforcement decision. |
| `aura-plugins-l0w6v` | NEEDS_VERIFY | Verify C-slice-review-before-close is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from Temporal runtime. Deferred to epic y5fps (CLI L4 enforcement). Remains open pending implementation. |
| `aura-plugins-lwm3m` | NEEDS_VERIFY | Verify C-max-review-cycles is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from Temporal. Deferred to epic y5fps (orchestrator FSM gate L5/L6 completion). Remains open. |
| `aura-plugins-nnnzg` | NEEDS_VERIFY | Verify C-proposal-naming is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime. Deferred to epic y5fps (CLI L4 enforcement). Remains open pending implementation. |
| `aura-plugins-oeufm` | NEEDS_VERIFY | Verify C-slice-leaf-tasks is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: enforced at L2 (codegen ensures ≥1 leaf task). User note: 'L1/L2/L3 is illustrative not fixed'. Remains open pending final disposition. |
| `aura-plugins-p2nq2` | NEEDS_VERIFY | Verify C-blocker-dual-parent is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime. Deferred to epic y5fps (CLI L4 enforcement). Remains open pending implementation. |
| `aura-plugins-rfqkm` | NEEDS_VERIFY | Verify C-agent-commit is enforced by its intended layer (hook/SKILL.md/schema/codegen/runtime) — mh4ek gap-vs-design | mh4ek audit Phase-11 UAT reframed. Verdict: missing from runtime (codegen metadata only). Deferred to epic y5fps (Claude Code PreToolUse hook L5). Remains open. |
| `aura-plugins-t70aw` | NEEDS_VERIFY | Verify rk2su's 9 closed children addressed the original ACP-wiring findings, then close rk2su | 3iz51 Phase-11 verification task (residual from 3iz51 escalation). Gating rk2su closure (which blocks ow0pq). Verify ACP-WIRING-REVIEW A/B/C findings actually resolved before closing rk2su umbrella epic. Check: all 9 child tasks done ✓, verify their findings addressed original targets. |
| `aura-plugins-vji97` | NEEDS_VERIFY | Investigate Go constraint enforcement: is 'no RuntimeConstraintChecker' a decided design or a gap? | mh4ek Phase-11 investigation task. Deferred to verify whether Go's missing C-* constraints are by-design (enforced at different layer) or implementation gaps. Phase-11 UAT found constraints enforced at L1 (skill prompt) + L2 (codegen) not L5/L6 (runtime). vji97 remains as verification task pointer to deferred epic aura-plugins-y5fps. |


### DEDUPE — covered by another task (1)

| ID | Category | Title | Reason |
|---|---|---|---|
| `aura-plugins-cgct` | DUPLICATE | MINOR: __init__.py docstring shows stale query_audit_events(epoch_id, phase) — missing role parameter | Duplicate of aura-plugins-gtbu (identical issue, same file, same epoch). Both from closed FOLLOWUP epic hgki. |


### KEEP — genuine pending aura-plugins-side work (71)

| ID | Category | Title | Reason |
|---|---|---|---|
| `aura-plugins-026c1` | ACTIVE | MINOR: x5071 port dropped non-normative illustrative content from 3 skills | x5071 port finding (epoch/research/status skills); non-binding documentation loss; tracked in pasture GitHub residuals #4 |
| `aura-plugins-0e7ej` | ACTIVE | R-B: Verify supervisor-rework (q72mt R1-R7) captured in Go codegen | Coverage residual from qzr8a audit. Verify supervisor-rework URD (q72mt) is fully captured in Go codegen. Anchored on fzctk. Priority 3, open. |
| `aura-plugins-0ou9f` | ACTIVE | R-D: Verify v2 schema-driven codegen (gen_schema/gen_skills/gen_agents) Go-coverage | Coverage residual from qzr8a audit. Verify schema-driven codegen (Python gen_schema/gen_skills) coverage in Go. References 5wbhm/fzctk. Priority 3, open. |
| `aura-plugins-1dos9` | ACTIVE | R-E1: Verify aura-swarm URD (1nla) R1-R11 deliverables present in Python aura-swarm | Coverage residual from qzr8a audit. Verify Python aura-swarm (no Go side) has all URD R1-R11 deliverables from 1nla. Priority 3, open. |
| `aura-plugins-2uauq` | ACTIVE | R-C: Verify Python aura_protocol v1 (state machine + Temporal + constraints) ported to Go | Coverage residual from qzr8a audit. Verify aura_protocol v1 core (state machine, Temporal, constraints) is ported to Go pasture. Carries constraint-subquestion → mh4ek. Priority 3, open. |
| `aura-plugins-3jjt` | ACTIVE | FOLLOWUP-REVIEW-A-1 MINOR | Review finding on FOLLOWUP epic z8ga (still open, P3); real correctness findings on gen_schema.py |
| `aura-plugins-40ujq` | ACTIVE | R-A: Verify aurad+aura-msg Go-coverage in pastured/pasture-msg | Coverage residual from qzr8a audit. Verify aurad+aura-msg Go coverage (bwfqm R1-R15 + tf45a + u3ae0 slices + 7vtb R1/R3/R5/R6). Priority 3, open. |
| `aura-plugins-47zju` | ACTIVE | q9sz9-MINOR-5: ExtractSection double-walk (negligible perf) | Child of q9sz9 epic; non-blocking pasture MINOR from code review; performance/elegance cleanup |
| `aura-plugins-4wcp` | ACTIVE | FIX: Complete PROCESS.md cycle exit conditions table | Genuinely missing: PROCESS.md:659-663 has 3 rows, supervisor/SKILL.md:298-303 has 4 (missing 'escalate' row) |
| `aura-plugins-5h31p` | ACTIVE | MINOR group — SLICE-1 review (cosmetic + clarifying) | SLICE-1 shared-fragments review MINOR; feeds into u3z4m epic; aura-plugins side |
| `aura-plugins-63f` | ACTIVE | REQUEST: Unified standing research team for architect and supervisor roles | User request (verbatim, 2026-02-22) to unify architect+supervisor research teams. Real work item; affects skills/architect/SKILL.md, skills/supervisor/SKILL.md, schema.xml role definitions; scope documented. |
| `aura-plugins-64mld` | ACTIVE | ROADMAP §1+§0: Reframe v1/v2/v3/v4 across CLAUDE.md + architecture.md + aurad.md + aura-msg.md (Q3b+Q8) | Real cross-doc reframing work. Reframe v1/v2/v3/v4 version model across multiple docs (Q3b+Q8). Blocks e86ea. Priority 3, open. |
| `aura-plugins-6knah` | ACTIVE | SLICE-3 review MINORs: unused AppendMarkers + unquoted YAML description | SLICE-3 review finding; part of pasture-plugin epic (aura-plugins-9aztn) |
| `aura-plugins-6l5yo` | ACTIVE | ROADMAP §2g: Graduate git_recorder.go from stub to production (Q3a) | Real pasture work: graduate git_recorder.go from stub to production in pasture. Should MIGRATE to standalone pasture tracker, not stay here. Priority 3, open. |
| `aura-plugins-6ujr` | ACTIVE | EPIC: aura-acp plugin — ACP integration for protocol engine | Deferred epic (ACP R13-R17). Blocked on Claude Code native ACP support; label aura:epic-deferred. DESCOPED from ow0pq per Phase-11 (no longer blocking jbnx3 closure). Low priority, not abandoned. |
| `aura-plugins-7dq08` | ACTIVE | Gap: ReviewCycleRecord structured type for tracking review iterations | Genuine pending work on aura-protocol side. From closed UAT-2 revisions requirement (PROPOSAL-10 R2-8); Go port needs this structured type for supervisor tracking. |
| `aura-plugins-7j072` | ACTIVE | pasture-release sync-versions: also reconcile cross-repo marketplace entries | IN_PROGRESS (P2, created 2026-06-04). User directive to extend sync-versions for marketplace reconciliation. Manual fix applied (pasture marketplace bumped 0.0.1→0.0.2 on main 3c78b46); feature work in-flight. |
| `aura-plugins-7u4sg` | ACTIVE | wftdf-MINOR-3: Update AGENTS.md to document Go test paradigm (testdata/, testutil.LoadFixtures, FixtureName) | Child of wftdf epic; aura-plugins AGENTS.md documentation update; non-blocking MINOR |
| `aura-plugins-954g` | ACTIVE | FOLLOWUP: A2A-compliant runtime for ProcedureStep FSM | Deferred from z8ga epic as 'separate feature'; discovered during UAT; real work item for A2A protocol compliance; tracked separately from v2 codegen. |
| `aura-plugins-9aztn` | ACTIVE | FOLLOWUP: pasture-plugin epic — non-blocking review MINORs | Epic aggregating plugin review findings; children exist (6knah, fjazf, esqny, r06zs); pasture-specific work, will migrate to standalone pasture repo |
| `aura-plugins-9wdwc` | ACTIVE | EPIC: Beads -> provenance integration — how pasture uses provenance + provenance<->Temporal | Deferred epic for pasture architecture (re-scoped Phase-11: Beads→Temporal became Beads→provenance). Scope TBD; label aura:epic-deferred. Does not block ow0pq per 3iz51 (§2-active, ROADMAP §2q). |
| `aura-plugins-alu1w` | ACTIVE | ENHANCEMENT: cross-referencable fragment marker (render reference, not inline) | Feature enhancement from shared-fragments Phase-11 UAT; non-blocking; aura-plugins side (not pasture); part of thune REQUEST |
| `aura-plugins-aoknb` | ACTIVE | design: enforce global ID uniqueness + shared-fragment mechanism for SkillBody Sections/Behaviors | Design task for pasture codegen. Root-cause analysis of rev-vote-options ID collision (tdmfw). Part of h74rn/aoknb/tdmfw refactoring triad. Active, needed to address golden debt before further skill ports. |
| `aura-plugins-b5cp` | ACTIVE | Migrate dolt data directory to managed location | Part of open beads Dolt backend epic (aura-plugins-l6z1). Real infrastructure work item; depends on completed leaf task aura-plugins-ojl8 (HM modules). Actionable: requires stopping dolt server + moving ~/dotfiles/.beads/dolt/ → ~/.beads/dolt/. |
| `aura-plugins-c1du1` | ACTIVE | q9sz9-IMPORTANT-1: Replace deprecated goldmark API c.Text(src)->c.Value(src) (markdown.go:246,248 + mdtest_helpers_test.go:60,62) | Child of q9sz9 epic; pasture dependency upgrade IMPORTANT; deprecated goldmark API replacement |
| `aura-plugins-cmvu5` | ACTIVE | FOLLOWUP-ROADMAP: PROPOSAL-2 deferred items + smoke-test infrastructure gaps | Real tracker epic. Aggregates smoke-test gaps (Temporal E2E, hooks E2E, git-discipline soak, crash binary CI) + deferred roadmap items (pasture-msg unify, skill-bodies bd→task, replication, provenance evolution). Not a blocker for ow0pq. Priority 3, open. |
| `aura-plugins-coac` | ACTIVE | FOLLOWUP-REVIEW-C-1 IMPORTANT | Review finding on FOLLOWUP epic z8ga (still open, P3); real IMPORTANT findings (SubstepType enum usage, DRY violations) |
| `aura-plugins-e46nw` | ACTIVE | q9sz9-MINOR-4: subSkillDirKey has no dedicated unit test (covered transitively) | Child of q9sz9 epic; pasture test-coverage documentation; non-blocking MINOR |
| `aura-plugins-e86ea` | ACTIVE | ROADMAP refresh: post-URE updates to docs/ROADMAP.md (consolidator) | Real doc-update work. Consolidates §5/§2/§0 changes (figures-pipeline, R7 polyrepo, multi-vendor, pkg/protocol cross-consumption, v1/v2/v3/v4 reframing). Depends on 64mld. Priority 3, open. |
| `aura-plugins-esqny` | ACTIVE | SLICE-5 MINOR: tag-failure rollback comment overstates behavior | SLICE-5 review finding; non-blocking MINOR; part of ongoing pasture-plugin epic (aura-plugins-9aztn) |
| `aura-plugins-f59jc` | ACTIVE | FOLLOWUP: Non-blocking improvements from Phase 10 code review (PROPOSAL-2 epic) | Real FOLLOWUP epic aggregating Phase 10 Round 1 code-review findings (IMPORTANT + MINOR). Non-blocking per C-followup-lifecycle. References REQUEST j9c88, URD dr2ps, IMPL_PLAN eauj6. Priority 3, open. |
| `aura-plugins-f89mx` | ACTIVE | R-E2: Verify aura-release URD (99q/s7l0) in Python + pasture-release Go has no path-bug | Coverage residual from qzr8a audit. Verify aura-release URD (99q FR/NFR + s7l0 path-fix) in Python AND pasture-release Go has path-bug fixed. Priority 3, open. |
| `aura-plugins-fjazf` | ACTIVE | SLICE-4 review MINOR: marketplace em-dash encoding + pasture description normalization | SLICE-4 review finding; feeds into pasture-plugin epic (aura-plugins-9aztn) |
| `aura-plugins-fkmj` | ACTIVE | FOLLOWUP-REVIEW-B-1 MINOR | Review finding on FOLLOWUP epic z8ga (still open, P3); real test-quality findings on gen_* modules |
| `aura-plugins-fs107` | ACTIVE | ad8i1: verify which of the 8 'IMPORTANT' UAT-review findings apply to the Go port (Pasture), file Go-side, close Python-obsolete | Residual from 3iz51 Phase-11 re-place; ad8i1's findings target deprecated Python (aura-msg/formatters/config); verify/file Go-side or close Python obsoletes; R-A coverage theme |
| `aura-plugins-g8egz` | ACTIVE | File the skill-drift CI check for the 8 overlapping skills (ROADMAP §1i, never filed) | Real work: create CI check for skill-drift across 8 overlapping skills (ROADMAP §1i). Referenced but never filed as task. Priority 3, open. |
| `aura-plugins-h74rn` | ACTIVE | URD: shared context fragment management (Go codegen) | Go pasture codegen work. Scoped for shared-fragment mechanism to deduplicate behavior/section IDs across skills. Discovered from x5071; active pasture work. Part of aoknb/tdmfw/h74rn triad addressing codegen debt. |
| `aura-plugins-hd0ho` | ACTIVE | wftdf-MINOR-1: want_stderr_contains naming misleading (pasture-release cli_smoke.yaml merges stdout+stderr) | Child of wftdf epic; pasture-release test naming clarity; non-blocking MINOR |
| `aura-plugins-iab2f` | ACTIVE | x5071-REVIEW-r1 MINOR findings | x5071 port code review MINORs; tracked in pasture GitHub residuals #4; aura-plugins side (tracking the Go port review findings) |
| `aura-plugins-icrfz` | ACTIVE | Release flow under PR-protected main: tag-on-merge CI + PR-friendly pasture-release | IN_PROGRESS (P2, created 2026-06-06). Implemented in PR #10 with tag-on-merge CI. Blocked on user provisioning repo secrets (RELEASE_APP_ID + RELEASE_APP_PRIVATE_KEY); not stale, actively managed. |
| `aura-plugins-ijcfk` | ACTIVE | Cleanup: rename 'providence' -> 'provenance' misnomer across labels + ROADMAP frontmatter + §0 prose + memory | Residual from 3iz51 Phase-11 terminology correction; terminology cleanup (providence→provenance per PROV-O shipped replacement); affects bd labels + ROADMAP prose + supervisor memory |
| `aura-plugins-ikgp` | ACTIVE | FOLLOWUP_URE: Scope follow-up for schema-driven protocol engine v2 | Deferred from z8ga epic as 'lifecycle task'; real work item to scope 14 IMPORTANT findings (type consistency, test coverage, elegance, silent failures) for possible follow-up work. |
| `aura-plugins-ikqvh` | ACTIVE | q9sz9-MINOR-3: Extract SkillBodySpecs save/restore into shared test helper | Child of q9sz9 epic; pasture test refactoring; non-blocking MINOR |
| `aura-plugins-infkn` | ACTIVE | q9sz9-IMPORTANT-2: Mutable global SkillBodySpecs in tests — extract save/restore helper or use local copy | Child of q9sz9 epic; pasture test correctness IMPORTANT; mutable global state test-isolation issue |
| `aura-plugins-jbnx3` | ACTIVE | URD: Pasture — Go port with ACP, observability, and polyrepo marketplace | Foundational URD for pasture epic. Still blocks ow0pq (jbnx3 closure triage). Needed to keep open until ow0pq closure workflow completes. |
| `aura-plugins-jyaii` | ACTIVE | q9sz9-MINOR-1: Remove dead lineEnd struct field (markdown.go:138) | Child of q9sz9 epic; pasture code cleanup; non-blocking MINOR |
| `aura-plugins-k637` | ACTIVE | FOLLOWUP-REVIEW-C-1 MINOR | Review finding on FOLLOWUP epic z8ga (still open, P3); real nits on gen_schema.py minor code quality |
| `aura-plugins-kv0od` | ACTIVE | ROADMAP §2m (NEW): Multi-vendor extensibility — OpenCode / Codex / Gemini / Antigravity | Real ROADMAP doc item. New row for multi-vendor extensibility (OpenCode/Codex/Gemini/Antigravity). Part of 3iz51 audit edits. Priority 3, open. |
| `aura-plugins-l6z1` | ACTIVE | Beads Dolt backend: import, fixes, and NixOS integration | EPIC tracking beads Dolt infrastructure. 5 of 7 subtasks completed (pz9x, ojl8, 77q6, pzq9, qlnr); 2 open (b5cp, m4i3). Real infrastructure work with actionable scope. |
| `aura-plugins-lxlil` | ACTIVE | Gap: supervisor skill missing autonomous progression documentation | aura-protocol side work on skill generation. From closed supervisor rework (aura-plugins-rrisd) requirement 5; Go codegen needs to document user-gated vs autonomous phases. |
| `aura-plugins-m4i3` | ACTIVE | Upstream getStore() fix to beads repo | Part of open beads Dolt backend epic (aura-plugins-l6z1). Real infrastructure work item; depends on completed leaf task aura-plugins-pz9x (beads fix). |
| `aura-plugins-n19wo` | ACTIVE | R-F: Sweep ~30 stale open sub-tasks orphaned by qzr8a closures | Genuine residual work from qzr8a audit; ~30 stale Python-era sub-tasks need sweep. discovered-from qzr8a (closed 2026-05-30). Not an ow0pq blocker but real cleanup work. |
| `aura-plugins-n856x` | ACTIVE | 6ujr R16/indexer: adopt acp-go-sdk ContentBlock/SessionUpdate types + indexer cleanup (replace ~320 lines brittle parsing) — LOW PRIO | Residual from 3iz51 Phase-11 split (6ujr descoped from ow0pq); harness-independent; low-priority nice-to-have; pasture ACP integration refinement |
| `aura-plugins-nnpjm` | ACTIVE | ELICIT: URE for aura-plugins-6l5yo — graduate git_recorder.go from stub | Go pasture work. ROADMAP item requesting URE for graduating git_recorder.go from stub. Linked to 6l5yo. Active, needed for pasture provenance/audit trail. |
| `aura-plugins-ow0pq` | ACTIVE | jbnx3 closure triage — re-walk R1–R7 after cmvu5 visibility audits + peer epics land | Closure triage for jbnx3 (pasture epic). Blocks on x5071, rk2su, 6ujr landing. x5071 done (2026-05-31), rk2su pending verification (t70aw), 6ujr descoped from ow0pq in Phase-11. Still open waiting for rk2su verification + final closure coordination. |
| `aura-plugins-oy9s7` | ACTIVE | URD: h2zd9 pkg/protocol cross-module consumption spec | Go pasture work. URD for cross-module consumption spec (pasture/pkg/protocol). Part of h2zd9 audit wave-3. Active, linked to PROPOSAL-2 execution plan. |
| `aura-plugins-p87cs` | ACTIVE | wftdf-MINOR-2: Config subtests missing t.Parallel() (viper_test.go) | Child of wftdf epic; pasture test optimization; non-blocking MINOR |
| `aura-plugins-pj4wo` | ACTIVE | q9sz9-MINOR-6: ReplaceBodyRegion string-vs-line approach (justified) | Child of q9sz9 epic; pasture code design note; non-blocking MINOR |
| `aura-plugins-q9sz9` | ACTIVE | FOLLOWUP: Non-blocking improvements from codegen body integration review | aura-protocol side follow-up. 2 IMPORTANTs + 7 MINORs across 9 child tasks; does not block ow0pq per 3iz51 audit (placed §2-active, ROADMAP §2n). |
| `aura-plugins-r06zs` | ACTIVE | SLICE-2 review MINORs: guard-test comment cleanups | SLICE-2 review finding; part of pasture-plugin epic (aura-plugins-9aztn) |
| `aura-plugins-rk2su` | ACTIVE | FOLLOWUP: ACP wiring non-blocking improvements | Pending verification before closure. All 9 child tasks done; umbrella still blocks ow0pq per 3iz51 decision B. Verification task aura-plugins-t70aw filed; stay OPEN until verified + closed. |
| `aura-plugins-t7x6e` | ACTIVE | Remove hardcoded C-* constraint count from aura-plugins/CLAUDE.md (+ check other docs) | Residual from mh4ek Phase-5 UAT decision C; remove volatile hardcoded constraint count (26→27 NOT done; remove entirely per user); affects CLAUDE.md + schema.xml + AGENTS.md |
| `aura-plugins-t8r49` | ACTIVE | q9sz9-MINOR-2: Proposal says 11 fields but impl has 13 (doc only) | Child of q9sz9 epic; proposal documentation drift; non-blocking MINOR |
| `aura-plugins-u3z4m` | ACTIVE | FOLLOWUP: Non-blocking MINOR findings from shared-fragments code review | Epic aggregating shared-fragments Phase-11 review findings; aura-plugins side (not pasture); thune REQUEST followup |
| `aura-plugins-vqur` | ACTIVE | SLICE-3-REVIEW-C-1 IMPORTANT | Depends on FIX (4wcp) which is genuinely outstanding; PROCESS.md table incomplete |
| `aura-plugins-wftdf` | ACTIVE | FOLLOWUP: Non-blocking improvements from Go test paradigm code review | aura-protocol side follow-up. 3 MINORs outstanding (want_stderr_contains naming, t.Parallel(), AGENTS.md update); 4 child tasks. Does not block ow0pq per 3iz51 audit (§2-active, ROADMAP §2o). |
| `aura-plugins-wkbc3` | ACTIVE | wftdf MINOR-4: Python aura<->Go pasture test-contract parity audit (Go fixtures cover same behavioral contracts as Python YAML) | Residual from 3iz51 Phase-11 cross-check (3iz51 audit missed it in comments); parity-audit theme; R-C family (Go coverage verification) |
| `aura-plugins-x45ho` | ACTIVE | PROV-O activities table never populated — workflow missing StartActivity/EndActivity calls | Pasture Temporal workflow bug. Discovered during cn5ax E2E smoke. Activities table never gets populated because no workflow calls StartActivity/EndActivity. Active bug in pasture, needed for provenance auditing. |
| `aura-plugins-x6gb` | ACTIVE | FOLLOWUP: Mandate YAML frontmatter in bd task descriptions and handoff docs | Deferred from z8ga epic as 'process improvement'; discovered during UAT (aura-plugins-sm9c); real work item about schema-driven documentation standardization. |
| `aura-plugins-y5fps` | ACTIVE | EPIC: Machine-enforce protocol constraints in pasture (CLI+hooks+FSM) — deferred from mh4ek | Deferred constraint enforcement epic from mh4ek Phase-11 UAT (14 constraints); pasture GitHub issue #3; L4 CLI + L5/L6 FSM completions; near-term driver is skill+bd path per user architecture decision |
| `aura-plugins-yivi2` | ACTIVE | EPIC: fzctk codegen-fidelity fixes (supervisor/worker SKILL.md) | Epic aggregating fzctk audit distortion fix (1 child 9e42d done); Ride-the-Wave Stage 2 worker-spawn command defect; one dependent SLICE-5-REVIEW on this (7p27w blocks it) |


### Appendix — ID lists (for scripted action after sign-off)

**CLOSE (205):**

```
f85gw xh675 ygkp0 cgwc1 thm2d 6wqht j82qd 0gns 0hmi szw8 7m29 loq9 y4l6 msfq oa70 1gqh g6yl kez2 fs7g 2wzn tmjs moot 2onu ni3n 1mll e1z2 prs2 70yh q413 ul1o lybp fl5p at57 lvsy m0gg nkx7 iv5j 18zp v3yv p2kp mvfw kqtf yjwc zhre 9lqe xqed 82gp ip41 ib09 p4fb v1ak cyyk nno9 6m2m ta1k qrgx oqw9 zwty 6btj zldt ishd 8uc1 1ma7 ltcs 2kv1 qz5b 83sn wksc vd4m vjsk r75e oz82 ckg0 rwg8 0fmy wrfs ho6x mj69 2y3s jjy8 9g9r i491 gtbu l1lk 6p08 ltvf 7vzp uvgb qy79 192h cyc2 wfhc 46yx lvm7 cq1o a0x0 90s0 5r4v mdyr qrm4 odb3 9mch 82ya.2.1 82ya.2 2j4v.3.1 2j4v.3 9suu.1.1 9suu.1 3tfg ui9d 3zs8 ehy0 msfr msfr rgos zn6o bl50 ghxm 7iy2 lnce 2cl4 14lr 9m27 umye pcs6 9wd6 oitf ss87 mz34 udj3 3dyw a6r9 59fg nzx3 x7k5 ct01 n93g po9n tt57 gyzs 0qlw 4gx1 r5kx ai2x 5n2l sfr0 v015 j02 r8f 3xe xui hls 7d2 ngd qqf jwb sk6 68o bnr dvi 3m4 4u1 4hu eqy 5zf lkk ipj n0n 0yd yno 1ic tcn in8 v1b r8m o83 8jy gdx x36 utj 947 pxo 295 don h7x 220 6yr nfr jjo e19 bch 5sn 1bm 1ey wux wqw j2k 6lyb9 qkopt 6skbw ad8i1 0yuk klac z8ga x5071
```

**MIGRATE (16):**

```
qt23k z7k9l 7p27w d2041 tdmfw xzpnv gqzbv oo359 punit yeym1 m656u awe1p pc82r tou3b goz62 i2n
```

