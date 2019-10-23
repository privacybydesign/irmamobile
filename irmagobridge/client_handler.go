package irmagobridge

import (
	irma "github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

// compile-time type-check ClientHandler to implement irmaclient.ClientHandler
var _ irmaclient.ClientHandler = (*ClientHandler)(nil)

type ClientHandler struct {
}

func (ch *ClientHandler) UpdateConfiguration(new *irma.IrmaIdentifierSet) {
	logDebug("Handling UpdateConfiguration")
	sendConfiguration()
}

func (ch *ClientHandler) UpdateAttributes() {
	logDebug("Handling UpdateAttributes")
	sendCredentials()
}

func (ch *ClientHandler) EnrollmentFailure(managerIdentifier irma.SchemeManagerIdentifier, plainErr error) {
	logDebug("Handling EnrollmentFailure")

	// Make sure the error is wrapped in a SessionError, so we only have one type to handle in irma_mobile
	err, ok := plainErr.(*irma.SessionError)
	if !ok {
		err = &irma.SessionError{ErrorType: irma.ErrorType("unknown"), Err: plainErr}
	}

	action := &OutgoingAction{
		"type":            "IrmaClient.EnrollmentFailure",
		"schemeManagerId": managerIdentifier,
		"error": &OutgoingAction{
			"type":         err.ErrorType,
			"wrappedError": err.WrappedError(),
			"info":         err.Info,
			"stack":        err.Stack(),
			"remoteStatus": err.RemoteStatus,
			"remoteError":  err.RemoteError,
		},
	}

	sendAction(action)
}

func (ch *ClientHandler) EnrollmentSuccess(managerIdentifier irma.SchemeManagerIdentifier) {
	logDebug("Handling EnrollmentSuccess")

	action := &OutgoingAction{
		"type":            "IrmaClient.EnrollmentSuccess",
		"schemeManagerId": managerIdentifier,
	}

	sendEnrollmentStatus()
	sendAction(action)
}

func (ch *ClientHandler) ChangePinFailure(managerIdentifier irma.SchemeManagerIdentifier, plainErr error) {
	logDebug("Handling ChangePinFailure")

	// Make sure the error is wrapped in a SessionError, so we only have one type to handle in irma_mobile
	err, ok := plainErr.(*irma.SessionError)
	if !ok {
		err = &irma.SessionError{ErrorType: irma.ErrorType("unknown"), Err: plainErr}
	}

	action := &OutgoingAction{
		"type":            "IrmaClient.ChangePinFailure",
		"schemeManagerId": managerIdentifier,
		"error": &OutgoingAction{
			"type":         err.ErrorType,
			"wrappedError": err.WrappedError(),
			"info":         err.Info,
			"stack":        err.Stack(),
			"remoteStatus": err.RemoteStatus,
			"remoteError":  err.RemoteError,
		},
	}

	sendAction(action)
}

func (ch *ClientHandler) ChangePinSuccess(managerIdentifier irma.SchemeManagerIdentifier) {
	logDebug("Handling ChangePinSuccess")

	action := &OutgoingAction{
		"type": "IrmaClient.ChangePinSuccess",
	}

	sendAction(action)
}

func (ch *ClientHandler) ChangePinIncorrect(managerIdentifier irma.SchemeManagerIdentifier, attempts int) {
	logDebug("Handling ChangePinIncorrect")

	action := &OutgoingAction{
		"type":              "IrmaClient.ChangePinIncorrect",
		"remainingAttempts": attempts,
	}

	sendAction(action)
}

func (ch *ClientHandler) ChangePinBlocked(managerIdentifier irma.SchemeManagerIdentifier, timeout int) {
	logDebug("Handling ChangePinBlocked")

	action := &OutgoingAction{
		"type":    "IrmaClient.ChangePinBlocked",
		"timeout": timeout,
	}

	sendAction(action)
}
