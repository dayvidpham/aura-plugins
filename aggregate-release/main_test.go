package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
	"testing"

	"github.com/dayvidpham/pasture/artifact"
)

const (
	pastureRevision = "f5cbf4f92bb458eb0baff64f6adec603bcf0d74f"
	auraRevision    = "b8e467d5d31f98f503f05f703890f9a2dcfb704c"
)

type fixture struct {
	root, componentSet string
	records            []map[string]any
	payloads           map[string][]byte
}

func newFixture(t *testing.T, version string) fixture {
	t.Helper()
	root := t.TempDir()
	payloads := map[string][]byte{}
	records := make([]map[string]any, 0, 9)
	for index, id := range artifact.ComponentIDs() {
		content := []byte("exact bytes for " + id.String() + "\n")
		input := fmt.Sprintf("input-%d.tgz", index+1)
		if err := os.WriteFile(filepath.Join(root, input), content, 0o600); err != nil {
			t.Fatal(err)
		}
		asset := canonicalFixtureAsset(version, id)
		payloads[id.String()] = content
		records = append(records, map[string]any{
			"id": id.String(), "artifact": input, "asset": asset,
			"bundle_id": fmt.Sprintf("artifact.bundle.v1:sha256:%064x", index+1),
		})
	}
	path := filepath.Join(root, "components.json")
	result := fixture{root: root, componentSet: path, records: records, payloads: payloads}
	result.write(t, map[string]any{"schema": componentSetSchema, "components": records})
	return result
}

func canonicalFixtureAsset(version string, id artifact.ComponentID) string {
	stem := string(id.Harness())
	if id.Harness() == artifact.HarnessClaudeCode {
		stem = "claude"
	}
	return fmt.Sprintf("pasture-%s-%s-%s.tgz", version, stem, id.Extension())
}

func (fixture fixture) write(t *testing.T, document any) {
	t.Helper()
	encoded, err := json.Marshal(document)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(fixture.componentSet, encoded, 0o600); err != nil {
		t.Fatal(err)
	}
}

func (fixture fixture) arguments(version, output string) []string {
	return []string{
		"--version", version, "--installer-min", "1.0.0", "--installer-max", "1.9.9",
		"--pasture-revision", pastureRevision, "--aura-revision", auraRevision,
		"--components", fixture.componentSet, "--output-dir", filepath.Join(fixture.root, output),
	}
}

func runFixture(t *testing.T, fixture fixture, version, output string) (int, string) {
	t.Helper()
	outputPath := filepath.Join(fixture.root, output)
	t.Cleanup(func() {
		_ = filepath.WalkDir(outputPath, func(path string, entry fs.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			if entry.IsDir() {
				_ = os.Chmod(path, 0o755)
			} else {
				_ = os.Chmod(path, 0o644)
			}
			return nil
		})
	})
	var stderr bytes.Buffer
	code := run(fixture.arguments(version, output), &stderr)
	return code, stderr.String()
}

func TestProductionCLIEmitsExactTypedNineCellContract(t *testing.T) {
	fixture := newFixture(t, "1.2.0")
	code, stderr := runFixture(t, fixture, "1.2.0", "release")
	if code != 0 {
		t.Fatalf("code=%d stderr=%s", code, stderr)
	}
	output := filepath.Join(fixture.root, "release")
	manifestBytes, err := os.ReadFile(filepath.Join(output, artifact.AggregateManifestAsset))
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := artifact.ParseAggregateManifest(manifestBytes)
	if err != nil {
		t.Fatal(err)
	}
	version, _ := artifact.ParseVersion("1.2.0")
	minimum, _ := artifact.ParseVersion("1.0.0")
	maximum, _ := artifact.ParseVersion("1.9.9")
	pasture, _ := artifact.ParseRevision(pastureRevision)
	aura, _ := artifact.ParseRevision(auraRevision)
	if manifest.Version() != version || manifest.Channel() != artifact.ReleaseFinal || manifest.InstallerMin() != minimum || manifest.InstallerMax() != maximum || manifest.PastureRevision() != pasture || manifest.AuraRevision() != aura {
		t.Fatalf("aggregate fields differ: version=%s channel=%s compatibility=%s..%s revisions=%s/%s", manifest.Version(), manifest.Channel(), manifest.InstallerMin(), manifest.InstallerMax(), manifest.PastureRevision(), manifest.AuraRevision())
	}
	wantOrder := []string{"claude-code/agents", "claude-code/hooks", "claude-code/skills", "codex/agents", "codex/hooks", "codex/skills", "opencode/agents", "opencode/hooks", "opencode/skills"}
	components := manifest.Components()
	if len(components) != len(wantOrder) {
		t.Fatalf("components=%d", len(components))
	}
	for index, component := range components {
		id := component.ID()
		if id.String() != wantOrder[index] || component.Harness() != id.Harness() || component.Extension() != id.Extension() {
			t.Fatalf("component[%d]=%s/%s/%s", index, id, component.Harness(), component.Extension())
		}
		wantAsset := canonicalFixtureAsset("1.2.0", id)
		wantBundle, _ := artifact.ParseBundleID(fixture.records[indexForID(fixture.records, id.String())]["bundle_id"].(string))
		wantRuntime, _ := artifact.ProductionRuntimeContract(id.Harness())
		payload := fixture.payloads[id.String()]
		actualPayload, err := os.ReadFile(filepath.Join(output, component.Asset()))
		if err != nil {
			t.Fatal(err)
		}
		if component.Asset() != wantAsset || component.Digest() != artifact.DigestBytes(payload) || component.BundleID() != wantBundle || component.RuntimeContractID() != wantRuntime || component.PastureRevision() != pasture || component.AuraRevision() != aura || !bytes.Equal(actualPayload, payload) {
			t.Fatalf("component %s mapping differs: asset=%s digest=%s bundle=%s runtime=%s revisions=%s/%s bytes=%q", id, component.Asset(), component.Digest(), component.BundleID(), component.RuntimeContractID(), component.PastureRevision(), component.AuraRevision(), actualPayload)
		}
	}
	wantInventory := []string{artifact.AggregateChecksumAsset, artifact.AggregateManifestAsset}
	for _, id := range artifact.ComponentIDs() {
		wantInventory = append(wantInventory, canonicalFixtureAsset("1.2.0", id))
	}
	sort.Strings(wantInventory)
	entries, err := os.ReadDir(output)
	if err != nil {
		t.Fatal(err)
	}
	gotInventory := make([]string, 0, len(entries))
	for _, entry := range entries {
		gotInventory = append(gotInventory, entry.Name())
		info, err := entry.Info()
		if err != nil || info.Mode().Perm() != 0o444 {
			t.Fatalf("entry %s mode=%v err=%v", entry.Name(), info.Mode(), err)
		}
	}
	if !reflect.DeepEqual(gotInventory, wantInventory) {
		t.Fatalf("inventory=%v want=%v", gotInventory, wantInventory)
	}
	outputInfo, _ := os.Stat(output)
	if outputInfo.Mode().Perm() != 0o555 {
		t.Fatalf("output mode=%o", outputInfo.Mode().Perm())
	}
	wantChecksum := artifact.AggregateManifestChecksum(manifestBytes)
	gotChecksum, _ := os.ReadFile(filepath.Join(output, artifact.AggregateChecksumAsset))
	if !bytes.Equal(gotChecksum, wantChecksum) {
		t.Fatalf("checksum=%q want=%q", gotChecksum, wantChecksum)
	}
	verified, err := artifact.VerifyAggregate(context.Background(), directorySource(output), artifact.AggregateRequirements{Version: version, Installer: minimum, PastureRevision: pasture, AuraRevision: aura})
	if err != nil || len(verified.Manifest().Components()) != 9 {
		t.Fatalf("direct typed verification failed: verified=%v err=%v", verified.Manifest().Version(), err)
	}
}

func indexForID(records []map[string]any, id string) int {
	for index, record := range records {
		if record["id"] == id {
			return index
		}
	}
	return -1
}

func TestPrereleaseChannelComesFromPastureVersion(t *testing.T) {
	fixture := newFixture(t, "1.2.0-rc.1")
	code, stderr := runFixture(t, fixture, "1.2.0-rc.1", "candidate")
	if code != 0 {
		t.Fatalf("code=%d stderr=%s", code, stderr)
	}
	data, _ := os.ReadFile(filepath.Join(fixture.root, "candidate", artifact.AggregateManifestAsset))
	manifest, err := artifact.ParseAggregateManifest(data)
	if err != nil || manifest.Channel() != artifact.ReleasePrerelease {
		t.Fatalf("channel=%s err=%v", manifest.Channel(), err)
	}
}

func TestStrictInputFailuresAreIndependentAndLeaveNoOutput(t *testing.T) {
	tests := []struct {
		name, want string
		mutate     func(*fixture)
	}{
		{"eight cells", "found 8 records instead of exactly 9", func(f *fixture) { f.records = f.records[:8] }},
		{"ten cells", "found 10 records instead of exactly 9", func(f *fixture) { f.records = append(f.records, cloneRecord(f.records[0])) }},
		{"duplicate canonical cell", "is duplicated", func(f *fixture) { f.records[8] = cloneRecord(f.records[0]) }},
		{"unknown cell", "parsing component identity", func(f *fixture) { f.records[0]["id"] = "unknown/skills" }},
		{"malformed bundle", "parsing target-owned bundle identity", func(f *fixture) { f.records[0]["bundle_id"] = "not-a-bundle" }},
		{"missing record field", "validating component paths", func(f *fixture) { delete(f.records[0], "asset") }},
		{"unknown record field", "validating component-set JSON", func(f *fixture) { f.records[0]["moving_alias"] = "pasture-stable" }},
		{"wrong schema", "validating component-set schema", func(f *fixture) {}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t, "1.2.0")
			test.mutate(&fixture)
			schema := componentSetSchema
			if test.name == "wrong schema" {
				schema = "wrong"
			}
			fixture.write(t, map[string]any{"schema": schema, "components": fixture.records})
			code, stderr := runFixture(t, fixture, "1.2.0", "release")
			if code != 2 || !strings.Contains(stderr, test.want) || pathExists(filepath.Join(fixture.root, "release")) {
				t.Fatalf("code=%d stderr=%s output=%t", code, stderr, pathExists(filepath.Join(fixture.root, "release")))
			}
		})
	}

	for _, test := range []struct{ name, data, want string }{
		{"duplicate JSON key", `{"schema":"aura.aggregate-components/v1","schema":"aura.aggregate-components/v1","components":[]}`, "appears more than once"},
		{"malformed JSON", `{"schema":`, "validating component-set JSON"},
		{"unknown top-level field", `{"schema":"aura.aggregate-components/v1","components":[],"moving_alias":"pasture-stable"}`, "validating component-set JSON"},
	} {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t, "1.2.0")
			if err := os.WriteFile(fixture.componentSet, []byte(test.data), 0o600); err != nil {
				t.Fatal(err)
			}
			code, stderr := runFixture(t, fixture, "1.2.0", "release")
			if code != 2 || !strings.Contains(stderr, test.want) || pathExists(filepath.Join(fixture.root, "release")) {
				t.Fatalf("code=%d stderr=%s", code, stderr)
			}
		})
	}
}

func TestComponentSetRootRejectsCaseVariantFields(t *testing.T) {
	for _, data := range []string{
		`{"Schema":"aura.aggregate-components/v1","components":[]}`,
		`{"schema":"aura.aggregate-components/v1","Schema":"aura.aggregate-components/v1","components":[]}`,
	} {
		fixture := newFixture(t, "1.2.0")
		if err := os.WriteFile(fixture.componentSet, []byte(data), 0o600); err != nil {
			t.Fatal(err)
		}
		code, stderr := runFixture(t, fixture, "1.2.0", "release")
		if code != 2 || !strings.Contains(stderr, `field "Schema" is not an exact allowed field at component set`) || pathExists(filepath.Join(fixture.root, "release")) {
			t.Fatalf("code=%d stderr=%s", code, stderr)
		}
	}
}

func TestComponentSetRecordRejectsCaseVariantFields(t *testing.T) {
	for _, semanticDuplicate := range []bool{false, true} {
		fixture := newFixture(t, "1.2.0")
		record := cloneRecord(fixture.records[0])
		if !semanticDuplicate {
			delete(record, "id")
		}
		record["ID"] = fixture.records[0]["id"]
		fixture.records[0] = record
		fixture.write(t, map[string]any{"schema": componentSetSchema, "components": fixture.records})
		code, stderr := runFixture(t, fixture, "1.2.0", "release")
		if code != 2 || !strings.Contains(stderr, `field "ID" is not an exact allowed field at component set.components[0]`) || pathExists(filepath.Join(fixture.root, "release")) {
			t.Fatalf("semanticDuplicate=%t code=%d stderr=%s", semanticDuplicate, code, stderr)
		}
	}
}

func TestCLIArgumentFailuresAreSingleActionableDiagnostic(t *testing.T) {
	fixture := newFixture(t, "1.2.0")
	valid := fixture.arguments("1.2.0", "release")
	tests := []struct {
		name      string
		arguments []string
		stage     string
		location  string
		cause     string
	}{
		{"unknown option", []string{"--unknown", "value"}, "parsing CLI options", "command-line arguments", "flag provided but not defined"},
		{"malformed option", []string{"--version"}, "parsing CLI options", "command-line arguments", "flag needs an argument"},
		{"positional argument", append(append([]string{}, valid...), "unexpected"), "validating CLI argument shape", "command-line arguments", "unexpected positional arguments"},
		{"duplicate option", append(append([]string{}, valid...), "--version", "1.2.0"), "parsing CLI options", "command-line arguments", "specified more than once"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			var stderr bytes.Buffer
			code := run(test.arguments, &stderr)
			diagnostic := stderr.String()
			for _, want := range []string{test.stage, test.location, test.cause, "impact:", "fix:"} {
				if !strings.Contains(diagnostic, want) {
					t.Fatalf("code=%d diagnostic=%q missing=%q", code, diagnostic, want)
				}
			}
			if code != 2 || strings.Count(diagnostic, "error:") != 1 || strings.Contains(diagnostic, "Usage:") || pathExists(filepath.Join(fixture.root, "release")) {
				t.Fatalf("code=%d diagnostic=%q", code, diagnostic)
			}
		})
	}

	for index := 0; index < len(valid); index += 2 {
		name := strings.TrimPrefix(valid[index], "--")
		t.Run("missing "+name, func(t *testing.T) {
			arguments := append([]string{}, valid[:index]...)
			arguments = append(arguments, valid[index+2:]...)
			var stderr bytes.Buffer
			code := run(arguments, &stderr)
			diagnostic := stderr.String()
			if code != 2 || strings.Count(diagnostic, "error:") != 1 || !strings.Contains(diagnostic, "validating required CLI option") || !strings.Contains(diagnostic, "at --"+name) || !strings.Contains(diagnostic, "required option is missing or empty") || !strings.Contains(diagnostic, "impact:") || !strings.Contains(diagnostic, "fix:") {
				t.Fatalf("code=%d diagnostic=%q", code, diagnostic)
			}
		})
	}
}

func TestCLIHelpRemainsSuccessful(t *testing.T) {
	var stderr bytes.Buffer
	if code := run([]string{"--help"}, &stderr); code != 0 || !strings.Contains(stderr.String(), "Usage: aura-aggregate-release [options]") || strings.Contains(stderr.String(), "error:") {
		t.Fatalf("code=%d help=%q", code, stderr.String())
	}
}

func cloneRecord(record map[string]any) map[string]any {
	result := map[string]any{}
	for key, value := range record {
		result[key] = value
	}
	return result
}

func TestPastureVersionAndAssetDomainsRejectOverflowAndReservedNames(t *testing.T) {
	tests := []struct {
		name, version, want string
		mutate              func(*fixture)
	}{
		{"uint64 overflow", "18446744073709551616.0.0", "numeric component", func(*fixture) {}},
		{"reserved version token", "1.2.0-pasture-stable", "duplicated, moving, or differs from canonical", func(*fixture) {}},
		{"reserved asset alias", "1.2.0", "duplicated, moving, or differs from canonical", func(f *fixture) { f.records[0]["asset"] = "pasture-stable.tgz" }},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t, test.version)
			test.mutate(&fixture)
			fixture.write(t, map[string]any{"schema": componentSetSchema, "components": fixture.records})
			code, stderr := runFixture(t, fixture, test.version, "release")
			if code != 2 || !strings.Contains(stderr, test.want) || pathExists(filepath.Join(fixture.root, "release")) {
				t.Fatalf("code=%d stderr=%s", code, stderr)
			}
		})
	}
}

func TestLateArtifactAndOutputFailuresAreActionableAndCleaned(t *testing.T) {
	t.Run("late artifact", func(t *testing.T) {
		fixture := newFixture(t, "1.2.0")
		last := fixture.records[len(fixture.records)-1]
		if err := os.Remove(filepath.Join(fixture.root, last["artifact"].(string))); err != nil {
			t.Fatal(err)
		}
		code, stderr := runFixture(t, fixture, "1.2.0", "release")
		if code != 2 || !strings.Contains(stderr, last["id"].(string)) || !strings.Contains(stderr, "exact component bytes cannot be frozen") || pathExists(filepath.Join(fixture.root, "release")) {
			t.Fatalf("code=%d stderr=%s", code, stderr)
		}
	})

	t.Run("late output write", func(t *testing.T) {
		fixture := newFixture(t, "1.2.0")
		configuration, err := parseOptions(fixture.arguments("1.2.0", "release"), os.Stderr)
		if err != nil {
			t.Fatal(err)
		}
		operations := productionOutputOperations
		operations.writeFile = func(path string, content []byte, mode fs.FileMode) error {
			if filepath.Base(path) == artifact.AggregateManifestAsset {
				return errors.New("injected disk full")
			}
			return os.WriteFile(path, content, mode)
		}
		err = generate(configuration, operations)
		if err == nil || !strings.Contains(err.Error(), "writing the canonical aggregate manifest") || !strings.Contains(err.Error(), "injected disk full") || !strings.Contains(err.Error(), "will be removed") || pathExists(filepath.Join(fixture.root, "release")) {
			t.Fatalf("err=%v output=%t", err, pathExists(filepath.Join(fixture.root, "release")))
		}
	})
}

type treeEntry struct {
	mode fs.FileMode
	data []byte
}

func snapshotTree(t *testing.T, root string) map[string]treeEntry {
	t.Helper()
	result := map[string]treeEntry{}
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		relative, _ := filepath.Rel(root, path)
		info, err := entry.Info()
		if err != nil {
			return err
		}
		var data []byte
		if !entry.IsDir() {
			data, err = os.ReadFile(path)
		}
		result[relative] = treeEntry{mode: info.Mode(), data: data}
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	return result
}

func TestExistingOutputTreeIsPreservedCompletely(t *testing.T) {
	fixture := newFixture(t, "1.2.0")
	code, stderr := runFixture(t, fixture, "1.2.0", "release")
	if code != 0 {
		t.Fatalf("code=%d stderr=%s", code, stderr)
	}
	output := filepath.Join(fixture.root, "release")
	if err := os.Chmod(output, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(output, "publisher-sentinel"), []byte("preserve me"), 0o640); err != nil {
		t.Fatal(err)
	}
	if err := os.Chmod(output, 0o555); err != nil {
		t.Fatal(err)
	}
	before := snapshotTree(t, output)
	code, stderr = runFixture(t, fixture, "1.2.0", "release")
	after := snapshotTree(t, output)
	if code != 2 || !strings.Contains(stderr, "will not be mutated") || !reflect.DeepEqual(after, before) {
		t.Fatalf("code=%d stderr=%s\nbefore=%v\nafter=%v", code, stderr, before, after)
	}
}

func TestChecksumUsesPastureCanonicalBytes(t *testing.T) {
	fixture := newFixture(t, "1.2.0")
	code, stderr := runFixture(t, fixture, "1.2.0", "release")
	if code != 0 {
		t.Fatalf("code=%d stderr=%s", code, stderr)
	}
	manifest, _ := os.ReadFile(filepath.Join(fixture.root, "release", artifact.AggregateManifestAsset))
	sum := sha256.Sum256(manifest)
	want := hex.EncodeToString(sum[:]) + "  " + artifact.AggregateManifestAsset + "\n"
	checksum, _ := os.ReadFile(filepath.Join(fixture.root, "release", artifact.AggregateChecksumAsset))
	if string(checksum) != want || !bytes.Equal(checksum, artifact.AggregateManifestChecksum(manifest)) {
		t.Fatalf("checksum=%q want=%q", checksum, want)
	}
}

func pathExists(path string) bool {
	_, err := os.Lstat(path)
	return err == nil
}
