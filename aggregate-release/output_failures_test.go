package main

import (
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/dayvidpham/pasture/artifact"
)

// injectOutputOperations swaps the production seam that run() passes to
// generate(), so the injected-failure cases below exercise the real production
// entry point (run -> generate -> stderr -> exit code) rather than a
// test-only path. Tests in this package are serial, so the swap is safe.
func injectOutputOperations(t *testing.T, operations outputOperations) {
	t.Helper()
	previous := productionOutputOperations
	productionOutputOperations = operations
	t.Cleanup(func() { productionOutputOperations = previous })
}

func isStagedComponent(path string) bool {
	return strings.HasPrefix(filepath.Base(path), ".component-")
}

// TestInjectedOutputFailuresAreActionableAndCleaned covers every output
// filesystem failure branch reachable through the outputOperations seam:
// staged component write, asset rename, per-file mode freeze, and directory
// mode freeze. Each must surface its exact stage text and injected cause,
// promise removal of the claimed output, exit 2, and leave no output directory.
func TestInjectedOutputFailuresAreActionableAndCleaned(t *testing.T) {
	tests := []struct {
		name       string
		operations func(output string) outputOperations
		wantStage  string
		wantCause  string
		wantPath   func(output string) string
	}{
		{
			name: "staged component write",
			operations: func(string) outputOperations {
				operations := productionOutputOperations
				operations.writeFile = func(path string, content []byte, mode fs.FileMode) error {
					if isStagedComponent(path) {
						return errors.New("injected staged write failure")
					}
					return os.WriteFile(path, content, mode)
				}
				return operations
			},
			wantStage: "writing staged component bytes",
			wantCause: "injected staged write failure",
			wantPath:  func(output string) string { return filepath.Join(output, ".component-00") },
		},
		{
			name: "asset rename",
			operations: func(string) outputOperations {
				operations := productionOutputOperations
				operations.rename = func(string, string) error {
					return errors.New("injected rename failure")
				}
				return operations
			},
			wantStage: "committing a validated component asset",
			wantCause: "injected rename failure",
			wantPath: func(output string) string {
				return filepath.Join(output, canonicalFixtureAsset("1.2.0", artifact.ComponentIDs()[0]))
			},
		},
		{
			name: "output file mode freeze",
			operations: func(output string) outputOperations {
				operations := productionOutputOperations
				operations.chmod = func(path string, mode fs.FileMode) error {
					if path != output {
						return errors.New("injected file chmod failure")
					}
					return os.Chmod(path, mode)
				}
				return operations
			},
			wantStage: "freezing an output file mode",
			wantCause: "injected file chmod failure",
			wantPath:  nil,
		},
		{
			name: "output directory mode freeze",
			operations: func(output string) outputOperations {
				operations := productionOutputOperations
				operations.chmod = func(path string, mode fs.FileMode) error {
					if path == output {
						return errors.New("injected directory chmod failure")
					}
					return os.Chmod(path, mode)
				}
				return operations
			},
			wantStage: "freezing the output directory mode",
			wantCause: "injected directory chmod failure",
			wantPath:  func(output string) string { return output },
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t, "1.2.0")
			output := filepath.Join(fixture.root, "release")
			injectOutputOperations(t, test.operations(output))
			code, stderr := runFixture(t, fixture, "1.2.0", "release")
			if code != 2 {
				t.Fatalf("code=%d want 2 stderr=%s", code, stderr)
			}
			for _, want := range []string{
				"error: aggregate generation failed while " + test.wantStage,
				test.wantCause,
				"the claimed output is incomplete and will be removed",
			} {
				if !strings.Contains(stderr, want) {
					t.Fatalf("stderr=%q missing %q", stderr, want)
				}
			}
			if test.wantPath != nil && !strings.Contains(stderr, " at "+test.wantPath(output)+" ") {
				t.Fatalf("stderr=%q missing location %q", stderr, test.wantPath(output))
			}
			if pathExists(output) {
				t.Fatalf("output directory survived a failed generation: %s", output)
			}
		})
	}
}

// TestCleanupFailureReportsBothTheOriginalAndTheCleanupFailure pins the
// RemoveAll branch of the cleanup defer: when the producer cannot remove its
// own incomplete output, the reported error is the cleanup failure carrying
// the original failure, and the partial directory is documented as surviving.
func TestCleanupFailureReportsBothTheOriginalAndTheCleanupFailure(t *testing.T) {
	if os.Geteuid() == 0 {
		t.Skip("running as root bypasses the directory permission that makes RemoveAll fail")
	}
	fixture := newFixture(t, "1.2.0")
	output := filepath.Join(fixture.root, "release")
	// Restore write permission before t.TempDir's own cleanup runs (cleanups
	// are LIFO, and this one is registered last).
	t.Cleanup(func() { _ = os.Chmod(fixture.root, 0o755) })
	operations := productionOutputOperations
	operations.chmod = func(path string, mode fs.FileMode) error {
		if path == output {
			// Make the parent unwritable so the producer's own RemoveAll of
			// the claimed output directory fails.
			if err := os.Chmod(fixture.root, 0o555); err != nil {
				t.Fatalf("could not make the fixture root unwritable: %v", err)
			}
			return errors.New("injected directory chmod failure")
		}
		return os.Chmod(path, mode)
	}
	injectOutputOperations(t, operations)

	code, stderr := runFixture(t, fixture, "1.2.0", "release")
	if code != 2 {
		t.Fatalf("code=%d want 2 stderr=%s", code, stderr)
	}
	for _, want := range []string{
		"error: aggregate generation failed while removing the incomplete output directory at " + output,
		"partial release bytes may remain and must not be published",
		"remove the incomplete directory manually after repairing permissions",
		"original failure: aggregate generation failed while freezing the output directory mode",
		"injected directory chmod failure",
	} {
		if !strings.Contains(stderr, want) {
			t.Fatalf("stderr=%q missing %q", stderr, want)
		}
	}
	if err := os.Chmod(fixture.root, 0o755); err != nil {
		t.Fatal(err)
	}
	// The cleanup is best effort: children are removed, but the claimed
	// directory itself survives, which is exactly what the error warns about.
	if !pathExists(output) {
		t.Fatalf("expected the unremovable output directory to survive: %s", output)
	}
	entries, err := os.ReadDir(output)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 0 {
		names := make([]string, 0, len(entries))
		for _, entry := range entries {
			names = append(names, entry.Name())
		}
		t.Fatalf("surviving output directory is not empty: %v", names)
	}
}
