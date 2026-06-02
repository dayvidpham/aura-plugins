---
name: PROPOSAL-1 — 5wbhm status audit (codegen authority — qualified claim, 8-skill coverage overlay)
status: Phase 6 RATIFIED. Phase 4 3-axis ACCEPT consensus + Phase 5 plan-UAT ACCEPT with the 3 open questions resolved (verified set = overlapping-8; 'verified' = content-currency; claim corrected 7→8). Per-audit execution plan refining PROPOSAL-2 §5.6 (Status). → Phase 7-9 execution.
references:
  parent_audit: aura-plugins-5wbhm
  elicit: aura-plugins-hwnt2
  ratified_meta_plan: docs/proposals/PROPOSAL-2-audit-execution-plan.md
  meta_plan_section: "§5.6 Status audits"
  type: status
  wave: 1
  cascade: out-of-cascade (does NOT block ow0pq)
  ure_answers: "aura-plugins-hwnt2 (Q8 reworded claim)"
  uat: "aura-plugins-hwnt2 (Phase 5 UAT comment — Q1/Q2 overlapping-8, Q3 content-currency)"
  migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
  roadmap_section: "docs/ROADMAP.md §1i (skill-drift CI check)"
  related_epic: aura-plugins-x5071 (port remaining 31 Python-only skills)
  residuals:
    doc_correction: aura-plugins-acroy (7→8 overlapping correction)
    skill_drift_ci: aura-plugins-g8egz (skill-drift CI check, ROADMAP §1i)
  deliverable_target: pasture/AGENTS.md ("Code generation" section)
---

# PROPOSAL-1 — `5wbhm` status audit

> Delta over PROPOSAL-2 §5.6. The Status type template (St1–St5 /
> St-A1/St-A2/St-A3) is **referenced, not restated** — read §5.6. The URE
> reworded this audit's claim; Phase-5 UAT then resolved the 3 open questions.
> This doc locks the corrected claim, the verified set, the `verified` predicate,
> and the deliverable.

## §0. Provenance + revision log

- **Type template:** PROPOSAL-2 §5.6 (Status). Standard URE/UAT: §4.
- **URE (`hwnt2` Q8):** user rewrote the claim from trivial "confirmed" to a
  qualified-authority + coverage-overlay claim.
- **Out-of-cascade:** does NOT block `ow0pq` / `jbnx3`.
- **Plan, not audit.** The per-skill enumeration is Phase 9 work.

| Stage | Outcome | Changes |
|---|---|---|
| Phase 4 | 3-axis ACCEPT (consensus) | Candidate "the 7" presented WITH evidence but NOT locked; 3 open questions surfaced for UAT. Denominator standardized to 31 Python-only. |
| Phase 5 UAT | **ACCEPT + 3 resolutions** | User verbatim (`hwnt2`): (Q1/Q2) "Overlapping-8 (protocol included)" → verified set = **overlapping-8** (drifted-7 + `protocol`); the claim's "7" was an **off-by-one**, corrected to 8 and noted. (Q3) "Go is ahead-of / at-parity-with Python (content currency)" → **`verified` = content-currency**, not schema-structural, not a formal drift-tool pass. Residuals filed: `acroy` (7→8 doc correction), `g8egz` (skill-drift CI check). §3/§4/§10 updated; the §10 open-questions are now resolved. |

## §1. The claim (corrected 7 → 8 per Phase-5 UAT)

**User's reworded claim (verbatim, URE `hwnt2` Q8):**

> "Go is the authoritative implementation of the SKILL.md generation pipeline,
> but has only been verified for 7 skills. Python generation pipeline and content
> is slightly less up-to-date for these 7 skills, but the rest would be used as
> reference as they haven't been fully ported over yet."

**Correction (Phase-5 UAT):** the count "7" was an **off-by-one** — the
overlapping (and verified) set is **8** skills: the 7 drifted skills **plus
`protocol`** (which the migration doc lists at 0-diff/in-sync; the user confirmed
it counts). The audit **verifies the corrected 8-skill claim and notes the 7→8
correction** (and files `acroy` to fix the doc/ROADMAP phrasing).

**Parsed (corrected) claim, two parts:**
1. **Qualified authority** — Go is authoritative for the SKILL.md pipeline, but
   that authority is *verified* only across the **8 overlapping** skills; for
   those 8, Python is *slightly less up-to-date* (Go is ahead / at parity).
2. **Coverage overlay** — the remaining **31 Python-only** skills are NOT yet
   ported (Python remains the reference); this is `x5071`'s scope.

## §2. Verdict vocabulary (St1) + expected verdict

`confirmed` / `refuted` / `qualified`. **Expected: `qualified`** — the corrected
claim is true *with the explicit caveat* that verification covers only the 8
overlapping skills while 31 remain Python-as-reference (St4: true-with-caveats).

## §3. The verified set (RESOLVED at UAT — overlapping-8, locked)

The verified set is the **overlapping-8** (no longer a candidate; locked):

`architect`, `impl-review`, `reviewer`, `supervisor`, `supervisor-plan-tasks`,
`supervisor-spawn-worker`, `worker`, **`protocol`**.

(= the migration doc's "Drifted skills (7)" + `protocol` at 0-diff/in-sync.)

**The not-yet-ported remainder:** **31 Python-only** skills (exist only under
`aura-plugins/skills/`) — `x5071`'s scope — plus **1 Pasture-only** skill
(`install-cli`). This is the coverage-overlay denominator for "the rest."

**`verified` predicate (RESOLVED at UAT — content currency):** a skill is
"verified" when the **Go-generated SKILL.md is content-current — i.e. Go is
ahead-of or at-parity-with the Python copy** (matching the claim's "Python
slightly less up-to-date"). **NOT** mere schema-structural correctness, and
**NOT** a formal drift-check-tool pass.

## §4. Methodology (execution steps for Phase 9)

1. **Establish part 1 (qualified authority):** evidence (St3 — observed behavior
   weighted highest, then code, then docs/history) that the Go pipeline
   (`pasture/internal/codegen/skills.go`) is authoritative, and that for **each
   of the 8** overlapping skills Go is **content-current** (ahead-of/at-parity
   with Python). Check `Makefile` / `go:generate`, the regeneration sections of
   `aura-plugins/CLAUDE.md` + `pasture/AGENTS.md`, the migration doc's
   "Regenerator commands" result (Go regen produced 0 changes on a clean tree),
   any `DEPRECATED.md` banner, and observed regeneration behavior.
2. **Establish part 2 (coverage overlay):** enumerate the verified-8 vs the 31
   not-yet-ported (cross-ref `x5071`). Reconcile counts against the migration doc.
3. **Verdict:** assign `qualified` (expected) to the corrected claim, with the
   8-vs-31 split stated explicitly.

## §5. Done criteria (status + overlay)

Done when: (a) the corrected claim has a verdict (expected `qualified`) with
bullet-list evidence (St-A1); (b) the deliverable **enumerates** the verified-8
and the 31 not-yet-ported (the overlay — not a binary authority statement); and
(c) the §6 residuals are filed (done — `acroy`, `g8egz`).

## §6. Residual policy (St-A3 — filed)

Because the verdict is `qualified`, St-A3 applies. Filed at Phase-5 UAT
(`discovered-from:aura-plugins-5wbhm`, `aura:residual`):
- **`acroy`** — correct "7 overlapping skills" → 8 in PYTHON_TO_GO_MIGRATION.md +
  ROADMAP §1i.
- **`g8egz`** — file the skill-drift CI check for the 8 overlapping skills
  (ROADMAP §1i, never filed).
The not-yet-ported remainder is tracked by `x5071` (not duplicated).

## §7. Deliverable

- **`pasture/AGENTS.md` "Code generation" section** (add if absent) — the verdict
  statement (`qualified`) **and the coverage overlay**: the enumerated
  **verified-8** + the **31 not-yet-ported** (cross-ref `x5071`) + the 7→8 note.
  Not a binary authority sentence.
- **bd comment** on `aura-plugins-5wbhm`: St-A1 1-sentence verdict + bullet
  evidence; close reason = the verdict statement.
- St-A2 trivial (one claim, one verdict).

## §8. UAT gates (inherited)

Standard A1–A5 (PROPOSAL-2 §4) + §5.6 St-A1 / St-A2 / St-A3. **No R-row verdict
line** (out-of-cascade).

## §9. Phase 10 (code review) applicability

**SKIP** — rationale on the slice: "enumerate-and-verdict, no interpretive
judgment beyond Phase 11 UAT." Docs-only deliverable (`pasture/AGENTS.md`), no
production code. **Escalation:** if the per-skill content-currency call surfaces
genuine ambiguity needing a judgment review, promote to full Phase 10 and notify
team-lead first.

## §10. UAT resolutions (was: open questions — now CLOSED)

All three Phase-4 open questions were resolved at Phase-5 UAT:
1. **Which set / 7-vs-8** → **overlapping-8** (drifted-7 + `protocol`); the "7"
   was an off-by-one, corrected to 8 (residual `acroy`).
2. **Does `protocol` count?** → **Yes** (0-diff/in-sync still counts as verified).
3. **What `verified` requires** → **content currency** (Go ahead-of/at-parity
   with Python), not schema-structural-only, not a formal drift-tool pass.
