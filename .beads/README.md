# Retained Beads archive — read-only

This directory is historical evidence, not the operational task tracker.
The maintainer-approved [retirement ledger](../docs/audits/bd-retirement-triage.md)
is the successor/disposition record for the assigned 55-ID snapshot set:
**0 REAL / 55 STALE / 0 UNCLEAR**. No successor task URI is required for STALE.
All 55 already have terminal closures with reasons in the later tracker export;
do not close them again from the older snapshot's open/in_progress statuses.

## Freeze policy

- Retain this directory, its existing files and Git history; do not delete them.
- Treat the archive as read-only: no new bd writes, refreshes, synchronization,
  imports, issue edits, labels, comments or closure operations against it.
- Use Pasture for ongoing work, in namespace
  `https://github.com/dayvidpham/aura-plugins`; never resume a parallel bd workflow.
- Do not install, enable or modify any Git hook, `core.hooksPath` or tracker
  integration as part of retirement. Any separate hook change needs explicit
  maintainer approval. No hook or configuration change implements this freeze.
- Preserve source bytes. Read-only checks may parse retained JSONL or export
  pinned Git blobs to an external temporary path, never overwrite archive files.
- This is a documented review policy, not a filesystem permission lock or an
  automatically enforced Git barrier. Do not claim chmod alone enforces it.

## Source reconciliation and integrity

`.beads/issues.jsonl` is a February snapshot: 117 rows, including the original
54 open and one in_progress selected for this ledger. It is not current liveness.
The already tracked `.beads/backup/issues.jsonl` at source revision
`954dd5402d93f42f447ab9798f7417faffdf6b0e` records all 55 selected IDs closed
with reasons. Other exported rows are retained history, not newly approved work
or silently classified by this bounded migration.

Expected SHA-256 for retained source data:

| File | SHA-256 |
|---|---|
| `issues.jsonl` | `43fe1700fe541959ed781a49bd29a6f10a243f27f609efc41a195a62fb11d75a` |
| `backup/issues.jsonl` | `d5a5022a898904c2557066ca0569e74ed347fea4dca450282e4a1f6845668592` |

The ledger records the snapshot revision, export hashes, original fields,
dependencies, per-ID approved reasons and case-(6) verification. Recheck hashes
after read-only inspection or Pasture-only activity. Any data drift is a failed
archive-integrity check; report it and seek maintainer reconciliation, rather
than repairing history with tracker writes or deleting evidence.
