//go:build !longfellow

package irmagobridge

import "github.com/privacybydesign/irmago/client"

// zkProverOptions returns no prover, which is the ordinary build.
//
// The zero-knowledge prover is a C++ library reached through a separate Go
// module (longfellow-go) that irmago deliberately does not import. It links only
// when bind_go.sh found per-ABI static libraries to point cgo at, and set the
// `longfellow` build tag. Every other build -- iOS, CI, a plain `go build ./...`
// -- compiles this file instead and carries no reference to that module at all.
//
// A wallet with no prover is not degraded. AV Annex A section A.8 requires an
// AVI to fall back to the plain ISO mDoc presentation of section A.6 where the
// device cannot generate a proof, and irmago's isomdoc.Session does exactly that
// when no system is registered. It becomes a refusal only against a reader that
// set zkRequired, which is that reader's choice.
func zkProverOptions() []client.Option {
	return nil
}
