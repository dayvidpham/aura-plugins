---
name: 3iz51 — Sibling Epic Placement Audit
status: Phase 9 — deliverable (C-A1 table + C-A3 ROADMAP diff)
references:
  audit_task: aura-plugins-3iz51
  proposal: docs/proposals/PROPOSAL-1-audit-3iz51.md
  ure_uat: aura-plugins-tpm4r
  roadmap: docs/ROADMAP.md
  executor: wave-1-lead (2026-05-29)
---

# 3iz51 — Sibling Epic Placement Audit

Classification audit per PROPOSAL-1-audit-3iz51.md §8 / PROPOSAL-2 §5.4.
Methodology: `bd show` each of 8 epics, verify status + open children + ow0pq-blocker relationship, classify.

## C-A1 Placement Table

| epic-id | title | verdict | rationale (bd-verified) | roadmap-location |
|---|---|---|---|---|
| `x5071` | EPIC: Port remaining 30 Python skills to Go | **§2-active** | OPEN; 1 dep (cgwc1) is done, but the 30-skill port work itself has not started; umbrella open; explicitly blocks `ow0pq` | §2h (existing) + §1.5 (existing) |
| `q9sz9` | FOLLOWUP: Non-blocking improvements from codegen body integration review | **§2-active** | OPEN; 2 IMPORTANTs + 7 MINORs outstanding in description; no child tasks filed under this epic (findings not yet broken out into child tasks); does NOT block `ow0pq` | §2 new row |
| `wftdf` | FOLLOWUP: Non-blocking improvements from Go test paradigm code review | **§2-active** | OPEN; 3 MINORs outstanding (want_stderr_contains naming, t.Parallel() missing, AGENTS.md update); no child tasks under epic (findings unresolved); does NOT block `ow0pq` | §2 new row |
| `rk2su` | FOLLOWUP: ACP wiring non-blocking improvements | **PENDING-USER** | All 9 child tasks are done (✓); umbrella task remains OPEN and still explicitly blocks `ow0pq`; this is the §4-step-3 rk2su contradiction. See escalation section below. | PENDING-USER decision |
| `ytzcl` | FOLLOWUP: Non-blocking improvements from Pasture code review | **§5-done** | All 8 child tasks done (✓); umbrella open but work complete; does NOT block `ow0pq`; all Pasture code-review findings resolved | §5 new row |
| `ad8i1` | FOLLOWUP-2: Non-blocking improvements from UAT revision code review | **§2-active** | OPEN; 8 IMPORTANT findings listed in description; no child tasks filed; references Python-era UAT revision (`oqhjg`); may be partially obsoleted by Python deprecation but is not closed; does NOT block `ow0pq` | §2 new row |
| `9wdwc` | EPIC: Beads → Temporal migration — move task tracking to aurad | **§2-active** | OPEN; scope deliberately TBD; deferred from aurad+aura-msg UAT with label `aura:epic-deferred`; does NOT block `ow0pq` | §2 new row |
| `6ujr` | EPIC: aura-acp plugin — ACP integration for protocol engine | **§2-active** | OPEN; deferred ACP R13–R17 (bidirectional ACP event emission, TranscriptRecorder, ACP types, SecurityGate); label `aura:epic-deferred`; explicitly blocks `ow0pq` | §2j (existing) + §1.5 (existing) |

**Summary:** 7 clear-cut classifications + 1 escalation (rk2su).

## C-A3 ROADMAP diff summary

Edits to `docs/ROADMAP.md` (see git diff for full text):

- **§2 (Deferred roadmap items):** Added 4 new rows — `q9sz9`, `wftdf`, `ad8i1`, `9wdwc`. Existing rows for `x5071` (§2h), `6ujr`/`rk2su` (§2j) unchanged.
- **§5 (Done so far):** Added 1 new row — `ytzcl`.
- **§1.5 (Sibling epics):** No changes. `x5071`, `6ujr`, `rk2su` rows already present and accurate. `rk2su` status left unchanged pending user decision.
- **rk2su:** Zero ROADMAP edits. Escalated to user per §10.

## C-5 Peer-linkage reconciliation

ow0pq's DEPENDS ON among the 8 audit epics: `{x5071, 6ujr, rk2su}`.
These are the three that "block `jbnx3` closure" directly.

- `x5071` — §2-active (correctly in §1.5 as blocker). Confirmed.
- `6ujr` — §2-active (correctly in §2j + §1.5 as blocker). Confirmed.
- `rk2su` — PENDING-USER (in §1.5 as blocker; contradiction unresolved).

The other 5 (`q9sz9`, `wftdf`, `ytzcl`, `ad8i1`, `9wdwc`) do NOT appear in ow0pq's DEPENDS ON and are not `jbnx3` closure blockers. §1.5 is accurate; no restructuring needed.

---

## ESCALATION — rk2su (PENDING-USER)

**Epic:** `aura-plugins-rk2su` — "FOLLOWUP: ACP wiring non-blocking improvements"

**What bd shows:**
- Status: OPEN
- Child tasks: 9, all marked ✓ (done). Specifically:
  - aura-plugins-9mhni (ACP-WIRING-REVIEW-B-1 MINOR) ✓
  - aura-plugins-a887a (ACP-WIRING-REVIEW-B-2 MINOR) ✓
  - aura-plugins-gnkk5 (ACP-WIRING-REVIEW-C-1 MINOR) ✓
  - aura-plugins-pexyy (ACP-WIRING-REVIEW-A-1 IMPORTANT) ✓
  - aura-plugins-potip (ACP-WIRING-REVIEW-B-1 IMPORTANT) ✓
  - aura-plugins-rd0oy (ACP-WIRING-REVIEW-C-1 IMPORTANT) ✓
  - aura-plugins-srav7 (ACP-WIRING-REVIEW-A-1 MINOR) ✓
  - aura-plugins-uxpqe (ACP-WIRING-REVIEW-B-2 IMPORTANT) ✓
  - aura-plugins-yf18c (ACP-WIRING-REVIEW-C-2 MINOR) ✓
- BLOCKS: `aura-plugins-ow0pq` (jbnx3 closure triage)

**The contradiction:** All child work is done (9/9 ✓), but the umbrella task (`rk2su`) was never closed and still appears in `ow0pq`'s DEPENDS ON list. This means `ow0pq` (and transitively `jbnx3`) cannot close until `rk2su` itself closes — yet the actual work tracked by `rk2su` appears complete.

**User decision needed:**
1. **Close `rk2su`** — if all IMPORTANT/MINOR findings are verified resolved, simply close the umbrella epic. This unblocks `ow0pq`.
2. **Add a ROADMAP §5 note** — if the user wants to verify residuals first before closing, add a §5 note to ROADMAP and leave `rk2su` open with explicit rationale.

**Worker action:** Zero edits to ROADMAP or rk2su. Reported here and to team-lead per §10 escalation rule.

---

## Phase-5/6 UAT Resolution — rk2su escalation (2026-05-30)

The `rk2su` PENDING-USER escalation is **resolved** (user decision B):

- **Placement:** `§2-active` (OPEN, **pending verification**) — ROADMAP **§2r**. NOT `§5-done`, NOT closed.
- **Why:** all 9 children (ACP-WIRING-REVIEW A/B/C IMPORTANT+MINOR) are closed, but closure is **gated on verifying the children actually addressed the original findings**.
- **Verification task:** [`aura-plugins-t70aw`](beads://aura-plugins-t70aw) (`discovered-from:aura-plugins-3iz51`) — on confirmation → close `rk2su` (unblocks `ow0pq`).
- **`rk2su` continues to block `ow0pq`** until verified + closed.

The other 7 epic placements stand as executed in Phase 9. **Final ledger: 8/8 placed** (7 clear-cut + rk2su §2-active pending verification).

---

## Phase-11 Impl-UAT — final ledger (2026-05-30)

The per-epic walkthrough confirmed/refined all 8 placements; cross-check caught a conflation/missed-finding pattern on nearly every epic.

| Epic | Final placement | Phase-11 change |
|---|---|---|
| `x5071` | §2-active | Confirmed (remaining-30 port unstarted; blocks ow0pq). Distinguished from re-opened foundation URD `f85gw` — IMPL_UAT decisions belong to f85gw, not x5071. |
| `q9sz9` | §2-active | Confirmed. 9 findings (2 IMPORTANT + 7 MINOR) filed as child tasks. |
| `wftdf` | §2-active | Confirmed. 3 MINORs filed as child tasks; **MINOR-4** (test-contract parity audit, missed by the audit — in comments) filed as residual `aura-plugins-wkbc3` (R-C/parity theme). |
| `ad8i1` | §2-active → **extract-residual** | RE-PLACED: its 8 IMPORTANTs target deprecated Python → verify-against-Go residual `aura-plugins-fs107` (R-A theme). |
| `9wdwc` | §2-active | **RE-SCOPED**: 'Beads → Temporal' → 'Beads → provenance integration' (provenance/PROV-O is the shipped Beads-replacement). Links ROADMAP §2b. |
| `6ujr` | §2-active (P3 low-prio) | **SPLIT + DESCOPED from `ow0pq`**: R16/indexer → `aura-plugins-n856x` (low-prio, harness-independent); R13/R15/R17 externally-blocked on Claude Code native ACP. jbnx3 R4 = 'core + ACP types delivered; live bidirectional ACP deferred'. |
| `ytzcl` | §5-done (pending verification) | Verify-first (like rk2su): residual `aura-plugins-0qrq1`; ytzcl NOT closed until verified. |
| `rk2su` | §2-active (pending verification) | Decision B (residual `aura-plugins-t70aw`); kept OPEN, still blocks ow0pq. |

### State changes
- **RE-OPENED** (port-to-Go effort incomplete): `f85gw` (URD foundation) + `cgwc1` (REQUEST) + `xh675` (ELICIT) + `ygkp0` (PROPOSAL-3) — all were CLOSED P1. `f85gw` linked to the open follow-up `x5071`.
- **6ujr descoped from `ow0pq`** (dependency removed) — jbnx3 no longer gated on external Claude Code ACP support.
- **9wdwc re-scoped** (title + comment): Beads → provenance.
- **`in_progress`**: none set — all 8 epics are open-not-started (no demonstrable current progress); per the user directive, left OPEN.
- **Provenance-misnomer cleanup** residual `aura-plugins-ijcfk` (rename `providence`→`provenance` across labels + ROADMAP frontmatter/prose + memory).

### C-5 peer-linkage reconciliation (updated)
`ow0pq` blockers among the 8 audit epics: **`x5071` + `rk2su`** (rk2su pending verification). **`6ujr` removed** (descoped 2026-05-30). ROADMAP §1.5 updated (9→8 prerequisites; 4→3 peer epics).

**Final: 8/8 placed.** 3iz51 audit complete (Phase-11 ACCEPT). Closing `ow0pq` still requires `x5071` + `rk2su` (+ the non-epic blockers) to land.
