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
