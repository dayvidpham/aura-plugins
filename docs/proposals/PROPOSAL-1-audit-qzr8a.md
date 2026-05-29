---
name: PROPOSAL-1 — qzr8a triage audit (18 unique stale work items)
status: Phase 3 PROPOSAL, Round-2 revision. Per-audit execution plan refining PROPOSAL-2 §5.2 (Triage) with the URE answers locked on the ELICIT task. Round-1 reviewer findings (correctness/coverage/elegance all REVISE) applied in place per the pre-approved coordination directive. Re-submitted to the 3-reviewer cycle. ACCEPT consensus → batched Phase 5 UAT.
references:
  parent_audit: aura-plugins-qzr8a
  elicit: aura-plugins-7a8nu
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.2 Triage audits"
  type: triage
  wave: 1
  cascade: in-cascade (R1/R2 residual surface for ow0pq)
  ure_answers: "aura-plugins-7a8nu (latest comment — Q3 done-criteria, Q4 attention, Q5 PAUSE override)"
  roadmap: docs/ROADMAP.md
  migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
---

# PROPOSAL-1 — `qzr8a` triage audit

> Delta over PROPOSAL-2 §5.2. The Triage type template (T1–T5 / T-A1/T-A3/T-A5)
> and the R-row residuals-appendix sub-policy are **referenced, not restated** —
> read §5.2 + §4. This doc pins only the URE-locked answers, the audit-specific
> facts, and the execution mechanics (esp. the Bucket-A pause).

## §0. Provenance + revision log

- **Type template:** PROPOSAL-2 §5.2 (Triage). Standard URE/UAT + R-row
  residuals-appendix sub-policy: PROPOSAL-2 §4 (RATIFIED per UAT4).
- **URE answers (locked):** `aura-plugins-7a8nu`, latest comment.
- **Plan, not audit.** The 18-item triage is Phase 9 work; this specifies how.

| Round | Outcome | Changes applied |
|---|---|---|
| R1 | correctness=REVISE, coverage=REVISE, elegance=REVISE | (1) **discovered-from contradiction** (correctness IMPORTANT + coverage BLOCKER): §4 and §6 disagreed (`<source-item>` vs audit-id). Resolved to the audit-id form `aura-plugins-qzr8a` — matches the captured U3 answer in the ELICIT, satisfies the ratified A3 gate (`discovered-from:<audit-id>`) as written, and keeps the 4-proposal batch consistent; per-item lineage preserved via the §5c per-item comment + source-item named in the residual. (2) **Bucket-A execution-hold** (coverage BLOCKER): §4 previously executed closes globally, firing Bucket-A closes before the user saw them. Reworked to verdict-only-then-execute-on-sign-off (§4 + §8). (3) **No rejection loop at the pause** (coverage IMPORTANT): added the revise-and-re-present path (§8). (4) **DRY** (elegance BLOCKER×2 + IMPORTANT×3): §3/§6/§7/§9/§10 collapsed to references with only audit-specific facts pinned. (5) **19-vs-18 count** (coverage MINOR): reconciliation note added (§2). |

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

**Count reconciliation (19 → 18):** the ELICIT title and PROPOSAL-2 §5.2 header
say "19 stale items" by summing the raw bucket counts (10 + 6 + 3). `bwfqm`
appears in **both** A and B, so the deduplicated total is **18 unique items**.
This plan uses 18 throughout; a single audit of `bwfqm` satisfies both buckets.
(The ratified §5.2 header is left unchanged per the no-modify-PROPOSAL-2
boundary; this note resolves the discrepancy.)

Bucket boundaries used as-is (T2 default) unless execution surfaces a misfit.

## §3. Verdict vocabulary

T1 default accepted unchanged — `close-superseded / extract-residual /
special-attention / keep-open` (see §5.2 T1). Exactly one per item.

## §4. Methodology (execution steps for Phase 9)

Execution is **verdict-first, execute-on-sign-off** to honor the Bucket-A pause
(§8) — no destructive action (close / residual-filing) fires before the user has
reviewed the bucket it belongs to.

1. **Verdict Bucket A** — assign one §3 verdict to each of the 10 Bucket-A items
   via `bd show`. **Do not execute** any close or residual-filing yet.
2. **PAUSE (§8)** — present Bucket-A interim verdicts to the user; obtain
   sign-off (with the rejection loop in §8).
3. **On sign-off, execute Bucket A** then **verdict + execute Bucket B and C**:
   for every `close-superseded` item, close it (T5 reason convention below); for
   every `extract-residual` item, file a residual (§6). This is the T-A3 gate.
4. **Closure-reason convention (T5):** default `--reason="superseded by
   PROPOSAL-2 + naupi"`; an audit-specific reason otherwise (recorded in the
   T-A1 table).

Residual filing uses the §6 policy. T3 residual fields are referenced there, not
restated here.

## §5. Done criteria (URE Q3 — FULL, default accepted)

Done when **all 18** items have: (a) a verdict in the artifact table, (b) the
verdict's action executed (close / residual filed), **and** (c) a `bd` comment
on the source item citing this audit (and, for extracted residuals, the residual
task id). Full traceability — not table-only.

## §6. Residual policy (canonical)

Residuals → new `bd` tasks: **`discovered-from:aura-plugins-qzr8a`** (canonical
provenance — matches the ELICIT U3 answer and the A3 gate), label
`aura:residual`, priority inherited unless lowered with a stated reason. The
remaining T3 fields (title, 1-sentence description) are per §5.2 T3. **Per-item
lineage:** name the source stale item in the residual's title/description and in
a `references:` frontmatter block; the §5c per-item comment is the reverse link.
The T-A1 table records the residual task id alongside the source item.

## §7. Verbatim-attention (URE Q4 — no additions)

T4 defaults accepted unchanged — `q72mt`, `s7l0`, `1nla` (see §5.2 in-use for
each item's rationale). No other item flagged; standard triage vocab on the
other 15.

## §8. Bucket-A PAUSE override (URE Q5 — OVERRIDE, NOT default)

**This audit pauses mid-execution, and Bucket A is verdicted but NOT executed
before the pause** (so the user reviews live verdicts, not a fait accompli).

Sequence:
1. Verdict all 10 Bucket-A items (§4 step 1) — no closes/residual-filings yet.
2. **Present** the Bucket-A interim verdicts to the user (via team-lead).
3. **Sign-off / rejection loop:**
   - If the user accepts: proceed to step 4.
   - If the user revises any verdict: the coordinator updates that verdict per
     user direction and **re-presents the affected rows** before proceeding.
     Because nothing has executed yet, no undo is needed.
4. **On sign-off:** execute Bucket-A actions, then verdict + execute Bucket B +
   Bucket C.

- Adds **one Phase 9 mid-audit user touchpoint** (beyond Phase 5 plan-UAT and
  Phase 11 impl-UAT).
- **Post-pause remainder:** Bucket B = `2tj`, `o7i9`, `7vtb`, `e28b`, `s6i`
  (`bwfqm` already verdicted in A); Bucket C = `99q` + the pre-flagged
  `1nla` / `s7l0`.
- **Channel:** coordinator posts Bucket-A interim verdicts to team-lead via bd
  (SendMessage unavailable in this context; `aura-msg` is not for teammate
  messaging). team-lead relays user sign-off.

## §9. Deliverable

`docs/audits/qzr8a-stale-work-triage.md`. Table schema per **T-A1** (§5.2);
T-A3 closure-execution log; T-A5 R-row verdict line(s) per §10.

## §10. R-row impact

This audit produces an **R-row verdict line** for R1 ("Port aurad") and R2
("Port aura-msg"): whether any Bucket A/B item carried a residual against either.
Verdict-line forms and the structured residuals-appendix trigger are per
**PROPOSAL-2 §4** (UAT4, RATIFIED) — not restated here.

## §11. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.2 T-A1 / T-A3 / T-A5 (+ appendix when
triggered). A3 is satisfied by the §6 canonical `discovered-from:aura-plugins-qzr8a`
form.

## §12. Phase 10 (code review) applicability

**DO Phase 10** — this is the one Wave-1 audit with interpretive judgment
(close-vs-extract-vs-keep decisions that destroy/transform tracked work).
Ephemeral reviewers verify the close/extract calls before the supervisor closes
the slice (max 3 fix cycles per slice).

## §13. Open questions for UAT

Confirm the Bucket-A pause mechanics (§8): **(a)** Bucket A is verdicted but NOT
executed before the pause (the user reviews live verdicts, can revise, and
execution for all buckets begins only after sign-off); **(b)** the cadence adds
exactly one mid-audit touchpoint. This is the captured Q5 OVERRIDE; UAT confirms
the safe verdict-only-first interpretation is as the user intended. Otherwise no
open questions; defaults locked.
