package irmagobridge

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/irmaclient"
)

// IrmaMobileBridge is the iOS or Android native component that is used for message passing
type IrmaMobileBridge interface {
	DispatchFromGo(name string, payload string)
	DebugLog(message string)
}

var bridge IrmaMobileBridge
var client *irmaclient.Client
var appDataVersion = "v2"

// eventHandler maintains a sessionLookup for actions incoming
// from irma_mobile (see action_handler.go)
var eventHandler = &EventHandler{
	sessionLookup: map[int]*SessionHandler{},
}

// clientHandler is used for messages coming in from irmago (see client_handler.go)
var clientHandler = &ClientHandler{}

// Prestart is invoked only on Android in MainActivity's onCreate, to initialize
// the Go binding at the earliest moment, instead of inside the Flutter plugin
func Prestart() {
	// noop
}

// Start is invoked from the native side, when the app starts
func Start(givenBridge IrmaMobileBridge, appDataPath string, assetsPath string) {
	// raven.CapturePanic(func() {
	recoveredStart(givenBridge, appDataPath, assetsPath)
	// }, nil)
}

func recoveredStart(givenBridge IrmaMobileBridge, appDataPath string, assetsPath string) {
	bridge = givenBridge

	// Check for user data directory, and create version-specific directory
	exists, err := pathExists(appDataPath)
	if err != nil || !exists {
		logError(errors.WrapPrefix(err, "Cannot access app data directory", 0))
		return
	}

	appVersionDataPath := filepath.Join(appDataPath, appDataVersion)
	exists, err = pathExists(appVersionDataPath)
	if err != nil {
		logError(errors.WrapPrefix(err, "Cannot check for app data path existence", 0))
		return
	}

	if !exists {
		os.Mkdir(appVersionDataPath, 0770)
	}

	// Initialize the client
	// TODO: Deprecate third argument (androidPath) of irmaclient.New
	configurationPath := filepath.Join(assetsPath, "irma_configuration")
	client, err = irmaclient.New(appVersionDataPath, configurationPath, "", clientHandler)
	if err != nil {
		logError(errors.WrapPrefix(err, "Cannot initialize client", 0))
		return
	}
}

func logError(err error) {
	message := fmt.Sprintf("%s\n%s", err.Error(), err.(*errors.Error).ErrorStack())

	// raven.CaptureError(err, nil)
	bridge.DebugLog(message)
}

func logDebug(message string) {
	bridge.DebugLog(message)
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
