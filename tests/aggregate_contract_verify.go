package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/dayvidpham/pasture/artifact"
)

type directorySource string

func (source directorySource) OpenAsset(_ context.Context, name string) (io.ReadCloser, error) {
	return os.Open(filepath.Join(string(source), name))
}

func main() {
	if len(os.Args) != 7 {
		panic("usage: aggregate-contract-verify OUTPUT VERSION INSTALLER PASTURE-REVISION AURA-REVISION EXPECTED-CHANNEL")
	}
	version, err := artifact.ParseVersion(os.Args[2])
	if err != nil {
		panic(err)
	}
	installer, err := artifact.ParseVersion(os.Args[3])
	if err != nil {
		panic(err)
	}
	pastureRevision, err := artifact.ParseRevision(os.Args[4])
	if err != nil {
		panic(err)
	}
	auraRevision, err := artifact.ParseRevision(os.Args[5])
	if err != nil {
		panic(err)
	}
	verified, err := artifact.VerifyAggregate(context.Background(), directorySource(os.Args[1]), artifact.AggregateRequirements{
		Version: version, Installer: installer, PastureRevision: pastureRevision, AuraRevision: auraRevision,
	})
	if err != nil {
		panic(err)
	}
	if len(verified.Manifest().Components()) != 9 || string(verified.Manifest().Channel()) != os.Args[6] {
		panic(fmt.Sprintf("unexpected verified contract: components=%d channel=%s", len(verified.Manifest().Components()), verified.Manifest().Channel()))
	}
}
