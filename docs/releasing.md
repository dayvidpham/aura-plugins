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
> One prerequisite is outside this repository — see
> [Before the first release](#before-the-first-release).

## The pipeline at a glance

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/gates.yml` | `workflow_call` only | The full quality gate: `nix flake check -L` (which runs `hm-module-test` and `aggregate-release-test`), `nix build .#aggregate-release`, an assertion that the producer still exposes its seven-option contract, `nix build .#aura-swarm`, `nix run .#aura-swarm -- --help`, `shellcheck` + the release-script test suites, and `actionlint`. |
| `.github/workflows/release-pr.yml` | `pull_request` (opened/edited/synchronize/reopened) into `main` | On a `release(...)`-titled PR: validates the title grammar, asserts the author is a maintainer, refuses a version that is already released, then calls `gates.yml` in full. |
| `.github/workflows/release-tag.yml` | `pull_request` `closed` into `main` | When a `release(...)` PR **merges**: mints the immutable annotated tag with the release App token, refusing duplicate tags and unreachable commits. |
| `.github/workflows/release.yml` | `push` of a `v*` tag | Guards the tag (App actor, annotated, reachable from `main`), re-runs `gates.yml` against the tagged commit, builds the nine component assets from the pinned Pasture and packages them with the aggregate producer, publishes the GitHub Release with the App identity, then re-downloads the published assets and verifies them. |

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
```

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

`main` should require the `validate release PR` and `gates (release PR)` checks,
so a release PR cannot be merged before the full gate set is green.

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
   runs the full quality gate. Both must be green.

3. **Merge.** `release-tag.yml` then mints the annotated tag `v0.1.0` on the
   merge commit, after re-confirming the tag does not already exist locally or
   on the remote and that the merge commit is reachable from `main`.

4. **`release.yml` runs from the tag** and publishes. In order:

   - the **guard** verifies the actor, the annotation, and reachability from
     `main`;
   - the **gates** re-run against the tagged commit;
   - **build-components** reads the pinned Pasture revision out of `flake.lock`,
     builds that exact Pasture, runs `pasture bundle export` for the release
     version, and packages the result with `aura-aggregate-release`;
   - **publish** re-verifies the aggregate after the artifact round-trip,
     refuses to touch an existing release, and creates the GitHub Release with
     the App identity, marking a `-rcN` version as a prerelease;
   - **smoke** downloads the published assets fresh and verifies them again.

   If any stage fails, nothing partial is published. The tag remains valid,
   annotated, and permanent, and it stays publishable: fix the cause and re-run
   the workflow from the Actions tab. The tag is never recreated.

5. **Afterwards**, bump the aura-plugins entry in
   `.claude-plugin/marketplace.json` if the release should be offered through
   the marketplace.

Nothing in this flow requires a local tag, and no step should ever be performed
by hand. If a release must be re-attempted after a fixed infrastructure problem,
re-run the failed workflow from the Actions tab — the tag already exists and is
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

The revision is read from `flake.lock`, never written into the workflow, and
`flake.nix` refuses to evaluate when its `pastureAggregateContract` pin and that
locked input disagree. Since publication needs `nix build .#aggregate-release`
to succeed, the producer cannot be built against a different Pasture than the
one that exported the assets. Moving the pin means moving both together:

```bash
nix flake update pasture
# then set pastureAggregateContractRev + its fetchzip hash in flake.nix to match
```

### How the published bytes are checked

`scripts/release/verify-aggregate-dir.sh` runs twice: over the produced
directory before anything is uploaded, and over a fresh download of the
published assets afterwards. Both runs use the same script, because a
pre-publish check and a post-publish check that can disagree are worse than
either alone. It re-derives, with independent tools, what the producer cannot
know — that the manifest matches its sidecar, that its version is the tag
without the leading `v`, that its revisions are the commits this run actually
built from, and that every named component is present, exclusive, and hashes to
its recorded digest.

### Installer compatibility

The manifest's compatibility range is **derived, not chosen**: both bounds are
the version reported by the pinned Pasture binary itself. That is the narrowest
claim that is provably true, and narrow is the safe direction — a too-wide range
would let a future, incompatible installer accept an aggregate it cannot
correctly activate, whereas a too-narrow one only makes that installer decline
to offer this version.

Widening the range is a deliberate decision for a *later* release. A published
range can never be corrected in place, only superseded.

## Before the first release

Two things must be settled before a release PR is merged. Both are decisions,
not code.

1. **The pinned Pasture revision must build under Nix.** The build job runs
   `nix build github:dayvidpham/pasture/<pinned-revision>#pasture`. Confirm that
   command succeeds for the currently pinned revision before cutting a release:
   a Pasture commit whose `go.mod` moved without its `vendorHash` being updated
   fails there, and the release stops with the tag already permanent.

   ```bash
   nix build "github:dayvidpham/pasture/$(jq -r '.nodes.pasture.locked.rev' flake.lock)#pasture" --no-link
   ```

   As of the revision currently pinned here, that command **fails**: Pasture's
   `go.mod` moved to a newer `provenance` without `vendorHash` in Pasture's own
   `flake.nix` being updated to match. It must be fixed in Pasture, and the pin
   here moved to the fixed commit, before a release can complete.

2. **Confirm the installer compatibility range is what you want published.** By
   default it is exactly the pinned Pasture's own version, on both bounds — see
   [Installer compatibility](#installer-compatibility). If this release should
   be usable by a wider band of installers, that has to be decided and
   implemented before publication, not after.

## Open items

- No release has been cut, so nothing in this pipeline has runtime evidence yet.
  The first run should be watched stage by stage, and this document's status
  banner updated once it has succeeded.
