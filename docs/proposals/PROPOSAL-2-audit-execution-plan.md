---
name: PROPOSAL-2 — Audit execution plan (URE-revised)
status: Revision of PROPOSAL-1 incorporating URE outputs from [`aura-plugins-blh3a`](beads://aura-plugins-blh3a). Submitted to the 3-reviewer cycle (correctness / coverage / elegance). Reviewer ACCEPT consensus across one wave is the gate to UAT.
description: Meta-plan for executing the cmvu5 audit roster — 6 audits + 1 separate-track REQUEST. PROPOSAL-2 expands the strawman by (a) adding mh4ek (coverage) and 5wbhm (status) to the audit roster, (b) growing the audit-type taxonomy from 4 to 8, (c) providing per-type URE/UAT templates so future audits can drop into existing slots, (d) refining the fzctk vocabulary. Sequencing keeps Wave 1 parallel / Wave 2 / Wave 3 with the 2 newly-folded audits joining Wave 1.
references:
  request: aura-plugins-mld74
  elicit: aura-plugins-blh3a
  prior_proposal: docs/proposals/PROPOSAL-1-audit-execution-plan.md
  parent_urd: aura-plugins-jbnx3
  closure_triage: aura-plugins-ow0pq
  source_epic: aura-plugins-cmvu5
  audit_proposal: aura-plugins-ircvi (docs/proposals/ROADMAP-COMPLETENESS-AUDIT.md)
  roadmap: docs/ROADMAP.md
  migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
  audits:
    fzctk: aura-plugins-fzctk (§1j SKILL.md fidelity)
    qzr8a: aura-plugins-qzr8a (§2i stale-items triage)
    h2zd9: aura-plugins-h2zd9 (§2k pkg/protocol consumption spec)
    iz51: aura-plugins-3iz51 (§4c sibling-epic placement)
    mh4ek: aura-plugins-mh4ek (§1f 26 C-* constraint coverage)
    5wbhm: aura-plugins-5wbhm (§1g codegen authority status)
    l5yo: aura-plugins-6l5yo (§2g git_recorder.go — separate REQUEST track)
---

# PROPOSAL-2 — Audit execution plan for the `cmvu5` audit roster

## §0. Revision log

| Round | Date | Outcome | Changes applied |
|---|---|---|---|
| Pre-URE | 2026-05-25 | PROPOSAL-1 strawman drafted before URE. User feedback: process violation — URE should precede proposal. | Doc renamed to PROPOSAL-1; frontmatter re-flagged as pre-URE strawman; REQUEST + ELICIT bd tasks filed. |
| URE | 2026-05-25 | All 9 URE questions answered (3 pre-URE-strawman + 6 proper URE). Verbatim outputs on [`aura-plugins-blh3a`](beads://aura-plugins-blh3a). | Drafted as PROPOSAL-2 (this doc). |
| Round 1 | TBD | 3-reviewer cycle (correctness / coverage / elegance) | TBD |
| UAT | TBD | User ACCEPT/REVISE | TBD |

### URE outputs (locked into PROPOSAL-2)

| # | Question | Decision |
|---|---|---|
| **U-pre1** | Should `6l5yo` (git_recorder.go) be audit-shaped or REQUEST-shaped? | REQUEST-shaped. Split off the audit batch; runs through its own REQUEST → ELICIT → PROPOSAL → IMPL_PLAN → SLICE. Fold §1b smoke into the same scope. |
| **U-pre2** | One batch ELICIT or one per audit? | One ELICIT per audit. Filed only after this meta-plan ratifies. |
| **U-pre3** | UAT cadence per audit or batched at end? | Pause for user UAT per audit. Matches "look like /user-elicit and /user-uat for each audit" framing. |
| **U1** | Wall-clock sequencing? | Wave 1 (parallel) → Wave 2 (serial) → Wave 3 (serial). Newly-folded `mh4ek` + `5wbhm` join Wave 1 (parallel-with-no-contention). |
| **U2** | Are 4 audit types enough? | No — add `coverage`, `status`, `sweep`, `reconciliation` = **8 total types**. |
| **U3** | Reviewer axes for this meta-plan? | Standard: correctness / coverage / elegance. |
| **U4** | Which strawman vocab needs refinement? | `fzctk` — architect adds `unverifiable` (Go region unclear) + `superseded` (fragment intentionally replaced by different mechanism). New vocab: `captured / distorted / irrelevant / unverifiable / superseded`. |
| **U5** | Fold `mh4ek` and `5wbhm` into this plan? | Yes — fold both. **Flag them as out-of-cascade** (do not block `ow0pq`) so priority isn't conflated. |
| **U6** | Spec all 8 types or only in-use? | In-use + structural placeholder. Full URE/UAT templates for the 6 types with current audits; short stubs for `sweep` and `reconciliation`. |

---

## §1. Audit roster

PROPOSAL-2 covers **6 audits + 1 separate-track REQUEST**. Two of the audits (`mh4ek`, `5wbhm`) are out-of-cascade — they're audits in `cmvu5` but don't block `ow0pq` / `jbnx3` closure. They're folded into this meta-plan for uniform shape, not for elevated priority.

| Task | ROADMAP § | Type | Wave | Blocks `ow0pq`? | Cost | Risk |
|---|---|---|---|---|---|---|
| [`fzctk`](beads://aura-plugins-fzctk) | §1j | Fidelity | 2 | **Yes** | High | High (informs R1 codegen completeness) |
| [`qzr8a`](beads://aura-plugins-qzr8a) | §2i | Triage | 1 | **Yes** | Medium (wide, shallow) | Medium (may carry residuals against R1/R2) |
| [`h2zd9`](beads://aura-plugins-h2zd9) | §2k | Spec | 3 | **Yes** | Medium-High | Medium (IS `jbnx3` R5) |
| [`3iz51`](beads://aura-plugins-3iz51) | §4c | Classification | 1 | **Yes** | Low-Medium | Low |
| [`mh4ek`](beads://aura-plugins-mh4ek) | §1f | **Coverage** | 1 | No (out-of-cascade) | Medium | Low (defense-in-depth) |
| [`5wbhm`](beads://aura-plugins-5wbhm) | §1g | **Status** | 1 | No (out-of-cascade) | Low | Low (mostly answered by `naupi`; verify) |
| [`6l5yo`](beads://aura-plugins-6l5yo) | §2g | Implementation (REQUEST) | Separate | **Yes** | Medium-High | Low |

**Why `mh4ek` and `5wbhm` are out-of-cascade but still in this plan:** The user direction was to fold them in for taxonomy/process uniformity. They're flagged because their completion isn't gating `jbnx3` closure — if `ow0pq` is ready to triage before `mh4ek`/`5wbhm` finish, that's fine. They proceed in parallel without holding up the cascade.

**4 peer epics excluded from this plan** (their own implementation workflows): [`bch`](beads://aura-plugins-bch) (R3), [`6ujr`](beads://aura-plugins-6ujr) (R4), [`rk2su`](beads://aura-plugins-rk2su) (R4 followup), [`x5071`](beads://aura-plugins-x5071) (R5-adjacent). They appear in `ow0pq`'s dep graph but are tracked separately.

## §2. Audit type taxonomy (8 types)

| # | Type | Shape | In-use audit(s) | Verdict vocabulary |
|---|---|---|---|---|
| 1 | **Fidelity** | Compare hand-authored vs generated, fragment by fragment | `fzctk` | captured / distorted / irrelevant / unverifiable / superseded |
| 2 | **Triage** | Read N items, judge each, close-or-extract-or-defer | `qzr8a` | close-superseded / extract-residual / special-attention / keep-open |
| 3 | **Spec** | Author missing policy/design where none exists today | `h2zd9` | (axes, not verdicts) versioning / semver / import-path / deprecation / pinning |
| 4 | **Classification** | Place items into existing buckets in a structure | `3iz51` | §5-done / §2-active / §0-cross-ref |
| 5 | **Coverage** | Verify a port/migration/feature set is complete | `mh4ek` | ported / missing / divergent |
| 6 | **Status** | Verify a claimed state holds today | `5wbhm` | confirmed / refuted / qualified |
| 7 | **Sweep** | Find things that shouldn't be there | *(none current — placeholder)* | (TBD: clean / found-N-issues / further-sweep-needed) |
| 8 | **Reconciliation** | Compare two sources of truth, verify they agree | *(none current — placeholder)* | (TBD: aligned / drift-found / unresolvable) |

Types 7 and 8 get a structural placeholder in §5 (not a full template). The user direction is "TBD when first audit of that shape lands" — speculative depth on sweep/reconciliation without a caller is YAGNI.

## §3. Wave sequencing

```
              ┌───────────────────────────────────────┐
  Wave 1      │ 3iz51    qzr8a    mh4ek    5wbhm      │  4 parallel
  (parallel)  │  (cls)   (triage) (cov)    (status)   │
              │  ow0pq   ow0pq    out-of-  out-of-     │
              │                   cascade  cascade     │
              └─────────────┬─────────────────────────┘
                            │ surfaces residuals + status; mh4ek + 5wbhm don't gate downstream
                            ▼
              ┌───────────────────────────────────────┐
  Wave 2      │ fzctk                                 │  serial after Wave 1
              │ (deep fidelity audit)                 │  (so earlier audits clear false work)
              └─────────────┬─────────────────────────┘
                            │
                            ▼
              ┌───────────────────────────────────────┐
  Wave 3      │ h2zd9                                 │  serial after Wave 2
              │ (design spec)                         │
              └───────────────────────────────────────┘

  Separate    ┌───────────────────────────────────────┐
  track       │ 6l5yo (own REQUEST workflow)          │  parallel throughout
              │ folds §1b hook smoke into same scope  │
              └───────────────────────────────────────┘
```

**Why Wave 1 holds 4 parallel audits** (vs strawman's 2): `mh4ek` and `5wbhm` are read-classify-document work over disjoint inputs (constraint list / codegen claim). Zero contention with `3iz51`/`qzr8a`. Adding them to Wave 1 maximizes information-per-unit-time without blocking the cascade.

**Why `fzctk` still after Wave 1** (despite being in-cascade): Same rationale as strawman — `qzr8a` may reveal that older hand-authored SKILL.md fragments were absorbed by superseded REQUESTs (`bwfqm` etc.), invalidating fzctk fragment-walks. Serial-after-parallel is the cheapest sequencing that avoids re-work.

**Why `h2zd9` is last:** Design-spec authoring for `pkg/protocol` consumption benefits from knowing what's actually used today; Wave 1 + 2 surface that.

**Why `6l5yo` is parallel throughout:** Implementation work runs on its own REQUEST workflow. No dependency on the audit cadence.

## §4. Cross-cutting URE/UAT template

Every audit URE asks (at minimum) these 5 standard questions. Audit-specific URE additions in §5 layer on top. All audits go through (at minimum) these 5 standard UAT gates.

### Standard URE (per audit)

| # | Question | Why it matters |
|---|---|---|
| **U1. Vocabulary** | Is the proposed verdict vocabulary the right one for this audit? Any verdicts to add/remove/rename? | Locks the audit's decision space. Drifting vocabulary mid-audit is the most common failure mode. |
| **U2. Done criteria** | What does "audit done" mean — every item verdicted, every item *and* commented, every item *and* residual filed? | Determines termination. |
| **U3. Residual policy** | Where do residuals go? new bd tasks (with `discovered-from`), ROADMAP.md notes, both, other? | Audits surface follow-up work; the policy must be set before the audit starts. |
| **U4. Verbatim-attention items** | Any items the user wants flagged for special treatment? | Lets the user steer attention. |
| **U5. Approval to proceed** | Once U1–U4 answered, proceed to completion, or pause again at a defined midpoint? | Some audits are wide enough to warrant mid-checkpoints. |

### Standard UAT gates (per audit)

| # | Gate | Pass criterion |
|---|---|---|
| **A1. Artifact exists** | Audit produced a durable artifact (table / doc / bd comments) in the agreed location. |
| **A2. Coverage** | Every item in input list has exactly one verdict from the U1-approved vocabulary. |
| **A3. Residual provenance** | Every residual is filed per U3 policy with `discovered-from:<audit-id>` (or equivalent). |
| **A4. ROADMAP synchronization** | `docs/ROADMAP.md` reflects the audit's outcome. |
| **A5. Audit task closes** | Audit's bd task closes with a one-line summary; `ow0pq` re-checks readiness if applicable. |

---

## §5. Per-type templates with in-use instantiations

Each subsection has:
- **Template** — the URE additions + UAT additions for any future audit of this type.
- **In-use instantiation** — the audit currently in this slot, with its specific scope and overrides.

### §5.1 Fidelity audits

**Type template — URE additions:**

| # | Question | Default |
|---|---|---|
| **F1. Verdict vocabulary** | Per-fragment verdict set | `captured / distorted / irrelevant / unverifiable / superseded` |
| **F2. Fragment granularity** | What counts as a "fragment"? | Header-rooted block (each `##`/`###` section is one fragment) |
| **F3. Distortion threshold** | Paraphrase-equivalent OK or byte-for-byte? | Paraphrase-equivalent OK *if* operational instruction is preserved |
| **F4. Distorted-fragment handling** | File bd fix task, edit Go literal directly, or flag for next codegen revision? | File bd fix tasks; do not edit during audit (audit = read-only) |
| **F5. Irrelevant-fragment handling** | ROADMAP §0 cross-ref entry for irrelevant fragments? | Yes — irrelevant fragments deserve a "why this isn't carried" note |

**Type template — UAT additions:**

| # | Gate |
|---|---|
| **F-A1** | Fidelity table — one row per fragment: `[fragment-name | parent-line-range | Go-region | verdict | note]` in `docs/audits/<id>-<slug>.md`. |
| **F-A5** | One-line R-row verdict declared (when applicable) — e.g., for `fzctk`: R1 status DONE / DONE-with-residuals / NOT-DONE. |

#### In-use: `fzctk` — Supervisor + worker SKILL.md per-fragment fidelity

- **Scope:** Parent `aura-plugins/skills/supervisor/SKILL.md` L341–L869 (528 lines) + `aura-plugins/skills/worker/SKILL.md` L253–L568 (315 lines). Pasture `pasture/internal/codegen/specs_data_body.go::supervisorBody` (L24+) + `::workerBody` (L1375+).
- **Vocabulary additions (per URE U4):** `unverifiable` (Go region unclear), `superseded` (fragment intentionally replaced by different mechanism — e.g., constraint cross-reference replacing severity-routing prose per Q2 outcome).
- **Per-audit overrides:** F4 — `superseded` verdict adds a ROADMAP §0 entry citing the replacement mechanism (e.g., "SKILL.md severity-routing prose superseded by C-* constraint cross-references — see §0").
- **R-row impact:** Audit ends with one line declaring R1 ("Port aurad") completeness at the codegen-fidelity layer.

### §5.2 Triage audits

**Type template — URE additions:**

| # | Question | Default |
|---|---|---|
| **T1. Verdict vocabulary** | Per-item verdict set | `close-superseded / extract-residual / special-attention / keep-open` |
| **T2. Bucket boundaries** | Cuts already proposed, or refine? | Use as-is unless the audit surfaces misfits |
| **T3. Residual extraction template** | What fields does the new bd task need? | At minimum: title, 1-sentence description, `discovered-from:<source-item>`, label `aura:residual`, priority inherited unless lowered with reason |
| **T4. Verbatim attention** | Items to flag for special handling? | Audit-specific |
| **T5. Closure-reason convention** | Standard `--reason=` string? | Audit-specific |

**Type template — UAT additions:**

| # | Gate |
|---|---|
| **T-A1** | Triage table — one row per item: `[bucket | id | title | verdict | reason | residual-task-id?]` in `docs/audits/<id>-<slug>.md`. |
| **T-A3** | Closure execution — all `close-superseded` items actually closed; all `extract-residual` items have residual tasks filed. |
| **T-A5** | One-line R-row verdict (when applicable) — for `qzr8a`: R1/R2 carry-residuals YES/NO. |

#### In-use: `qzr8a` — 19 stale items across 3 buckets

- **Scope:** Bucket A (10 REQUESTs: `oqhjg/bwfqm/fw1cx/u3ae0/odasf/lczzv/ytj66/3ubig/v2a51/q72mt`); Bucket B (6 Python-era: epic `2tj` + URDs `bwfqm/o7i9/7vtb/e28b/s6i`); Bucket C (3 non-Python URDs: `1nla/99q/s7l0`). `bwfqm` overlaps A+B (single audit suffices) → 18 unique items.
- **Verbatim attention (T4):** `q72mt` (rework supervisor — may already be covered by Pasture), `s7l0` (path bug — may need pasture-release carry-over), `1nla` (aura-swarm scope decision).
- **Closure reason convention (T5):** `"superseded by PROPOSAL-2 + naupi"` for the default close-superseded case; audit-specific otherwise.
- **R-row impact:** Ends with one line on whether any Bucket A/B item carried residuals against R1 ("Port aurad") or R2 ("Port aura-msg").

### §5.3 Spec audits

**Type template — URE additions:**

| # | Question | Default |
|---|---|---|
| **S1. Spec axes** | What policy/design axes does the spec cover? | Audit-specific (vocabulary is the axis list, not a verdict set) |
| **S2. Audience** | Internal contributors, external consumers, or both? | Both. `[internal]` vs `[external]` section tags where they differ |
| **S3. Survey-before-spec?** | Should the audit first survey current state before authoring policy? | Yes — survey informs whether `v0.x` ("no stability") or `v1.0+` ("semver-strict") framing is honest |
| **S4. Deliverable location** | Where does the spec live? | `docs/specs/<slug>.md` (new file). Cross-link from relevant package docs |
| **S5. Examples required?** | Worked examples mandatory? | Yes — one example per spec axis. Abstract policy without examples ages badly |

**Type template — UAT additions:**

| # | Gate |
|---|---|
| **S-A1** | Spec doc exists at agreed location with sections for all S1 axes. |
| **S-A2** | Each axis has: (a) policy statement, (b) rationale, (c) at least one worked example. |
| **S-A3** | Cross-references from relevant package docs land. |
| **S-A5** | One-line R-row verdict (when applicable). |

#### In-use: `h2zd9` — `pkg/protocol` cross-module consumption spec

- **Scope:** Author missing consumption policy for `pasture/pkg/protocol` — versioning, semver, import-path, deprecation, module-pinning.
- **Spec axes (S1):** `versioning-strategy / semver-guarantees / import-path-convention / deprecation-policy / module-version-pinning`.
- **Audience (S2):** Both internal Pasture contributors AND external consumers (`agent-data-leverage` first).
- **Survey-before-spec (S3):** Yes — survey current consumers (intra-Pasture + `agent-data-leverage`) before writing policy.
- **Deliverable location (S4):** `docs/specs/pkg-protocol-consumption.md` (new file). Cross-link from `pasture/pkg/protocol/doc.go` or `pkg/protocol/README.md`.
- **R-row impact:** Ends with one line declaring `jbnx3` R5 ("Shared Go Library") status: DONE / DONE-with-residuals / NOT-DONE.

### §5.4 Classification audits

**Type template — URE additions:**

| # | Question | Default |
|---|---|---|
| **C1. Placement vocabulary** | Per-item placement set | `§5-done / §2-active / §0-cross-ref / §4-discovered` |
| **C2. Verify-vs-trust** | Confirm placement defaults via `bd show`, or trust them? | Verify — costs N `bd show` calls, prevents misclassification |
| **C3. Cross-reference style** | Full ROADMAP rows or bullet cross-refs? | Full rows for `§2-active`; bullet refs in `§0` for policy/administrative items |
| **C4. Edit batching** | One commit for all edits or per-item? | One commit (the audit is the unit of work) |
| **C5. Peer linkage** | Does placement reveal items as IS-R-rows? Update dep graph if so. | Verify per item; §1.5 table should match dep graph |

**Type template — UAT additions:**

| # | Gate |
|---|---|
| **C-A1** | Placement table: `[item-id | title | verdict | rationale | roadmap-location]` in bd comments or `docs/audits/<id>-<slug>.md`. |
| **C-A3** | ROADMAP.md has N new entries (or cross-refs) at the placements. Verifiable via diff. |

#### In-use: `3iz51` — 8 sibling epic placement

- **Scope:** Place 8 sibling epics into ROADMAP buckets. Epics: `x5071`, `q9sz9`, `wftdf`, `rk2su`, `ytzcl`, `ad8i1`, `9wdwc`, `6ujr` (defaults per task description).
- **Verify-vs-trust (C2):** Verify each — `q9sz9` / `wftdf` may not actually be done despite default of `§5-done`.
- **Peer-epic linkage (C5):** Verify per epic; if `rk2su` is placed `§5-done` but still blocks `ow0pq`, either close it or add a ROADMAP note that closure is upstream-of-`ow0pq`.

### §5.5 Coverage audits

**Type template — URE additions:**

| # | Question | Default |
|---|---|---|
| **Cv1. Verdict vocabulary** | Per-item completeness verdict set | `ported / missing / divergent` |
| **Cv2. Source-of-truth identification** | What's the canonical list to cover against? | Audit-specific (e.g., Python `constraints.py` source enumeration) |
| **Cv3. Test-coverage required?** | Is "ported" enough, or must Go side also be tested? | Both — `ported` requires (a) presence in Go (b) test coverage. `divergent` if implementations differ semantically |
| **Cv4. Gap-handling** | What happens to `missing` items? | File bd bug tasks with `discovered-from:<audit-id>` for each missing item; do not implement during audit |
| **Cv5. Closure condition** | Close audit when all items verdicted, or when all `missing` items filed? | When all items verdicted AND all `missing`/`divergent` items have follow-up bd tasks |

**Type template — UAT additions:**

| # | Gate |
|---|---|
| **Cv-A1** | Coverage table: `[item-id | source-canonical | go-impl-path | tested? | verdict | gap-task-id?]` in `docs/audits/<id>-<slug>.md`. |
| **Cv-A2** | Every item from source-canonical list appears exactly once. |
| **Cv-A3** | Every `missing`/`divergent` has a follow-up bd task. |

#### In-use: `mh4ek` — 26 Python C-* constraint coverage in Go

- **Scope:** Enumerate Python `aura-plugins/scripts/aura_protocol/constraints.py::RuntimeConstraintChecker` constraints (canonical source = 26 items per `aura-plugins/CLAUDE.md`). Cross-reference each against Go (`pasture/internal/temporal/ActivityCheckConstraints` + dependents).
- **Source-of-truth (Cv2):** Python `constraints.py` validator list (26 C-* IDs).
- **Test-coverage requirement (Cv3):** Yes — `ported` requires (a) Go implementation exists, (b) Go unit/integration test exercises it. `divergent` if the Go validator returns different results from Python for the same input.
- **Out-of-cascade:** `mh4ek` does NOT block `ow0pq`. It runs in Wave 1 for parallelism but its completion is decoupled from `jbnx3` closure. If gaps surface, the gap-fix bd tasks are filed under `cmvu5` §4 (discoveries) per task description.

### §5.6 Status audits

**Type template — URE additions:**

| # | Question | Default |
|---|---|---|
| **St1. Verdict vocabulary** | Per-claim verdict set | `confirmed / refuted / qualified` |
| **St2. Claim statement** | What claim is being verified? | Audit-specific (1-sentence claim) |
| **St3. Evidence types accepted** | Code, docs, commit history, tests, observed behavior? | All four; weight observed behavior highest, code second, docs/history as supporting |
| **St4. Qualified-answer threshold** | When does `qualified` apply vs `refuted`? | `qualified` if claim is true with caveats explicitly stated; `refuted` if claim is false and no salvageable form holds |
| **St5. Deliverable location** | Where does the answer land? | (a) bd comment on the audit task with verdict + evidence, (b) update relevant package docs / AGENTS.md if status was undocumented |

**Type template — UAT additions:**

| # | Gate |
|---|---|
| **St-A1** | Verdict statement: 1-sentence verdict + bullet-list evidence. In bd comment AND in target docs location per St5. |
| **St-A2** | Coverage = 1 (one claim, one verdict — trivial). |
| **St-A3** | If `refuted` or `qualified`, follow-up tasks filed to either fix the gap or update the claim. |

#### In-use: `5wbhm` — Is Go codegen authoritative for SKILL.md generation?

- **Claim statement (St2):** "`pasture/internal/codegen/skills.go` is the authoritative implementation for SKILL.md generation; Python `aura-plugins/scripts/aura_protocol/gen_skills.py` is deprecated and superseded."
- **Expected verdict:** Likely `confirmed` — `naupi` closure + `docs/PYTHON_TO_GO_MIGRATION.md` already establish Go canonicity. Audit serves as the formal status capture.
- **Evidence types (St3):** Check `Makefile`, `go:generate` directives, `aura-plugins/CLAUDE.md` "Regenerating Skill Headers" section, the `DEPRECATED.md` banner, observed regeneration behavior.
- **Deliverable location (St5):** Update `pasture/AGENTS.md` "Code generation" section (or add one) + close the audit task with the verdict statement as the close reason.
- **Out-of-cascade:** Doesn't block `ow0pq`.

### §5.7 Sweep audits (placeholder)

*No current audit. Template TBD when first sweep audit lands. Anticipated shape:*

- **Verdict vocabulary:** `clean` / `found-N-issues` / `further-sweep-needed`
- **URE focus:** scope boundary (what's in vs out), "clean" definition (zero issues vs zero issues above-severity), how to handle found items.
- **UAT focus:** sweep coverage (was every in-scope file/dir/symbol checked?), found-issue follow-up tasks filed.

Expand to full template when a sweep audit is filed.

### §5.8 Reconciliation audits (placeholder)

*No current audit. Template TBD when first reconciliation audit lands. Anticipated shape:*

- **Verdict vocabulary:** `aligned` / `drift-found` / `unresolvable`
- **URE focus:** the two sources of truth being compared, how to handle drift (which source wins, or both update), what "unresolvable" means.
- **UAT focus:** comparison table, drift findings filed, source-of-truth precedence documented.

Expand to full template when a reconciliation audit is filed.

---

## §6. Reviewer axes + cadence for THIS meta-plan

Per URE U3: standard 3 axes.

| Axis | Reviewer mandate |
|---|---|
| **Correctness** | Does PROPOSAL-2 actually solve the user's REQUEST? Are the URE outputs incorporated faithfully? Does the audit roster (§1) cover what `cmvu5` and `ow0pq` need? Are the verdict vocabularies sound for each audit type? |
| **Coverage** | Has anything been missed? Audits not in §1 that should be (sweep/reconciliation excluded by URE U6, but verify nothing else is dropped). Per-type templates that miss a common question/gate. Out-of-cascade items mis-flagged. Edge cases in the wave sequencing. |
| **Elegance** | Is the 8-type taxonomy actually clean, or are types collapsible (e.g., does coverage IS classification-with-completeness-overlay)? Is the wave sequencing the simplest defensible? Is the per-type + per-audit structure (§5) the right factoring, or are the templates and instantiations doing the same work twice? |

**Reviewer cadence:** Parallel waves. All 3 reviewers run on each round; round closes only when all 3 ACCEPT in the same wave. REVISE → PROPOSAL-N+1 → re-launch all 3 reviewers. Per protocol: a partial ACCEPT (2/3) is still a REVISE.

**Reviewer spawn:** `general-purpose` subagents via Task tool, each instructed to first invoke `/aura:reviewer` skill, then read PROPOSAL-2 + this revision-log + URE outputs from `blh3a`.

## §7. Open questions for UAT signoff

These persist past reviewer consensus to UAT. Items the reviewer cycle won't decide because they're user judgment calls:

| # | Question | Default proposal |
|---|---|---|
| **UAT1. Wave-1 mh4ek/5wbhm parallelism** | OK that out-of-cascade audits run in Wave 1, or should they wait until in-cascade Wave 1 finishes? | Run in Wave 1 (zero contention). |
| **UAT2. Audit artifact directory** | `docs/audits/<id>-<slug>.md` (new dir) or different location? | `docs/audits/` — created lazily by first audit. |
| **UAT3. Per-audit ELICIT timing** | File all 6 ELICIT tasks at once after ratify, or per-wave as we approach each? | Per-wave — defer Wave 2/3 ELICIT filing until Wave 1 lands (qzr8a outputs may inform fzctk URE). |
| **UAT4. R-row verdict format** | Standardize the one-line R-row verdict format? | "R<N> status: DONE / DONE-with-residuals-filed / NOT-DONE-residuals-block-R<N>" — strict 3-form. |
| **UAT5. 6l5yo REQUEST timing** | File 6l5yo's REQUEST workflow now (parallel with Wave 1) or after Wave 1 lands? | Now — fully independent of audit waves. |
| **UAT6. mh4ek and 5wbhm priority** | Bump priority to match in-cascade audits, or leave at P3? | Leave at P3. Out-of-cascade by design. |

## §8. Cross-references

- **Closure triage:** [`aura-plugins-ow0pq`](beads://aura-plugins-ow0pq) — gate this plan unblocks (for 4 of 6 audits).
- **Source epic:** [`aura-plugins-cmvu5`](beads://aura-plugins-cmvu5) — FOLLOWUP-ROADMAP epic.
- **Parent URD:** [`aura-plugins-jbnx3`](beads://aura-plugins-jbnx3) — Pasture URD whose closure this gates.
- **REQUEST:** [`aura-plugins-mld74`](beads://aura-plugins-mld74) — captures verbatim user prompt.
- **ELICIT:** [`aura-plugins-blh3a`](beads://aura-plugins-blh3a) — URE outputs locked.
- **Prior proposal:** [PROPOSAL-1](PROPOSAL-1-audit-execution-plan.md) — pre-URE strawman.
- **Prior audit precedent:** [ROADMAP-COMPLETENESS-AUDIT.md](ROADMAP-COMPLETENESS-AUDIT.md) — 2026-05-24 investigation that produced the 5 in-cascade follow-ups.
- **Live ROADMAP:** [docs/ROADMAP.md](../ROADMAP.md) — §1.5 lists the closure cascade.
- **Migration policy:** [docs/PYTHON_TO_GO_MIGRATION.md](../PYTHON_TO_GO_MIGRATION.md) — relevant to `fzctk`, `qzr8a`, `mh4ek`, `5wbhm`.
