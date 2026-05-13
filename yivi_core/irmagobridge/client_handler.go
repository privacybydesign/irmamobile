package irmagobridge

import (
	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/irma"
	"github.com/privacybydesign/irmago/irma/irmaclient"
)

// compile-time type-check ClientHandler to implement irmaclient.ClientHandler
var _ irmaclient.ClientHandler = (*YiviClientHandler)(nil)

type YiviClientHandler struct {
}

func (i *YiviClientHandler) ReportError(err error) {
	wrappedErr, ok := err.(*errors.Error)
	if !ok {
		wrappedErr = errors.Wrap(err, 0)
	}
	reportError(wrappedErr, false)
}

func (ch *YiviClientHandler) Revoked(cred *irma.CredentialIdentifier) {
	dispatchCredentialsEvent()
}

func (ch *YiviClientHandler) UpdateConfiguration(new *irma.IrmaIdentifierSet) {
	dispatchConfigurationEvent()
}

func (ch *YiviClientHandler) UpdateAttributes() {
	dispatchCredentialsEvent()
}

func (ch *YiviClientHandler) EnrollmentFailure(managerIdentifier irma.SchemeManagerIdentifier, plainErr error) {
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

func (ch *YiviClientHandler) EnrollmentSuccess(managerIdentifier irma.SchemeManagerIdentifier) {
	dispatchEnrollmentStatusEvent()
	dispatchEvent(&enrollmentSuccessEvent{
		SchemeManagerID: managerIdentifier,
	})
}

func (ch *YiviClientHandler) ChangePinFailure(managerIdentifier irma.SchemeManagerIdentifier, plainErr error) {
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

func (ch *YiviClientHandler) ChangePinSuccess() {
	dispatchEvent(&changePinSuccessEvent{})
}

func (ch *YiviClientHandler) ChangePinIncorrect(managerIdentifier irma.SchemeManagerIdentifier, remainingAttempts int) {
	dispatchEvent(&changePinFailedEvent{
		SchemeManagerID:   managerIdentifier,
		RemainingAttempts: remainingAttempts,
		Timeout:           0,
	})
}

func (ch *YiviClientHandler) ChangePinBlocked(managerIdentifier irma.SchemeManagerIdentifier, timeout int) {
	dispatchEvent(&changePinFailedEvent{
		SchemeManagerID:   managerIdentifier,
		RemainingAttempts: 0,
		Timeout:           timeout,
	})
}
