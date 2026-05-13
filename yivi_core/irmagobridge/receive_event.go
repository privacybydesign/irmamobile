package irmagobridge

import (
	"encoding/json"
	"fmt"

	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/irma"
)

// DispatchFromNative receives events from the Android / iOS native side
func DispatchFromNative(eventName, payloadString string) {
	defer recoverFromPanic(fmt.Sprintf("Handling %s panicked", eventName))

	payloadBytes := []byte(payloadString)
	var err error

	<-clientLoaded
	if clientErr != nil {
		// Error occurred during client initialization. If the app is ready, we can report it.
		// If the client couldn't be started at all, we can't do anything sensible here, so then just return.
		fatal := yiviClient == nil
		if eventName == "AppReadyEvent" {
			reportError(clientErr, fatal)
		}
		if fatal {
			return
		}
	}

	switch eventName {
	case "AppReadyEvent":
		dispatchEnrollmentStatusEvent()
		dispatchConfigurationEvent()
		dispatchPreferencesEvent()
	case "EnrollEvent":
		event := &enrollEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.enroll(event)
		}
	case "AuthenticateEvent":
		event := &authenticateEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.authenticate(event)
		}
	case "ChangePinEvent":
		event := &changePinEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.changePin(event)
		}
	case "NewSessionEvent":
		event := &newSessionEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.newSession(event)
		}
	case "SessionUserInteractionEvent":
		event := &sessionUserInteractionEvent{}
		if err = json.Unmarshal(payloadBytes, event); err != nil {
			break
		}
		// Run in a goroutine: the permission handler may block waiting for
		// pin input (via the keyshare session), which requires dispatching
		// events back to Dart on the main thread. Running synchronously
		// would deadlock, because DispatchFromNative blocks the main thread.
		go func() {
			defer recoverFromPanic("Handling SessionUserInteractionEvent panicked")
			if err := bridgeEventHandler.handleUserInteraction(event); err != nil {
				reportError(errors.New(err), false)
			}
		}()
	case "ClearAllDataEvent":
		err = bridgeEventHandler.clearAllData()
	case "DeleteCredentialEvent":
		event := &deleteCredentialEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.deleteCredential(event)
		}
	case "UpdateSchemesEvent":
		go func() {
			defer recoverFromPanic("Handling UpdateSchemesEvent panicked")
			err := bridgeEventHandler.updateSchemes()
			// Ignore transport errors
			if serr, ok := err.(*irma.SessionError); ok && serr.ErrorType == irma.ErrorTransport {
				return
			}
			if err != nil {
				reportError(errors.New(err), false)
			}
		}()
	case "LoadLogsEvent":
		event := &loadLogsEvent{}
		if err = json.Unmarshal(payloadBytes, &event); err == nil {
			err = bridgeEventHandler.loadLogs(event)
		}
	case "ClientPreferencesEvent":
		event := &clientPreferencesEvent{}
		if err = json.Unmarshal(payloadBytes, &event); err == nil {
			err = bridgeEventHandler.setPreferences(event)
		}
	case "InstallSchemeEvent":
		event := &installSchemeEvent{}
		if err = json.Unmarshal(payloadBytes, &event); err == nil {
			err = bridgeEventHandler.installScheme(event)
		}
	case "RemoveSchemeEvent":
		event := &removeSchemeEvent{}
		if err = json.Unmarshal(payloadBytes, &event); err == nil {
			err = bridgeEventHandler.removeScheme(event)
		}
	case "RemoveRequestorSchemeEvent":
		event := &removeRequestorSchemeEvent{}
		if err = json.Unmarshal(payloadBytes, &event); err == nil {
			err = bridgeEventHandler.removeRequestorScheme(event)
		}
	case "InstallCertificateEvent":
		event := &installCertificateEvent{}
		if err = json.Unmarshal(payloadBytes, &event); err == nil {
			err = bridgeEventHandler.installCertificate(event)
		}
	}

	if err != nil {
		reportError(errors.New(err), false)
	}
}
