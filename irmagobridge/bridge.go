package irmagobridge

import (
	"encoding/json"
	"fmt"
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

var bridge IrmaMobileBridge
var client *irmaclient.Client
var appDataVersion = "v2"
var clientLoaded = make(chan struct{})
var clientErr *errors.Error

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
func Start(givenBridge IrmaMobileBridge, appDataPath string, assetsPath string) {
	defer recoverFromPanic()

	bridge = givenBridge

	if client != nil || clientErr != nil {
		// If this function was run previously, either client or clientErr (or both) will be non-nil.
		// In the first case, nothing to do. In the second case, retrying won't help. Either way, we
		// just return - also ensuring that clientLoaded is not closed a second time, which would panic.
		return
	}

	var err error
	defer func() {
		if clientErr == nil && err != nil {
			clientErr = errors.WrapPrefix(err, "Unknown error while starting bridge", 0)
		}
		close(clientLoaded) // make all future reads return immediately
	}()

	// Check for user data directory, and create version-specific directory
	var exists bool
	exists, err = pathExists(appDataPath)
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
			return
		}
	}

	// forward irma log message to bridge
	irma.Logger.SetOutput(writer(func(m string) {
		bridge.DebugLog(fmt.Sprintf("[irmago] %s", m))
	}))

	// Initialize the client
	configurationPath := filepath.Join(assetsPath, "irma_configuration")
	client, err = irmaclient.New(appVersionDataPath, configurationPath, bridgeClientHandler)
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
	client.Close()
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

func recoverFromPanic() {
	if e := recover(); e != nil {
		clientErr = errors.WrapPrefix(e, "Starting of bridge panicked", 0)
	}
}
