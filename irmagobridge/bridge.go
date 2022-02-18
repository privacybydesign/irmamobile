package irmagobridge

import (
	"crypto/tls"
	"crypto/x509"
	"embed"
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"strings"

	"github.com/go-errors/errors"
	irma "github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
	"github.com/sirupsen/logrus"
)

// IrmaMobileBridge is the iOS or Android native component that is used for message passing
type IrmaMobileBridge interface {
	DispatchFromGo(name string, payload string)
	DebugLog(message string)
}

type Signer irmaclient.Signer

var bridge IrmaMobileBridge
var client *irmaclient.Client
var appDataVersion = "v2"
var clientLoaded = make(chan struct{})
var clientErr *errors.Error

//go:embed assets
var embeddedAssets embed.FS

// eventHandler maintains a sessionLookup for actions incoming
// from irma_mobile (see action_handler.go)
var bridgeEventHandler = &eventHandler{
	sessionLookup: map[int]*sessionHandler{},
}

// clientHandler is used for messages coming in from irmago (see client_handler.go)
var bridgeClientHandler = &clientHandler{}

// Prestart is invoked only on Android in MainActivity's onCreate, to initialize
// the Go binding at the earliest moment, instead of inside the Flutter plugin
func Prestart() {
	// noop
}

type writer func(string)

func (p writer) Write(b []byte) (int, error) {
	p(string(b))
	return len(b), nil
}

// Start is invoked from the native side, when the app starts
func Start(givenBridge IrmaMobileBridge, appDataPath string, assetsPath string, signer Signer, aesKey []byte) {
	defer recoverFromPanic("Starting of bridge panicked")

	bridge = givenBridge

	if client != nil || clientErr != nil {
		// If this function was run previously, either client or clientErr (or both) will be non-nil.
		// In the first case, nothing to do. In the second case, retrying won't help. Either way, we
		// just return - also ensuring that clientLoaded is not closed a second time, which would panic.
		return
	}

	defer func() {
		close(clientLoaded) // make all future reads return immediately
	}()

	// Older Android versions don't have the most recent cacerts in storage. Because web browsers either ship their own
	// cacerts or rely on expired cacerts (the trust anchor approach), websites keep working on these devices.
	// To make sure the IRMA app keeps working too, we ship it with some cacerts that are known to be missing.
	rootCAs, err := x509.SystemCertPool()
	if err != nil {
		clientErr = errors.WrapPrefix(err, "System certificate pool could not be loaded", 0)
		return
	}

	err = fs.WalkDir(embeddedAssets, "assets/cacerts", func(path string, d fs.DirEntry, err error) error {
		// We have to skip the root directory itself.
		if err != nil || d.IsDir() {
			return err
		}

		f, err := embeddedAssets.ReadFile(path)
		if err != nil {
			return err
		}

		if !rootCAs.AppendCertsFromPEM(f) {
			return errors.Errorf("Certificate could not be parsed: %s", path)
		}
		return nil
	})
	if err != nil {
		clientErr = errors.WrapPrefix(err, "Embedded certificates could not be loaded", 0)
		return
	}
	irma.SetTLSClientConfig(&tls.Config{
		RootCAs: rootCAs,
		CipherSuites: []uint16{
			// TLS 1.3 cipher suites are always accepted, so we only specify the secure cipher suites for <= TLS 1.2.
			tls.TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,
			tls.TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,
			tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
			tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
			tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
		},
	})

	// Check for user data directory, and create version-specific directory
	exists, err := pathExists(appDataPath)
	if err != nil || !exists {
		clientErr = errors.WrapPrefix(err, "Cannot access app data directory", 0)
		return
	}

	appVersionDataPath := filepath.Join(appDataPath, appDataVersion)
	exists, err = pathExists(appVersionDataPath)
	if err != nil {
		clientErr = errors.WrapPrefix(err, "Cannot check for app data path existence", 0)
		return
	}

	if !exists {
		if err = os.Mkdir(appVersionDataPath, 0770); err != nil {
			clientErr = errors.WrapPrefix(err, "Cannot create app data directory", 0)
			return
		}
	}

	// forward irma log message to bridge
	irma.Logger.SetOutput(writer(func(m string) {
		bridge.DebugLog(fmt.Sprintf("[irmago] %s", m))
	}))

	// Initialize the client
	configurationPath := filepath.Join(assetsPath, "irma_configuration")
	client, err = irmaclient.New(appVersionDataPath, configurationPath, bridgeClientHandler, signer, aesKey)
	if err != nil {
		clientErr = errors.WrapPrefix(err, "Cannot initialize client", 0)
		return
	}

	if client.Preferences.DeveloperMode {
		irma.Logger.SetLevel(logrus.TraceLevel)
	}
}

func dispatchEvent(event interface{}) {
	jsonBytes, err := json.Marshal(event)
	if err != nil {
		reportError(errors.Errorf("Cannot marshal event payload: %s", err), false)
		return
	}

	eventName := strings.Title(reflect.TypeOf(event).Elem().Name())
	bridge.DebugLog("Sending event " + eventName)
	bridge.DispatchFromGo(eventName, string(jsonBytes))
}

func Stop() {
	defer recoverFromPanic("Closing of bridge panicked")

	if client != nil {
		if err := client.Close(); err != nil {
			clientErr = errors.WrapPrefix(err, "Cannot close client", 0)
			return
		}
	}

	client = nil
	clientErr = nil
	clientLoaded = make(chan struct{})
}

func reportError(err *errors.Error, fatal bool) {
	message := fmt.Sprintf("%s\n%s", err.Error(), err.ErrorStack())

	// raven.CaptureError(err, nil)
	bridge.DebugLog(message)

	// We need to json encode the error, but cant do full error checking
	jsonBytes, err2 := json.Marshal(errorEvent{Exception: err.Error(), Stack: err.ErrorStack(), Fatal: fatal})
	if err2 != nil {
		bridge.DebugLog(err2.Error())
	} else {
		bridge.DispatchFromGo("ErrorEvent", string(jsonBytes))
	}
}

// PathExists checks if the specified path exists.
func pathExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return true, err
}

// Use this function when the app is not ready yet to handle errors. The recovered panic is
// converted to an error and cached in clientErr. It will be handled as soon as the app is ready.
func recoverFromPanic(message string) {
	if e := recover(); e != nil {
		clientErr = errors.WrapPrefix(e, message, 0)
	}
}
