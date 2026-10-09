# Bundled longfellow circuits

Eight circuits: revisions 6 and 7, at one to four attributes. The wallet holds
all of them because the circuit is negotiated per request — a reader offers a
set and the intersection decides — so holding only some means falling back to a
plain presentation against a reader that offers the others.

These cannot be produced from source. `generate_circuit` emits only the newest
revision the library supports, so any revision the ecosystem still uses cannot
be regenerated, and readers reasonably lag the library. See irmago issue #724.

The filenames follow Multipaz's convention,
`<version>_<numAttributes>_<blockEncHash>_<blockEncSig>_<circuitHash>`, but
**nothing reads the hash out of the filename**. Each file's identity is
recomputed with the native `circuit_id` and recorded in `zkcircuits_map.go`,
which is generated — parsing the claimed hash out of a filename and trusting it
is what makes an accepted-circuit check theatre.
