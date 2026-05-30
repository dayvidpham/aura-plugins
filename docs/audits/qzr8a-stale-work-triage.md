---
name: qzr8a stale-work triage — T-A1 draft artifact
status: INTERIM — ALL 18 VERDICTS PENDING USER SIGN-OFF — NOTHING EXECUTED
audit_task: aura-plugins-qzr8a
elicit_ure_uat: aura-plugins-7a8nu
ratified_plan: docs/proposals/PROPOSAL-1-audit-qzr8a.md
meta_plan_section: "PROPOSAL-2 §5.2 (Triage)"
wave: 1
phase: 9 (verdict complete; awaiting all-18 user sign-off before execution)
---

# `qzr8a` stale-work triage — T-A1 triage table

> **INTERIM — ALL 18 VERDICTS PENDING USER SIGN-OFF — NOTHING EXECUTED.**
>
> Per PROPOSAL-1 §8 (ratified, Phase-5 UAT refinement): all 18 items have been
> verdicted. No closes, no residual filings, no bd comments on source items, no
> ROADMAP edits have been executed. The all-18 pause is now active. The
> coordinator will present this table to the user via team-lead and await
> sign-off (or per-item revisions via the rejection loop) before executing.

---

## T-A1: Verdict table

| Bucket | ID | Title (short) | Verdict | Reason | Proposed residual (if extract-residual) |
|--------|----|---------------|---------|--------|------------------------------------------|
| A | oqhjg | REQUEST: Implement aurad + aura-msg | close-superseded | Python aurad+aura-msg implementation was completed (bin/aurad.py + bin/aura-msg exist); Go port (pastured + pasture-msg) is now canonical runtime per naupi migration. Python work fully superseded. | — |
| A+B | bwfqm | URD: aurad + aura-msg implementation | close-superseded | URD ratified and fully executed across PROPOSAL-5/7/8/9/10 lifecycle; Go Pasture (pastured + pasture-msg + hooks/scripts/session-register.sh) delivers R1–R15 + UAT amendments at Go fidelity. No uncovered requirement. | — |
| A | fw1cx | PROPOSAL-5: aurad+aura-msg review fixes | close-superseded | Python PROPOSAL document; ratified and executed in Python era. Go port supersedes as canonical implementation. Correctness/test-quality fixes (D20–D24) are covered at Go layer. | — |
| A | u3ae0 | IMPL_PLAN: aurad+aura-msg 7-slice plan | close-superseded | Python-era implementation plan; superseded by Go Pasture (pastured + pasture-msg) as canonical runtime per naupi. IMPL_PLAN never executed in Python; Go epoch covered the full scope via PROPOSAL-2 epic (aura-plugins-wab79). | — |
| A | odasf | PROPOSAL-6: UAT revision — StrEnums, --format, SA dual-write, dev workflow | close-superseded | Python PROPOSAL document; superseded-before-completion (rev cycle never ratified to impl). All requirements folded into Go Pasture implementation (OutputFormat enum, SA dual-write, StrEnum types all present in Go types). | — |
| A | lczzv | PROPOSAL-7: UAT-2 revisions stub | close-superseded | Python PROPOSAL stub, explicitly superseded by PROPOSAL-8 (ytj66) per its own comment; never ratified. Superseded in Python era, Go era makes further Python proposals moot. | — |
| A | ytj66 | PROPOSAL-8: UAT-2 revisions (fleshed out) | close-superseded | Python PROPOSAL; depends on PROPOSAL-9 (aura-plugins-2fefg, CLOSED) and was superseded by the PROPOSAL-9/10 ratification path. Go Pasture implements D38–D45 natively. | — |
| A | 3ubig | REQUEST: Rework supervisor role | close-superseded | Work completed: agents/supervisor.md exists (opus, restricted tools), cartographers removed, clean-review exit enforced in supervisor/SKILL.md, PROCESS.md, schema.xml. Request fully satisfied. | — |
| A | v2a51 | ELICIT: Rework supervisor role | close-superseded | Elicitation completed; all 6 URE rounds answered and captured in URD q72mt. Superseded by completion of the downstream work. | — |
| A | q72mt | URD: Rework supervisor role (SPECIAL ATTENTION — see §SA below) | close-superseded | R1–R7 all delivered: (R1) cartographers removed from all protocol files; (R2) agents/supervisor.md created with correct tools + model=opus; (R3) clean review exit (0 BLOCKERs + 0 IMPORTANTs) enforced in SKILL.md + PROCESS.md; (R4) worker-persistence documented; (R5) autonomous progression rules in place; (R6) verbatim URD pattern established; (R7) atomic commit guidance present. PROPOSAL-3 (aura-plugins-0dai6) was closed "stale: Python-era" but the protocol *changes* it specified were implemented (gen_agents.py exists, agents/*.md generated). No uncovered residual against R1 ("Port aurad"). | — |
| B | 2tj | EPIC: aura_protocol v1 followup | close-superseded | Epic marked "FOLLOWUP epic complete" in its own comment (2026-02-22 17:23): all 4 slices implemented, code reviewed, Impl UAT ACCEPT, 554 tests pass. Work done; task left open administratively. Closure reason: completed. | — |
| B | o7i9 | URD: Un-skip 25 tests | close-superseded | Impl UAT ACCEPT per comment (2026-03-03 09:30): 4 Temporal sandbox tests pass, 20 constraint violation tests pass, final suite 1431 passed / 1 skipped. Work done; task left open administratively. Closure reason: completed. | — |
| B | 7vtb | URD: aurad rename + aura-msg stub + protocol improvements | close-superseded | Python-era URD predating the Go port decision. Requirements R1 (rename bin/worker.py → bin/aurad.py), R3 (SQLite default), R5 (aura-msg stub), R6 (doc restructure), R7–R9 (workflow signals, ReviewAxis, constraint fixture) were all delivered in Python and/or superseded by Go. | — |
| B | e28b | FOLLOWUP_URD: schema-driven protocol engine v2 follow-up | close-superseded | URD stub; its parent FOLLOWUP epic (aura-plugins-z8ga) and original URD (aura-plugins-w07o) are the schema-driven codegen that became gen_schema.py + gen_skills.py + gen_agents.py (all delivered and frozen in Python; Go codegen is canonical). This URD was never populated ("Scope: [Filled after FOLLOWUP_URE completes]") — vestigial stub from an incomplete protocol cycle. Superseded. | — |
| B | s6i | FOLLOWUP_URD: aura_protocol v1 follow-up | close-superseded | URD has Impl UAT ACCEPT comment (2026-02-22 17:22): refinements applied, 554 tests pass. Work done; task left open administratively. Closure reason: completed. | — |
| C | 1nla | URD: Unified aura-swarm (SPECIAL ATTENTION — see §SA below) | close-superseded | R1–R11 all delivered in current aura-swarm: (R1) bin/aura-parallel is a deprecation wrapper delegating to aura-swarm start --swarm-mode intree; (R2) --swarm-mode {worktree,intree} implemented; (R3) --tmux-dest {session,window}; (R4) XDG_STATE_HOME state dir; (R5) YAMLSessionRegistry with all listed fields; (R6) permission inheritance via detect_parent_permission(); (R7) registry lifecycle (write-on-launch + lazy cleanup); (R8) unified start subcommand; (R9) mode-aware subcommands; (R10) skills/parallel deprecated, skills/swarm canonical; (R11) Nix packaging updated. aura-swarm is a Python tool retained outside Pasture scope. Closure reason: completed. | — |
| C | 99q | URD: Release automation (aura-release) | close-superseded | FR-1 through FR-5 + NFR-1 through NFR-4 all delivered: bin/aura-release exists (1000+ lines), implements version bump, consistency check (--check/--sync), CHANGELOG generation, git commit, annotated tag, dry-run, atomic rollback, registry subcommand. Pasture counterpart (pasture-release) also delivered Go-native equivalent. Closure reason: completed. | — |
| C | s7l0 | URD: aura-release reads pyproject.toml from wrong directory (SPECIAL ATTENTION — see §SA below) | close-superseded | Both requirements delivered: (1) dead code removed — _discover_repo_root(), REPO_ROOT, VERSION_FILES are absent from bin/aura-release (confirmed by grep); (2) regression tests Cases A–D exist in tests/test_aura_release.py (subdirectory-pyproject discovery, version-key filter, both-root-and-subdir, no-version-key). pasture-release independently has `subdirs: true` in its scanSpecs (version.go). No carry-over needed. Closure reason: completed. | — |

---

## §SA: Special-attention item findings

### q72mt — "Rework supervisor — maybe covered by Pasture"

**Finding: COVERED, no residual required against R1.**

Evidence:
- `agents/supervisor.md` exists, frontmatter: `model: opus`, `thinking: medium`, tools list = Read, Glob, Grep, Bash, Skill, Agent, Task (no Edit, Write, NotebookEdit). Matches R2 + UAT revision U1 exactly.
- `skills/supervisor/SKILL.md` contains "CLEAN REVIEW = 0 BLOCKERs + 0 IMPORTANTs" and "Ride the Wave (Rewritten)" section — R3 and R4 delivered.
- `scripts/aura_protocol/gen_agents.py` exists — R2 UAT component (U5: generated agents/*.md) delivered.
- Cartographers: no references found in supervisor/SKILL.md (grep returned zero hits) — R1 delivered.
- Autonomous progression rules: R5 (user-gated phases list) present in SKILL.md.
- Note: There is a 208-line diff between the Python gen_skills.py output and the Go codegen output for supervisor/SKILL.md (documented in PYTHON_TO_GO_MIGRATION.md). This is *structural template drift*, already tracked by `aura-plugins-fzctk` (§1j supervisor+worker fidelity audit). It is NOT a new residual against q72mt's R1–R7.

**Verdict: close-superseded (work was delivered; task tracking didn't close).**

---

### s7l0 — "Path bug — maybe pasture-release carry-over"

**Finding: BOTH requirements delivered in Python; no carry-over residual needed for Go.**

Evidence:
- Python dead-code removal: `_discover_repo_root`, `REPO_ROOT`, `VERSION_FILES` absent from bin/aura-release (grep confirmed zero hits).
- Regression tests: tests/test_aura_release.py contains `test_case_b_subdir_only`, `test_case_c_both_root_and_subdir`, `test_case_d_subdir_pyproject_without_version_key` plus root-level case — Cases A–D confirmed present.
- pasture-release (Go): `internal/release/version.go` has `subdirs: true` in its `scanSpecs` struct — the Go implementation was written with the correct approach from the start; it did not inherit the Python bug.

**Verdict: close-superseded (work done in Python; Go independently correct).**

---

### 1nla — "aura-swarm scope decision"

**Finding: ALL R1–R11 delivered. No open scope decision needed.**

Evidence:
- R1 (script consolidation): `bin/aura-parallel` is a 26-line deprecation wrapper with a `--swarm-mode intree` delegation comment and correct forwarding logic.
- R2 (`--swarm-mode {worktree,intree}`): confirmed in aura-swarm source and help text.
- R3 (`--tmux-dest {session,window}`): confirmed in aura-swarm help text.
- R4 (XDG_STATE_HOME): `YAMLSessionRegistry` uses XDG state dir.
- R5 (session registry with full field list): `YAMLSessionRegistry` implements all listed fields (session_id, permission_mode, model, pid, working_dir, started_at, parent_session_id, role, epic_id, swarm_mode, tmux_session, tmux_window, status, last_activity_at, git_branch).
- R6 (permission inheritance): `detect_parent_permission(registry)` present.
- R7 (registry lifecycle): write-on-launch + `registry.cleanup_stale()` confirmed.
- R8–R9 (unified start + mode-aware subcommands): confirmed in `build_intree_prompt()` and `676:def ... start:` handler.
- R10 (skill consolidation): `aura-parallel` skill deprecated; `skills/swarm/SKILL.md` is canonical.
- R11 (Nix packaging): confirmed in flake.nix (aura-parallel removed as standalone package; deprecation wrapper included).
- aura-swarm is a Python tool retained outside Pasture scope — this is correct; no port decision needed.

**Verdict: close-superseded (completed).**

---

## T-A5: Provisional R-row verdict lines

> These are PROVISIONAL — residual task-ids are TBD (no residuals were filed
> per the all-18 pause). Final R-row lines will be confirmed on sign-off.

**R1 status ("Port aurad" / pastured): DONE**

No Bucket A or B item carries an unmet residual against R1. The Python aurad
implementation was completed, then superseded by pastured (Go) as the canonical
runtime. The Go port delivers full aurad scope at higher fidelity. No extract-residual
verdicts filed against R1. R1 closes with no residuals appendix.

**R2 status ("Port aura-msg" / pasture-msg): DONE**

No Bucket A or B item carries an unmet residual against R2. The Python
aura-msg was implemented and the Go pasture-msg port is canonical. All bwfqm
R1–R15 requirements are covered in pasture-msg (subcommands, session register,
config resolution, output format, SA dual-write, hooks). No extract-residual
verdicts filed against R2. R2 closes with no residuals appendix.

---

## §NEXT: Execution sequence (awaiting user sign-off)

On sign-off (or after rejection-loop revisions), the coordinator will execute
all 18 verdicts in sequence:

1. **Bucket A — 10 close-superseded items** (oqhjg, bwfqm, fw1cx, u3ae0,
   odasf, lczzv, ytj66, 3ubig, v2a51, q72mt): `bd close <id> --reason "superseded by PROPOSAL-2 + naupi"` for all 10, with audit-specific reasons noted in §REASONS below.
2. **Bucket B — 5 close-superseded items** (2tj, o7i9, 7vtb, e28b, s6i):
   `bd close` with audit-specific reasons (2tj/o7i9/s6i = completed; 7vtb/e28b = superseded).
3. **Bucket C — 3 close-superseded items** (1nla, 99q, s7l0): `bd close`
   with completed reasons.
4. **bd comments on all 18** source items citing this audit per §5c traceability.
5. **T-A3 log** to be written post-execution.

### §REASONS: Per-item closure reason overrides (T5)

Items where the standard "superseded by PROPOSAL-2 + naupi" reason
does not accurately reflect reality, per T5 audit-specific reason policy:

| ID | Reason override |
|----|----------------|
| 2tj | completed: FOLLOWUP epic complete, all 4 slices implemented, 554 tests passed (impl UAT ACCEPT 2026-02-22) |
| o7i9 | completed: 20 constraint violation tests + 4 Temporal sandbox tests pass; 1431 passed / 1 skipped (impl UAT ACCEPT 2026-03-03) |
| s6i | completed: aura_protocol v1 followup delivered, 554 tests pass (impl UAT ACCEPT 2026-02-22) |
| 1nla | completed: aura-swarm R1–R11 all delivered; aura-parallel deprecated-wrapper present |
| 99q | completed: bin/aura-release FR-1–FR-5 + NFR-1–NFR-4 all delivered |
| s7l0 | completed: dead code removed, regression tests Cases A–D present; pasture-release Go independently correct |
| 3ubig | completed: agents/supervisor.md created, cartographers removed, clean review exit enforced |
| v2a51 | completed: elicitation done, all URE answers captured in q72mt |
| q72mt | completed: R1–R7 delivered (agents/supervisor.md, SKILL.md rewritten, gen_agents.py, autonomous progression); then superseded by Go codegen as canonical agent-def authority |

All other Bucket A items (oqhjg, bwfqm, fw1cx, u3ae0, odasf, lczzv, ytj66)
and Bucket B items (7vtb, e28b): standard `"superseded by PROPOSAL-2 + naupi"`.

---

## §META: Audit traceability

| Field | Value |
|-------|-------|
| Phase 9 worker | wave-1-lead |
| Verdict date | 2026-05-29 |
| Items verdicted | 18 / 18 |
| close-superseded | 18 |
| extract-residual | 0 |
| special-attention | 0 |
| keep-open | 0 |
| Execution status | NONE — awaiting all-18 user sign-off |
| Next step | Coordinator posts to team-lead via bd comment on aura-plugins-7a8nu; team-lead relays to user |
