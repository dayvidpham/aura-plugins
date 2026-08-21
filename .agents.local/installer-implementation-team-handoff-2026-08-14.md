# Installer Implementation Team Handoff

Date: 2026-08-14
Status: SUPERSEDED (updated 2026-08-16)

> SUPERSEDED. This is a historical snapshot from 2026-08-14, when Wave 1
> (registry + release catalog) was still in its final review cycles and every
> global harness/frontend slice was unstarted. The live plan and true state are
> in `installer-next-milestones-2026-08-15.md`.
>
> Current reality (2026-08-16): Pasture #39 global harness + CLI is COMPLETE and
> integrated on `epic/39-global-installer-delivery` at `9d8a02d` (synced with
> origin; NOT yet merged to Pasture `main` at `6fcdc45`). Slices `opbgi6.1`
> through `opbgi6.7` are CLOSED. Only `opbgi6.8` (global validation) remains
> open for #39, plus implementation UAT and landing. The interactive TUI was
> deferred to `aura-plugins-vjplx5`. Aura #8 IP-2 (`aura-plugins-yr93f9.2`) and
> Pasture #96 (`aura-plugins-yos54n`) remain not started.
>
> The "Potentially Active Workers", "Pasture #39 Worktree Topology", "Release
> Catalog Current State", and "Shared Registry Current State" sections below are
> obsolete point-in-time status; the state tables in those sections have been
> annotated. Constraints, settled product contracts, Beads roots, dependency
> order, #96 topology, and landing/validation rules below remain valid reference.

## Mission

Drive the Pasture installer portfolio to completion:

- Pasture #39: global three-harness installer and immutable aggregate release selection.
- Pasture #96: project-local three-harness installer.
- Aura #8: pure-Nix nine-cell projection and immutable aggregate release publication.

Pasture #95, hidden `__adapter` retirement, is complete and merged. Pasture #58 is indefinite backlog and is not an installer completion gate.

## Non-Negotiable Constraints

- Use only agent types whose names end in `-openai`.
- Never install, enable, or modify Git hooks.
- Do not revert, stash, stage, or commit unrelated changes.
- Preserve `/home/minttea/codebases/dayvidpham/aura-plugins/.claude/skills/tui-components/SKILL.md` exactly as found. It is unrelated user work.
- Beads dependency direction is parent blocked by child: `bd dep add <parent> --blocked-by <work-that-finishes-first>`.
- Use `git agent-commit`, never `git commit`, for implementation commits.
- Do not add migration or compatibility code for installer state. Installer state has not shipped.
- Existing generated skills remain unchanged. Manual tracker-neutral rendering is deferred.
- Before the next fix-review wave, the coordinating agent must personally run all tests and generation checks. Pass the exact results to reviewers and explicitly tell reviewers not to rerun tests; reviewers should focus on code inspection and acceptance evidence.

## Settled Product Contracts

- One first-shipped registry store owns both logical tables:
  - `global_installations[cell]`
  - `project_installations[canonical_project_root, cell]`
- `pasture install status` is the unified global/project status surface.
- `pasture projects list` is a filtered view of the same store.
- Immutable aggregate releases are selected by exact typed candidate. No moving `pasture-stable` alias and no fallback from an exact user selection.
- Release catalog public behavior is listing plus exact verified resolution. Mutation belongs to the installer-service slice.
- Integration tests must use production paths and real persistence/HTTP seams, not test-only dual paths.

## Repository State

Aura root:

```text
/home/minttea/codebases/dayvidpham/aura-plugins
branch: main, aligned with origin/main before current Beads coordination writes
last landed portfolio commit: b8e467d
```

Current Aura dirt:

- `.beads/backup/*.json*`: intended task/review coordination records. Do not discard.
- `.claude/skills/tui-components/SKILL.md`: unrelated user change. Do not touch.

Pasture source repository/submodule:

```text
/home/minttea/codebases/dayvidpham/aura-plugins/pasture
primary submodule worktree: detached at 64316a7
origin/main: 6fcdc45 after merged PR #98
```

Do not update the Aura submodule pointer merely to make the detached worktree current. Update it as part of an intentional portfolio landing after the relevant Pasture PRs merge.

## Completed Epic: Pasture #95

- GitHub PR: https://github.com/dayvidpham/pasture/pull/98
- Merged commit: `6fcdc45d29dbf3c9d1c144bae7be0ba00553d780`
- UAT choice, verbatim:
  - Question: `Which end-user behavior should #95 ship with?`
  - Response: `Completely absent (Recommended)`
- `__adapter` is now an ordinary unknown command and creates no DB/WAL/SHM.
- Claude, OpenCode, and Codex remain on typed `pasture hook lifecycle` transports.
- CI passed both Go versions, race tests, lint, and codegen drift after rerunning one unrelated SQLite concurrency flake.
- Beads epic `aura-plugins-1aq2is` and slices are closed.

The #95 epic worktree is now the worktree holding Pasture `main` at `6fcdc45`:

```text
/home/minttea/codebases/dayvidpham/aura-plugins/pasture/worktree/95--hidden-adapter-retirement
```

## Planning and Beads Roots

- Portfolio planning record: `aura-plugins-j303y0`
- Pasture #39 epic: `aura-plugins-opbgi6`
- Pasture #96 epic: `aura-plugins-yos54n`
- Aura #8 integration epic: `aura-plugins-yr93f9`
- Release-catalog escalation proposal: `aura-plugins-rgpqe4` (`PROPOSAL-62`)
- Global installer URD: `aura-plugins-lrzbog`
- Project installer URD: `aura-plugins-re8ksm`

The review budget originally selected by the user was three rounds. Release catalog exhausted that budget and then received two explicit bounded exceptions. The latest exception authorizes exactly one narrow patch and one targeted A/B/C confirmation review, with no further cycle.

Latest exception, verbatim:

```text
Question: "The authorized final review still has two test-contract BLOCKERs. Which disposition do you authorize?"
Response: "One narrow patch (Recommended)"
```

## Potentially Active Workers: Check First

> OBSOLETE (2026-08-16): Both worker sessions listed below completed long ago.
> The release catalog and shared registry slices are CLOSED and integrated. Do
> not act on the sessions below; they are retained only as historical record.

Do not duplicate these assignments. Background completion notifications may arrive after this handoff was written.

1. Release catalog final narrow patch
   - Task session: `ses_ffe95fa32ffeB8R7OEJIckLUDm`
   - Worktree: `/home/minttea/codebases/dayvidpham/aura-plugins/pasture/worktree/39--global-installer-delivery/worktree/2--release-catalog`
   - Branch: `slice/39-02-release-catalog`
   - Starting HEAD: `c901386908ed75f3542a6f17f54d991e4cd1b09d`
   - A prior reused worker session falsely reported completion without changing HEAD. This fresh session owns the actual narrow patch.

2. Shared registry final round-2 fix
   - Task session: `ses_0016cf6c1ffe2mEVkVxMueOLXw`
   - Worktree: `/home/minttea/codebases/dayvidpham/aura-plugins/pasture/worktree/39--global-installer-delivery/worktree/1--shared-registry`
   - Branch: `slice/39-01-shared-registry`
   - Last observed HEAD: `5605e3665bb7822a4f0fa32eeb96327eec4f8eab`
   - No completion notification for the final round-2 fix had arrived when this handoff was written.

Check worktree status and commit logs before taking action. Do not poll running Task sessions; wait for notifications. If a session is no longer active and left changes, preserve and inspect them rather than resetting.

## Pasture #39 Worktree Topology

Epic:

```text
/home/minttea/codebases/dayvidpham/aura-plugins/pasture/worktree/39--global-installer-delivery
branch: epic/39-global-installer-delivery
```

Slices (State column updated 2026-08-16):

| Slice | Beads | Path | Branch | State (2026-08-16) |
|---|---|---|---|---|
| Shared registry | `opbgi6.1`, leaf `opbgi6.1.1` | `worktree/1--shared-registry` | `slice/39-01-shared-registry` | CLOSED, integrated |
| Release catalog | `opbgi6.2`, leaf `opbgi6.2.1` | `worktree/2--release-catalog` | `slice/39-02-release-catalog` | CLOSED, integrated |
| Installer service | `opbgi6.3`, leaf `opbgi6.3.1` | `worktree/3--installer-service` | `slice/39-03-installer-service` | CLOSED, integrated |
| Claude global | `opbgi6.4`, leaf `opbgi6.4.1` | `worktree/4--claude-global` | `slice/39-04-claude-global` | CLOSED, integrated (`f31fc15`) |
| OpenCode global | `opbgi6.5`, leaf `opbgi6.5.1` | `worktree/5--opencode-global` | `slice/39-05-opencode-global` | CLOSED, integrated (`727be8d`) |
| Codex global | `opbgi6.6`, leaf `opbgi6.6.1` | `worktree/6--codex-global` | `slice/39-06-codex-global` | CLOSED, integrated (`5c27573`) |
| Installer frontends | `opbgi6.7`, leaf `opbgi6.7.1` | `worktree/7--installer-frontends` | `slice/39-07-installer-frontends` | CLOSED (CLI shipped; TUI deferred to `vjplx5`) |
| Global validation | `opbgi6.8`, leaf `opbgi6.8.1` | `worktree/8--global-validation` | `slice/39-08-global-validation` | OPEN, not started |

All relative slice paths above are under the epic path. Epic HEAD is now `9d8a02d` (was `64316a7` base when this table was written).

## Release Catalog Current State

> OBSOLETE (2026-08-16): The release catalog slice (`opbgi6.2`) is CLOSED and
> integrated. The narrow-patch findings below were resolved or dispositioned.
> Retained as historical record only.

Branch history before the active narrow patch:

```text
c901386 fix(installer): bind exact release and component identities
e7dbe67 merge: integrate main after adapter removal
4e1a2c5 fix(installer): finalize exact release catalog boundaries
6fcdc45 refactor: retire hidden adapter transport (#98)
3c261fa fix(installer): harden immutable release discovery
caa1548 feat(installer): verify immutable aggregate releases
```

Current public API:

```go
Catalog.ListCompatible(...)
Catalog.ResolveCandidate(...)
```

There must be no catalog mutation/apply API, fallback selection, moving alias, or compatibility wrapper.

The final narrow patch is limited to these findings:

- `aura-plugins-s7240f`: compile-time proof that activation indexing is exactly `map[cell.Extension]ComponentActivation`, plus typed lookup tests for all three extensions.
- `aura-plugins-zpse4y`: exact failure location equality and explicit nil/zero output phase assertions.
- `aura-plugins-h9lmue` and corroborating `aura-plugins-b7o95m`: close acquired HTTP bodies/readers on cancellation while preserving context causes; add close-tracking tests.
- `aura-plugins-8zywbr`: comments only, replacing stale Claude `ComponentKind` claims with canonical `artifact.ComponentID`/`artifact.Extension` terminology.

Allowed files are only the tests/production files directly required by those findings, plus comments in:

- `internal/codegen/opencode_target.go`
- `internal/codegen/codex.go`

Do not broaden public APIs or modify generated outputs.

### Mandatory Coordinator-Owned Validation Before Review

After the worker commits, the coordinator, not a reviewer, must run from the release-catalog worktree:

```bash
nix develop --command go test -race -count=1 ./internal/install/activation ./internal/install/releasecatalog ./internal/codegen/...
nix develop --command env CGO_ENABLED=1 go test -race -count=1 ./...
nix develop --command make fmt
nix develop --command make lint
nix develop --command make test
nix develop --command make test-race
nix develop --command make build
nix develop --command env CGO_ENABLED=0 go build ./...
nix develop --command go vet ./...
nix develop --command make generate
git diff --exit-code
git diff --check
git status --short --branch
```

Record exact pass/fail output and HEAD. Then spawn fresh `reviewer-openai` A/B/C reviewers and pass them the coordinator's results. Explicitly instruct them not to rerun tests or generation. They should inspect code, tests, diff scope, and acceptance evidence only.

This is the one authorized targeted confirmation review. If any reviewer reports a BLOCKER, stop and return to the user. Do not start another fix cycle.

## Shared Registry Current State

> OBSOLETE (2026-08-16): The shared registry slice (`opbgi6.1`) is CLOSED and
> integrated. The round-2 findings below were resolved. Retained as historical
> record only.

Commits observed:

```text
5605e366 fix: round-1 registry review findings
d1cee8a feat: shared installer registry
```

Round-2 findings assigned to the active/unknown worker include:

- Nonblocking/no-follow Save inspection for FIFO destinations.
- Windows-native access and durability semantics with Windows-specific tests.
- Unified mixed-scope production status using `registry.Store.Status()`.
- Removal of `inventory.New` and `inventory.Load`; inventory is a projection over caller-owned Store.
- Opaque validated values rather than exported string aliases.
- Byte-distinct failed-save and complete nested round-trip assertions.
- Explicit null, duplicate directory, unclean root, and bounded FIFO tests.

When the worker completes, run coordinator-owned gates before the final registry review too. Registry was entering its third and originally final review round. If the worker did not complete, inspect Beads findings and working tree before reassigning.

Registry and release branches were originally based on `64316a7`. Release already merged `6fcdc45`; registry must integrate current Pasture main after its fix commit and before final review.

## Safe Implementation Waves After Wave 1

Do not launch downstream workers before dependencies are reviewed and integrated.

1. Finish and integrate shared registry and release catalog.
2. Implement installer service after registry is accepted.
3. Freeze Aura aggregate producer contract after release catalog is accepted.
4. Implement Claude/OpenCode/Codex global controllers in parallel after service, release, and #95 dependencies are integrated.
5. Implement global CLI/TUI and Aura projection/publication.
6. Run global validation.
7. Begin project foundation and reconciler.
8. Implement three project harness adapters in parallel.
9. Implement project commands and project validation.

Key dependency order:

- #39 S3 blocked by S1.
- #39 S4/S5/S6 blocked by S2, S3, and completed #95.
- #39 S7 blocked by registry, catalog, and all global harness controllers.
- Aura #8 producer contract blocked by #39 S2.
- #39 S8 blocked by S7 and Aura publication/projection evidence.
- #96 S1 blocked by #39 S1.
- #96 S2 blocked by #96 S1 and #39 S3.
- #96 harness slices blocked by reconciler and corresponding global harness slices.
- #96 commands blocked by all project harness slices and #39 frontend contracts.

## Pasture #96 Worktrees

Epic:

```text
/home/minttea/codebases/dayvidpham/aura-plugins/pasture/worktree/96--project-installer-delivery
branch: epic/96-project-installer-delivery
```

Nested slices:

```text
1--project-foundation   slice/96-01-project-foundation
2--project-reconciler   slice/96-02-project-reconciler
3--claude-project       slice/96-03-claude-project
4--opencode-project     slice/96-04-opencode-project
5--codex-project        slice/96-05-codex-project
6--project-commands     slice/96-06-project-commands
7--project-validation   slice/96-07-project-validation
```

All remain at the original epic base and must be updated only when their declared predecessors integrate.

## Standard Validation

Pasture:

```bash
make fmt
make lint
make test
make test-race
make build
CGO_ENABLED=0 go build ./...
go vet ./...
make generate
git diff --exit-code
git diff --check
```

Use `nix develop --command ...` when Go/tooling is not available directly on PATH.

Aura:

```bash
nix flake check --no-build
nix build .#aura-swarm --no-link
nix run .#aura-swarm -- --help
nix build .#checks.x86_64-linux.hm-module-test --no-link
```

## First Actions for the New Team

1. Read this document and `bd show` the portfolio, #39 epic, active slices, PROPOSAL-62, and open findings.
2. Check whether the two worker task sessions completed. Do not duplicate active ownership.
3. Inspect both Wave-1 worktrees for clean status and new commits.
4. For release catalog, run the coordinator-owned complete validation suite before spawning any reviewer.
5. Give exact gate results and HEAD to fresh A/B/C `reviewer-openai` agents; tell them not to run tests.
6. Stop on any release-catalog BLOCKER because no further cycle is authorized.
7. For registry, integrate current Pasture main after the final fix, run coordinator-owned gates, then conduct its final review.
8. Only after Wave 1 is accepted, merge reviewed commits into `epic/39-global-installer-delivery` in dependency order and launch S3/Aura contract work.

## Landing Rules

- Pasture `main` is protected. Push epic branches and use GitHub PRs.
- Inspect status, diff, remote tracking, recent commits, and full base diff before every PR.
- Require CI, independent review, and explicit implementation UAT before merge.
- Use squash merge unless repository history indicates otherwise.
- Update and commit Aura's Pasture submodule pointer only after intentional Pasture landing.
- Stage only intended Beads backups and the submodule pointer. Never stage the unrelated TUI skill change.
