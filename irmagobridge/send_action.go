package irmagobridge

import (
	"encoding/json"

	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

type OutgoingAction map[string]interface{}

type irmaConfigurationEvent struct {
	SchemeManagers  map[irma.SchemeManagerIdentifier]*irma.SchemeManager
	Issuers         map[irma.IssuerIdentifier]*irma.Issuer
	CredentialTypes map[irma.CredentialTypeIdentifier]*irma.CredentialType
	AttributeTypes  map[irma.AttributeTypeIdentifier]*irma.AttributeType
}

type credentialsEvent struct {
	Credentials irma.CredentialInfoList
}

type preferencesEvent struct {
	Preferences irmaclient.Preferences
}

type enrollmentStatusEvent struct {
	EnrolledSchemeManagerIds   []irma.SchemeManagerIdentifier
	UnenrolledSchemeManagerIds []irma.SchemeManagerIdentifier
}

type authenticationFailedEvent struct {
	RemainingAttempts int
	BlockedDuration   int
}

func sendConfiguration() {
	dispatchEvent("IrmaConfigurationEvent", &irmaConfigurationEvent{
		SchemeManagers:  client.Configuration.SchemeManagers,
		Issuers:         client.Configuration.Issuers,
		CredentialTypes: client.Configuration.CredentialTypes,
		AttributeTypes:  client.Configuration.AttributeTypes,
	})
}

func sendCredentials() {
	dispatchEvent("CredentialsEvent", &credentialsEvent{
		Credentials: client.CredentialInfoList(),
	})
}

func sendPreferences() {
	dispatchEvent("PreferencesEvent", &preferencesEvent{
		Preferences: client.Preferences,
	})
}

func sendEnrollmentStatus() {
	dispatchEvent("EnrollmentStatusEvent", &enrollmentStatusEvent{
		EnrolledSchemeManagerIds:   client.EnrolledSchemeManagers(),
		UnenrolledSchemeManagerIds: client.UnenrolledSchemeManagers(),
	})
}

func sendAuthenticateFailure(tries, blocked int) {
	dispatchEvent("AuthenticationFailedEvent", &authenticationFailedEvent{
		RemainingAttempts: tries,
		BlockedDuration:   blocked,
	})
}

func sendAuthenticateSuccess() {
	sendAction(&OutgoingAction{
		"type": "IrmaClient.AuthenticateSuccess",
	})
}

func sendAuthenticateError(err *irma.SessionError) {
	sendAction(&OutgoingAction{
		"type":  "IrmaClient.AuthenticateError",
		"error": err,
	})
}

func sendAction(action interface{}) {
	bridge.DebugLog("Blackholing action...")
}

func dispatchEvent(name string, payload interface{}) {
	jsonBytes, err := json.Marshal(payload)
	if err != nil {
		logError(errors.Errorf("Cannot marshal event payload: %s", err))
		return
	}

	bridge.DebugLog("Sending event " + name)
	bridge.DispatchFromGo(name, string(jsonBytes))
}
