//go:build longfellow

package irmagobridge

import (
	"embed"
	"io/fs"

	"github.com/privacybydesign/irmago/client"
	"github.com/privacybydesign/longfellow-go/longfellow"
)

// zkCircuits are the circuits this build can prove with, compiled into the
// binary rather than provisioned onto the device.
//
// They ship because they cannot be produced: generate_circuit emits only the
// newest revision the library supports, so any revision the ecosystem still
// uses cannot be regenerated, and readers reasonably lag the library. All eight
// are here — revisions 6 and 7, one to four attributes — because the circuit is
// negotiated per request and holding only some of them means falling back to a
// plain presentation against a reader that offers the others.
//
// Embedding rather than shipping them as Android assets keeps this to one
// mechanism that also works on iOS, and means the circuits travel inside the
// signed binary rather than beside it. The cost is that they are duplicated per
// ABI in a multi-ABI build; at 2.5 MB, and with app bundles delivering one ABI
// per device, that was judged the better trade.
//
//go:embed zkcircuits
var zkCircuits embed.FS

// zkProverOptions registers the longfellow prover over the bundled circuits.
//
// The startup cost is the whole reason zkcircuits_map.go exists. Identifying a
// circuit means decompressing and parsing it — about 1.2 seconds each, so ten
// seconds for eight — and because the bridge is started on the UI thread, the
// first version of this froze the app long enough for Android's ANR watchdog to
// sample it twice. The generated MapCache turns each identification into a
// SHA-256 over the compressed bytes.
//
// The map is not trusted to say what a circuit IS. A cache entry that no longer
// names a circuit this build knows costs a slow load and nothing else, because
// longfellow's identify() falls back to real identification when a cached id
// does not resolve — so a stale map degrades startup rather than integrity.
//
// Returning no options is a complete wallet, not a broken one: AV Annex A
// section A.8 requires falling back to the plain ISO mDoc presentation where a
// device cannot generate a proof, and a session with no system registered does
// exactly that.
func zkProverOptions() []client.Option {
	circuits, err := fs.Sub(zkCircuits, "zkcircuits")
	if err != nil {
		bridge.DebugLog("[zk] bundled circuits unreadable: " + err.Error())
		return nil
	}

	system, err := longfellow.Open(circuits, longfellow.WithCache(bundledCircuits))
	if err != nil {
		bridge.DebugLog("[zk] bundled circuits did not load: " + err.Error())
		return nil
	}

	bridge.DebugLog("[zk] prover ready over " + itoa(len(system.Circuits())) + " circuit(s)")
	return []client.Option{client.WithZkProver(system)}
}

// itoa keeps this file's imports to what it genuinely needs.
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var digits []byte
	for n > 0 {
		digits = append([]byte{byte('0' + n%10)}, digits...)
		n /= 10
	}
	return string(digits)
}
