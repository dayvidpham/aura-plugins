# Proposal 50, 57, and 61: Parallel Delivery Map

## Purpose

This is an execution map, not another design proposal. It groups work into
coarse public-interface delivery waves so implementation can proceed in
parallel without turning every review comment into a new micro-slice.

**Delivery rule:** a wave owns an end-to-end production path and its dependent
chain. Review occurs after the wave's shared gate run, not after each internal
refinement. One reviewer-mini runs automation once; all code reviewers consume
that report.

## Proposal relationship

```text
Proposal 50: broad Pasture delivery / activation and protocol platform
    │
    └── Proposal 57: epoch lifecycle and assignment aggregate delivery
            │
            ├── CreateSlice governed-allocation vertical (current MVP)
            ├── review / candidate / rework / close / publish aggregate
            ├── CLI and adapter boundaries
            └── acceptance integration
            │
            └── Proposal 61: bounded fact-query substrate
                    (only blocks Proposal-57 consumers that need persisted
                     decision/evidence history; it does not block CreateSlice)
```

## Public API ownership

| Owner | Public surface it owns | Downstream consumers | Status / boundary |
|---|---|---|---|
| **Provenance governed allocation** | `FusedGovernedAllocator.RunAllocateComposed`, `GovernedAllocationComposedRequest`, `GovernedAllocationParticipant`, immutable closure/slot/event result | Pasture `CreateSlice` | Public shape is stable; current replay hardening is internal only. |
| **Pasture Slice 57.2 / CreateSlice** | `EpochService.CreateSlice`, typed `CreateSliceInput` and `SliceResult`; exact task/assignment IDs and returned activity/event bindings | CLI/adapters and later lifecycle operations | Current downstream MVP. One composed allocation plus canonical supplemental effects and Pasture audit participant. |
| **Pasture Slice 57.2 / lifecycle aggregate** | Review start/submit/finalize, candidate create/rework, slice close, publication commands and typed results | CLI, adapters, acceptance runner | Starts in a separate worktree after CreateSlice's public contract is committed. |
| **Pasture Slice 57.3** | Typed epoch CLI grammar, versioned `--input -` DTO decoding, private native adapter invocation envelope | Generated host adapters | May build grammar/envelope foundations in parallel once Slice 57.2 contracts freeze. |
| **Pasture Slice 57.4** | Version-bounded Claude/Codex/OpenCode event-to-command mappings | Host integration | Semantic mappings can start after Slice 57.2 types freeze; native wiring waits for Slice 57.3 envelope. |
| **Pasture Slice 57.5** | Store snapshot reader, minimal acceptance schema, built-binary integration runner | All delivered command paths | Reader/schema foundation can parallelize; full runner waits for commands and adapters. Do not make corpus/mutation machinery a current MVP gate. |
| **Proposal 61 / Provenance facts** | `Tracker.Journal().Facts()`, `QueryDecisions`, `QueryEvidence`, bounded typed pages | Only Proposal-57 consumers that reconstruct fact history | Separate follow-up. Requires `providence-d29s` then `providence-j8i.1.4`; not a CreateSlice dependency. |
| **Proposal 50 platform work** | Activation/selection, protocol/decision-ledger and host-management surfaces defined by Proposal 50 | Proposal-57/Pasture delivery where explicitly referenced | Broad parent stream. Do not start a monolithic implementation; publish a small public API kernel before dependent work. |

## Coarse parallel waves

```text
W0 — NOW
───────
Provenance replay hardening ────────┐
                                    ├── immutable Provenance pin
Pasture CreateSlice prototype ──────┘

W1 — CREATE SLICE INTEGRATION
─────────────────────────────
Pasture pin conversion / final CreateSlice gate
  - remove temporary local replace
  - pin pushed Provenance commit
  - update module/Nix dependency metadata
  - exercise real CreateSlice production path

W2 — PARALLEL AFTER CREATE SLICE PUBLIC CONTRACT IS COMMITTED
────────────────────────────────────────────────────────────
Worktree A: Slice 57.2 remainder
  review, candidate, rework, close, publish aggregate

Worktree B: Slice 57.3 foundation
  typed CLI grammar + strict input DTOs + private envelope

Worktree C: Slice 57.5 foundation
  file-backed snapshot reader + minimal acceptance schema

W3 — PARALLEL AFTER SLICE 57.2 TYPES / SLICE 57.3 ENVELOPE FREEZE
────────────────────────────────────────────────────────────────
Worktree D: Slice 57.4 host semantic mappings
Worktree E: Slice 57.3 command wiring / migrations
Worktree F: Proposal 61 prerequisites, only if their Provenance
            integrations (`d29s`, `j8i.1.4`) are accepted

W4 — INTEGRATION
────────────────
Slice 57.5 consumes frozen command and adapter contracts for built-binary
coverage. Keep only contract-level integration cases in the MVP; defer large
corpus, permutation, mutation, and host-matrix expansion unless a concrete
delivery path needs it.
```

## Dependencies that must remain serial

1. **Provenance pin before Pasture final verification.** A temporary local
   replace is development-only and must never be the final proof.
2. **CreateSlice commit before the remaining Slice 57.2 worker.** Those paths
   share `internal/tasks` authority/replay contracts; a committed interface is
   the integration point that prevents worktree merge conflicts.
3. **Slice 57.3 envelope before Slice 57.4 native wiring.** Mapping semantics
   can be drafted early, but native transport must consume the frozen envelope.
4. **Proposal 61's `d29s` and `j8i.1.4` before its Pasture consumer.** It is a
   fact-history dependency only; do not use it to delay CreateSlice.

## Worktree and review policy

- Each coarse wave uses isolated worktrees and one owner per production file.
- Workers may complete dependent chains within their assigned wave before
  requesting review.
- A shared reviewer-mini runs automated gates exactly once per completed wave.
- The three code reviewers inspect behavior and public contracts only. Do not
  create findings for cosmetic refactors, speculative hardening, or deferred
  matrix coverage.
- A reviewer finding creates one consolidated repair wave, not a per-finding
  sequence of workers and gates.
- Final dependency pins and landing still require real integration verification
  and immutable commits.

## Explicit deferrals

- Proposal 61 implementation until its two Provenance prerequisites are
  accepted.
- Broad Slice 57.5 corpus/mutation and authentic-host matrices.
- Broad Proposal 50 implementation until its smallest required public API
  kernel is identified and independently committed.
- Legacy/temporal paths and any bootstrap allocation exception.
