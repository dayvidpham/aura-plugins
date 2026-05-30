---
name: PROPOSAL-1 — 3iz51 classification audit (8 sibling epic placement)
status: Phase 6 RATIFIED. 3-axis ACCEPT consensus (Phase 4) + Phase 5 plan-UAT ACCEPT with escalation refinements applied in place. Per-audit execution plan refining PROPOSAL-2 §5.4 (Classification). → Phase 7-9 execution.
references:
  parent_audit: aura-plugins-3iz51
  elicit: aura-plugins-tpm4r
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.4 Classification audits"
  type: classification
  wave: 1
  cascade: in-cascade (blocks ow0pq indirectly via placement accuracy)
  ure_answers: "aura-plugins-tpm4r (latest comment — Q1 done-criteria, Q2 attention)"
  uat: "aura-plugins-tpm4r (Phase 5 UAT comment — partial-done + rk2su escalation refinements)"
  roadmap: docs/ROADMAP.md
---

# PROPOSAL-1 — `3iz51` classification audit

> Delta over PROPOSAL-2 §5.4. The Classification type template (URE C1–C5 / UAT
> C-A1/C-A3) is **referenced, not restated** — read §5.4. This doc locks the URE
> answers, the Phase-5 UAT refinements, the execution methodology, and the
> deliverable schema.

## §0. Provenance + revision log

- **Type template:** PROPOSAL-2 §5.4 (Classification). Standard URE/UAT: §4.
- **URE answers (locked):** `aura-plugins-tpm4r`, latest comment.
- **Plan, not the audit.** The 8-way classification is Phase 9 work.

| Stage | Outcome | Changes |
|---|---|---|
| Phase 4 | 3-axis ACCEPT (consensus) | Non-blocking minors applied: §4-discovered residual channel, §8 wording. |
| Phase 5 UAT | **ACCEPT + escalation refinements** | User verbatim (`tpm4r`): partial-done epics ("needs human review; depends on which child is still open") and the rk2su §5-done-but-still-blocks-`ow0pq` contradiction ("escalate to me, I need to see the problem") → **escalate to USER via team-lead, not coordinator self-resolution.** Applied to §4 step 4 + §10. |

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
for genuinely new items that surface during the audit, not a target for the 8.

## §4. Methodology (execution steps for Phase 9)

1. **Verify, don't trust (C2).** Run `bd show <epic>` for **all 8** (minimum 8
   calls). Read status, open blockers (open children), and whether the epic
   still blocks `ow0pq`. Defaults are hypotheses to confirm — especially
   `q9sz9` / `wftdf` (pre-flagged "may not actually be done").
2. **Classify** each of the 8 into one of `§5-done` / `§2-active` /
   `§0-cross-ref`. New items (not one of the 8) route to `§4-discovered` via §6.
3. **Escalation cases (Phase-5 UAT, do NOT self-resolve — see §10):**
   - **Partial-done epic** (mostly-done but with open children): do NOT
     auto-classify. Present the epic + its open children to team-lead → user
     decides the bucket (the open child determines the call).
   - **`rk2su` contradiction** (`§5-done` placement but still blocks `ow0pq`):
     do NOT close-or-note on coordinator judgment. Present the specifics to the
     user via team-lead; the user decides close-vs-ROADMAP-note.
4. **Cross-reference style (C3):** full ROADMAP rows for `§2-active`; bullet
   cross-refs in `§0` for policy/administrative items; `§4-discovered` items get
   a `bd` residual task (§6) plus an optional ROADMAP §4 bullet if warranted.
5. **Peer-linkage check (C5):** for each epic, confirm whether placement reveals
   it as an IS-R-row or an `ow0pq` blocker; reconcile against §1.5 dep graph.
6. **Edit batching (C4):** one commit for all (non-escalated) ROADMAP edits.

## §5. Done criteria (URE Q1 — BOTH, default accepted)

Audit is done when, for **every** epic: (a) it is placed in ROADMAP §5 / §2 / §0
**AND** (b) its bd task carries a comment citing this audit. Escalated epics
(§4 step 3) are "done" once the user's decision is recorded and applied. Any
item routed to `§4-discovered` is satisfied by its §6 residual task.

## §6. Residual policy (U3 — inherited from §4 standard template)

Residuals → new `bd` tasks with `discovered-from:aura-plugins-3iz51` (label
`aura:residual`) **and** a ROADMAP note where the placement warrants it.

## §7. Verbatim-attention (URE Q2 — no additions; Phase-5 escalation overlay)

Pre-flagged: `q9sz9`, `wftdf` (done-status suspect), `rk2su` (peer-epic /
`ow0pq` linkage — now an explicit **escalation** case per §4 step 3 / §10). No
other epic flagged — standard verify-vs-trust on the remaining five (`x5071`,
`ytzcl`, `ad8i1`, `9wdwc`, `6ujr`), subject to the partial-done escalation rule.

## §8. Deliverable

`docs/audits/3iz51-sibling-epic-placement.md` containing:

- **C-A1 placement table** — one row per epic:
  `[epic-id | title | verdict (§3) | rationale (bd-verified) | roadmap-location]`
  (escalated epics record the user's decision in the rationale column).
- **C-A3 ROADMAP diff** — the ROADMAP.md edits land in one commit (C4).
- Per-epic `bd` comment on the epic's own bd task (the second half of §5).

## §9. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.4 C-A1 / C-A3. A2 trivially satisfied (scope
fixed at 8). **No R-row verdict line** (`tpm4r` in-use: "R-row impact: None").

## §10. Phase 10 (code review) applicability + escalation

**SKIP Phase 10** — rationale recorded on the slice: "enumerate-and-verdict, no
interpretive judgment beyond Phase 11 UAT."

**Escalation rule (broadened per Phase-5 UAT)** — escalate to the **USER via
team-lead (bd)** — NOT coordinator self-resolution — when execution surfaces:
1. an epic that **fits no §3 bucket**;
2. a **partial-done epic** (mostly-done with open children — the open child
   determines the bucket);
3. the **`rk2su`-style contradiction** (`§5-done` but still blocks `ow0pq`).
Cases 2–3 are user touchpoints during Phase 9: post the specifics to team-lead
(comment on `aura-plugins-3iz51` + `aura:escalation` label + task-list entry);
team-lead relays; the user decides; the coordinator applies and records.

## §11. Open questions for UAT

Resolved at Phase 5 UAT (ACCEPT + the §10 escalation refinements). No open items.
