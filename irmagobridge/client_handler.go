package irmagobridge

import (
	"github.com/go-errors/errors"
	irma "github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

// compile-time type-check ClientHandler to implement irmaclient.ClientHandler
var _ irmaclient.ClientHandler = (*clientHandler)(nil)

type clientHandler struct {
}

func (i *clientHandler) ReportError(err error) {
	wrappedErr, ok := err.(*errors.Error)
	if !ok {
	 wrappedErr = errors.Wrap(err, 0)
	}
	reportError(wrappedErr, true)
}

func (ch *clientHandler) Revoked(cred *irma.CredentialIdentifier) {
	dispatchCredentialsEvent()
}

func (ch *clientHandler) UpdateConfiguration(new *irma.IrmaIdentifierSet) {
	dispatchConfigurationEvent()
}

func (ch *clientHandler) UpdateAttributes() {
	dispatchCredentialsEvent()
}

func (ch *clientHandler) EnrollmentFailure(managerIdentifier irma.SchemeManagerIdentifier, plainErr error) {
	// Make sure the error is wrapped in a SessionError, so we only have one type to handle in irma_mobile
	err, ok := plainErr.(*irma.SessionError)
	if !ok {
		err = &irma.SessionError{ErrorType: irma.ErrorType("unknown"), Err: plainErr}
	}

	dispatchEvent(&enrollmentFailureEvent{
		SchemeManagerID: managerIdentifier,
		Error:           &sessionError{err},
	})
}

func (ch *clientHandler) EnrollmentSuccess(managerIdentifier irma.SchemeManagerIdentifier) {
	dispatchEnrollmentStatusEvent()
	dispatchEvent(&enrollmentSuccessEvent{
		SchemeManagerID: managerIdentifier,
	})
}

func (ch *clientHandler) ChangePinFailure(managerIdentifier irma.SchemeManagerIdentifier, plainErr error) {
	// Make sure the error is wrapped in a SessionError, so we only have one type to handle in irma_mobile
	err, ok := plainErr.(*irma.SessionError)
	if !ok {
		err = &irma.SessionError{ErrorType: irma.ErrorType("unknown"), Err: plainErr}
	}

	dispatchEvent(&changePinErrorEvent{
		SchemeManagerID: managerIdentifier,
		Error:           &sessionError{err},
	})
}

func (ch *clientHandler) ChangePinSuccess(managerIdentifier irma.SchemeManagerIdentifier) {
	dispatchEvent(&changePinSuccessEvent{
		SchemeManagerID: managerIdentifier,
	})
}

func (ch *clientHandler) ChangePinIncorrect(managerIdentifier irma.SchemeManagerIdentifier, remainingAttempts int) {
	dispatchEvent(&changePinFailedEvent{
		SchemeManagerID:   managerIdentifier,
		RemainingAttempts: remainingAttempts,
		Timeout:           0,
	})
}

func (ch *clientHandler) ChangePinBlocked(managerIdentifier irma.SchemeManagerIdentifier, timeout int) {
	dispatchEvent(&changePinFailedEvent{
		SchemeManagerID:   managerIdentifier,
		RemainingAttempts: 0,
		Timeout:           timeout,
	})
}
