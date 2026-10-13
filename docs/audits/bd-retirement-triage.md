# bd retirement triage — maintainer-approved archive ledger

**Maintainer-approved: REAL 0 / STALE 55 / UNCLEAR 0.** No successor tasks or
repeat legacy closures are required. Independent slice review remains separate.
Evidence for [aura-plugins #34](https://github.com/dayvidpham/aura-plugins/issues/34),
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

**Reconciled by maintainer instruction (2026-10-12):** the repo JSONL is the
February snapshot; the live bd store shows all 55 closed with recorded reasons.
The ledger preserves both views, corroborated by the pinned later export. Scope
is the assigned 55-ID original set, not a new claim to triage all 724 other
nonclosed rows in the pinned export (716 in the later dirty base export,
including `done`). No scope expansion, reopening or second
closure is authorized. The maintainer adopted all three recorded decisions below
as STALE and directed finalization of this bounded archive slice.

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

Approved counts: **REAL 0 / STALE 55 / UNCLEAR 0**. A zero REAL count is not a
claim that every future Go feature is delivered. All 55 original IDs have reviewed
stale reasons and already recorded closures. No successor URI is applicable or
has been created; this ledger is the successor/disposition record.

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

| ID | Original status | Original title | Original labels | Approved disposition | Concrete reason / evidence |
|---|---|---|---|---|---|
| aura-plugins-0yd | open | SLICE-3-REVIEW-B-1 MINOR | REV, MIN | STALE | Python constraint test timestamps/assertions; suite removed by [D][retirement]. |
| aura-plugins-1bm | open | PROPOSAL-2: bin/aura-release — revised after review | PROP | STALE | Revised release design; CLI delivered in [R][release], then CLI/plugin retired in [D][retirement]. |
| aura-plugins-1ey | open | PROPOSAL-1-REVIEW: Design review findings | PLANREV | STALE | Historical design review led to 1bm; target release CLI/plugin retired in [D][retirement]. |
| aura-plugins-1ic | open | SLICE-2-REVIEW-A-1 MINOR | REV, MIN | STALE | Group for 4hu's Python state role typing; state machine removed by [D][retirement]. |
| aura-plugins-220 | open | REQUEST: Multi-agent orchestration schema-as-runtime with generation pipeline and constraint enforcement | REQ | STALE | Maintainer-approved: delivered/superseded by Go pasture SoT; recorded close reason 2026-06-06T21:00:10Z in [backup][backup], per [request-level-triage][request-triage]. |
| aura-plugins-295 | open | SLICE-1-REVIEW-B-1 IMPORTANT | REV, IMP | STALE | Frozen Python dataclass test exception specificity; types/tests removed by [D][retirement]. |
| aura-plugins-2tj | open | FOLLOWUP: Non-blocking improvements from aura_protocol v1 code review | FOLLOWUP | STALE | Aggregate of Python v1 findings; engine/tests removed by [D][retirement]. i2n is separately approved STALE below. |
| aura-plugins-3m4 | open | SLICE-5-REVIEW-C-1-F1: Workflow reassigns frozen TransitionRecord in transition_history list — breaks expected immutability guarantee | REV, MIN | STALE | Python workflow/state timestamp seam removed by [D][retirement]. |
| aura-plugins-3xe | open | SLICE-5-REVIEW-A-1 IMPORTANT | REV, IMP | STALE | Python workflow review group for closed 6wg; workflow removed by [D][retirement]. |
| aura-plugins-4hu | open | SLICE-2-REVIEW-A-1 MINOR: EpochState.current_role type is str not RoleId | REV, MIN | STALE | Python EpochState typing target removed by [D][retirement]; no Go parity claim. |
| aura-plugins-4u1 | open | SLICE-4-REVIEW-B-1 MINOR | REV, MIN | STALE | Python ToolCall test naming and ModelId parsing tests removed by [D][retirement]. |
| aura-plugins-5sn | open | UAT-1: Plan acceptance for release automation PROPOSAL-2 | PLANUAT | STALE | Row already records ACCEPT; remaining plan lifecycle obsolete after release CLI/plugin retirement [D][retirement]. |
| aura-plugins-5zf | open | SLICE-4-REVIEW-B-1 IMPORTANT | REV, IMP | STALE | Python runtime Protocol/checker integration test target removed by [D][retirement]. |
| aura-plugins-63f | open | REQUEST: Unified standing research team for architect and supervisor roles | REQ | STALE | Maintainer-approved: deprecated; standing research team concept abandoned per user; recorded close reason 2026-06-06T08:32:39Z in [backup][backup]. |
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
| aura-plugins-i2n | in_progress | FIX: Apply C-actionable-errors to all error messages in aura_protocol | UAT, SLICE | STALE | Maintainer-approved: closed as Python-moot 2026-06-06T09:09:55Z in [backup][backup]; target files subsequently deleted wholesale under aura-plugins-4s5zt (landed 2026-07-10), corroborated by [D][retirement]. |
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

No active edge is recreated: all 55 parents/children are STALE or historical.
The approved omissions below are migration decisions, not legacy deletions. All edges
remain intact in the retained source. Snapshot-live parents absent here have no outgoing
dependencies in the JSONL; incoming edges from closed rows remain historical
in the snapshot and are not imported as live blockers.

| Original parent | Original depends_on_id set | Approved dependency disposition |
|---|---|---|
| 1bm | 5sn | Omit retired release-plan edge. |
| 1ey | 1bm | Omit retired release-review edge. |
| 1ic | 4hu | Omit retired Python review edge. |
| 2tj | 0yd, 1ic, 295, 3xe, 4u1, 5zf, 68o, 7d2, 7no, 8jy, 947, bnr, don, dvi, gdx, h7x, i2n, j02, ngd, o83, pxo, sk6, tcn, utj, v1b, x36, xui, yno | 7no is historical closed. All other 27 edges, including approved STALE i2n, omitted with retired Python follow-up parent/children; no held edge remains. |
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

The original snapshot-live parent set has 26 parents and 54 edges, including
four edges to already closed historical children. No self/cycle/unmapped active
blocker is recreated. IDs 220/63f/i2n have no outgoing source edge.

## Maintainer decisions — resolved

The earlier gate questions/options remain in draft commit `c828678bd458cfd05d790a18c8a7303dd7fc0d32` for audit. The continuing
worker instruction reports the maintainer approval verbatim: **“all 3 UNCLEAR ->
STALE. Final counts: 0 REAL / 55 STALE / 0 UNCLEAR.”** Approved reasons are
recorded in the ledger rows above. This resolves all three holds and adopts the
existing closure of the historical in_progress commitment; no new closure or
historical-author impersonation occurred. The orchestrator owns the matching URD
decision record; this document does not claim that separate tracker write.

| Resolved hold | ID | Recorded historical decision | Approved answer |
|---|---|---|---|
| H1 | aura-plugins-220 | [Backup][backup]: closed 2026-06-06T21:00:10Z, “Audit close-chain (verify-then-close): REQUEST chain delivered/superseded by Go pasture SoT.” Cites request-level-triage.md and per-chain residual verification. | STALE — delivered/superseded by the Go pasture SoT (live bd close reason 2026-06-06, per docs/audits/request-level-triage.md). |
| H2 | aura-plugins-63f | [Backup][backup]: closed 2026-06-06T08:32:39Z, “Deprecated — standing research team concept abandoned; we've since moved on from it (per user). No ratified proposal/impl; standalone REQUEST.” | STALE — deprecated; standing research team concept abandoned (per user; live close reason). |
| H3 | aura-plugins-i2n | [Backup][backup]: closed 2026-06-06T09:09:55Z, “PYTHON_MOOT: target is Python/aurad code being deleted (aura-plugins-4s5zt).” Later deletion is corroborated by [D][retirement]. | STALE — Python-moot; target files deleted wholesale (aura-plugins-4s5zt; live close reason). |

Historical owner for each resolved hold is the original row's
`dayvidpham@gmail.com`; no active assignment is created or presumed.
Cross-repo successors are not created by this program. No generic link to
Pasture #43 is represented as a verified successor for these retired requests.

**Final answers to H1/H2/H3:** STALE / STALE / STALE, as approved above.
There are **zero currently held decisions**.

## Invariants and archive finalization

Verified accounting: **`original_live_ID_set = disjoint REAL + STALE`**,
**`55 = 0 + 55`**, with **zero held decisions**. Here `original_live_ID_set`
means the original February snapshot selection, not today's live store.
Every STALE ID has its reviewed evidence-backed reason and a recorded terminal
closure in the later export. REAL successor existence/namespace/status/edge
checks are vacuously satisfied because REAL is empty. The 62 historical closed
rows remain unchanged; no original was reopened or closed again.

- Maintainer classification approval: **approved** (all 55 rows).
- Independent full slice review (three ACCEPT votes): **pending**; focused draft
  review is not final slice or archive approval.
- H1-H3/source reconciliation: **resolved for the assigned 55-ID scope** by the
  maintainer instruction. Other exported rows are not silently reclassified.
- Archive policy: [`.beads/README.md`](../../.beads/README.md); read-only history,
  no deletion or continuing bd writes. No filesystem/Git-enforced lock is claimed.
- No successors, new blockers or original closures are needed or performed.
- Only the archive README and this ledger are changed; all pre-existing archive
  data/configuration and unrelated base dirt remain unchanged. No Git hook,
  user configuration or other-repo code is changed.
- The approved read-only case-(6) check below verifies unchanged data hashes.
  This is not evidence of a new mutation-based dogfood loop: SLICE-3/SLICE-4
  replacement deployment and R7 operational dogfood remain integration-owned.

### Case-(6) verification receipt

Finalization check executed with the host clock reporting `2026-10-13T01:42:22Z`
(approval was reported in the continuing instruction dated 2026-10-12).
Read-only Python parsing of the retained data and finalized ledger passed:

- 117 unique original rows; status counts 54 open / 1 in_progress / 62 closed.
- Exact equality of the original 55-ID selection and the ledger, with no duplicates;
  original status/title/expanded labels match for every ID.
- REAL is empty; STALE contains exactly all 55; UNCLEAR is empty. Every ledger
  row has a concrete evidence-backed reason; the later pinned export has a
  `closed` status, `closed_at` and nonempty `close_reason` for every selected ID.
- All 26 original dependency-parent sets / 54 edges match the ledger exactly.
  No successor or active blocker is required or created.
- Both source hashes match the recorded snapshot/export hashes above.
  All **18 pre-existing tracked archive files except the intentionally rewritten
  README** match their pre-finalization Git bytes and have identical before/after
  read-only-check hashes. No existing archive data/configuration file was removed.
- Sorted manifest SHA-256:
  `7bd033592e418b29cd0c2a636d20bbc60ea3f01508670f2b2b70dee944e94a63`.
  Manifest bytes are one UTF-8 `path + " " + lowercase_sha256 + "\n"` per file,
  sorted lexicographically by Python string order on repo-relative ASCII paths
  from `git ls-files .beads`, excluding `.beads/README.md`. Do not use
  locale-dependent shell `sort`. Exact worktree-byte reproduction:

  ```python
  import hashlib, pathlib, subprocess
  paths = subprocess.check_output(["git", "ls-files", ".beads"], text=True).splitlines()
  paths = sorted(p for p in paths if p != ".beads/README.md")
  manifest = "".join(p + " " + hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
                     + "\n" for p in paths).encode("utf-8")
  print(hashlib.sha256(manifest).hexdigest())
  ```

  This permits independent verification without committing a private export.
- `git diff --check` passes. This documentation/data audit does not require Go
  type checks or Nix packaging changes; no runtime, source projection or pin changed.

Case (6) is satisfied for the approved original set. Independent supervisor
review and integration deployment/dogfood remain distinct gates, not worker task
closure authority.

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
[request-triage]: https://github.com/dayvidpham/aura-plugins/blob/954dd5402d93f42f447ab9798f7417faffdf6b0e/docs/audits/request-level-triage.md
