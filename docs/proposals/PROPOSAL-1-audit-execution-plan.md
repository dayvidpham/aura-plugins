---
name: PROPOSAL-1 — Audit execution plan
status: PRE-URE STRAWMAN — drafted before the URE was filed (process violation per user 2026-05-25). The URE in aura-plugins-blh3a takes precedence; this doc will be revised in light of URE outputs and then run through the 3-reviewer cycle until consensus, then UAT.
description: Meta-plan for executing the 5 visibility audits that block `jbnx3` closure. For each audit, lays out the URE-style scoping questions and UAT-style acceptance criteria so the user can sign off on shape before execution begins. Sequencing organizes audits into 3 parallelizable waves plus a separate-track REQUEST for the lone implementation item. No bd tasks are filed by this doc; it produces the spec, not the work.
references:
  request: aura-plugins-mld74
  elicit: aura-plugins-blh3a
  parent_urd: aura-plugins-jbnx3
  closure_triage: aura-plugins-ow0pq
  source_epic: aura-plugins-cmvu5
  audit_proposal: aura-plugins-ircvi (docs/proposals/ROADMAP-COMPLETENESS-AUDIT.md)
  audit_request: aura-plugins-t3498
  roadmap: docs/ROADMAP.md
  migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
  audits:
    fzctk: aura-plugins-fzctk (§1j SKILL.md fidelity)
    qzr8a: aura-plugins-qzr8a (§2i stale-items triage)
    h2zd9: aura-plugins-h2zd9 (§2k pkg/protocol consumption spec)
    iz51: aura-plugins-3iz51 (§4c sibling-epic placement)
    l5yo: aura-plugins-6l5yo (§2g git_recorder.go graduation)
---

# PROPOSAL-1 — Audit execution plan for `jbnx3` closure visibility audits

> **Status:** Pre-URE strawman. User feedback 2026-05-25: *"Before
> producing this: should have done a URE. Then this audit plan should
> go through the proposal and review cycle until we have all 3
> reviewers agreeing every review wave. Then the plan should go to a
> UAT."* The doc remains useful as an anchor for the URE discussion,
> but its specifics (sequencing, vocabularies, gates) are proposals
> subject to URE revision, not ratified decisions. After the URE in
> [`aura-plugins-blh3a`](beads://aura-plugins-blh3a) settles, this doc
> will be revised (potentially as PROPOSAL-2) and submitted to the
> 3-reviewer cycle.

This document plans the execution of the 5 visibility audits that block
`aura-plugins-ow0pq` (the `jbnx3` closure triage), so the user can sign
off on **shape, sequencing, and acceptance criteria** before any audit
work begins.

The plan is structured as the URE + UAT that will be run *for each
audit* — not the URE + UAT for the whole audit batch. Each audit gets
its own scoping survey (URE) and its own acceptance ceremony (UAT)
because the audits differ enough in shape (fidelity vs triage vs spec
vs classification vs implementation) that a single uniform spec would
under-serve all of them.

## §0. What this doc is and isn't

**Is:**

- A meta-plan for the 5 audit-shaped tasks under
  [`aura-plugins-ow0pq`](beads://aura-plugins-ow0pq).
- A per-audit URE-question + UAT-acceptance specification so the user
  can red-line shape before execution.
- The basis for filing the actual URE bd tasks once the plan is
  approved.

**Isn't:**

- An implementation plan (no code or doc edits proposed here).
- A bd task tree (no `bd create` happens from this doc).
- A plan for the 4 peer epics ([`bch`](beads://aura-plugins-bch),
  [`6ujr`](beads://aura-plugins-6ujr),
  [`rk2su`](beads://aura-plugins-rk2su),
  [`x5071`](beads://aura-plugins-x5071)) that also block `ow0pq` —
  those are implementation epics with their own existing workflows.
  They're flagged in §6 for visibility but not specified here.

## §1. Audit inventory

The 5 tasks blocking `ow0pq` are not all the same shape. The plan
classifies them as **4 audits** (URE/UAT-shaped) + **1 implementation**
(REQUEST-shaped), per advisor feedback that `6l5yo` is "graduate a
stub to production" rather than a backlog-hygiene investigation.

| Task | ROADMAP § | Shape | Cost | Risk | Surfaces info for |
|---|---|---|---|---|---|
| [`fzctk`](beads://aura-plugins-fzctk) | §1j | **Fidelity audit** — compare hand-authored vs generated, fragment by fragment | High | High (informs R1 codegen completeness) | `jbnx3` R1 closure |
| [`qzr8a`](beads://aura-plugins-qzr8a) | §2i | **Residual triage** — 19 stale items across 3 buckets, close or extract | Medium (wide, shallow) | Medium (may carry residuals against R1/R2) | `jbnx3` R1/R2 closure + backlog hygiene |
| [`h2zd9`](beads://aura-plugins-h2zd9) | §2k | **Design spec** — author missing consumption policy for `pkg/protocol` | Medium-High | Medium (IS `jbnx3` R5) | `jbnx3` R5 closure |
| [`3iz51`](beads://aura-plugins-3iz51) | §4c | **Classification audit** — place 8 sibling epics into ROADMAP buckets | Low-Medium | Low (mostly classification) | Status of `x5071`/`6ujr`/`rk2su`/`9wdwc` |
| [`6l5yo`](beads://aura-plugins-6l5yo) | §2g | **Implementation** (REQUEST-shaped, not audit) | Medium-High (real code) | Low (well-scoped) | R1/R4-adjacent hook wiring |

## §2. Wave sequencing

The advisor pushed back on over-serialization. Final sequencing:

```
              ┌─────────────────────────────┐
  Wave 1      │ 3iz51    qzr8a              │  parallel (both classification/triage)
  (parallel)  │ (8 epics)  (19 items)       │
              └─────────────┬───────────────┘
                            │ surfaces residuals + status
                            ▼
              ┌─────────────────────────────┐
  Wave 2      │ fzctk                       │  serial after Wave 1
              │ (deep fidelity audit)       │  (so earlier audits clear false work)
              └─────────────┬───────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
  Wave 3      │ h2zd9                       │  serial after Wave 2
              │ (design spec)               │  (consumption story informed by audits)
              └─────────────────────────────┘

  Separate    ┌─────────────────────────────┐
  track       │ 6l5yo                       │  REQUEST workflow, parallel throughout
              │ (graduate git_recorder.go)  │  (no dependency on the audit waves)
              └─────────────────────────────┘
```

**Rationale per wave:**

- **Wave 1 (parallel):** `3iz51` and `qzr8a` are both
  read-classify-decide work over disjoint lists (8 sibling epics vs
  19 stale items). No contention; running in parallel gives the most
  information per unit time. `3iz51` resolves the status of 4 peer
  epics that also block `ow0pq` — useful framing for everything
  downstream. `qzr8a` may surface residuals that need to be filed as
  follow-ups (or that turn out to already be covered by Pasture),
  clearing the field for `fzctk`.
- **Wave 2 (serial):** `fzctk` is the deepest, most-information audit.
  Running it last on the audit side prevents wasted attention on
  fragments that Wave 1 might reveal as already-superseded.
- **Wave 3 (serial after Wave 2):** `h2zd9` is design-authoring work
  (a policy spec for `pkg/protocol` consumption). It has no hard
  dependency on Wave 1 or 2, but the import-path / deprecation-policy
  decisions are easier to make once we've audited what's actually
  using the package today.
- **Separate track (parallel throughout):** `6l5yo` is implementation
  work (graduate `git_recorder.go` from stub). It runs under its own
  REQUEST → ARCHITECT → IMPL_PLAN workflow, independent of the audit
  cadence. See §6.

**Why not run all 4 audits in parallel?** Wave 1's outputs change what
`fzctk` and `h2zd9` are actually auditing. If `qzr8a` reveals that
`bwfqm` already absorbed half of `fzctk`'s in-scope fragments, we
don't want to have already done that fragment-by-fragment walk.
Serial-after-parallel is the cheapest sequencing that avoids
re-work.

## §3. Cross-cutting URE/UAT template

Every audit URE asks (at minimum) these 5 questions. Audit-specific
URE questions in §4 are layered on top.

### URE (5 standard questions per audit)

| # | Question | Why it matters |
|---|---|---|
| **U1. Vocabulary** | Is the proposed verdict vocabulary (see audit-specific §4 entries) the right one? Any verdicts to add/remove/rename? | Locks the audit's decision space. Drifting vocabulary mid-audit is the most common failure mode. |
| **U2. Done criteria** | What does "audit done" mean — every item verdicted, every item *and* commented, every item *and* residual filed? | Determines termination. Without it the audit drifts. |
| **U3. Residual policy** | Where do residuals go? (a) new bd tasks with `discovered-from`, (b) ROADMAP.md notes, (c) both, (d) other. | Audits surface follow-up work; the policy must be set before the audit starts so we don't lose findings. |
| **U4. Verbatim-attention items** | Any items in the list the user wants flagged verbatim or treated specially? (Audit-specific defaults listed in §4 where applicable.) | Lets the user steer attention without re-deriving from scratch. |
| **U5. Approval to proceed** | Once U1–U4 are answered, proceed without further check-in, or pause again at a defined midpoint? | Some audits are wide enough that a mid-audit re-check might be wanted. |

### UAT (5 standard acceptance gates per audit)

| # | Gate | Pass criterion |
|---|---|---|
| **A1. Artifact exists** | Audit produced a durable artifact (table, doc, or set of bd comments) in the agreed location. |
| **A2. Coverage** | Every item in the audit's input list has exactly one verdict from the U1-approved vocabulary — no omissions, no double-verdicts. |
| **A3. Residual provenance** | Every residual is filed per U3 policy with `discovered-from:<audit-id>` (or equivalent) so the audit chain is traceable. |
| **A4. ROADMAP synchronization** | `docs/ROADMAP.md` reflects the audit's outcome (status flips, new §-rows added, removed items struck through). |
| **A5. Audit task closes** | The audit's bd task (`fzctk` / `qzr8a` / etc.) closes with a one-line summary commit, and `ow0pq` re-checks readiness. |

---

## §4. Per-audit URE + UAT specs

### §4.1 `fzctk` — SKILL.md per-fragment fidelity audit

**ROADMAP row:** §1j. **bd task:** [`aura-plugins-fzctk`](beads://aura-plugins-fzctk).
**Wave:** 2 (serial after Wave 1).

#### Scope (what the audit walks)

- **Parent (hand-authored):**
  - `aura-plugins/skills/supervisor/SKILL.md` — lines L341–L869 (528 lines)
  - `aura-plugins/skills/worker/SKILL.md` — lines L253–L568 (315 lines)
- **Pasture (generated):**
  - `pasture/internal/codegen/specs_data_body.go::supervisorBody` (L24+)
  - `pasture/internal/codegen/specs_data_body.go::workerBody` (L1375+)

#### Per-audit URE questions (layered on §3 U1–U5)

| # | Question | Default proposal |
|---|---|---|
| **F1. Verdict vocabulary** | Per-fragment verdict set | `captured` / `distorted` / `irrelevant` (per task description). Add `unverifiable` for fragments where the Go-side region is unclear? |
| **F2. Fragment granularity** | What counts as a "fragment" — paragraph, section, header-rooted block? | Header-rooted block (i.e., each `##`/`###` section under the audited line range is one fragment). |
| **F3. Distortion threshold** | Is paraphrase-equivalent OK, or must it be byte-for-byte? | Paraphrase-equivalent OK *if* the operational instruction is preserved. The Q2 outcome already settled severity-routing prose: SoT moves to the constraint-ID cross-reference. |
| **F4. Distorted-fragment handling** | When a fragment is `distorted`, file a bd fix task, edit the Go literal directly, or flag for next codegen-spec revision? | File bd fix tasks with `discovered-from:fzctk`; do not edit during the audit (audit = read-only). |
| **F5. Irrelevant-fragment handling** | When a fragment is `irrelevant` (e.g., parent-only prose that shouldn't be carried), is that worth a ROADMAP §0 cross-ref entry? | Yes — `irrelevant` fragments deserve a ROADMAP §0 note explaining why they don't carry (otherwise a future reader re-asks). |
| **F6. Constraint cross-references** | If a fragment defers to a C-* constraint (per Q2), is that automatically `captured`, even if the Go literal omits it? | Yes — constraint deference is the SoT pattern. The Go SKILL.md should mention the constraint by ID; absence of the prose itself isn't a distortion. |

#### Per-audit UAT acceptance (layered on §3 A1–A5)

| # | Gate | Pass criterion |
|---|---|---|
| **F-A1** | Fidelity table | A markdown table with one row per fragment: `[fragment-name | parent-line-range | Go-region | verdict | note]`. Lives in `docs/audits/fzctk-skill-fidelity.md` (new file). |
| **F-A2** | Coverage | Every header-rooted block in supervisor L341–L869 and worker L253–L568 appears exactly once. Verify via diff against a generated section-list. |
| **F-A3** | Distorted-fragment tasks | Each `distorted` verdict has a corresponding `aura-plugins-*` bd fix task with `discovered-from:fzctk`. The task title cites the parent line range and the Go region. |
| **F-A4** | ROADMAP impact | ROADMAP §1j status flips ✅; new §0 cross-ref entries land if any `irrelevant` fragments deserved them. |
| **F-A5** | jbnx3 R1 verdict | The audit ends with one line in the fidelity doc declaring whether R1 "Port aurad" is genuinely complete at the codegen-fidelity layer (DONE / DONE-with-residuals-filed / NOT-DONE-residuals-block-R1). This is the line `ow0pq` will quote. |

---

### §4.2 `qzr8a` — 19 stale work items triage

**ROADMAP row:** §2i. **bd task:** [`aura-plugins-qzr8a`](beads://aura-plugins-qzr8a).
**Wave:** 1 (parallel with `3iz51`).

#### Scope (what the audit walks)

19 items across 3 buckets (`bwfqm` appears in both A and B — single audit suffices):

- **Bucket A — 10 stale 2026-03 REQUESTs:** `oqhjg / bwfqm / fw1cx / u3ae0 / odasf / lczzv / ytj66 / 3ubig / v2a51 / q72mt`
- **Bucket B — 6 Python-era artifacts:** epic `2tj` + URDs `bwfqm / o7i9 / 7vtb / e28b / s6i`
- **Bucket C — 3 non-Python URDs:** `1nla / 99q / s7l0`

#### Per-audit URE questions

| # | Question | Default proposal |
|---|---|---|
| **Q1. Verdict vocabulary** | Per-item verdict set | `close-superseded` / `extract-residual` / `special-case-attention` / `keep-open-as-is`. ("keep-open-as-is" handles items that are stale-looking but still actively relevant.) |
| **Q2. Bucket boundaries** | Are A/B/C the right cuts, or should we add a Bucket D for items that don't fit (none currently flagged)? | Keep A/B/C as is; flag any misfits during the audit. |
| **Q3. Residual extraction template** | When `extract-residual`, what fields does the new bd task need? | At minimum: title, 1-sentence description citing the source item, `discovered-from:<source-item>`, label `aura:residual`, priority inherited from source unless lowered with reason. |
| **Q4. Verbatim attention** | Defaults from the task description: `q72mt` (rework supervisor — may already be covered by Pasture), `s7l0` (path bug — may need pasture-release carry-over), `1nla` (aura-swarm scope decision). Any other items to flag? | Confirm or add. |
| **Q5. Closure-reason convention** | When `close-superseded`, what reason string? | `"superseded by PROPOSAL-2 + naupi"` per task description, OR audit-specific reason per item. |

#### Per-audit UAT acceptance

| # | Gate | Pass criterion |
|---|---|---|
| **Q-A1** | Triage table | A markdown table with one row per item: `[bucket | id | title | verdict | reason | residual-task-id?]`. Lives in `docs/audits/qzr8a-stale-items.md` (new file). |
| **Q-A2** | Coverage | 18 unique items (19 - 1 for the `bwfqm` overlap) appear exactly once. Each verdict is from the Q1 vocabulary. |
| **Q-A3** | Closure execution | All `close-superseded` items are actually closed via `bd close <id> --reason=<reason-from-Q5>`. All `extract-residual` items have residual tasks filed per Q3 template. |
| **Q-A4** | ROADMAP impact | ROADMAP §2i status flips ✅. Any newly-filed residuals that match an existing §-row are linked there. |
| **Q-A5** | jbnx3 R1/R2 verdict | The audit ends with one line declaring whether any Bucket A/B item carried residuals against R1 ("Port aurad") or R2 ("Port aura-msg"). This is the second line `ow0pq` will quote. |

---

### §4.3 `h2zd9` — `pkg/protocol` cross-module consumption spec

**ROADMAP row:** §2k. **bd task:** [`aura-plugins-h2zd9`](beads://aura-plugins-h2zd9).
**Wave:** 3 (serial after Wave 2).

#### Scope (what the audit writes)

This is a **design-spec audit** — the output is a written policy, not a
fidelity verdict. It specifies the consumption story for *other* Go
modules importing `pasture/pkg/protocol`.

#### Per-audit URE questions

| # | Question | Default proposal |
|---|---|---|
| **H1. Spec axes** | What policy axes does the spec cover? | `versioning-strategy` / `semver-guarantees` / `import-path-convention` / `deprecation-policy` / `module-version-pinning`. Per advisor breakdown of "consumption story". |
| **H2. Audience** | Who is the spec written for — internal Pasture contributors, external `agent-data-leverage` consumers, or both? | Both. Sections marked `[internal]` vs `[external]` where they differ. |
| **H3. Existing consumer survey** | Should the audit first survey *current* consumers of `pkg/protocol` (intra-Pasture and `agent-data-leverage`) before writing policy? | Yes — survey first, then policy. Survey informs whether `v0.x` "no stability guarantees" or `v1.0` "semver-strict" framing is more honest. |
| **H4. Deliverable location** | Where does the spec live? | `docs/specs/pkg-protocol-consumption.md` (new file). Cross-link from `pasture/pkg/protocol/doc.go` package docs (or equivalent). |
| **H5. Examples required?** | Must the spec include worked examples (import statement, go.mod pin, deprecation cycle walkthrough)? | Yes — abstract policy without examples ages badly. Minimum: one import-path example, one deprecation-cycle example, one semver-bump example. |

#### Per-audit UAT acceptance

| # | Gate | Pass criterion |
|---|---|---|
| **H-A1** | Spec doc exists | `docs/specs/pkg-protocol-consumption.md` exists with sections for all H1-approved axes. |
| **H-A2** | Coverage | Each H1 axis has: (a) policy statement, (b) rationale, (c) at least one worked example (per H5). |
| **H-A3** | Cross-reference | `pkg/protocol` package docs (`pasture/pkg/protocol/doc.go` or `README.md`) link to the spec. |
| **H-A4** | ROADMAP impact | ROADMAP §2k status flips ✅. URD `jbnx3` R5 ("Shared Go Library") gets a comment linking the spec. |
| **H-A5** | jbnx3 R5 verdict | The audit ends with one line declaring R5 status (DONE — spec landed and external consumer story is documented; or DONE-with-residuals — spec landed but specific items deferred). Third line `ow0pq` quotes. |

---

### §4.4 `3iz51` — 8 sibling epic placement

**ROADMAP row:** §4c. **bd task:** [`aura-plugins-3iz51`](beads://aura-plugins-3iz51).
**Wave:** 1 (parallel with `qzr8a`).

#### Scope (what the audit walks)

8 sibling epics not yet placed in ROADMAP:

| Epic | Default placement (from task desc) |
|---|---|
| `x5071` (Port 30 Python skills — POLICY) | §2 active |
| `q9sz9` (codegen body integration review FOLLOWUP) | §5 done (verify) |
| `wftdf` (Go test paradigm review FOLLOWUP) | §5 done (verify) |
| `rk2su` (ACP wiring FOLLOWUP) | §5 done — IS R4 (verify per `3iz51` placement) |
| `ytzcl` (Pasture code review FOLLOWUP) | §5 done (verify) |
| `ad8i1` (UAT revision code review FOLLOWUP) | §5 done (verify) |
| `9wdwc` (Beads → Temporal migration EPIC) | §2 active |
| `6ujr` (aura-acp plugin EPIC) | §2 active — IS R4 |

#### Per-audit URE questions

| # | Question | Default proposal |
|---|---|---|
| **I1. Placement vocabulary** | Per-epic placement set | `§5-done` / `§2-active` / `§0-cross-ref` / `§4-discovered`. ("§4-discovered" added for completeness; default proposals above use §2/§5.) |
| **I2. Verify-vs-trust** | For each epic with default placement `§5-done`, must we `bd show` and confirm DONE status before placing, or trust the default? | Verify each — `q9sz9` / `wftdf` may not actually be done. Costs 8 `bd show` calls, prevents misclassification. |
| **I3. Cross-reference style** | When placing in §5/§2, do epics get full ROADMAP rows (with notes/blame) or just bullet-list cross-references? | Full rows for `§2-active` (need status, blockers, notes); bullet cross-references in §0 for items that are policy/administrative. |
| **I4. ROADMAP edit batching** | Make all 8 ROADMAP edits in one commit, or one per epic? | One commit — the audit is the unit of work, not the individual placement. |
| **I5. Peer-epic linkage** | When the placement reveals an epic IS a `jbnx3` R-row (e.g., `6ujr` IS R4), is the `ow0pq` linkage already correct, or does it need updating? | Verify per epic; the §1.5 table in ROADMAP should match the dep graph. |

#### Per-audit UAT acceptance

| # | Gate | Pass criterion |
|---|---|---|
| **I-A1** | Placement table | A markdown table (in the audit's bd comments or in a `docs/audits/3iz51-sibling-placement.md` artifact): `[epic-id | title | verdict | rationale | roadmap-location]`. |
| **I-A2** | Coverage | All 8 epics have exactly one placement from I1's vocabulary. |
| **I-A3** | ROADMAP edits applied | `docs/ROADMAP.md` has 8 new entries (or cross-refs) at the placements specified by I-A1. Verifiable via diff. |
| **I-A4** | Status flip | ROADMAP §4c status flips ✅. |
| **I-A5** | ow0pq dep graph reconciliation | If I5 reveals dep-graph drift (e.g., `rk2su` placed `§5-done` but still blocks `ow0pq`), it's either resolved by closing the epic or by an explicit ROADMAP note that the closure is upstream-of-`ow0pq`. |

---

## §5. The four standard URE questions, summarized as a matrix

For quick reference when the user is signing off on multiple audits:

| Question (per §3) | `fzctk` default | `qzr8a` default | `h2zd9` default | `3iz51` default |
|---|---|---|---|---|
| **U1 vocabulary** | captured / distorted / irrelevant | close-superseded / extract-residual / special-attention / keep-open | versioning / semver / import-path / deprecation / pinning | §5-done / §2-active / §0-cross-ref |
| **U2 done criteria** | every fragment verdicted + distorted-fix tasks filed | every item verdicted + closures executed + residuals filed | spec written + examples + cross-linked | every epic placed + ROADMAP edits applied |
| **U3 residual policy** | bd fix tasks (`discovered-from:fzctk`) | bd tasks (`discovered-from:qzr8a`, label `aura:residual`) | none expected; if any, bd tasks (`discovered-from:h2zd9`) | none expected; if any, bd tasks (`discovered-from:3iz51`) |
| **U4 verbatim attention** | (none default; user may flag fragments) | `q72mt`, `s7l0`, `1nla` per task desc | (none default; user may flag specific consumers) | (defaults in §4.4 table) |
| **U5 mid-audit checkpoint?** | Optional after supervisor done, before worker | Optional after Bucket A done | None — single design pass | None — single classification pass |

## §6. Out of scope: 4 peer epics + `6l5yo` separate track

### 6.1 Peer epics (no URE/UAT plan in this doc)

The 4 peer epics that also block `ow0pq` are implementation epics with
their own existing workflows. They are NOT URE/UAT-shaped and are NOT
specified here:

| Epic | Why excluded |
|---|---|
| [`aura-plugins-bch`](beads://aura-plugins-bch) | R3 `bin/pasture-release` IMPL_PLAN — already has slices `e19` + `6yr` + review `jjo`; runs under standard 12-phase workflow. |
| [`aura-plugins-6ujr`](beads://aura-plugins-6ujr) | R4 `aura-acp` plugin epic — standalone implementation epic. |
| [`aura-plugins-rk2su`](beads://aura-plugins-rk2su) | R4 ACP wiring FOLLOWUP — most leaves already closed; remaining work is its own cleanup, not an audit. |
| [`aura-plugins-x5071`](beads://aura-plugins-x5071) | R5 port 30 Python skills — `cgwc1` REQUEST already closed; remaining work is implementation. |

These continue under their existing dep chains. Their closure feeds
`ow0pq` directly.

### 6.2 `6l5yo` — separate track as a REQUEST

`6l5yo` (graduate `git_recorder.go` from stub to production) is
implementation work that **doesn't fit URE/UAT shape**:

- There's no list to triage, no policy to author, no fragments to
  verdict.
- The acceptance criteria are functional ("RecordCommit fires on
  upstream Claude Code Stop hook events") not investigatory.
- The work needs an architect-authored design proposal, not a
  user-clarification survey.

Proposed handling: **file `6l5yo` as its own REQUEST** under the
standard 12-phase workflow:

```
REQUEST (6l5yo or new)
  └── ELICIT (small URE — confirm hook-event variant naming, upstream bridge owner)
        └── PROPOSAL-1 (architect proposes wiring approach)
              └── IMPL_PLAN (likely 1 slice — package update + smoke)
                    └── SLICE-1 (worker)
```

The §1b smoke (hook-fired free-floating event recording) is coupled to
this and should be folded into the same REQUEST scope. Approve in §7
Q6 below.

## §7. Open questions for user signoff

Before any URE bd tasks are filed, the user should answer:

| # | Question | Default proposal |
|---|---|---|
| **S1. Wave sequencing** | Approve the Wave 1 (parallel) / Wave 2 / Wave 3 ordering, or re-shape? | Approve as drafted (§2). |
| **S2. 6l5yo as REQUEST** | Approve splitting `6l5yo` off the audit batch and handling as a standard REQUEST? Or force-fit URE/UAT? | Split off (§6.2). |
| **S3. Cross-cutting URE/UAT template** | Approve the 5 standard URE questions + 5 standard UAT gates (§3)? | Approve as drafted. |
| **S4. Verdict vocabularies** | For each audit, approve the per-§4 default vocabularies, or re-shape any? | Approve all four defaults. |
| **S5. Audit artifact location** | Audits produce `docs/audits/<id>-<slug>.md` files; create that directory now? | Yes — `docs/audits/` directory created lazily by first audit. |
| **S6. URE bd task creation** | After §7 signoff, file 4 ELICIT bd tasks (one per audit) and 1 REQUEST bd task (`6l5yo` split)? Or one batch ELICIT covering all 4 audits + the REQUEST? | 4 separate ELICIT tasks — each audit's URE is materially different and should have its own task. |
| **S7. UAT pause-point** | After each audit completes A1–A4, pause for user UAT (Phase 5–style), or auto-advance to the next wave on supervisor sign-off? | Pause for user UAT per audit — the user sees the artifact, ACCEPTs or REVISEs, then we move on. Matches "look like a /user-elicit and /user-uat for each audit" framing. |

## §8. Cross-references

- **Closure triage:** [`aura-plugins-ow0pq`](beads://aura-plugins-ow0pq) — the gate task this plan unblocks.
- **Source epic:** [`aura-plugins-cmvu5`](beads://aura-plugins-cmvu5) — the FOLLOWUP-ROADMAP epic.
- **Parent URD:** [`aura-plugins-jbnx3`](beads://aura-plugins-jbnx3) — the Pasture URD whose closure this gates.
- **Prior audit precedent:** [docs/proposals/ROADMAP-COMPLETENESS-AUDIT.md](ROADMAP-COMPLETENESS-AUDIT.md) — the 2026-05-24 audit that produced these 5 follow-ups.
- **Live ROADMAP:** [docs/ROADMAP.md](../ROADMAP.md) — §1.5 lists the closure cascade.
- **Migration policy:** `docs/PYTHON_TO_GO_MIGRATION.md` (doc since deleted in PR #6) — Python deprecation + reconciliation framing relevant to `fzctk` and `qzr8a`.
