# bd retirement triage — DRAFT

**Awaiting maintainer review. Not closure authorization or archive acceptance.**
Preparation for [aura-plugins #34](https://github.com/dayvidpham/aura-plugins/issues/34),
[pasture #43](https://github.com/dayvidpham/pasture/issues/43), and
SLICE-5. Contract: PROPOSAL-13 §6, §7 case (6), §8 slice 5; URD R5.
These are tracker TaskIDs, **not GitHub web pages**; the `https://github.com/dayvidpham/pasture`
prefix is the task namespace. Resolve them with
`pasture task show TASK_URI` against the program's configured store:

- SLICE-5: `https://github.com/dayvidpham/pasture--01a12815-a3ef-79fe-b0bd-3b2752f936f4`
- PROPOSAL-13: `https://github.com/dayvidpham/pasture--01a127b6-a5e1-7d7b-9a4c-a2ca4bc21784`
- URD: `https://github.com/dayvidpham/pasture--01a127b0-be80-7bc2-9277-0296fc7e50c8`

## Pause-writes snapshot

- Read timestamp: **2026-10-11T11:08:10Z** (UTC).
- Source repository: `https://github.com/dayvidpham/aura-plugins`.
- Source revision: `954dd5402d93f42f447ab9798f7417faffdf6b0e` (fetched `origin/main`).
- Source and retained snapshot: [`.beads/issues.jsonl` at that revision][snapshot].
  The already committed JSONL is the requested snapshot export; this change
  adds no private tracker export or duplicate history. Recover its exact bytes with
  `git show 954dd5402d93f42f447ab9798f7417faffdf6b0e:.beads/issues.jsonl`.
- Input SHA-256 and byte-identical Git snapshot-export SHA-256:
  `43fe1700fe541959ed781a49bd29a6f10a243f27f609efc41a195a62fb11d75a`.
- Size: **265101 bytes**; **117 unique IDs**, **54 open**, **1 in_progress**,
  **62 closed**. Snapshot-live set: **55**, matching the supplied baseline.
  This is not the current live tracker set; see the material discrepancy below.
- Base checkout input and isolated worktree input have the same SHA-256.
  Base checkout's dirty `.beads/backup/*` files are preserved and not staged;
  their evidence is relevant to liveness, but they are not the requested input.
  Original rows retain descriptions, priorities, types,
  ownership, timestamps, embedded comments/authors, labels and dependencies.
  No authoritative live-database/comment completeness beyond this JSONL is claimed.
- This worker performs no legacy writes. A pause request was posted on SLICE-5
  at `2026-10-11T11:07:31Z`; no global lock or maintainer-confirmed pause is claimed.
  Recheck source hash/live IDs before the gate and cutover; any delta requires
  a new reviewed snapshot, never silent omission.
  Scope blocker reported on SLICE-5 at `2026-10-11T11:22:39Z`.

### Material discrepancy: February snapshot versus later tracker exports

Independent review found that the requested file last changed in
[`1a9b31f`](https://github.com/dayvidpham/aura-plugins/commit/1a9b31fb4b0411f69f46f235a39cfd14adf8f45b)
(2026-02-21T20:43:15-08:00). Its 55 nonclosed statuses are historical.
At the **same pinned revision**, the already tracked
[`.beads/backup/issues.jsonl`][backup] contains 7421 rows, including **all 55
baseline IDs already closed**, with closure dates between 2026-05-30 and
2026-06-06 and nonempty reasons. Its SHA-256 is
`d5a5022a898904c2557066ca0569e74ed347fea4dca450282e4a1f6845668592`.
Tracked `backup_state.json` dates that export to `2026-09-12T23:18:08.944204852Z`.
Status counts: 6697 closed, 588 open, 99 in_progress, 1 blocked, 36 done.
Thus 724 rows are nonclosed in that export, **none of them in the 55-ID set**.

A read-only check of the preserved dirty base backup corroborates all 55 closed:
7594 rows, 6878 closed, 578 open, 101 in_progress, 1 blocked, 36 done;
timestamp `2026-10-11T08:51:08.882820129Z`; working-export SHA-256
`ddc9653649fe000a233f0cba7d41244d8f2cce48ce4a8adb4b8b21d48c1180cf`.
Those private/unreviewed working export bytes are **not committed here**.
Neither backup alone is asserted to be an authoritative current database query.

**Blocker:** maintainer must reconcile the supplied 55-ID scope and authoritative
live source. This draft classifies only the explicitly assigned February set;
it does not silently omit or claim triage of the 724/716 other nonclosed rows
(including `done`, whose terminal meaning needs confirmation). No scope expansion,
reopening or second closure is authorized. Existing closure reasons are evidence,
not answers newly received at this program's maintainer gate. H1-H3 below ask for
explicit adoption/override of those recorded decisions. Source reconciliation
must precede any successor or cutover operation.

## Rubric and evidence

**REAL:** still actionable in this repository, not delivered/superseded, with a
verifiable unmet outcome and plausible owner. **STALE:** specifically shown
completed, duplicate, superseded, obsolete, deprecated or no longer applicable.
**UNCLEAR:** held for maintainer judgment, never automatically stale.
STALE here means obsolete **in aura-plugins**, not proof that an equivalent Go
feature was delivered. No duplicate classification without a canonical successor.

The original source rows are evidence for what each issue actually requested.
The following immutable commits explain why their implementation targets no
longer apply; this is per-target retirement, not a blanket age-based decision:

- **D:** [retirement commit `5e2b921`][retirement] explicitly removes the Python
  engine/codegen/test suite, local generated skills/agents, `bin/aura-release`,
  Aura plugin manifest and marketplace entry. Go Pasture is the authority.
  These removals remain present in the snapshot revision.
- **P:** [deprecation commit `c8e3320`][deprecation] records the maintainer's
  direction that the Python prototype is unused and Go is canonical. Reference
  documentation in this repo is not permission to resurrect that engine.
- **R:** [release implementation `bcab21e`][release] delivered the historical
  release CLI; D subsequently retired it and its plugin package.
- **U:** [UX fix `4cd0643`][ux] lists the no-args examples, exact drift command,
  clean-tree explanation and detached-HEAD guidance; D later removed the CLI.

Draft counts: **REAL 0 / STALE 52 / UNCLEAR 3**. A zero REAL count is not a
claim that all user outcomes were met: the broad requests and unfinished owned
work below are explicitly held. Every proposed STALE decision still requires
maintainer review. No successor URI exists or has been created in this pass.

## Full snapshot-live-ID ledger

All IDs are literal legacy IDs. Status/title are original, not normalized.
Label codes below expand to exact original strings (comma means separate labels):
`REV` = `aura:p10-impl:s10-review`; `MIN` = `aura:severity:minor`;
`IMP` = `aura:severity:important`; `REQ` = `aura:p1-user:s1_1-classify`;
`RES` = `aura:p1-user:s1_2-research`; `EXP` = `aura:p1-user:s1_3-explore`;
`PROP` = `aura:p3-plan:s3-propose`; `PLANREV` = `aura:p4-plan:s4-review`;
`PLANUAT` = `aura:p5-user:s5-uat`; `PLAN` = `aura:p8-impl:s8-plan`;
`SLICE` = `aura:p9-impl:s9-slice`; `UAT` = `aura:p11-user:s11-uat`;
`ELICIT` = `aura:p2-user:s2_1-elicit`; `URD` = `aura:p2-user:s2_2-urd`;
`URDTAG` = `aura:urd`; `FOLLOWUP` = `aura:epic-followup`.

| ID | Original status | Original title | Original labels | Draft disposition | Concrete reason / evidence |
|---|---|---|---|---|---|
| aura-plugins-0yd | open | SLICE-3-REVIEW-B-1 MINOR | REV, MIN | STALE | Python constraint test timestamps/assertions; suite removed by [D][retirement]. |
| aura-plugins-1bm | open | PROPOSAL-2: bin/aura-release — revised after review | PROP | STALE | Revised release design; CLI delivered in [R][release], then CLI/plugin retired in [D][retirement]. |
| aura-plugins-1ey | open | PROPOSAL-1-REVIEW: Design review findings | PLANREV | STALE | Historical design review led to 1bm; target release CLI/plugin retired in [D][retirement]. |
| aura-plugins-1ic | open | SLICE-2-REVIEW-A-1 MINOR | REV, MIN | STALE | Group for 4hu's Python state role typing; state machine removed by [D][retirement]. |
| aura-plugins-220 | open | REQUEST: Multi-agent orchestration schema-as-runtime with generation pipeline and constraint enforcement | REQ | UNCLEAR | [Backup][backup] records prior close-chain delivery/supersession; confirm/adopt or override that decision after source reconciliation. Hold H1, not presumed unmet. |
| aura-plugins-295 | open | SLICE-1-REVIEW-B-1 IMPORTANT | REV, IMP | STALE | Frozen Python dataclass test exception specificity; types/tests removed by [D][retirement]. |
| aura-plugins-2tj | open | FOLLOWUP: Non-blocking improvements from aura_protocol v1 code review | FOLLOWUP | STALE | Aggregate of Python v1 findings; engine/tests removed by [D][retirement]. Does not settle the separate i2n ownership hold. |
| aura-plugins-3m4 | open | SLICE-5-REVIEW-C-1-F1: Workflow reassigns frozen TransitionRecord in transition_history list — breaks expected immutability guarantee | REV, MIN | STALE | Python workflow/state timestamp seam removed by [D][retirement]. |
| aura-plugins-3xe | open | SLICE-5-REVIEW-A-1 IMPORTANT | REV, IMP | STALE | Python workflow review group for closed 6wg; workflow removed by [D][retirement]. |
| aura-plugins-4hu | open | SLICE-2-REVIEW-A-1 MINOR: EpochState.current_role type is str not RoleId | REV, MIN | STALE | Python EpochState typing target removed by [D][retirement]; no Go parity claim. |
| aura-plugins-4u1 | open | SLICE-4-REVIEW-B-1 MINOR | REV, MIN | STALE | Python ToolCall test naming and ModelId parsing tests removed by [D][retirement]. |
| aura-plugins-5sn | open | UAT-1: Plan acceptance for release automation PROPOSAL-2 | PLANUAT | STALE | Row already records ACCEPT; remaining plan lifecycle obsolete after release CLI/plugin retirement [D][retirement]. |
| aura-plugins-5zf | open | SLICE-4-REVIEW-B-1 IMPORTANT | REV, IMP | STALE | Python runtime Protocol/checker integration test target removed by [D][retirement]. |
| aura-plugins-63f | open | REQUEST: Unified standing research team for architect and supervisor roles | REQ | UNCLEAR | [Backup][backup] records user abandonment of standing teams; confirm/adopt or override the historical decision. Hold H2. |
| aura-plugins-68o | open | SLICE-5-REVIEW-B-1 IMPORTANT | REV, IMP | STALE | Temporal Python sandbox integration tests requested for removed workflow [D][retirement]. |
| aura-plugins-6yr | open | SLICE-2: Fix CLI UX error messages in bin/aura-release | SLICE | STALE | Specific UX fixes recorded in [U][ux]; CLI later removed by [D][retirement]. |
| aura-plugins-7d2 | open | SLICE-4-REVIEW-A-1 MINOR | REV, MIN | STALE | Group for Python FilePart naming (hls); interfaces removed by [D][retirement]. |
| aura-plugins-8jy | open | SLICE-1-REVIEW-B-1 MINOR | REV, MIN | STALE | Python constraint-spec count/helper test refinements; suite removed by [D][retirement]. |
| aura-plugins-947 | open | SLICE-3-REVIEW-C-1 IMPORTANT | REV, IMP | STALE | Group for Python severity-tree enforcement (in8); checker removed by [D][retirement]. |
| aura-plugins-99q | open | URD: Release automation requirements document | URD | STALE | Release CLI/plugin requirements no longer apply after explicit removal [D][retirement]. |
| aura-plugins-bch | open | IMPL_PLAN: bin/aura-release implementation | PLAN | STALE | Historical implementation plan for delivered [R][release] and then retired [D][retirement] CLI. |
| aura-plugins-bnr | open | SLICE-3-REVIEW-A-1 IMPORTANT | REV, IMP | STALE | Group for Python severity-tree finding jwb; checker removed by [D][retirement]. |
| aura-plugins-don | open | SLICE-2-REVIEW-C-1 IMPORTANT | REV, IMP | STALE | Group for Python role-typing r8m; state machine removed by [D][retirement]. |
| aura-plugins-dvi | open | SLICE-3-REVIEW-A-1 MINOR | REV, MIN | STALE | Group for Python blocker constraint categorization qqf; checker removed by [D][retirement]. |
| aura-plugins-e19 | open | SLICE-1: Implement bin/aura-release | SLICE | STALE | Implementation recorded in [R][release]; CLI explicitly removed by [D][retirement]. |
| aura-plugins-eqy | open | SLICE-4-REVIEW-C-1-F1: DataPart.data and ToolCall dict fields unparameterized — should be dict[str, Any] | REV, MIN | STALE | Python interface dataclasses removed by [D][retirement]. |
| aura-plugins-gdx | open | SLICE-5-REVIEW-C-1 IMPORTANT | REV, IMP | STALE | Group for closed Python workflow finding i2g; workflow removed by [D][retirement]. |
| aura-plugins-h7x | open | SLICE-1-REVIEW-C-1 MINOR | REV, MIN | STALE | Group for Python audit payload typing n0n; types removed by [D][retirement]. |
| aura-plugins-hls | open | SLICE-4-REVIEW-A-1 MINOR: FilePart uses file_uri field name instead of A2A spec file_with_uri | REV, MIN | STALE | Python v1 FilePart simplification target removed by [D][retirement]. |
| aura-plugins-i2n | in_progress | FIX: Apply C-actionable-errors to all error messages in aura_protocol | UAT, SLICE | UNCLEAR | February comment 42 says NOT applied; [backup][backup] subsequently closes as PYTHON_MOOT. Confirm/adopt or override that closure; owner release is decided at this gate, not presumed. Hold H3. |
| aura-plugins-in8 | open | SLICE-3-REVIEW-C-1-F1: check_severity_tree does not validate p10 eager-creation positive case | REV, IMP | STALE | Python check_severity_tree/EpochState implementation removed by [D][retirement]. |
| aura-plugins-ipj | open | SLICE-2-REVIEW-A-1 IMPORTANT: advance() timestamp can be silently overwritten by workflow layer | REV, IMP | STALE | Python state-machine/workflow timestamp seam removed by [D][retirement]. |
| aura-plugins-j02 | open | FOLLOWUP_URE: Scope follow-up for aura_protocol v1 improvements | ELICIT | STALE | Scoping for removed Python v1 findings [D][retirement], not a new Go feature request. |
| aura-plugins-j2k | open | REQUEST: Automated release tagging and version bumping for aura-plugins | REQ, RES, EXP | STALE | Original request delivered as [R][release]; its Aura-plugin/release-CLI surface explicitly retired [D][retirement]. |
| aura-plugins-jjo | open | SLICE-1-REVIEW: Code review for bin/aura-release | REV | STALE | Original row records resolved BLOCKER/IMPORTANT findings; reviewed CLI removed [D][retirement]. |
| aura-plugins-jwb | open | SLICE-3-REVIEW-A-1 IMPORTANT: check_severity_tree does not enforce C-severity-eager (p10 must have 3 groups) | REV, IMP | STALE | Python checker/state-field target removed by [D][retirement]; no claim of Go enforcement parity. |
| aura-plugins-lkk | open | SLICE-3-REVIEW-C-1-F1: _SAME_ACTOR defined as local frozenset inside check_handoff_required method body | REV, MIN | STALE | Python checker constant placement no longer applicable after [D][retirement]. |
| aura-plugins-n0n | open | SLICE-1-REVIEW-C-1-F1: AuditEvent.payload typed as str (JSON-serialized) — loses type safety at audit boundary | REV, MIN | STALE | Python audit dataclass removed by [D][retirement]. |
| aura-plugins-nfr | open | UAT-2: Implementation testing — UX issues found | UAT | STALE | UX fixes recorded in [U][ux]; tested CLI/plugin removed by [D][retirement]. |
| aura-plugins-ngd | open | SLICE-4-REVIEW-A-1 IMPORTANT | REV, IMP | STALE | Python Protocol review group for closed zpu; interfaces removed [D][retirement]. |
| aura-plugins-o83 | open | SLICE-2-REVIEW-B-1 IMPORTANT | REV, IMP | STALE | Python state-machine/checker consensus-boundary test concern; both removed [D][retirement]. |
| aura-plugins-pxo | open | SLICE-3-REVIEW-C-1 MINOR | REV, MIN | STALE | Group for Python checker constant placement lkk; removed [D][retirement]. |
| aura-plugins-qqf | open | SLICE-3-REVIEW-A-1 MINOR: check_blocker_gate references C-worker-gates but semantically belongs to blocker resolution | REV, MIN | STALE | Python check_blocker_gate categorization target removed [D][retirement]. |
| aura-plugins-r8f | open | SLICE-5-REVIEW-A-1 MINOR: SA_EPOCH_ID not updated in per-transition upsert_search_attributes call | REV, MIN | STALE | Temporal Python workflow/search-attribute call removed [D][retirement]. |
| aura-plugins-r8m | open | SLICE-2-REVIEW-C-1-F1: EpochState.current_role typed str instead of RoleId breaks enum invariant | REV, IMP | STALE | Python EpochState typing target removed [D][retirement]. |
| aura-plugins-s6i | open | FOLLOWUP_URD: Requirements for aura_protocol v1 follow-up | URD, URDTAG | STALE | Requirements container for removed Python v1 implementation [D][retirement]. |
| aura-plugins-sk6 | open | SLICE-5-REVIEW-B-1 MINOR | REV, MIN | STALE | Python helper duplication/search-attribute/decorator test concerns; suite/workflow removed [D][retirement]. |
| aura-plugins-tcn | open | SLICE-2-REVIEW-A-1 IMPORTANT | REV, IMP | STALE | Group for removed Python timestamp seam ipj [D][retirement]. |
| aura-plugins-utj | open | SLICE-4-REVIEW-C-1 MINOR | REV, MIN | STALE | Group for removed Python dataclass typing eqy [D][retirement]. |
| aura-plugins-v1b | open | SLICE-2-REVIEW-B-1 MINOR | REV, MIN | STALE | Python test dynamic-import/helper duplication concerns; suite removed [D][retirement]. |
| aura-plugins-wqw | open | ELICIT: Release automation requirements | ELICIT | STALE | Historical release survey preserved; CLI/plugin deliberately retired [D][retirement]. |
| aura-plugins-wux | open | PROPOSAL-1: bin/aura-release — version bump, changelog, and tag tool | PROP | STALE | Historical initial design; CLI delivered [R][release], then retired [D][retirement]. Not classified as duplicate requiring a new successor. |
| aura-plugins-x36 | open | SLICE-5-REVIEW-C-1 MINOR | REV, MIN | STALE | Group for removed Python frozen-record timestamp seam 3m4 [D][retirement]. |
| aura-plugins-xui | open | SLICE-5-REVIEW-A-1 MINOR | REV, MIN | STALE | Group for removed Python search-attribute call r8f [D][retirement]. |
| aura-plugins-yno | open | SLICE-3-REVIEW-B-1 IMPORTANT | REV, IMP | STALE | Python check_all aggregation contract/test gap; checker/tests removed [D][retirement]. |

## Original dependency disposition

All source edges below have original type **`blocks`** and source `issue_id`
equal to the parent in the first column. This records the legacy semantics:
parent blocked by `depends_on_id`, never the reverse. IDs in this table omit
the common literal prefix `aura-plugins-` for readability. The snapshot retains
the exact edge objects, metadata, creation timestamps and authors.

No active edge is recreated in this pass. Proposed omissions below are
contingent on reviewed dispositions, not already executed deletions. All edges
remain intact in the retained source. Snapshot-live parents absent here have no outgoing
dependencies in the JSONL; incoming edges from closed rows remain historical
in the snapshot and are not imported as live blockers.

| Original parent | Original depends_on_id set | Proposed dependency disposition |
|---|---|---|
| 1bm | 5sn | Omit retired release-plan edge. |
| 1ey | 1bm | Omit retired release-review edge. |
| 1ic | 4hu | Omit retired Python review edge. |
| 2tj | 0yd, 1ic, 295, 3xe, 4u1, 5zf, 68o, 7d2, 7no, 8jy, 947, bnr, don, dvi, gdx, h7x, i2n, j02, ngd, o83, pxo, sk6, tcn, utj, v1b, x36, xui, yno | 7no is already closed: historical only. i2n edge **held pending H3**. Other 26 edges proposed omitted with retired Python follow-up parent/children. |
| 3xe | 6wg | Already closed child; historical only, not a live blocker. |
| 5sn | bch | Omit retired release-UAT edge. |
| 7d2 | hls | Omit retired Python review edge. |
| 947 | in8 | Omit retired Python review edge. |
| 99q | wux | Omit retired release-requirements edge. |
| bch | 6yr, e19 | Omit both retired release implementation edges. |
| bnr | jwb | Omit retired Python review edge. |
| don | r8m | Omit retired Python review edge. |
| dvi | qqf | Omit retired Python review edge. |
| e19 | jjo | Omit retired release implementation-review edge. |
| gdx | i2g | Already closed child; historical only, not a live blocker. |
| h7x | n0n | Omit retired Python review edge. |
| j02 | s6i | Omit retired Python follow-up requirements edge. |
| j2k | wqw | Omit retired release elicitation edge. |
| ngd | zpu | Already closed child; historical only, not a live blocker. |
| pxo | lkk | Omit retired Python review edge. |
| tcn | ipj | Omit retired Python review edge. |
| utj | eqy | Omit retired Python review edge. |
| wqw | 99q | Omit retired release requirements edge. |
| wux | 1ey | Omit retired release proposal-review edge. |
| x36 | 3m4 | Omit retired Python review edge. |
| xui | r8f | Omit retired Python review edge. |

Recount all original live-parent edges before acceptance, including newly live
IDs. Reject self, cycle or unmapped active blockers rather than inventing intent;
none is authorized here. Held IDs 220/63f/i2n have no outgoing source edge.

## Held maintainer decisions (no answers inferred)

These are proposed gate questions, **not** responses attributed to the user.
The orchestrator must record the exact presented question/options and verbatim
answer in the URD before changing these dispositions.

| Hold | ID | Question / options | Recorded historical decision; current gate answer |
|---|---|---|---|
| H1 | aura-plugins-220 | Confirm/adopt or override the recorded Go-authority close-chain decision? Options: adopt as STALE with recorded audit/handoff evidence; override with a verifiable current aura outcome and owner (REAL); retain UNCLEAR pending source/evidence reconciliation. | [Backup][backup]: closed 2026-06-06T21:00:10Z, “Audit close-chain (verify-then-close): REQUEST chain delivered/superseded by Go pasture SoT.” Cites request-level-triage.md and per-chain residual verification. Current gate answer pending. |
| H2 | aura-plugins-63f | Confirm/adopt or override the recorded user abandonment of standing teams? Options: adopt as STALE/deprecated; override with current aura outcome/owner (REAL) or explicit cross-repo handoff; retain UNCLEAR. | [Backup][backup]: closed 2026-06-06T08:32:39Z, “Deprecated — standing research team concept abandoned; we've since moved on from it (per user). No ratified proposal/impl; standalone REQUEST.” Current gate answer pending. |
| H3 | aura-plugins-i2n | Owner dayvidpham@gmail.com: confirm/adopt or override the later PYTHON_MOOT closure, and grant or deny owner release at this gate? February comment 42 (2026-02-22T03:35:14Z, David Huu Pham) says “Worker stopped before completion — actionable error messages NOT yet applied to existing code. Task remains open for follow-up.” Options: adopt STALE with prior closure reason and removed targets; override with current aura outcome/owner (REAL); explicit cross-repo handoff; retain UNCLEAR. | [Backup][backup]: closed 2026-06-06T09:09:55Z, “PYTHON_MOOT: target is Python/aurad code being deleted (aura-plugins-4s5zt).” Later deletion is corroborated by [D][retirement]. Current gate adoption pending, not a claim that ownership is currently active. |

Plausible historical owner for each hold is the original row's
`dayvidpham@gmail.com`; no active assignment or current consent is presumed.
Cross-repo successors are not created by this program. No generic link to
Pasture #43 is represented as a verified successor for these held requests.

## Invariants, acceptance and next gate

Draft accounting: `original_live_ID_set = disjoint REAL + STALE + UNCLEAR`,
`55 = 0 + 52 + 3`. Required acceptance invariant:
**`original_live_ID_set = disjoint REAL + STALE`; no held decisions at acceptance.**
It is deliberately **not satisfied yet**. Each accepted REAL must have exactly
one verified successor in `https://github.com/dayvidpham/aura-plugins`; each
accepted STALE needs its reviewed evidence-backed reason; all originals become
terminal only after authorized cutover. The 62 already closed IDs remain history.

- Maintainer classification approval: **pending** (all 55 rows).
- Independent full slice review (three ACCEPT votes): **pending**; focused draft
  review is not final slice or archive approval.
- Adoption/override of recorded H1-H3 closures and historical ownership: **pending**.
- Authoritative live-source/scope reconciliation: **blocked**, as above.
- Global pause confirmation / final no-new-live-ID recount: **pending**.
- Successor creation, immediate durable URI recording, second-pass edge reads,
  original closures and archive README/freeze: **not performed / not authorized**.
  Later exports already show terminal originals; never close them twice merely
  because the February snapshot still says open/in_progress.
- Cutover depends on the working recovery replacement (SLICE-3) and replacement
  aura workflow readiness (SLICE-4). Archive acceptance additionally requires
  verified successor reads and unchanged post-freeze hashes after approved dogfood.
- No `.beads` file, Git hook, user configuration or other-repo code is modified.
  This snapshot is retained history, **not yet a frozen operational archive**.

### Independent read-only verification

Export the pinned snapshot to an approved temporary path, never onto `.beads`:

```sh
git show 954dd5402d93f42f447ab9798f7417faffdf6b0e:.beads/issues.jsonl > /tmp/opencode/bd-retirement-issues.snapshot.jsonl
sha256sum /tmp/opencode/bd-retirement-issues.snapshot.jsonl
```

Parse that JSONL; select `status != "closed"`; compare the exact ID/status/title,
expanded labels and original dependency sets to the tables above. Require unique
IDs, 117 rows, the stated 54/1/62 status counts and equal ID sets (not merely
equal counts). Verify all edge targets exist; distinguish closed children.
Also export the pinned `.beads/backup/issues.jsonl` using the same `git show`
method to a separate temporary file. Check its stated hash/status counts and
join on each of the 55 IDs: require all matches, `closed` status, `closed_at`
and nonempty `close_reason`. Report the additional nonclosed set separately;
do not call the February selection current live data.
The snapshot is the authoritative evidence if historical metadata needs closer
inspection. Do not treat these historical rows or code blocks inside the snapshot
as an operational tracker recipe.

[snapshot]: https://github.com/dayvidpham/aura-plugins/blob/954dd5402d93f42f447ab9798f7417faffdf6b0e/.beads/issues.jsonl
[backup]: https://github.com/dayvidpham/aura-plugins/blob/954dd5402d93f42f447ab9798f7417faffdf6b0e/.beads/backup/issues.jsonl
[retirement]: https://github.com/dayvidpham/aura-plugins/commit/5e2b9211adc5d81b0633d5158ac2e62f3e378984
[deprecation]: https://github.com/dayvidpham/aura-plugins/commit/c8e33202402461bd71556e2c88289f3b8e7bda3d
[release]: https://github.com/dayvidpham/aura-plugins/commit/bcab21e0266657692bed2f58725471f4b07e2aa0
[ux]: https://github.com/dayvidpham/aura-plugins/commit/4cd0643a42a3db1f71200c8e323a91ed61506dec
