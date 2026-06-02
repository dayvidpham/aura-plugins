---
name: PROPOSAL-1 — qzr8a triage audit (18 unique stale work items)
status: Phase 6 RATIFIED. 3-axis ACCEPT consensus (Phase 4, cycle 2) + Phase 5 plan-UAT ACCEPT with the all-18-before-execution pause refinement applied in place. Per-audit execution plan refining PROPOSAL-2 §5.2 (Triage). → Phase 7-9 execution.
references:
  parent_audit: aura-plugins-qzr8a
  elicit: aura-plugins-7a8nu
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.2 Triage audits"
  type: triage
  wave: 1
  cascade: in-cascade (R1/R2 residual surface for ow0pq)
  ure_answers: "aura-plugins-7a8nu (latest comment — Q3 done, Q4 attention, Q5 pause)"
  uat: "aura-plugins-7a8nu (Phase 5 UAT comment — all-18-before-execution pause)"
  roadmap: docs/ROADMAP.md
  migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
---

# PROPOSAL-1 — `qzr8a` triage audit

> Delta over PROPOSAL-2 §5.2. The Triage type template (T1–T5 / T-A1/T-A3/T-A5)
> and the R-row residuals-appendix sub-policy are **referenced, not restated** —
> read §5.2 + §4. This doc pins the URE-locked answers, the Phase-5 UAT pause
> refinement, the audit-specific facts, and the execution mechanics.

## §0. Provenance + revision log

- **Type template:** PROPOSAL-2 §5.2 (Triage). Standard URE/UAT + R-row
  residuals-appendix sub-policy: PROPOSAL-2 §4 (RATIFIED per UAT4).
- **URE answers (locked):** `aura-plugins-7a8nu`, latest comment.
- **Plan, not audit.** The 18-item triage is Phase 9 work; this specifies how.

| Round | Outcome | Changes applied |
|---|---|---|
| Phase 4 R1 | 3-axis REVISE | discovered-from→audit-id; verdict-only-then-execute; rejection loop; DRY collapse; 19→18 note. |
| Phase 4 R2 | 3-axis ACCEPT (consensus) | R2 minors: §5 special-attention/keep-open termination; Bucket-A-only scope; §6 T3-override note. |
| Phase 5 UAT | **ACCEPT + all-18 pause refinement** | User verbatim (`7a8nu`): "Yes — verdict-only before I sign off" + "Show me ALL 18 verdicts before ANY execution". The pause is **no longer Bucket-A-only**: verdict ALL 18 first (no execution) → SINGLE pause presenting all 18 → on sign-off execute all 18. Removes the prior gap where B+C executed unreviewed. Applied to §4 + §8 + §13; the Bucket-A-only framing is superseded. Rejection loop preserved. |

## §1. Objective

Triage **18 unique stale work items** across 3 buckets, giving each a single
verdict, then *executing* the verdict (close superseded items, extract residuals
as new tracked tasks), so the backlog reflects the post-Pasture reality and any
residual against R1 ("Port aurad") / R2 ("Port aura-msg") is surfaced for
`ow0pq`.

## §2. Scope — 18 unique items in 3 buckets

- **Bucket A — 10 REQUESTs:** `oqhjg`, `bwfqm`, `fw1cx`, `u3ae0`, `odasf`,
  `lczzv`, `ytj66`, `3ubig`, `v2a51`, `q72mt`.
- **Bucket B — 6 Python-era:** epic `2tj` + URDs `bwfqm`, `o7i9`, `7vtb`,
  `e28b`, `s6i`.
- **Bucket C — 3 non-Python URDs:** `1nla`, `99q`, `s7l0`.

**Count reconciliation (19 → 18):** raw bucket counts sum to 19 (10+6+3); `bwfqm`
appears in **both** A and B, so the deduplicated total is **18 unique items**.
(The ratified §5.2 header's "19" is left unchanged per the no-modify-PROPOSAL-2
boundary; this note resolves it.) The buckets remain useful for grouping in the
artifact table, but **the Phase-5 pause is over all 18 at once, not per-bucket.**

## §3. Verdict vocabulary

T1 default accepted unchanged — `close-superseded / extract-residual /
special-attention / keep-open` (see §5.2 T1). Exactly one per item.

## §4. Methodology (execution steps for Phase 9)

Execution is **verdict-all-18-first, single-pause, execute-on-sign-off** — no
destructive action (close / residual-filing) fires before the user has reviewed
**all 18** verdicts (per Phase-5 UAT).

1. **Verdict all 18 items** — assign one §3 verdict to each via `bd show`.
   **Do not execute** any close or residual-filing yet.
2. **SINGLE PAUSE (§8)** — present **all 18** interim verdicts to the user;
   obtain sign-off (with the rejection loop in §8).
3. **On sign-off, execute all 18:** for every `close-superseded` item, close it
   (T5 reason convention below); for every `extract-residual` item, file a
   residual (§6). This is the T-A3 gate.
4. **Closure-reason convention (T5):** default `--reason="superseded by
   PROPOSAL-2 + naupi"`; an audit-specific reason otherwise (recorded in T-A1).

Residual filing uses the §6 policy. T3 residual fields are referenced there.

## §5. Done criteria (URE Q3 — FULL, default accepted)

Done when **all 18** items have: (a) a verdict in the artifact table, (b) the
verdict's action executed (close / residual filed), **and** (c) a `bd` comment
on the source item citing this audit (and, for extracted residuals, the residual
task id). Full traceability. For `special-attention` and `keep-open`, criterion
(b) is a **no-op** — done is satisfied at verdict + the (c) comment.

## §6. Residual policy (canonical)

Residuals → new `bd` tasks: **`discovered-from:aura-plugins-qzr8a`** (canonical
provenance — matches the ELICIT U3 answer and the A3 gate; overrides the T3
`<source-item>` default per U3), label `aura:residual`, priority inherited
unless lowered with a stated reason. The remaining T3 fields (title, 1-sentence
description) are per §5.2 T3. **Per-item lineage:** name the source stale item in
the residual's title/description and a `references:` frontmatter block; the §5c
per-item comment is the reverse link. The T-A1 table records the residual id.

## §7. Verbatim-attention (URE Q4 — no additions)

T4 defaults accepted unchanged — `q72mt`, `s7l0`, `1nla` (see §5.2 in-use for
each item's rationale). No other item flagged; standard triage vocab on the
other 15.

## §8. All-18 PAUSE (URE Q5 OVERRIDE + Phase-5 UAT refinement)

**The audit pauses mid-execution after verdicting ALL 18 items, and NOTHING is
executed before the pause** (so the user reviews every live verdict, not a fait
accompli — and not just Bucket A).

Sequence:
1. Verdict all 18 items (§4 step 1) — no closes/residual-filings yet.
2. **Present** all 18 interim verdicts to the user (via team-lead).
3. **Sign-off / rejection loop:**
   - If the user accepts: proceed to step 4.
   - If the user revises any verdict: the coordinator updates that verdict per
     user direction and **re-presents the affected rows** before proceeding.
     Because nothing has executed yet, no undo is needed.
4. **On sign-off:** execute all 18 (closes + residual-filings).

- Exactly **one** Phase 9 mid-audit user touchpoint, now covering **all 18**
  (beyond Phase 5 plan-UAT and Phase 11 impl-UAT).
- **Channel (mid-Phase-9 touchpoint):** when all 18 verdicts are ready, the
  coordinator posts them to team-lead via bd (comment on `aura-plugins-7a8nu`)
  **and** a team task-list entry, then PAUSES. team-lead relays to the user;
  user reviews/revises/signs off; then the coordinator executes.
  (SendMessage unavailable; `aura-msg` is not for teammate messaging.)

## §9. Deliverable

`docs/audits/qzr8a-stale-work-triage.md`. Table schema per **T-A1** (§5.2);
T-A3 closure-execution log; T-A5 R-row verdict line(s) per §10.

## §10. R-row impact

Produces an **R-row verdict line** for R1 ("Port aurad") and R2 ("Port aura-msg"):
whether any Bucket A/B item carried a residual against either. Verdict-line forms
and the structured residuals-appendix trigger are per **PROPOSAL-2 §4** (UAT4,
RATIFIED) — not restated here.

## §11. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.2 T-A1 / T-A3 / T-A5 (+ appendix when
triggered). A3 satisfied by the §6 canonical `discovered-from:aura-plugins-qzr8a`.

## §12. Phase 10 (code review) applicability

**DO Phase 10** — the one Wave-1 audit with interpretive judgment
(close-vs-extract-vs-keep decisions that destroy/transform tracked work).
Ephemeral reviewers verify the close/extract calls before the supervisor closes
the slice (max 3 fix cycles per slice).

## §13. Open questions for UAT

Resolved at Phase 5 UAT: ACCEPT + the all-18-before-execution pause (verdict all
18 → single pause → execute on sign-off; rejection loop preserved). No open items.
