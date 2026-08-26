# Releasing aura-plugins

Aura publishes **immutable aggregate plugin releases**. One release version
identifies one coherent set of Claude Code / OpenCode / Codex skills, agents,
and hooks, bound to the exact Aura and Pasture commits it was built from.

Two rules shape everything below:

- **A published version is permanent.** Tags and releases are never moved,
  overwritten, or deleted. A mistake is corrected by publishing the next
  version, not by editing the last one.
- **There is no moving alias.** No `pasture-stable` branch, tag, or "latest"
  pointer exists. Consumers select one exact version.

> **Status: wired end to end, but it has never run on GitHub.**
>
> Every stage — release PR, tag, guard, gates, component build, publication,
> post-publish smoke — is implemented and locally validated: `actionlint`,
> `shellcheck`, the release-script suites, `nix flake check`, and a full local
> dry-run of build → export → produce → verify against a real
> `pasture bundle export`.
>
> Local validation proves syntax and logic, not runtime behaviour. **None of
> these workflows has ever executed on GitHub**, so expect first-run breakage
> and treat the first release as a supervised operation. This caveat stays here
> until a release has actually been cut.
>
> **One prerequisite is outside this repository.** The pinned Pasture must be a
> published Pasture release: the pipeline derives the aggregate's installer
> compatibility floor from the pinned Pasture binary's own version and refuses
> to publish unless that version names a real Pasture release built from
> exactly the pinned revision. Pasture is released first, always — see
> [Installer compatibility](#installer-compatibility) and
> [Before the first release](#before-the-first-release).

## The pipeline at a glance

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/gates.yml` | `workflow_call` only | The full quality gate: `nix flake check -L` (which runs `hm-module-test`, `aggregate-release-test`, and the release-script suites), `nix build .#aggregate-release`, an assertion that the producer still exposes its seven-option contract, the grammar-versus-producer subset proof, the **cross-repository chain** (build the pinned Pasture, derive the installer compatibility range from its `--version` and assert that floor is a published Pasture release at the pinned revision, export the nine components, package them with the real producer, verify the result), `nix build .#aura-swarm`, `nix run .#aura-swarm -- --help`, `shellcheck` + the release-script test suites, and `actionlint`. |
| `.github/workflows/release-pr.yml` | `pull_request` (opened/edited/synchronize/reopened) into `main` | On a `release(...)`-titled PR: validates the title grammar, asserts the author is a maintainer, refuses a version that is already released, then calls `gates.yml` in full. |
| `.github/workflows/release-tag.yml` | `pull_request` `closed` into `main` | When a `release(...)` PR **merges**: mints the immutable annotated tag with the release App token, refusing duplicate tags and unreachable commits. |
| `.github/workflows/release.yml` | `push` of a `v*` tag | Guards the tag (App actor, annotated, reachable from `main`) and emits the dereferenced tagged commit that every later job uses, re-runs `gates.yml` against the tagged commit, builds the nine component assets from the pinned Pasture and packages them with the aggregate producer, publishes the GitHub Release **as a draft first** and undrafts it only once its contents are proven, then re-downloads the published assets and verifies them. |

Only `release-tag.yml` ever creates a tag as part of this flow, and
`release.yml`'s guard refuses any tag that was not pushed by the release App.
That guard is what makes "a release can only come from a merged release PR" an
enforced property rather than a convention: a hand-pushed `v*` tag still starts
the workflow, but the guard rejects it and no release is produced.

Note the guard is doing that work alone. Anyone with push access *can* create a
`v*` tag, and it *will* trigger `release.yml` — the rule that refs pushed with
`GITHUB_TOKEN` do not trigger workflows constrains tokens, not people. Add the
tag ruleset described below as defence in depth.

## Version grammar

`scripts/release/release-grammar.sh` is the single source of the grammar. Every
workflow calls it rather than embedding its own regex, so the PR gate, the tag
job, and the tag guard cannot drift apart.

```
release(vMAJOR.MINOR.PATCH): <summary>          → final release
release(vMAJOR.MINOR.PATCH-rcN): <summary>      → release candidate
```

The grammar is intentionally narrower than SemVer, because it is the
intersection of the PR ceremony and what the aggregate producer's own parser
(`artifact.ParseVersion`) accepts:

- no leading zeros in any numeric component;
- no build metadata (`+...`);
- prereleases are `-rcN` only, with `N` ≥ 1;
- no numeric component exceeds 17 digits, so every accepted version stays well
  inside the 64-bit parser the producer uses — the bound is deliberately
  conservative, and `gates.yml` proves the subset relation by feeding every
  representative accepted version to the real producer binary;
- the whole marker must be a single line: control characters, including
  newlines, are refused, because the parsed values are written to workflow
  outputs and into the annotated tag message;
- the summary after the colon must be non-empty — it becomes the annotated tag
  message, and is the durable record of *why* the release was cut.

Final releases are listed by default by the installer; release candidates are
visible only through explicit opt-in. The classification is derived from the
version itself, never configured separately.

Run the release-script suites locally:

```bash
scripts/release/release-grammar_test.sh
scripts/release/verify-aggregate-dir_test.sh
scripts/release/pinned-pasture-revision_test.sh
```

All three also run inside `nix flake check`, as the `release-scripts` check.

## One-time setup

### 1. The release GitHub App

Tag creation uses a GitHub App token, not the default `GITHUB_TOKEN`, for two
reasons: GitHub refuses to fire workflows for refs pushed with `GITHUB_TOKEN`
(its recursive-workflow guard), so a tag pushed that way would never trigger
publication; and an App token gives the tag a real bot identity that
`release.yml`'s actor guard can then require.

Pasture uses the same pattern and the same secret names, so the **same App can
be installed on both repositories** — see `pasture/.github/workflows/release.yml`,
which reads `RELEASE_APP_ID` and `RELEASE_APP_PRIVATE_KEY`. Reuse it rather than
creating a second App unless you want separate audit trails.

The App installation needs **`Contents: write`** on `aura-plugins`.

### 2. Repository secrets

Settings → Secrets and variables → Actions → *Secrets*:

| Secret | Value |
| --- | --- |
| `RELEASE_APP_ID` | The release App's numeric App ID. |
| `RELEASE_APP_PRIVATE_KEY` | The App's private key, full PEM including the header and footer lines. |

These are the only secrets the release pipeline needs. No values are recorded in
this repository.

### 3. Repository variables (the actor guard)

Settings → Secrets and variables → Actions → *Variables*:

| Variable | Value |
| --- | --- |
| `RELEASE_APP_BOT_LOGIN` | The App's bot login, e.g. `my-releaser[bot]`. |
| `RELEASE_APP_BOT_ID` | The bot user's numeric id. |

These are public identifiers, not secrets, which is why they are variables — the
guard's error message can name the expected identity when it refuses a tag.

They are configured rather than hardcoded because both values are specific to
the App installation. To read them off the first App-created tag:

```bash
gh api "repos/dayvidpham/aura-plugins/actions/runs?event=push" \
  --jq '.workflow_runs[0] | {actor: .actor.login, actor_id: .actor.id}'
```

Until both are set, `release.yml`'s guard **fails closed** — it refuses to
publish rather than accepting an unverified tag.

### 4. Branch protection

`main` should require the `release PR verdict` check — the one context that
reports on every pull request (a skipped reusable-workflow caller reports under
its own name, but a running one expands to sub-job names only). The verdict job
passes immediately on an ordinary PR and, on a release PR, only when the
validation and the full gate set are both green — so a release PR cannot be
merged, and its permanent tag cannot be minted, before the tree is proven.

### 5. A `v*` tag-creation ruleset

`release.yml`'s actor guard already refuses a tag that the release App did not
push, so a hand-pushed tag cannot produce a release. A ruleset stops that tag
from being *created* in the first place, which is better: it removes the
failed-run noise and the momentary existence of a bogus `v*` ref.

Settings → Rules → Rulesets → New ruleset:

- **Target:** Tags, with the pattern `v*`.
- **Rule:** *Restrict creations*.
- **Bypass list:** the release App only.

With this in place, tag creation is possible only through a merged release PR.
The guard in `release.yml` remains as the enforcing check — the ruleset is
defence in depth, not a replacement, and the guard is what fails closed if the
ruleset is ever relaxed.

## Cutting a release

1. **Open the release PR.** Branch off current `main`. The PR may contain the
   changes being released, or be a marker commit — the gate set runs in full
   either way, precisely because a marker commit would otherwise trigger no
   path-filtered CI.

   Title it exactly:

   ```
   release(v0.1.0): first immutable aggregate release
   ```

2. **Watch the PR checks.** `validate release PR` confirms the title grammar,
   your maintainer role, and that the version is unused. `gates (release PR)`
   runs the full quality gate — including the cross-repository chain, which
   builds the pinned Pasture, derives the installer compatibility range from it,
   and refuses a pin that is not a published Pasture release. Both must be
   green. A failure here is cheap: no tag exists yet, and the usual remedy is
   `nix flake update pasture` on this same PR.

3. **Merge.** `release-tag.yml` then mints the annotated tag `v0.1.0` on the
   merge commit, after re-confirming the tag does not already exist locally or
   on the remote and that the merge commit is reachable from `main`.

4. **`release.yml` runs from the tag** and publishes. In order:

   - the **guard** verifies the actor, the annotation, and reachability from
     `main`, and emits the *dereferenced* tagged commit — the one value every
     later job checks out, stamps into the manifest, and compares against;
   - the **gates** re-run against the tagged commit;
   - **build-components** reads the pinned Pasture revision out of `flake.lock`,
     builds that exact Pasture, derives the installer compatibility range from
     it and re-asserts that its floor is a published Pasture release at that
     revision, runs `pasture bundle export` for the release version, and
     packages the result with `aura-aggregate-release`;
   - **publish** re-verifies the aggregate after the artifact round-trip, then
     performs the two-phase publication described below;
   - **smoke** downloads the published assets fresh, after undrafting, and
     verifies them again.

### Publication is draft-first

A GitHub Release is visible the moment it is created, and its eleven assets
upload one at a time. Creating it published would mean a consumer could fetch a
release holding three of them. So `publish` works in two phases:

1. create the release as a **draft** (invisible to consumers, and never marked
   "latest" — there is no moving alias here);
2. upload every asset; ask the API what the release holds and compare that
   against the manifest's own inventory, including that GitHub finished storing
   each one; download the draft fresh over the network and run
   `verify-aggregate-dir.sh` over it; assert the prerelease flag matches the
   manifest's channel;
3. only then `--draft=false`.

Undrafting is a single API call over content that has already been proven, which
is the smallest irreversible step available. What this buys, precisely:

- **before** the undraft, a failure leaves at most a draft release. Nothing is
  visible, nothing is installable, and the tag is unharmed. Delete the draft
  from the Releases page if you want a clean slate; re-running works either way.
- **after** the undraft, the release is public. The `smoke` job re-downloads and
  re-verifies it, and if that fails it says so plainly: a published version is
  permanent and must be superseded, never edited or replaced.

### Re-running a release

Re-running is normal — an expired token, a runner failure, a network fault
mid-upload. `publish` classifies whatever already exists for the tag:

| Existing state | What happens |
| --- | --- |
| No release | The draft is created and the assets uploaded. |
| A **draft** | A previous attempt stopped before publication. The draft is resumed: assets are re-uploaded over it, since draft bytes are not yet a promise. |
| A **published** release | Its assets are downloaded and compared with what this run built, name for name and digest for digest. **Identical** — the work is already done, and the run converges without touching anything. **Different** — refused, with the diff, because two different aggregates claiming one permanent version is exactly what immutability exists to prevent. |

Re-run **all** jobs, not only the failed ones. The component build uploads its
aggregate as a workflow artifact with a 7-day retention, so a "re-run failed
jobs" attempt after that window has nothing to download; re-running all jobs
rebuilds the aggregate from the tagged commit and the pinned Pasture, which is
reproducible for as long as both exist. If the run itself has aged out of the
Actions retention window entirely, there is no re-run to perform: the tag still
stands, and the release can be published by any mechanism that produces the same
bytes — build them and attach them with the same verification, or supersede the
version.

The tag is never recreated by any of this.

5. **Afterwards**, bump the aura-plugins entry in
   `.claude-plugin/marketplace.json` if the release should be offered through
   the marketplace.

Nothing in this flow requires a local tag, and no step should ever be performed
by hand. If a release must be re-attempted after a fixed infrastructure problem,
re-run all jobs of the workflow from the Actions tab — see
[Re-running a release](#re-running-a-release). The tag already exists and is
reused, never recreated.

## What a published release contains

`aggregate-release/` is a **packager, not a builder**. The build job supplies
the nine already-built component archives and their identities; the producer
turns them into the immutable, verified release directory that is published
verbatim:

| Asset | What it is |
| --- | --- |
| `pasture-aggregate-manifest.json` | The release identity: version, channel, installer compatibility range, the exact Aura and Pasture commits, and one record per cell with its digest, its Pasture bundle ID, and its runtime contract. |
| `pasture-aggregate-manifest.json.sha256` | The manifest's checksum sidecar. |
| `pasture-<version>-<claude\|opencode\|codex>-<skills\|agents\|hooks>.tgz` | The nine component archives, one per harness/extension cell. |

Nothing in Aura derives a component identity. The archives, their digests, and
their bundle IDs all come from `pasture bundle export` at the pinned revision,
which composes each cell from the same target descriptors the installer
activates.

### One release binds one Pasture revision

There is exactly one pin: the `pasture` flake input. The producer compiles
against that input's source, and the workflow reads the same input's locked
revision out of `flake.lock` (through
`scripts/release/pinned-pasture-revision.sh`, which also asserts the locked node
really is `github:dayvidpham/pasture` before returning a revision). The producer
and the exporting binary therefore cannot be different commits, because there is
only one commit to be.

Moving it is one command:

```bash
nix flake update pasture
```

Earlier this was two pins — the input plus a separately hashed `fetchzip` of the
same commit — kept in agreement by an eval-time guard. They drifted three times.
The second pin is gone.

One divergence remains and is deliberate: the `pasture` **git submodule**
gitlink in this repository does not track the flake input. Nothing in the
release pipeline reads the submodule — the producer, the export binary, and the
manifest's `revisions.pasture` all come from the flake input — so the gitlink is
a convenience checkout for local reading, not a release input. Do not treat it
as evidence of what a release was built from; `flake.lock` is that evidence.

### How the published bytes are checked

`scripts/release/verify-aggregate-dir.sh` runs four times over the course of a
release: on the producer's output in the build job, on the artifact after its
round-trip, on a fresh download of the **draft**, and on a fresh download of the
**published** release. Every run is the same script, because a pre-publish check
and a post-publish check that can disagree are worse than either alone.

It re-derives, with independent tools, what only the workflow knows:

- the checksum sidecar is a single line naming the manifest, and the manifest's
  bytes match it (an empty sidecar makes `sha256sum --check` succeed vacuously,
  and a sidecar listing some other file proves nothing);
- the manifest's schema is the one this pipeline knows how to publish;
- its version is the tag without the leading `v`, and its channel matches;
- its revisions are the commits this run actually built from — the Pasture
  revision from `flake.lock`, and the *dereferenced* tagged commit from the
  guard;
- its declared installer compatibility range is the range this run passed to the
  producer;
- its components are exactly the nine canonical basenames for this version,
  derived from the harness × extension matrix rather than counted, each present,
  exclusive, and hashing to its recorded digest.

Its own suite (`verify-aggregate-dir_test.sh`) is hermetic and synthetic, and is
mutation-checked: deleting either the sidecar comparison or the per-asset
presence check makes the suite fail. Real producer output is covered where it
can be — `gates.yml` runs the export → produce → verify chain against the pinned
Pasture on every release PR.

### Installer compatibility

An installer reads the manifest's compatibility range to decide whether it may
activate an aggregate at all. The range is frozen into an immutable manifest: it
can never be corrected in place, only superseded. The policy is therefore
**the producer declares the format and the minimum; the consumer owns the
ceiling.**

**`installer_min` is the pinned Pasture's own released version.** The nine
component archives were composed by that installer, from its target
descriptors, so no lower floor would be honest. It is derived from
`pasture --version` rather than written down anywhere, and it is *asserted*
rather than assumed, in two steps:

1. the reported version must have the released shape `pasture version vX.Y.Z`.
   A development build reports a different, deliberately distinguishable shape
   and is refused: an aggregate cannot be cut against an untagged Pasture,
   because a floor naming no release is a claim no consumer can ever check. A
   release candidate is refused for a different reason — the floor is what every
   installer must *meet*, and a prerelease floor would exclude every stable
   installer.
2. the tag `vX.Y.Z` must exist on `dayvidpham/pasture`, **and the revision
   pinned in this repository's `flake.lock` must be the commit that tag points
   to.** The second half is what makes the first meaningful: without it a binary
   could report `v1.2.3` from a commit that is not `v1.2.3`, and the manifest
   would bind its provenance to a revision no consumer can relate to the version
   it advertises. The check is a single unauthenticated `git ls-remote` against
   the public Pasture repository.

**`installer_max` is an open ceiling, the constant `0.99.99`.** Aura cannot know
what a future installer can do, and the aggregate format itself already answers
the question: an installer that cannot activate a `pasture.aggregate-release/v1`
manifest refuses it **by schema** — a check it can genuinely make about itself,
unlike a version comparison against a number chosen before it existed. A
numeric ceiling pinned to whatever version happened to be current would lock
every later installer out of an aggregate it can activate perfectly well, and
that lock-out would be permanent.

`0.99.99` is a DEFERRED decision, not an absent one: it covers the 0.x Pasture
installer line only, and it expires the day Pasture ships `1.0.0`. Every
aggregate published before that day freezes `0.99.99` into its immutable
manifest, so once `1.0.0` ships those already-published aggregates formally
exclude the 1.x line by the numeric bound alone — the manifest schema remains
the underlying format guard regardless of where the numeric ceiling sits.
`scripts/release/release-grammar.sh installer-compatibility` also refuses to
derive a floor that is not strictly below the ceiling, so a pinned Pasture at
or beyond `0.99.99` fails the release PR rather than publishing an inverted or
collapsed range. Raising or replacing the ceiling policy for `1.0.0` and beyond
is Pasture-side contract work:
<https://github.com/dayvidpham/pasture/issues/39>.

Where each piece lives:

- `scripts/release/release-grammar.sh installer-compatibility` owns the released
  shape and the ceiling constant, and emits both bounds. It is hermetic and its
  suite runs in `nix flake check`, so the two values a release freezes are not
  defined by a regex embedded in a workflow file.
- `scripts/release/assert-pasture-release-tag.sh` owns the tag-existence and
  pinned-revision assertions. It needs the network, so it is invoked by the
  workflows; its own suite proves its logic against local repositories through
  the `PASTURE_TAG_REMOTE` seam and is gated by the `release helper scripts` job
  in `gates.yml` (it needs `git`, which the flake's script sandbox has no
  reason to carry).
- Both assertions run **twice**: in `gates.yml`, on every release PR, before any
  tag exists; and again in `release.yml`, on the values actually stamped into
  the manifest. The pre-tag run is the one that matters operationally — it turns
  "the tag is minted and the release cannot be published" into "re-lock the
  input and push again".
- `verify-aggregate-dir.sh` re-derives both bounds from the published manifest
  and compares them with what the workflow passed to the producer, so the
  published claim is checked against this run's intent rather than taken on the
  producer's word.

## Before the first release

One sequencing dependency remains, and one thing that used to be a manual check
is now enforced.

1. **Pasture must be released first.** The aggregate's `installer_min` is the
   pinned Pasture's own version, and it is only accepted if that version names a
   published Pasture release at exactly the pinned revision. So the order is:
   Pasture cuts its release; this repository re-locks its `pasture` input onto
   that tagged commit (`nix flake update pasture`); the Aura release PR is
   opened. Until then a release PR fails its gates — before any tag is minted —
   with the remedy spelled out. To see where the pin stands right now:

   ```bash
   revision="$(scripts/release/pinned-pasture-revision.sh)"
   pasture="$(nix build "github:dayvidpham/pasture/${revision}#pasture" \
     --no-link --print-out-paths)/bin/pasture"
   compatibility="$(scripts/release/release-grammar.sh installer-compatibility \
     "$("$pasture" --version)")"
   printf '%s\n' "$compatibility"
   scripts/release/assert-pasture-release-tag.sh \
     "$(printf '%s\n' "$compatibility" | sed -n 's/^installer_min=//p')" "$revision"
   ```

2. **The pinned Pasture revision is checked for you, before the tag exists.**
   `gates.yml` builds `github:dayvidpham/pasture/<pinned-revision>#pasture`,
   asserts its `--version` shape, and runs the whole export → produce → verify
   chain, so a Pasture commit whose `go.mod` moved without `vendorHash` in
   Pasture's own `flake.nix` following it fails the release *PR*. That defect is
   invisible in Pasture's source and used to surface only after the tag was
   permanent; it has happened once. To reproduce the check by hand:

   ```bash
   nix build "github:dayvidpham/pasture/$(scripts/release/pinned-pasture-revision.sh)#pasture" --no-link
   ```

## Open items

- No release has been cut, so nothing in this pipeline has runtime evidence yet.
  The first run should be watched stage by stage, and this document's status
  banner updated once it has succeeded.
- The first release cannot be cut until Pasture publishes a release whose tag is
  the revision pinned here; the pipeline refuses an aggregate built against an
  untagged Pasture, on the release PR rather than after the tag. The
  compatibility policy itself is settled — see
  [Installer compatibility](#installer-compatibility).
- The open ceiling (`0.99.99`) is a DEFERRED decision, not an absent one: it
  covers the 0.x Pasture installer line and expires the day Pasture ships
  `1.0.0`, at which point every aggregate published before then formally
  excludes the 1.x line by that frozen numeric bound. Raising or replacing the
  ceiling policy for `1.0.0` and beyond, and adding an explicit escape hatch
  for development-build installers, is tracked in Pasture:
  <https://github.com/dayvidpham/pasture/issues/39>.
- The `pasture` git submodule gitlink and the `pasture` flake input point at
  different commits. Only the flake input is a release input; see
  [One release binds one Pasture revision](#one-release-binds-one-pasture-revision).
