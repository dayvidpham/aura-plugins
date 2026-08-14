package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"

	"github.com/dayvidpham/pasture/artifact"
)

const (
	componentSetSchema = "aura.aggregate-components/v1"
	maxAssetBytes      = 64 << 20
	maxTotalBytes      = 256 << 20
)

type componentDocument struct {
	Schema     string            `json:"schema"`
	Components []componentRecord `json:"components"`
}

type componentRecord struct {
	ID       string `json:"id"`
	Artifact string `json:"artifact"`
	Asset    string `json:"asset"`
	BundleID string `json:"bundle_id"`
}

type componentInput struct {
	id       artifact.ComponentID
	source   string
	asset    string
	bundleID artifact.BundleID
}

type options struct {
	version, installerMin, installerMax string
	pastureRevision, auraRevision       string
	components, outputDir               string
}

type singleOption struct {
	name  string
	value *string
	isSet bool
}

func (option *singleOption) String() string {
	if option.value == nil {
		return ""
	}
	return *option.value
}

func (option *singleOption) Set(value string) error {
	if option.isSet {
		return fmt.Errorf("option --%s was specified more than once", option.name)
	}
	option.isSet = true
	*option.value = value
	return nil
}

type outputOperations struct {
	writeFile func(string, []byte, fs.FileMode) error
	rename    func(string, string) error
	chmod     func(string, fs.FileMode) error
}

var productionOutputOperations = outputOperations{
	writeFile: os.WriteFile,
	rename:    os.Rename,
	chmod:     os.Chmod,
}

type directorySource string

func (source directorySource) OpenAsset(_ context.Context, name string) (io.ReadCloser, error) {
	return os.Open(filepath.Join(string(source), name))
}

func actionable(stage, location string, cause error, impact, fix string) error {
	return fmt.Errorf("aggregate generation failed while %s at %s because %v; impact: %s; fix: %s", stage, location, cause, impact, fix)
}

func parseOptions(arguments []string, stderr io.Writer) (options, error) {
	var result options
	flags := flag.NewFlagSet("aura-aggregate-release", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	register := func(name, usage string, value *string) {
		flags.Var(&singleOption{name: name, value: value}, name, usage)
	}
	register("version", "canonical aggregate SemVer without a leading v", &result.version)
	register("installer-min", "inclusive minimum compatible Pasture installer SemVer", &result.installerMin)
	register("installer-max", "inclusive maximum compatible Pasture installer SemVer", &result.installerMax)
	register("pasture-revision", "exact 40-character lowercase Pasture commit", &result.pastureRevision)
	register("aura-revision", "exact 40-character lowercase Aura commit", &result.auraRevision)
	register("components", "strict nine-cell component-set JSON path", &result.components)
	register("output-dir", "new version-specific output directory; never overwritten", &result.outputDir)
	printUsage := func() {
		fmt.Fprintln(stderr, "Build one immutable nine-cell aggregate release without publishing it.")
		fmt.Fprintf(stderr, "Usage: %s [options]\n", flags.Name())
		flags.SetOutput(stderr)
		flags.PrintDefaults()
		flags.SetOutput(io.Discard)
	}
	flags.Usage = func() {}
	for _, argument := range arguments {
		if argument != "--help" && argument != "-h" {
			continue
		}
		if len(arguments) == 1 {
			printUsage()
			return options{}, flag.ErrHelp
		}
		return options{}, actionable("validating CLI argument shape", argument, errors.New("help cannot be combined with generation options or positional arguments"), "no aggregate was generated", "run --help by itself, or remove it and provide every required generation option")
	}
	if err := flags.Parse(arguments); err != nil {
		return options{}, actionable("parsing CLI options", "command-line arguments", err, "no aggregate was generated", "run --help and provide every option exactly once using the documented value syntax")
	}
	if flags.NArg() != 0 {
		return options{}, actionable("validating CLI argument shape", "command-line arguments", fmt.Errorf("unexpected positional arguments %q", flags.Args()), "no aggregate was generated", "remove positional arguments and use only the named options shown by --help")
	}
	for _, required := range []struct{ name, value string }{
		{"version", result.version},
		{"installer-min", result.installerMin},
		{"installer-max", result.installerMax},
		{"pasture-revision", result.pastureRevision},
		{"aura-revision", result.auraRevision},
		{"components", result.components},
		{"output-dir", result.outputDir},
	} {
		if required.value == "" {
			return options{}, actionable("validating required CLI option", "--"+required.name, errors.New("required option is missing or empty"), "no aggregate was generated", "provide this option exactly once with the value described by --help")
		}
	}
	return result, nil
}

func allowedComponentSetFields(location string) map[string]struct{} {
	if location == "component set" {
		return map[string]struct{}{"schema": {}, "components": {}}
	}
	const componentPrefix = "component set.components["
	if !strings.HasPrefix(location, componentPrefix) || !strings.HasSuffix(location, "]") {
		return nil
	}
	index := strings.TrimSuffix(strings.TrimPrefix(location, componentPrefix), "]")
	if _, err := strconv.ParseUint(index, 10, 64); err != nil {
		return nil
	}
	return map[string]struct{}{"id": {}, "artifact": {}, "asset": {}, "bundle_id": {}}
}

func validateComponentSetJSONFields(data []byte) error {
	decoder := json.NewDecoder(bytes.NewReader(data))
	var walk func(string) error
	walk = func(location string) error {
		token, err := decoder.Token()
		if err != nil {
			return err
		}
		delimiter, ok := token.(json.Delim)
		if !ok {
			return nil
		}
		switch delimiter {
		case '{':
			seen := map[string]bool{}
			allowed := allowedComponentSetFields(location)
			for decoder.More() {
				keyToken, err := decoder.Token()
				if err != nil {
					return err
				}
				key, ok := keyToken.(string)
				if !ok {
					return fmt.Errorf("object key is not a string")
				}
				if seen[key] {
					return fmt.Errorf("field %q appears more than once at %s", key, location)
				}
				seen[key] = true
				if allowed != nil {
					if _, ok := allowed[key]; !ok {
						return fmt.Errorf("field %q is not an exact allowed field at %s", key, location)
					}
				}
				if err := walk(location + "." + key); err != nil {
					return err
				}
			}
			_, err = decoder.Token()
			return err
		case '[':
			for index := 0; decoder.More(); index++ {
				if err := walk(fmt.Sprintf("%s[%d]", location, index)); err != nil {
					return err
				}
			}
			_, err = decoder.Token()
			return err
		default:
			return fmt.Errorf("unexpected JSON delimiter %q", delimiter)
		}
	}
	if err := walk("component set"); err != nil {
		return err
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		return fmt.Errorf("trailing data follows the component set")
	}
	return nil
}

func parseComponentSet(path string) ([]componentInput, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, actionable("reading the component set", path, err, "the nine immutable artifacts cannot be identified", "provide one readable UTF-8 JSON component-set document")
	}
	if err := validateComponentSetJSONFields(data); err != nil {
		return nil, actionable("validating component-set JSON", path, err, "producer input has multiple interpretations", "use the exact documented root and component field names without case variants, unknown fields, duplicates, or trailing data")
	}
	var document componentDocument
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&document); err != nil {
		return nil, actionable("decoding the component set", path, err, "the nine immutable artifacts cannot be identified", "use only schema and components, and only id, artifact, asset, and bundle_id in each component")
	}
	if document.Schema != componentSetSchema {
		return nil, actionable("validating component-set schema", path, fmt.Errorf("schema %q is not %q", document.Schema, componentSetSchema), "producer input semantics are ambiguous", "use the exact Aura component-set schema")
	}
	canonical := artifact.ComponentIDs()
	if len(document.Components) != len(canonical) {
		return nil, actionable("validating component inventory", path, fmt.Errorf("found %d records instead of exactly %d", len(document.Components), len(canonical)), "the aggregate would omit or add an installation cell", "provide every Pasture ComponentIDs entry exactly once")
	}
	base := filepath.Dir(path)
	byID := make(map[artifact.ComponentID]componentInput, len(canonical))
	for index, record := range document.Components {
		id, err := artifact.ParseComponentID(record.ID)
		if err != nil {
			return nil, actionable("parsing component identity", fmt.Sprintf("components[%d].id", index), err, "artifact ownership cannot be proven", "use one exact Pasture ComponentID")
		}
		if _, exists := byID[id]; exists {
			return nil, actionable("validating component identity", fmt.Sprintf("components[%d].id", index), fmt.Errorf("component %q is duplicated", record.ID), "per-cell artifact selection is ambiguous", "provide every Pasture ComponentIDs entry exactly once")
		}
		bundleID, err := artifact.ParseBundleID(record.BundleID)
		if err != nil {
			return nil, actionable("parsing target-owned bundle identity", fmt.Sprintf("components[%d].bundle_id", index), err, "installed bytes cannot be tied to a target descriptor", "provide the exact BundleID emitted by the Pasture target bundle")
		}
		if record.Artifact == "" || record.Asset == "" {
			return nil, actionable("validating component paths", fmt.Sprintf("components[%d]", index), fmt.Errorf("artifact and asset must both be non-empty"), "component bytes cannot be read or named", "provide the built archive path and its canonical Pasture aggregate asset basename")
		}
		source := record.Artifact
		if !filepath.IsAbs(source) {
			source = filepath.Join(base, source)
		}
		byID[id] = componentInput{id: id, source: filepath.Clean(source), asset: record.Asset, bundleID: bundleID}
	}
	result := make([]componentInput, 0, len(canonical))
	for _, id := range canonical {
		input, ok := byID[id]
		if !ok {
			return nil, actionable("validating component inventory", path, fmt.Errorf("canonical component %q is missing", id), "the aggregate is incomplete", "provide every Pasture ComponentIDs entry without fallback or skew")
		}
		result = append(result, input)
	}
	return result, nil
}

func readArtifact(input componentInput) ([]byte, error) {
	descriptor, err := syscall.Open(input.source, syscall.O_RDONLY|syscall.O_CLOEXEC|syscall.O_NOFOLLOW, 0)
	if err != nil {
		return nil, actionable("opening component artifact", input.id.String()+" at "+input.source, err, "exact component bytes cannot be frozen", "provide a readable non-symlink regular archive and retry")
	}
	file := os.NewFile(uintptr(descriptor), input.source)
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return nil, actionable("inspecting component artifact", input.id.String()+" at "+input.source, err, "the archive type and size cannot be proven", "repair the archive path and retry")
	}
	if !info.Mode().IsRegular() || info.Size() > maxAssetBytes {
		return nil, actionable("validating component artifact", input.id.String()+" at "+input.source, fmt.Errorf("mode is %s and size is %d", info.Mode(), info.Size()), "bounded exact-byte verification is impossible", fmt.Sprintf("provide a regular archive no larger than %d bytes", maxAssetBytes))
	}
	content, err := io.ReadAll(io.LimitReader(file, maxAssetBytes+1))
	if err != nil {
		return nil, actionable("reading component artifact", input.id.String()+" at "+input.source, err, "its digest cannot be established", "rebuild the archive and retry after writers finish")
	}
	if int64(len(content)) != info.Size() || len(content) > maxAssetBytes {
		return nil, actionable("reading component artifact", input.id.String()+" at "+input.source, fmt.Errorf("read %d bytes from a file reported as %d bytes", len(content), info.Size()), "its digest is not a stable identity", "rebuild the archive and retry after writers finish")
	}
	return content, nil
}

func generate(configuration options, operations outputOperations) (err error) {
	version, err := artifact.ParseVersion(configuration.version)
	if err != nil {
		return actionable("parsing aggregate version", "--version", err, "immutable release identity cannot be proven", "use canonical Pasture release SemVer")
	}
	installerMin, err := artifact.ParseVersion(configuration.installerMin)
	if err != nil {
		return actionable("parsing compatibility minimum", "--installer-min", err, "installer compatibility cannot be proven", "use canonical Pasture release SemVer")
	}
	installerMax, err := artifact.ParseVersion(configuration.installerMax)
	if err != nil {
		return actionable("parsing compatibility maximum", "--installer-max", err, "installer compatibility cannot be proven", "use canonical Pasture release SemVer")
	}
	pastureRevision, err := artifact.ParseRevision(configuration.pastureRevision)
	if err != nil {
		return actionable("parsing Pasture revision", "--pasture-revision", err, "release provenance would be mutable or ambiguous", "provide the exact lowercase Pasture commit")
	}
	auraRevision, err := artifact.ParseRevision(configuration.auraRevision)
	if err != nil {
		return actionable("parsing Aura revision", "--aura-revision", err, "release provenance would be mutable or ambiguous", "provide the exact lowercase Aura commit")
	}
	componentsPath, err := filepath.Abs(configuration.components)
	if err != nil {
		return actionable("resolving the component set", configuration.components, err, "component inputs cannot be located", "provide a valid component-set path")
	}
	components, err := parseComponentSet(componentsPath)
	if err != nil {
		return err
	}
	output, err := filepath.Abs(configuration.outputDir)
	if err != nil {
		return actionable("resolving the output directory", configuration.outputDir, err, "the immutable destination cannot be claimed", "provide a valid new version-specific path")
	}
	if err := os.Mkdir(output, 0o755); err != nil {
		return actionable("claiming the output directory", output, err, "an existing immutable aggregate is preserved and will not be mutated", "choose a new path whose parent already exists")
	}
	complete := false
	defer func() {
		if complete {
			return
		}
		if cleanupErr := os.RemoveAll(output); cleanupErr != nil {
			err = actionable("removing the incomplete output directory", output, cleanupErr, "partial release bytes may remain and must not be published", "remove the incomplete directory manually after repairing permissions; original failure: "+err.Error())
		}
	}()

	type preparedComponent struct {
		input componentInput
		temp  string
	}
	prepared := make([]preparedComponent, 0, len(components))
	specs := make([]artifact.AggregateComponentSpec, 0, len(components))
	total := 0
	for index, input := range components {
		content, err := readArtifact(input)
		if err != nil {
			return err
		}
		total += len(content)
		if total > maxTotalBytes {
			return actionable("validating aggregate byte limit", input.id.String(), fmt.Errorf("total exceeds %d bytes", maxTotalBytes), "the aggregate cannot be verified within its bounded contract", "reduce the component archives")
		}
		temporary := filepath.Join(output, fmt.Sprintf(".component-%02d", index))
		if err := operations.writeFile(temporary, content, 0o644); err != nil {
			return actionable("writing staged component bytes", temporary, err, "the claimed output is incomplete and will be removed", "repair output filesystem capacity and permissions, then retry with a new path")
		}
		runtimeContract, err := artifact.ProductionRuntimeContract(input.id.Harness())
		if err != nil {
			return actionable("selecting the production runtime contract", input.id.String(), err, "the component cannot be bound to its Pasture target", "use a component returned by Pasture ComponentIDs")
		}
		specs = append(specs, artifact.AggregateComponentSpec{
			Harness: input.id.Harness(), Extension: input.id.Extension(), Asset: input.asset,
			Digest: artifact.DigestBytes(content), BundleID: input.bundleID, RuntimeContractID: runtimeContract,
			PastureRevision: pastureRevision, AuraRevision: auraRevision,
		})
		prepared = append(prepared, preparedComponent{input: input, temp: temporary})
	}
	channel := artifact.ReleaseFinal
	if version.IsPrerelease() {
		channel = artifact.ReleasePrerelease
	}
	manifest, err := artifact.NewAggregateManifest(artifact.AggregateManifestSpec{
		Version: version, Channel: channel, InstallerMin: installerMin, InstallerMax: installerMax,
		PastureRevision: pastureRevision, AuraRevision: auraRevision, Components: specs,
	})
	if err != nil {
		return actionable("constructing the typed aggregate manifest", artifact.AggregateManifestAsset, err, "the claimed output is incomplete and will be removed", "correct the component asset names, compatibility range, or identities and retry")
	}
	manifestBytes, err := json.Marshal(manifest)
	if err != nil {
		return actionable("marshaling the typed aggregate manifest", artifact.AggregateManifestAsset, err, "the claimed output is incomplete and will be removed", "report the typed Pasture codec failure and do not publish the output")
	}
	assetByID := make(map[artifact.ComponentID]string, len(manifest.Components()))
	for _, component := range manifest.Components() {
		assetByID[component.ID()] = component.Asset()
	}
	for _, component := range prepared {
		destination := filepath.Join(output, assetByID[component.input.id])
		if err := operations.rename(component.temp, destination); err != nil {
			return actionable("committing a validated component asset", destination, err, "the claimed output is incomplete and will be removed", "repair output filesystem capacity and permissions, then retry with a new path")
		}
	}
	manifestPath := filepath.Join(output, artifact.AggregateManifestAsset)
	if err := operations.writeFile(manifestPath, manifestBytes, 0o644); err != nil {
		return actionable("writing the canonical aggregate manifest", manifestPath, err, "the claimed output is incomplete and will be removed", "repair output filesystem capacity and permissions, then retry with a new path")
	}
	checksumPath := filepath.Join(output, artifact.AggregateChecksumAsset)
	if err := operations.writeFile(checksumPath, artifact.AggregateManifestChecksum(manifestBytes), 0o644); err != nil {
		return actionable("writing the canonical manifest checksum", checksumPath, err, "the claimed output is incomplete and will be removed", "repair output filesystem capacity and permissions, then retry with a new path")
	}
	if _, err := artifact.VerifyAggregate(context.Background(), directorySource(output), artifact.AggregateRequirements{
		Version: version, Installer: installerMin, PastureRevision: pastureRevision, AuraRevision: auraRevision,
	}); err != nil {
		return actionable("verifying the complete output with Pasture", output, err, "the claimed output is incomplete and will be removed", "correct the component inputs and retry; never publish a verifier-rejected directory")
	}
	entries, err := os.ReadDir(output)
	if err != nil {
		return actionable("enumerating the completed output", output, err, "immutable file modes cannot be applied", "repair output filesystem permissions and retry")
	}
	for _, entry := range entries {
		path := filepath.Join(output, entry.Name())
		if err := operations.chmod(path, 0o444); err != nil {
			return actionable("freezing an output file mode", path, err, "the claimed output is incomplete and will be removed", "repair output filesystem permissions and retry with a new path")
		}
	}
	if err := operations.chmod(output, 0o555); err != nil {
		return actionable("freezing the output directory mode", output, err, "the claimed output is incomplete and will be removed", "repair output filesystem permissions and retry with a new path")
	}
	complete = true
	return nil
}

func run(arguments []string, stderr io.Writer) int {
	configuration, err := parseOptions(arguments, stderr)
	if errors.Is(err, flag.ErrHelp) {
		return 0
	}
	if err == nil {
		err = generate(configuration, productionOutputOperations)
	}
	if err != nil {
		fmt.Fprintf(stderr, "error: %v\n", err)
		return 2
	}
	return 0
}

func main() {
	os.Exit(run(os.Args[1:], os.Stderr))
}
