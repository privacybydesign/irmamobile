package irmagobridge

import (
	"encoding/json"
	"fmt"

	"github.com/go-errors/errors"
	irma "github.com/privacybydesign/irmago"
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
		fatal := client == nil
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
	case "RespondPermissionEvent":
		event := &respondPermissionEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.respondPermission(event)
		}
  case "RespondAuthorizationCodeEvent":
    event := &respondAuthorizationCodeEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.respondAuthorizationCode(event)
    }
	case "RespondPinEvent":
		event := &respondPinEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.respondPin(event)
		}
	case "ClearAllDataEvent":
		err = bridgeEventHandler.clearAllData()
	case "DeleteCredentialEvent":
		event := &deleteCredentialEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.deleteCredential(event)
		}
	case "DismissSessionEvent":
		event := &dismissSessionEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = bridgeEventHandler.dismissSession(event)
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
	case "GetIssueWizardContentsEvent":
		event := &getIssueWizardContentsEvent{}
		if err = json.Unmarshal(payloadBytes, &event); err == nil {
			err = bridgeEventHandler.getIssueWizardContents(event)
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
	}

	if err != nil {
		reportError(errors.New(err), false)
	}
}
