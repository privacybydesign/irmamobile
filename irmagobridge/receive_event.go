package irmagobridge

import (
	"encoding/json"

	"github.com/go-errors/errors"
)

// DispatchFromNative receives events from the Android / iOS native side
func DispatchFromNative(eventName, payloadString string) {
	defer recoverFromPanic()

	payloadBytes := []byte(payloadString)
	var err error

	switch eventName {
	case "AppReadyEvent":
		dispatchEnrollmentStatusEvent()
		dispatchConfigurationEvent()
		dispatchCredentialsEvent()
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
		err = bridgeEventHandler.updateSchemes()
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
	}

	if err != nil {
		reportError(errors.New(err))
	}
}
