package irmagobridge

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/getsentry/raven-go"
	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/irmaclient"
)

// IrmaBridge is the Objective C or Java component we use to communicate to Javascript
type IrmaBridge interface {
	SendEvent(channel string, message string)
	DebugLog(message string)
}

var bridge IrmaBridge
var client *irmaclient.Client
var appDataVersion = "v2"

// actionHandler maintains a sessionLookup for actions incoming
// from irma_mobile (see action_handler.go)
var actionHandler = &ActionHandler{
	sessionLookup: map[int]*SessionHandler{},
}

// clientHandler is used for messages coming in from irmago (see client_handler.go)
var clientHandler = &ClientHandler{}

// The Start function is invoked from Javascript via native code, when the app starts
func Start(givenBridge IrmaBridge, appDataPath string, assetsPath string) {
	raven.CapturePanic(func() {
		recoveredStart(givenBridge, appDataPath, assetsPath)
	}, nil)
}

func recoveredStart(givenBridge IrmaBridge, appDataPath string, assetsPath string) {
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
	configurationPath := filepath.Join(assetsPath, "irma_configuration")
	androidPath := appDataPath

	client, err = irmaclient.New(appVersionDataPath, configurationPath, androidPath, clientHandler)
	if err != nil {
		logError(errors.WrapPrefix(err, "Cannot initialize client", 0))
		return
	}

	// Update schemes before boot
	err = client.Configuration.UpdateSchemes()
	if err != nil {
		logError(errors.WrapPrefix(err, "Cannot update schemes", 0))
		// Continuing here should be safe
	}

	// Grab information from the client and send it to irma_mobile
	sendEnrollmentStatus()
	sendConfiguration()
	sendPreferences()
	sendCredentials()
}

func logError(err error) {
	message := fmt.Sprintf("%s\n%s", err.Error(), err.(*errors.Error).ErrorStack())

	raven.CaptureError(err, nil)
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
