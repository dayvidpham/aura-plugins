# Immutable aggregate release producer contract

`aura-aggregate-release` builds, but does not publish, one immutable aggregate
release directory for Pasture's closed three-harness by three-extension matrix.
The later publication workflow can upload the directory's eleven files without
rewriting them.

## Production API

```console
nix run .#aggregate-release -- \
  --version 1.2.0 \
  --installer-min 1.0.0 \
  --installer-max 1.9.9 \
  --pasture-revision <exact-40-character-commit> \
  --aura-revision <exact-40-character-commit> \
  --components ./components.json \
  --output-dir ./dist/1.2.0
```

The component-set document is strict JSON. Unknown or duplicate fields are
rejected. Artifact paths are relative to the document unless absolute.

```json
{
  "schema": "aura.aggregate-components/v1",
  "components": [
    {
      "id": "claude-code/skills",
      "artifact": "build/claude-skills.tgz",
      "bundle_id": "artifact.bundle.v1:sha256:<64 lowercase hex>"
    }
  ]
}
```

The array must contain exactly one record for every combination of
`claude-code`, `opencode`, and `codex` with `skills`, `agents`, and `hooks`.
The `bundle_id` comes from the corresponding Pasture target bundle; Aura does
not recreate that target-owned identity.

## Frozen output

The producer:

- derives `final` versus `prerelease` from canonical SemVer rather than taking
  a second mutable classification input;
- derives each canonical versioned asset name and the harness's registered
  runtime contract;
- computes each archive's exact SHA-256 digest;
- binds every component and the aggregate to the same exact Aura and Pasture
  revisions and one inclusive installer compatibility range;
- emits `pasture-aggregate-manifest.json` and its canonical two-space checksum
  sidecar; and
- atomically claims a new output directory and refuses to overwrite it.

There is no channel alias, latest-version lookup, fallback selection, per-cell
version input, catalog mutation, or publication operation in this producer.
Pasture's public typed `artifact.VerifyAggregate` path is the acceptance
boundary for the emitted directory.
