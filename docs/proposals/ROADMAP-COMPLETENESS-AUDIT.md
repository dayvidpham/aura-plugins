---
name: ROADMAP completeness audit
description: Investigation-only proposal — profiles the FOLLOWUP-ROADMAP epic for completeness, grounds or refutes the user's two recalled threads (figure rendering in skills; supervisor skill hand-written vs generated content), and surfaces other gaps found by the sweep. Implementation is out of scope; this proposal feeds the URE that comes after the Phase 4 review.
references:
  request: aura-plugins-t3498
  source_epic: aura-plugins-cmvu5
  roadmap_doc: docs/ROADMAP.md
  migration_doc: docs/PYTHON_TO_GO_MIGRATION.md
  ratified_proposal: aura-plugins-kf87g (PROPOSAL-2)
  prior_followup_epic: aura-plugins-f59jc
  prior_followup_pasture_task_cli: aura-plugins-yeym1
  parent_urd_pasture: aura-plugins-jbnx3
---

# PROPOSAL — ROADMAP completeness audit

## 0. Revision log

| Round | Date | Reviewer outcome | Changes applied |
|---|---|---|---|
| 1 | 2026-05-24 | A=ACCEPT, B=REVISE (coverage), C=ACCEPT | Axis B caught real coverage gaps. Applied in place: §4.5 corrected (`aura-plugins-x5071` exists; "no policy" claim was wrong); §4.11 added (enumerates all 16 open epics + classifies relevance to ROADMAP — 8 prior misses); §4.12 added (reconciles parent URD `jbnx3` R1–R7 against current state); §4.13 added (`q72mt` URD called out for §4.6 triage); §5 expanded with items 1k–1r (sibling epic cross-refs), 2j–2l (URD residuals R4/R5/R7); §6 revised: Q3+Q7 merged per Axis C, Q4 dropped (resolved by §4.5 correction), Q9 + Q10 added per Axis B. |
| 2 | 2026-05-24 | A=ACCEPT, B=REVISE (R-row labels + URD sweep), C=ACCEPT | Axis B caught two more real findings. Applied in place: §4.12 R-row table rewritten against the URD's verbatim R-row text (R1=Port aurad→pastured, R2=Port aura-msg→pasture-msg, R3=Port aura-release→pasture-release — the original audit conflated R3 with "observability" and called it done, but `bch` IMPL_PLAN tracks pasture-release as in-flight); §4.14 added (sweep of all 10 open URDs — 8 prior misses including `bwfqm` "aurad + aura-msg implementation" likely-superseded by PROPOSAL-2); §6 Q10 expanded to batch the 5 Python-era URDs alongside the `2tj` epic; new Q11 for the 3 non-Python URDs (`1nla` aura-swarm, `99q` release automation, `s7l0` aura-release path bug). |
| 3 | 2026-05-24 | A=ACCEPT, B=ACCEPT (after 3 rounds), C=REVISE (named consolidation, applied in place) | Axis B reached satisfaction: "further probing would surface only orphan-leaf data-hygiene items, not new ROADMAP categories." Axis C named the Q5+Q10+Q11 consolidation, applied in place. URE proceeded. |
| URE | 2026-05-24 | User verdict on 7 questions | **Q1:** Confirm figures-pipeline closure in writing (§5 done row). **Q2:** Keep `[sup-blocker-dual-parent]` cross-reference as SoT (constraints are source of truth; pasture-side wins for severity routing). **Q3:** `git_recorder.go` → §2 deferred; CLAUDE.md v3 line → keep but re-frame (see Q8 below). **Q5:** All three buckets get individual triage (10 + 6 + 3 = 19 individual tasks). **Q6:** R5 → explicit §2 row. R7 → re-classified as DONE (polyrepo split shipped; "marketplace" word in URD was a misnomer — actual scope was the polyrepo split + we *use* Claude Code's marketplace). **NEW from Q6:** multi-vendor extensibility (OpenCode, Codex, Gemini, Antigravity) is a new §2 item not previously tracked. **Q8 catch-all:** (i) supervisor reconciliation framing refined — not "Go side wins by default" but "audit each piece of previously hand-written content to verify the Go codegen captured it accurately"; (ii) v3 framing correction — v3 was a Python Temporal engine MVP that was BUILT then ABANDONED in favor of v4 (Pasture/Go+Temporal), NOT "future engine not built". **Q9:** Individual placement for the 8 sibling epics. |

---

This is a **non-implementing** proposal. Its purpose is to profile the
FOLLOWUP-ROADMAP epic (`aura-plugins-cmvu5`) against three angles —

1. The two threads of work the user explicitly recalled
   ([§2](#2-thread-figure-rendering-in-skills) and
   [§3](#3-thread-supervisor--worker-skill-provenance)),
2. A general sweep for other gaps ([§4](#4-sweep-other-gaps)),
3. Findings consolidated into ROADMAP additions / corrections
   ([§5](#5-proposed-roadmap-additions--corrections)) and URE questions
   ([§6](#6-open-questions-for-the-ure)),

— and then to feed the **Phase 4 review loops** and the **URE** that
follows. No code or task descriptions are modified by this proposal
itself; bd issues are filed only after the URE settles which items the
user accepts.

---

## 1. Methodology

Three parallel research/exploration agents ran on 2026-05-24:

| Agent | Scope | Output |
|---|---|---|
| A | "Figure rendering in skills" — find the months-old thread the user recalled. | Conclusion + evidence inventory + ROADMAP recommendation. |
| B | "Supervisor + worker skill provenance" — what's hand-written vs codegen-generated. | Boundary analysis of both `supervisor` (212 lines drift) and `worker` (122 lines drift) SKILL.md across parent vs pasture homes. |
| C | "ROADMAP completeness sweep" — anything else missing. | Bd↔ROADMAP coverage, PROPOSAL-2 §12 coverage, substantive TODOs, v3 markers, recent-commit follow-up audit, other gaps. |

All three returned. Each one's full report is preserved in the agent
transcripts; this proposal extracts decisions and open questions.

---

## 2. Thread: figure rendering in skills

**User's recollection (verbatim, 2026-05-24):**
> *"There were a few threads of work from several months ago that I'm not
> sure are completed concerning how we handle and render figures in the
> skills."*

### Finding: the work is DELIVERED, on both sides

The figure-rendering pipeline exists, is wired into both the Python and
Go codegens, has tests asserting completeness, and has a history of
closed bd epics that drove it.

**Concrete pipeline:**
- 3 hand-authored YAML figures at `skills/protocol/figures/{layer-cake,ride-the-wave,architect-state-flow}.yaml`
- Python: `scripts/aura_protocol/{types.py,context_injection.py,gen_skills.py}` + templates `skills/templates/{skill_header.j2,skill_sub_figure.j2}`
- Go: `pasture/internal/codegen/{specs.go,specs_data.go,context.go,skills.go,templates/skill.go.tmpl}`
- Schema: `skills/protocol/schema.xml` lines 1396–1416 (`<figures>` block)
- Tests: `specs_test.go::TestFigureSpecsCompleteness`, plus `schema_types_test.go` XML structure assertions

**Bd history (all CLOSED):** ELICIT `p6mr` → URD `m8az` → PROPOSAL `mrug` → SLICE `ggc0` → FOLLOWUP `c4pa` (dedup) → PROPOSAL-3 `0dai6` (Go port).

**Recent commits showing the pipeline is live:** `3721f8d` (figures pipeline), `18b64bd` (integrate into skill generation), `1c0a3a4` (H3 heading fix).

### Outstanding figure-adjacent risk

- **Codegen authority** for figures is implicitly bundled into the broader codegen-parity audit (`aura-plugins-5wbhm`), not separately called out. Low-risk; figures are stable.
- **Figure block drift** is empirically absent (parent vs pasture renders identically for the figure blocks themselves), even where the surrounding body has drifted.
- **`FigureType` enum** holds only one value (`AsciiDiagram`). The type system is extensible (Mermaid, SVG, etc.) but no other types are populated. Worth confirming whether the user's recollection was about extending the type set — see [URE Q1 below](#q1-figures).

### Recommendation
**Confirm closure in writing.** Add one row to ROADMAP §5 (Done):

> | ✅ | **Figures pipeline — ASCII diagrams auto-rendered into role + sub-skill SKILL.md headers** | `aura-plugins-c4pa` + `mrug` + `0dai6` (Go port) | 3 figures (layer-cake, ride-the-wave, architect-state-flow) load from `skills/protocol/figures/*.yaml` at generation time. Both Python `gen_skills.py` and Go `internal/codegen/skills.go` render. Tests `TestFigureSpecsCompleteness` enforce completeness. Parity included in §1g codegen-authority audit. |

Optionally, add a one-line clarification to ROADMAP §0 ("Code generation
vs runtime context injection"): the figure subsystem is part of (a)
build-time codegen, not (b) runtime context injection.

---

## 3. Thread: supervisor & worker skill provenance

**User's recollection (verbatim, 2026-05-24):**
> *"…figuring out what is hand-written and what is not in the supervisor
> skill."*

### Finding: boundaries are well-marked but DISAGREE between sides

The Go port absorbed the parent's hand-authored body content into Go
literal structs (`pasture/internal/codegen/specs_data_body.go::supervisorBody`
at line 24+, `workerBody` at line 1375+). The Go template
(`skill.go.tmpl`, 228 lines) extends the generated region to absorb
`Preamble`, `BodyBehaviors`, `BodySections`, `BodyRecipes` — covering
what used to be hand-authored prose in the parent. The Python template
(`skill_header.j2`, 180 lines) stops the generated region earlier.

**Concrete boundaries:**

| File | Lines (total) | Generated | Hand-authored |
|---|---:|---|---|
| Parent `aura-plugins/skills/supervisor/SKILL.md` | 869 | 9–340 (332 lines) | 341–869 (529 lines) |
| Pasture `pasture/skills/supervisor/SKILL.md` | 978 | 9–978 (970 lines) | (none) |
| Parent `aura-plugins/skills/worker/SKILL.md` | 568 | 9–252 (244 lines) | 253–568 (316 lines) |
| Pasture `pasture/skills/worker/SKILL.md` | 473 | 9–473 (465 lines) | (none) |

### Drift classification

For **supervisor (212-line drift)**:
- **~80% GENERATED-ONLY**: cosmetic regeneration delta (frontmatter sort order, "General Constraints" vs "Constraints (Given/When/Then/Should Not)", example-block reordering, etc.).
- **~5% HAND-EDIT-ONLY**: notably parent L762–767 has more emphatic prose about severity routing (*"**NEVER link IMPORTANT or MINOR…**"*) whereas pasture L809 collapses to `[sup-blocker-dual-parent]` constraint-ID cross-reference. **Pasture is less prescriptive here.**
- **~15% MIXED**: the marker-placement disagreement itself — parent's `<!-- END GENERATED -->` at L340 vs pasture's at L978 means the same prose lives on different sides of the marker.

For **worker (122-line drift)**: same shape; ~70% generated-only, ~30% mixed, ~0% hand-edit-only — pasture's `workerBody` has absorbed all parent body content.

### Reconciliation implications

The `aura-plugins-naupi` (now closed) reconciliation policy framed
"manual review required for supervisor + worker" — that framing is
**correctly shaped**. The manual review is needed not because there's
unmarked prose, but because:

1. The marker boundaries disagree, so the user needs to ratify that
   `specs_data_body.go::supervisorBody` carries the parent's intent.
2. The L762–767 emphasis ("NEVER link IMPORTANT or MINOR…") is more
   prescriptive in the parent than the pasture cross-reference; this
   may be intentional simplification or accidental loss of emphasis.

### Recommendation

Update `docs/PYTHON_TO_GO_MIGRATION.md` (doc since deleted in PR #6) §"Reconciliation policy"
with the boundary-analysis findings (added as a sub-note under each
of the 2 substantive-drift rows), and **file the per-skill
reconciliation REQUEST** that the migration doc said was "out of scope
for the deprecation declaration." That request is the natural successor
to `naupi`; see [§5 item 1j](#5-proposed-roadmap-additions--corrections).

---

## 4. Sweep: other gaps

The third investigation agent ran an exhaustive sweep. Findings ordered
by severity:

### 4.1 Stale Python-era documentation
Three docs in `worktree/aura-protocol/docs/` describe pre-deprecation
Python work with their own "Roadmap" sections that are now obsolete:
- `docs/architecture.md` lines 302–360 (roadmap section)
- `docs/aurad.md` lines 421+ (roadmap section)
- `docs/aura-msg.md` lines 185+ (roadmap section), plus L4–9 ("stub … No subcommands implemented" — contradicted by commits `a5ed19f`/`fd43d56` that un-stubbed it)

None of these carry a deprecation banner pointing at
`scripts/aura_protocol/DEPRECATED.md` or `PYTHON_TO_GO_MIGRATION.md`.
A reader landing on `architecture.md` would think Python `aurad` is
still the path forward. **This is the highest-impact documentation
drift hazard found by the sweep.**

### 4.2 Stub hook handler graduation
`pasture/internal/hooks/git_recorder.go:22-30` is a stub explicitly
described as "a stub hook handler that demonstrates the wiring." The
production upstream-hook → pasture-handler mapping is "S7+" deferred.
ROADMAP §1b ("Hook-fired free-floating event recording smoke") covers
the test-surface side; the implementation side is unfiled.

### 4.3 Per-skill reconciliation REQUEST unfiled
`PYTHON_TO_GO_MIGRATION.md` says: *"The actual reconciliation work
(running the diffs, picking content, applying merges) is scoped as a
follow-up REQUEST — out of scope for the deprecation declaration
itself."* No bd task exists for it. The two non-trivial drifts
(supervisor 212 lines, worker 122 lines) are highest-value.

### 4.4 Skill drift CI check unfiled
The migration doc says: *"A CI check should be added that flags any
drift between matching skill files in the two homes (separate task to
file when the Go codegen authority audit closes)."* The CI check is
named but not filed.

### 4.5 31 Python-only skills — POLICY EXISTS (correction; Round-1 Axis-B finding)

**Round-1 correction:** the audit originally claimed "no policy." That was wrong.
Epic [`aura-plugins-x5071`](beads://aura-plugins-x5071) ("EPIC: Port remaining
30 Python skills to Go", P3, OPEN, 2026-03-25) IS the filed policy. Its
description: *"Follow-up to the foundation port (PROPOSAL-3). Port all
remaining ~30 Python skill directories to Go pasture. User confirmed: Go
becomes canonical source."* — the policy is "port to Go", and `x5071` tracks
the work. The 30 skills enumerated in `x5071` overlap nearly perfectly with
the 31 the audit found.

What's still actionable: cross-reference `x5071` from `ROADMAP.md` and from
`PYTHON_TO_GO_MIGRATION.md` (both currently silent on it). See [§5 item
2h](#§2--deferred-roadmap-items-2-new) revised accordingly.

### 4.6 Stale 2026-03 P2 REQUESTs
A chain of bd tasks from 2026-03-07 about implementing the Python
`aurad` / `aura-msg` stubs are still OPEN but functionally superseded
by Pasture / PROPOSAL-2:
`oqhjg / bwfqm / fw1cx / u3ae0 / odasf / lczzv / ytj66` (Python stub
chain) and `3ubig / v2a51 / q72mt` (supervisor-rework chain — partially
landed in commit `cd88a86`).

### 4.7 FOLLOWUP epic `yeym1` not on ROADMAP
`aura-plugins-yeym1` — FOLLOWUP epic from the original `pasture task`
CLI review — is OPEN with 3 IMPORTANTs (`pc82r`, `awe1p`, `m656u`).
ROADMAP §5 mentions `f59jc` (the PROPOSAL-2 Phase 10 followup epic)
but not `yeym1`. Sibling, not duplicate.

### 4.8 Parent URD `aura-plugins-jbnx3` not cross-referenced
The Pasture parent URD (P1, "Go port with ACP, observability, polyrepo
marketplace") covers requirements broader than PROPOSAL-2 (which only
addressed the unified workflow record). Marketplace and ACP elements
are not fully cross-referenced from ROADMAP §2f (which gestures at
"marketplace" in a one-line catch-all). Worth surfacing whether the
URD R1–Rn requirements are tracked elsewhere or need explicit ROADMAP
rows.

### 4.9 v3 framing collision in `aura-plugins/CLAUDE.md`
The CLAUDE.md version-roadmap table lists *"v3 = Full Temporal workflow
engine — Future"*. This collides with two facts: (a) PROPOSAL-2 has
shipped substantial Temporal workflow work; (b) `docs/architecture.md`
also uses "v3" to refer to the Python prototype. Readers see two "v3"
referents and don't know which to trust.

### 4.10 `agents/*.md` codegen (new info from 2026-05-24 PYTHON_TO_GO_MIGRATION.md update)
The migration doc gained a row noting that the Go codegen now also
writes `pasture/agents/{epoch,architect,reviewer,supervisor,worker}.md`
with no Python counterpart. This is Go-canonical work; should appear
in ROADMAP §5 (Done) for completeness.

### 4.11 Sibling open epics (Round-1 Axis-B finding — coverage gap)

**Round-1 correction:** the audit's original sweep mentioned only the two
FOLLOWUP epics it knew (`f59jc`, `yeym1`). It missed 14 other open epics.
Full enumeration of all 16 open epics (`bd list --type=epic --status=open`):

| Epic | Title | ROADMAP relevance |
|---|---|---|
| `cmvu5` | FOLLOWUP-ROADMAP (this audit's parent) | **the ROADMAP itself** |
| `f59jc` | FOLLOWUP: PROPOSAL-2 Phase 10 review | already on ROADMAP §5 |
| `yeym1` | FOLLOWUP: pasture task CLI review | being added to ROADMAP §5 (this proposal §5c) |
| **`x5071`** | **EPIC: Port remaining 30 Python skills to Go** | **the policy for §4.5** — see corrected §4.5 above |
| **`q9sz9`** | FOLLOWUP: codegen body integration review | Pasture-adjacent; should be cross-referenced |
| **`wftdf`** | FOLLOWUP: Go test paradigm code review | Pasture-adjacent; cross-reference |
| **`rk2su`** | FOLLOWUP: ACP wiring | Maps to parent URD `jbnx3` R4 (ACP); cross-reference |
| **`ytzcl`** | FOLLOWUP: Pasture code review | Pasture-adjacent; cross-reference |
| **`ad8i1`** | FOLLOWUP-2: UAT revision code review | Pasture-adjacent; cross-reference |
| **`9wdwc`** | EPIC: Beads → Temporal migration (move task tracking to aurad) | Substrate-adjacent (relates to PROPOSAL-2); cross-reference |
| **`6ujr`** | EPIC: aura-acp plugin — ACP integration | Maps to parent URD `jbnx3` R4 (ACP); cross-reference |
| `2tj` | FOLLOWUP: aura_protocol v1 review | Python-era FOLLOWUP; may overlap with `naupi` deprecation; review for residual content |
| `l6z1` | Beads Dolt backend | Infrastructure, separate scope |
| `bch` | IMPL_PLAN: aura-release | Separate epic |
| `klac` | FOLLOWUP: aura-release test | Separate scope |
| `z8ga` | FOLLOWUP: aura-plugins-94yc Round 1 | Unclear scope — needs spot-check |

**6 epics directly relevant** to the Pasture ROADMAP but not currently
cross-referenced: `x5071`, `q9sz9`, `wftdf`, `rk2su`, `ytzcl`, `ad8i1`,
`9wdwc`, `6ujr`. Each merits at minimum a `ROADMAP.md` row (probably under
§5 if drained or §2 if open work, OR a new §1.5 "Sibling epics not yet
folded in"). See [§5 below](#5-proposed-roadmap-additions--corrections)
revised.

### 4.12 Parent URD `jbnx3` R1–R7 reconciliation (Round-2 Axis-B correction)

**Round-2 correction:** the table below now matches the URD's actual R-row
text (verified by `bd show aura-plugins-jbnx3 --allow-stale`).
The previous Round-1 version mislabeled R1/R2/R3 — those mislabelings
ALSO conflated R3 (port aura-release → pasture-release) with R3=done, when
in fact `pasture-release` IS open: the in-flight epic
[`aura-plugins-bch`](beads://aura-plugins-bch) ("IMPL_PLAN:
bin/aura-release implementation") tracks it.

| Req | URD title (verbatim) | Status vs current state |
|---|---|---|
| R1 | **Port aurad → pastured** | **Done** (PROPOSAL-2 landed `pastured` Temporal worker daemon, 4 activities, 12 hook events, signals, queries) |
| R2 | **Port aura-msg → pasture-msg** | **Done** (PROPOSAL-2 landed `pasture-msg` with all 8 subcommands + Cobra→handler pattern) |
| R3 | **Port aura-release → pasture-release** | **Partial — `bch` open** (IMPL_PLAN epic `bch` tracks pasture-release implementation; binary exists per `Makefile` `bin/pasture-release` but feature work is still open) |
| R4 | **ACP Integration (Full Client)** | **Open** — tracked by `6ujr` (aura-acp plugin) + `rk2su` (ACP wiring follow-up). Locally-defined ACP wire types + Adapter interface + static registry + 12 hook events per URD consolidation. |
| R5 | **Shared Go Library** | **Partial** — `internal/{config,errors,types,temporal,formatters}` shipped (used by pastured + pasture-msg); the consumption story for OTHER modules (e.g., agent-data-leverage) importing `pkg/protocol` is unspecified. |
| R6 | **Build & Distribution (4 channels)** | **Done** (nix flake builds all 5 binaries; Home Manager integration shipped; GitHub Releases for linux/darwin × amd64/arm64 supported via cross-compile). |
| R7 | **Polyrepo Marketplace** | **Partial** — pasture is a submodule in aura-plugins (D11) but the broader marketplace (separate repo registry, version coordination) is still open. Gestured at by ROADMAP §2f's catch-all. |

**Residuals**: R3 (covered by `bch`), R4 (covered by `6ujr`/`rk2su`), R5
(under-tracked), R7 (under-tracked). All four warrant explicit ROADMAP
rows; see [§5 items 2j–2l](#5-proposed-roadmap-additions--corrections)
plus the §1k–1r sibling-epic cross-refs.

### 4.13 Other open URDs and EPIC-chain residuals

The §4.6 stale 2026-03 REQUEST chain includes URD-shaped tasks (`q72mt`
supervisor-rework URD, plus `3ubig`/`v2a51` from the same chain).
Particularly: **`q72mt` is "rework supervisor"** — the exact surface §3
profiles. Whether `q72mt`'s requirements are still wanted (post the
PROPOSAL-2 supervisor work) or fully superseded is the same triage
question as §4.6 in general.

### 4.14 Open URD sweep (Round-2 Axis-B finding)

**Round-2 correction:** the original sweep named only `jbnx3` (§4.12) and
`q72mt` (§4.13). 10 open URDs exist; the 8 not yet inventoried:

| URD | Title | ROADMAP relevance |
|---|---|---|
| `jbnx3` | Pasture — Go port (ACP / observability / polyrepo) | §4.12 above |
| `q72mt` | Rework supervisor role | §4.13 above |
| **`bwfqm`** | **aurad + aura-msg implementation** | **Likely superseded by PROPOSAL-2** (which IS the aurad + aura-msg implementation that landed). Candidate for `superseded by PROPOSAL-2` closure; same triage shape as §4.6. |
| **`o7i9`** | Un-skip 25 tests — Temporal sandbox + constraint violation combinatorial | **Python-era** (was about the Python `aura_protocol` test suite). Likely superseded by `naupi` deprecation; URE Q10 framing applies. |
| **`1nla`** | Unified aura-swarm requirements | Separate scope — `aura-swarm` is the parent-repo orchestration tool, not part of the Pasture toolkit per se. Worth flagging if still active. |
| **`7vtb`** | aurad rename + aura-msg stub + protocol improvements | Pre-Pasture-rename era; likely superseded by PROPOSAL-2 (which already renamed aurad→pastured). Same triage as `bwfqm`. |
| **`s7l0`** | aura-release reads pyproject.toml from wrong directory | Bug-fix URD scoped to `aura-release` (Python binary, now deprecated). Either superseded by the `bch` `pasture-release` port or applicable as a bug to carry over — needs triage. |
| **`e28b`** | FOLLOWUP_URD: schema-driven protocol engine v2 follow-up | Python-era FOLLOWUP. Likely superseded by `naupi` deprecation; URE Q10. |
| **`s6i`** | FOLLOWUP_URD: aura_protocol v1 follow-up | Python-era FOLLOWUP — peer of `2tj` (called out in Q10). Likely superseded by `naupi`; same triage. |
| **`99q`** | Release automation requirements | Separate scope — the build/distribution side of R6, partially shipped (`bin/aura-release` and `bch` `pasture-release` IMPL_PLAN). Worth confirming whether this URD's requirements are subsumed by `bch`. |

**Triage required for 8 URDs**: same flavor of question as §4.6 (the
stale REQUEST chain). Most likely outcomes: 5 closed as "superseded by
PROPOSAL-2 / naupi" (`bwfqm`, `o7i9`, `7vtb`, `e28b`, `s6i`), 2 kept open
but cross-referenced from ROADMAP (`1nla` aura-swarm; `99q` release
automation if not subsumed by `bch`), 1 carried over as a real bug
(`s7l0` if it still reproduces on `pasture-release`). The URE Q10 frame
now expands to cover all 8 + the original `2tj` epic — see revised Q10
in [§6](#6-open-questions-for-the-ure).

---

## 5. Proposed ROADMAP additions / corrections

Each item below is a candidate addition — the URE in §6 ratifies
which actually get filed.

### §1 — Observability + smoke-test infrastructure (3 new audits)

- **1h.** Banner + redirect the 3 stale Python-era docs (`architecture.md`, `aurad.md`, `aura-msg.md`). Add a top-of-file notice analogous to `scripts/aura_protocol/DEPRECATED.md` pointing readers at `PYTHON_TO_GO_MIGRATION.md`. Trivial doc fix; tracked as bd task.
- **1i.** Skill-drift CI check between `aura-plugins/skills/` and `pasture/skills/` for the 7 overlapping skills. Named in the migration doc; never filed.
- **1j.** Per-skill reconciliation REQUEST for the 7 drifted skills — especially the 212-line `supervisor` and 122-line `worker` substantive drifts. Migration doc explicitly punts this as a follow-up REQUEST; the bd task for it doesn't exist yet.

### §2 — Deferred roadmap items (2 new)

- **2g.** Graduate `internal/hooks/git_recorder.go` from stub to production. Currently §1b covers the smoke; this is the implementation side of the hook subsystem.
- **2h.** (**REVISED — see §4.5 correction**) Cross-reference epic [`aura-plugins-x5071`](beads://aura-plugins-x5071) ("Port remaining 30 Python skills to Go") from `ROADMAP.md` and from `PYTHON_TO_GO_MIGRATION.md`. The audit originally claimed "no policy" — wrong. The policy exists; the work is filed; the ROADMAP just doesn't link it. Trivial cross-reference fix; tracked as bd task.

### §2 — Cleanup (1 new)

- **2i.** Triage + close stale 2026-03 P2 REQUESTs that PROPOSAL-2 superseded: `oqhjg / bwfqm / fw1cx / u3ae0 / odasf / lczzv / ytj66 / 3ubig / v2a51 / q72mt`. Either close each with "superseded by PROPOSAL-2" reason, or list residual unbuilt asks per task. Notable: **`q72mt` is "rework supervisor"** (URD-shaped) — directly overlaps with §3 supervisor-skill findings; needs explicit accept/supersede decision (URE Q5 covers).

### §1 — Sibling epic cross-references (NEW; Round-1 Axis-B finding §4.11)

The audit missed 8 open epics relevant to the Pasture roadmap. Each merits at minimum a ROADMAP cross-reference; some warrant being folded in as full rows.

- **1k.** [`aura-plugins-x5071`](beads://aura-plugins-x5071) — 30 Python skills port (the §2h policy; see above).
- **1l.** [`aura-plugins-q9sz9`](beads://aura-plugins-q9sz9) — FOLLOWUP: codegen body integration review. Pasture-adjacent.
- **1m.** [`aura-plugins-wftdf`](beads://aura-plugins-wftdf) — FOLLOWUP: Go test paradigm review.
- **1n.** [`aura-plugins-rk2su`](beads://aura-plugins-rk2su) — FOLLOWUP: ACP wiring. Maps to parent URD `jbnx3` R4.
- **1o.** [`aura-plugins-ytzcl`](beads://aura-plugins-ytzcl) — FOLLOWUP: Pasture code review.
- **1p.** [`aura-plugins-ad8i1`](beads://aura-plugins-ad8i1) — FOLLOWUP-2: UAT revision code review.
- **1q.** [`aura-plugins-9wdwc`](beads://aura-plugins-9wdwc) — EPIC: Beads → Temporal migration (move task tracking to aurad). Substrate-adjacent.
- **1r.** [`aura-plugins-6ujr`](beads://aura-plugins-6ujr) — EPIC: aura-acp plugin — ACP integration. Maps to parent URD `jbnx3` R4.

For each: depending on URE outcome (Q9), they get either (a) a row in ROADMAP §5 (if effectively drained), (b) a row in ROADMAP §2 (if active deferred work), or (c) a single §0 cross-reference paragraph noting they exist outside the immediate ROADMAP scope.

### §2 — Parent URD `jbnx3` residual requirements (NEW; Round-1 Axis-B finding §4.12)

PROPOSAL-2 covered R1–R3 + R6 of the Pasture parent URD. Residual:

- **2j. R4 ACP full client integration.** Open work covered by `6ujr` + `rk2su` (already named in §4.11). Should be an explicit ROADMAP row pointing at those, not just a §2f catch-all gesture.
- **2k. R5 shared protocol library cross-module consumption.** Partially shipped (`pkg/protocol` exists); the consumption story (how other modules in the dayvidpham org actually import and use the public surface) is unspecified. Worth a row.
- **2l. R7 polyrepo marketplace.** Currently absorbed by §2f's catch-all. Worth promoting to its own row given the URD names it explicitly.

### §5 — Done so far (3 additions for completeness)

- **5a.** **Figures pipeline** — see [§2 recommendation above](#recommendation).
- **5b.** **`agents/*.md` codegen** — Go codegen writes the 5 agent stubs (epoch, architect, reviewer, supervisor, worker); no Python counterpart. Captured in `PYTHON_TO_GO_MIGRATION.md` 2026-05-24 update.
- **5c.** **`aura-plugins-yeym1`** — FOLLOWUP epic from the original `pasture task` CLI review; OPEN with 3 IMPORTANTs (`pc82r`, `awe1p`, `m656u`). Add alongside `f59jc` in §5.

### §0 — Design context (clarifications)

- Clarify under "Code generation vs runtime context injection" that the **figure subsystem is build-time codegen** (avoid confusion with runtime context injection).
- Note that the **"v3" label in `aura-plugins/CLAUDE.md`** is ambiguous post-deprecation and should be reframed once a single canonical referent is chosen.
- Add a one-paragraph **cross-reference to the parent URD `aura-plugins-jbnx3`** explaining which of its R1–Rn requirements are covered by PROPOSAL-2 (workflow record + audit + Temporal) and which remain open (ACP, marketplace, polyrepo) — the latter feed §2f's catch-all but deserve named lines.

---

## 6. Open questions for the URE

These get asked AFTER Phase 4 review, with the proposal's framings as
context. Each is structured for the boundary-splitting `AskUserQuestion`
pattern in `/aura:user-uat` / `/aura:user-elicit`.

### Q1 — Figures
The figure-pipeline thread you recalled appears to be **delivered**: 3
YAML figures, both codegens render them, tests assert completeness.
Was your recollection about that pipeline (in which case we just
confirm closure in writing), or about an extension to it (Mermaid,
SVG, more figure types) that I should surface as a missed item?

### Q2 — Supervisor / worker provenance
Pasture's `supervisor`/`worker` SKILL.md files are **fully generated**
from `specs_data_body.go`. Parent's are **partially hand-authored**.
The parent's hand-authored regions appear to be mirrored in the Go
literal — but parent L762–767's prose ("NEVER link IMPORTANT or
MINOR…") is more emphatic than pasture's `[sup-blocker-dual-parent]`
cross-reference. Is the cross-reference an **intentional simplification**
(constraints are the source of truth; prose is redundant) or an
**accidental loss of emphasis** in the Go port that should be restored?

### Q3 — Small placement calls (was Q3 + Q7; merged per Round-1 Axis-C)

Two small placement calls — pick once, default if no override:
(a) **`git_recorder.go` stub graduation (was Q3)**: ROADMAP §2 (deferred) or higher priority because §1b smoke depends on it? Default: §2.
(b) **`aura-plugins/CLAUDE.md` "v3 = Full Temporal" line (was Q7)**: rename / delete / keep as historical-flagged? Default: keep as historical-flagged, add a one-line redirect note.

### Q4 — DROPPED (Round-1 Axis-B finding)

The "no policy for 31 Python-only skills" framing was wrong — epic
[`aura-plugins-x5071`](beads://aura-plugins-x5071) IS the filed policy
("port them all to Go"). Question reduces to a cross-reference fix
(§2h), which doesn't need user input. No Q4 in this round.

### Q5 — Triage stale work (3 buckets, merged from Q5+Q10+Q11 per Round-3 Axis-C)

Three buckets of likely-superseded work surfaced by the audit. Same
meta-decision per bucket: batch-close, individual-audit, or leave-open.

**Bucket A — 10 stale 2026-03 REQUESTs** (`oqhjg / bwfqm / fw1cx / u3ae0 / odasf / lczzv / ytj66 / 3ubig / v2a51 / q72mt`):
notably `q72mt` is "rework supervisor" — overlaps directly with §3 findings.

**Bucket B — 6 Python-era artifacts** likely superseded by `naupi` + PROPOSAL-2:
the epic `2tj` (27 children) plus 5 URDs `bwfqm` / `o7i9` / `7vtb` / `e28b` / `s6i`.

**Bucket C — 3 non-Python URDs** with independent triage needs:
- `1nla` Unified aura-swarm: Pasture-adjacent or out-of-scope (aura-swarm is parent-repo orchestration)?
- `99q` Release automation: subsumed by `bch` IMPL_PLAN (pasture-release), or separate work still needed?
- `s7l0` aura-release reads pyproject.toml from wrong directory: real bug carried into `pasture-release` testing, or closed with Python deprecation?

For each bucket pick one of: **(a)** batch-close with "superseded by PROPOSAL-2 / naupi"; **(b)** audit each individually for residuals; **(c)** leave open as historical record. (Defaults if no override: A=b individual, B=b individual, C=b individual — these are real items, not pure superseded chaff.)

### Q6 — Parent URD `jbnx3` R5 + R7 (was Q6; refined per Round-1 Axis-B §4.12)

Per §4.12, R1–R3+R6 are done, R4 has bd-task coverage (`6ujr` + `rk2su`).
The remaining residuals:
(a) **R5 shared protocol library** — does the "how other modules import
`pkg/protocol`" story need explicit specification, or is the current
state (it exists; consumers figure it out) acceptable?
(b) **R7 polyrepo marketplace** — promote to its own ROADMAP §2 row, or
keep under §2f's catch-all?

### Q8 — Anything else

Are there threads of work you remember being left mid-flight that the
audit + Axis-B coverage check didn't surface? (You are the source of
truth on unrecorded recollections.)

### Q9 — Sibling epic fold-in (NEW per Round-1 Axis-B §4.11)

8 open epics map onto Pasture roadmap territory but aren't currently
cross-referenced: `x5071`, `q9sz9`, `wftdf`, `rk2su`, `ytzcl`, `ad8i1`,
`9wdwc`, `6ujr`. For each, do you want:
(a) Inspect each epic individually now and place each into §5 (done),
§2 (open work), or §0 (cross-reference paragraph)?
(b) Treat them as a batch — add a single new §1.5 "Sibling epics not yet
folded in" subsection that points at each one, then triage individually
in a follow-up?
(c) Leave the cross-references unfiled; they're tracked in bd already.

### Q10 — DROPPED (merged into Q5 per Round-3 Axis-C consolidation)

The Round-2-introduced "6 Python-era artifacts" question is now Bucket B
of Q5. No standalone Q10.

### Q11 — DROPPED (merged into Q5 per Round-3 Axis-C consolidation)

The Round-2-introduced "3 non-Python URDs" question is now Bucket C of
Q5. No standalone Q11.

---

## 7. Acceptance for this proposal (Phase 4 review)

- All three investigation reports cited and ground-truthed against
  files / commits.
- Drift between recall and reality named explicitly for each thread.
- Proposed ROADMAP additions / corrections each tied to a §1.x /
  §2.x / §3.x / §4.x / §5.x slot.
- URE questions structured for boundary-splitting (each question
  surfaces an ambiguity the user is the source of truth on).
- **No code, schema, or bd-task descriptions modified by this proposal
  itself** — implementation deferred.

---

## 8. Out of scope

- Actually filing any bd task suggested above — that happens after the
  URE settles which are wanted.
- Reconciling any of the 7 drifted SKILL.md files (that's the
  reconciliation REQUEST §1j proposes filing).
- Touching `aura-plugins/CLAUDE.md` v3 wording (URE Q7).
- Implementing any ROADMAP item.

---

*End of PROPOSAL.*
