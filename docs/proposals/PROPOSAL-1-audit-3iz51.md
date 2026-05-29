---
name: PROPOSAL-1 — 3iz51 classification audit (8 sibling epic placement)
status: Phase 3 PROPOSAL (3-axis ACCEPT consensus; non-blocking minors applied in place — §4-discovered handling clarified, no re-review required). Per-audit execution plan refining PROPOSAL-2 §5.4 (Classification) with the URE answers locked on the ELICIT task. → batched Phase 5 UAT.
references:
  parent_audit: aura-plugins-3iz51
  elicit: aura-plugins-tpm4r
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.4 Classification audits"
  type: classification
  wave: 1
  cascade: in-cascade (blocks ow0pq indirectly via placement accuracy)
  ure_answers: "aura-plugins-tpm4r (latest comment — Q1 done-criteria, Q2 attention)"
  roadmap: docs/ROADMAP.md
---

# PROPOSAL-1 — `3iz51` classification audit

> Delta over PROPOSAL-2 §5.4. The Classification type template (URE C1–C5 / UAT
> C-A1/C-A3) is **referenced, not restated** — read §5.4. This doc locks the URE
> answers, the execution methodology, the deliverable schema, and open questions.

## §0. Provenance

- **Type template:** PROPOSAL-2 §5.4 (Classification). Standard URE/UAT: §4.
- **URE answers (locked):** `aura-plugins-tpm4r`, latest comment (captured
  2026-05-27 via team-lead relay).
- **Plan, not the audit.** The 8-way classification is Phase 9 work.

## §1. Objective

Place the **8 sibling epics** that surround the Pasture port into the correct
`docs/ROADMAP.md` bucket, with each placement verified against live `bd` state
(not trusted from defaults), so the ROADMAP accurately reflects which epics are
done / active / cross-referenced and `ow0pq` can read an honest dep picture.

## §2. Scope — the 8 epics

`x5071`, `q9sz9`, `wftdf`, `rk2su`, `ytzcl`, `ad8i1`, `9wdwc`, `6ujr`
(per the `3iz51` task description). No additions, no removals.

## §3. Placement vocabulary (locked — URE C1 default accepted)

`§5-done` / `§2-active` / `§0-cross-ref` / `§4-discovered`.

Each of the 8 known epics gets exactly one placement from {`§5-done`,
`§2-active`, `§0-cross-ref`}. **`§4-discovered` is the residual channel** (§6) —
reserved for genuinely new items that surface *during* the audit, not a target
for the 8 pre-identified epics.

## §4. Methodology (execution steps for Phase 9)

1. **Verify, don't trust (C2).** Run `bd show <epic>` for **all 8** (minimum 8
   calls). Read status, open blockers, and whether the epic still blocks
   `ow0pq`. Defaults in the task description are hypotheses to confirm —
   especially `q9sz9` / `wftdf` (pre-flagged "may not actually be done").
2. **Classify** each of the 8 into one of `§5-done` / `§2-active` /
   `§0-cross-ref`. If verification surfaces a *new* item (not one of the 8),
   route it to `§4-discovered` via the §6 residual policy — do not force-fit it
   into a placement for the 8.
3. **Cross-reference style (C3):** full ROADMAP rows for `§2-active`; bullet
   cross-refs in `§0` for policy/administrative items; `§4-discovered` items get
   a `bd` residual task (§6) plus an optional ROADMAP §4 bullet if warranted.
4. **Peer-linkage check (C5):** for each epic, confirm whether placement reveals
   it as an IS-R-row or an `ow0pq` blocker, and reconcile against §1.5 dep graph.
   For `rk2su` specifically: if placed `§5-done` but it still blocks `ow0pq`,
   either close it or add a ROADMAP note that its closure is upstream-of-`ow0pq`
   (do not leave the contradiction).
5. **Edit batching (C4):** one commit for all ROADMAP edits.

## §5. Done criteria (URE Q1 — BOTH, default accepted)

Audit is done when, for **every** epic: (a) it is placed in ROADMAP §5 / §2 / §0
**AND** (b) its bd task carries a comment citing this audit. Both required. Any
item routed to `§4-discovered` is satisfied instead by its §6 residual task (it
is, by definition, not one of the 8 placements).

## §6. Residual policy (U3 — inherited from §4 standard template)

Residuals → new `bd` tasks with `discovered-from:aura-plugins-3iz51` (label
`aura:residual`) **and** a ROADMAP note where the placement warrants it.

## §7. Verbatim-attention (URE Q2 — no additions)

Pre-flagged: `q9sz9`, `wftdf` (done-status suspect), `rk2su` (peer-epic /
`ow0pq` linkage). No other epic flagged — standard verify-vs-trust on the
remaining five (`x5071`, `ytzcl`, `ad8i1`, `9wdwc`, `6ujr`).

## §8. Deliverable

`docs/audits/3iz51-sibling-epic-placement.md` containing:

- **C-A1 placement table** — one row per epic:
  `[epic-id | title | verdict (§3) | rationale (bd-verified) | roadmap-location]`.
- **C-A3 ROADMAP diff** — the ROADMAP.md edits land in one commit (C4).
- Per-epic `bd` comment on the **epic's own bd task** (the second half of §5).

## §9. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.4 C-A1 / C-A3. A2 is trivially satisfied —
scope is fixed at the 8 epics (§2). **No R-row verdict line** (ELICIT `tpm4r`
in-use: "R-row impact: None").

## §10. Phase 10 (code review) applicability

**SKIP** — rationale recorded on the slice: "enumerate-and-verdict, no
interpretive judgment beyond Phase 11 UAT." Placement is mechanical
classify-and-record; ROADMAP edits are reviewable at Phase 11 UAT.
**Escalation rule:** if execution reveals an epic that needs a genuine policy
decision (fits no §3 bucket, or an unresolvable `rk2su`-style contradiction),
promote to full Phase 10 and notify team-lead (add `aura:escalation` label +
comment on `aura-plugins-3iz51`; bd is the coordination channel).

## §11. Open questions for UAT

None material — URE answers locked at §5.4 defaults + the two captured answers
(done = both; no extra attention items). Proceeds to execution on UAT ACCEPT.
