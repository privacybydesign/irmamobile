package irmagobridge

import (
	"crypto/tls"
	"crypto/x509"
	"net/http"
	"testing"
)

// The EUDI clients in irmago use Go's default HTTP transport, so the TLS
// configuration of the bridge has to reach it.
func TestUseTLSConfigForDefaultTransport(t *testing.T) {
	transport, ok := http.DefaultTransport.(*http.Transport)
	if !ok {
		t.Fatalf("http.DefaultTransport is a %T, not a *http.Transport", http.DefaultTransport)
	}
	original := transport.TLSClientConfig
	t.Cleanup(func() { transport.TLSClientConfig = original })

	roots := x509.NewCertPool()
	config := &tls.Config{
		RootCAs:      roots,
		MinVersion:   tls.VersionTLS12,
		CipherSuites: []uint16{tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384},
	}

	useTLSConfigForDefaultTransport(config)

	got := transport.TLSClientConfig
	if got == nil {
		t.Fatal("the default transport has no TLS configuration")
	}
	if got == config {
		t.Error("the default transport shares the configuration instead of holding a copy")
	}
	if got.RootCAs != roots {
		t.Error("the default transport does not use the bridge's root certificates")
	}
	if got.MinVersion != tls.VersionTLS12 {
		t.Errorf("minimum TLS version is %x, want TLS 1.2", got.MinVersion)
	}
	if len(got.CipherSuites) != 1 || got.CipherSuites[0] != tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 {
		t.Errorf("cipher suites are %v, want only the configured one", got.CipherSuites)
	}
}
