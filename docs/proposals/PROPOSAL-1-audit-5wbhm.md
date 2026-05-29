---
name: PROPOSAL-1 — 5wbhm status audit (codegen authority — REWORDED qualified claim + coverage overlay)
status: Phase 3 PROPOSAL. Per-audit execution plan refining PROPOSAL-2 §5.6 (Status). SCOPE-CHANGED by the URE — the claim was reworded by the user from a trivial "confirmed" pass-through into a qualified-verdict status audit WITH a skill-coverage overlay. Submitted to the 3-reviewer cycle. ACCEPT consensus → batched Phase 5 UAT.
references:
  parent_audit: aura-plugins-5wbhm
  elicit: aura-plugins-hwnt2
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.6 Status audits"
  type: status
  wave: 1
  cascade: out-of-cascade (does NOT block ow0pq)
  ure_answers: "aura-plugins-hwnt2 (latest comment — Q8 SCOPE-CHANGING reword, read carefully)"
  migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
  roadmap_section: "docs/ROADMAP.md §1i (skill-drift CI check — '7 overlapping skills')"
  related_epic: aura-plugins-x5071 (port remaining 31 Python-only skills — the not-yet-ported remainder)
  deliverable_target: pasture/AGENTS.md ("Code generation" section)
---

# PROPOSAL-1 — `5wbhm` status audit (REWORDED)

> Delta over PROPOSAL-2 §5.6. The Status type template (St1–St5 /
> St-A1/St-A2/St-A3) is not restated — read §5.6. **This audit's scope was
> changed by the URE**; this proposal locks the reworded claim, the coverage
> overlay it now requires, the candidate skill sets (WITH evidence, NOT locked),
> and the open questions that UAT must resolve before execution.

## §0. Provenance + SCOPE CHANGE

- **Type template:** PROPOSAL-2 §5.6 (Status). Standard URE/UAT: PROPOSAL-2 §4.
- **URE answer (locked):** `aura-plugins-hwnt2`, latest comment — **Q8 is
  scope-changing.** The user rejected the pre-filled trivial "Go authoritative;
  Python deprecated" claim (expected `confirmed`) and reworded it.
- **Effect:** 5wbhm is **no longer a binary pass-through.** It is now a
  **qualified-verdict status audit with a skill-coverage overlay.** Expected
  verdict shifts from `confirmed` → **`qualified`**.
- **Out-of-cascade:** does NOT block `ow0pq` / `jbnx3` closure.
- **Plan, not audit.** Enumerating exactly which skills are Go-verified is
  Phase 9 work; this specifies the methodology and flags what UAT must confirm.

## §1. The reworded claim (VERBATIM, replaces the pre-filled St2 claim)

> "Go is the authoritative implementation of the SKILL.md generation pipeline,
> but has only been verified for 7 skills. Python generation pipeline and
> content is slightly less up-to-date for these 7 skills, but the rest would be
> used as reference as they haven't been fully ported over yet."

**Parse into two verifiable parts:**

1. **Qualified authority.** Go is authoritative *for the SKILL.md generation
   pipeline*, but that authority has only been *verified across 7 skills*. For
   those 7, Python is *slightly less up-to-date* (Go is ahead).
2. **Coverage overlay.** The *remaining* skills are NOT yet ported; Python
   pipeline/content remains the *reference* for them. The deliverable must
   **enumerate** which skills fall in each set.

## §2. Verdict vocabulary (locked — St1 default; expected verdict shifted)

`confirmed` / `refuted` / `qualified`. **Expected: `qualified`** — the claim is
true *with the explicit caveat* that verification covers only a subset of skills
(St4: `qualified` = true-with-caveats).

## §3. Coverage overlay — candidate skill sets (EVIDENCE, NOT locked)

The reworded claim hinges on "the 7." The supporting doc evidence gives **three
non-identical candidate definitions** — this proposal surfaces all three rather
than silently picking one (see §10 open questions):

- **Candidate A — "Drifted skills (7)"** (PYTHON_TO_GO_MIGRATION.md L47):
  `architect`, `impl-review`, `reviewer`, `supervisor`, `supervisor-plan-tasks`,
  `supervisor-spawn-worker`, `worker`. These are the 7 the migration doc tracked
  as drifted, and ROADMAP §1i's "7 overlapping skills" phrasing.
- **Candidate B — overlapping skills (8):** Candidate A **+ `protocol`** — which
  the same table lists as a row with **0 diff** ("in sync; not previously
  tracked"). So the homes actually overlap on **8** skills, not 7. `protocol`
  being already-in-sync may or may not count as "verified."
- **Candidate C — the user's "verified 7":** a *verified* predicate, which is
  not necessarily the same as the *drifted* set (A) or the *overlapping* set
  (B). A skill can be overlapping-and-in-sync (e.g. `protocol`) yet still be
  "verified."

**The not-yet-ported remainder (the "rest"):** the migration doc records **31
Python-only skills** (exist only under `aura-plugins/skills/`, e.g. `epoch`,
`feedback`, `research`, the `msg-*` / `architect-*` / `reviewer-*` sub-skills)
plus **1 Pasture-only skill** (`install-cli`). The 31 Python-only set is exactly
the scope of epic **`x5071`** ("port remaining Python-only skills"). This is the
audit's coverage-overlay denominator for "the rest."

## §4. Methodology (execution steps for Phase 9)

1. **Resolve "the 7"** against the UAT answer (§10) + the migration doc, and
   record the exact verified set with the 7-vs-8 (`protocol`) reconciliation.
2. **Establish part 1 (qualified authority):** evidence (St3 — observed behavior
   weighted highest, then code, then docs/history) that the Go pipeline
   (`pasture/internal/codegen/skills.go`) is authoritative and that for the
   verified set Python is *slightly less up-to-date* (Go ahead). Check
   `Makefile` / `go:generate` directives, the regeneration sections of
   `aura-plugins/CLAUDE.md` + `pasture/AGENTS.md`, any `DEPRECATED.md` banner,
   and observed regeneration behavior.
3. **Establish part 2 (coverage overlay):** enumerate which skills are
   Go-verified vs which still rely on Python as reference (cross-ref `x5071`).
   Reconcile counts against the migration doc (7/8 overlapping + 31 Python-only
   + 1 Pasture-only).
4. **Verdict:** assign `confirmed`/`refuted`/`qualified` to the reworded claim
   (expected `qualified`).

## §5. Done criteria (status + overlay)

Done when: (a) the reworded claim has a verdict with bullet-list evidence
(St-A1), (b) the deliverable **enumerates** the verified-skill set and the
not-yet-ported remainder (the overlay — not just a binary authority statement),
and (c) if `qualified` (expected) or `refuted`, follow-up tasks are filed per §6.

## §6. Residual policy (St-A3)

Because the expected verdict is `qualified`, **St-A3 applies:** file follow-up
`bd` tasks (`discovered-from:aura-plugins-5wbhm`, `aura:residual`) to either
close the gap or update the claim. Cross-reference `x5071` for the
not-yet-ported remainder rather than duplicating it; file the skill-drift CI
check (ROADMAP §1i, "never filed") as a residual if the audit confirms it is
still missing.

## §7. Deliverable

- **`pasture/AGENTS.md` "Code generation" section** (add if absent) — must
  contain the verdict statement **and the coverage overlay**: the enumerated
  verified-skill set + the not-yet-ported remainder (cross-ref `x5071`). Not a
  binary authority sentence.
- **bd comment** on `aura-plugins-5wbhm`: St-A1 1-sentence verdict + bullet
  evidence; close reason = the verdict statement.
- St-A2 trivial (one claim, one verdict).

## §8. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.6 St-A1 / St-A2 / St-A3. **No R-row verdict
line** (out-of-cascade; confirmed in ELICIT in-use overrides).

## §9. Phase 10 (code review) applicability

**SKIP** — rationale to be recorded on the slice: "enumerate-and-verdict, no
interpretive judgment beyond Phase 11 UAT." The audit gathers evidence and
records a verdict + enumeration; it edits docs only (`pasture/AGENTS.md`), no
production code. **Escalation rule:** if resolving "the 7" or the qualified-vs-
refuted call surfaces genuine ambiguity that needs a judgment review (beyond the
§10 UAT confirmation), promote to full Phase 10 and notify team-lead first.

## §10. OPEN QUESTIONS FOR UAT (must resolve before execution)

This audit carries **real open questions** the user must settle (do not silently
resolve):

1. **Which 7 is "the verified 7"?** Confirm whether the user's "verified for 7
   skills" maps to Candidate A (drifted-7), Candidate B (overlapping-8 incl.
   `protocol`), or a different explicit set (Candidate C). The deliverable's
   enumeration depends on this.
2. **7 vs 8 — does `protocol` count?** ROADMAP §1i says "7 overlapping" but the
   migration doc actually shows **8** overlapping skills (the 7 drifted +
   `protocol` at 0 diff). Is `protocol` part of "verified," excluded as
   trivially-in-sync, or the source of an off-by-one in the original "7"?
3. **"Verified" definition.** What does "verified" require for a skill — Go
   output matches the schema? Go is *ahead* of Python? A passing drift check?
   This sets the bar the enumeration must meet.

These are surfaced at Phase 5 UAT; the §4 methodology executes against whatever
the user confirms.
