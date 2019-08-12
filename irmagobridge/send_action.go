package irmagobridge

import (
	"encoding/json"

	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

type OutgoingAction map[string]interface{}

func sendConfiguration() {
	sendAction(&OutgoingAction{
		"type":              "IrmaClient.Configuration",
		"irmaConfiguration": client.Configuration,
		"sentryDSN":         irmaclient.SentryDSN,
	})
}

func sendPreferences() {
	sendAction(&OutgoingAction{
		"type":        "IrmaClient.Preferences",
		"preferences": client.Preferences,
	})
}

func sendCredentials() {
	sendAction(&OutgoingAction{
		"type":        "IrmaClient.Credentials",
		"credentials": client.CredentialInfoList(),
	})
}

func sendEnrollmentStatus() {
	sendAction(&OutgoingAction{
		"type": "IrmaClient.EnrollmentStatus",
		"enrolledSchemeManagerIds":   client.EnrolledSchemeManagers(),
		"unenrolledSchemeManagerIds": client.UnenrolledSchemeManagers(),
	})
}

func sendAuthenticateFailure(tries, blocked int) {
	sendAction(&OutgoingAction{
		"type":              "IrmaClient.AuthenticateFailure",
		"remainingAttempts": tries,
		"blockedDuration":   blocked,
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

func sendAction(action *OutgoingAction) {
	jsonBytes, err := json.Marshal(action)
	if err != nil {
		logError(errors.Errorf("Cannot marshal action: %s", err))
		return
	}

	bridge.SendEvent("irmago", string(jsonBytes))
}
