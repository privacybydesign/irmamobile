package irmagobridge

import (
	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/client"
	"github.com/privacybydesign/irmago/irma"
)

// compile-time type-check ClientHandler to implement client.ClientHandler
var _ client.ClientHandler = (*YiviClientHandler)(nil)

type YiviClientHandler struct {
}

func (i *YiviClientHandler) ReportError(err error) {
	wrappedErr, ok := err.(*errors.Error)
	if !ok {
		wrappedErr = errors.Wrap(err, 0)
	}
	reportError(wrappedErr, false)
}

// CredentialsChanged is the client's single "what you are showing is stale"
// signal: an issuance, a revocation status that moved either way, or a logo
// that finished downloading. It names no credential, so the app re-reads the
// whole list.
//
// Recovered here because every caller is an irmago goroutine that does not
// recover: the scheduled status sweep (gocron swallows the panic and reports it
// nowhere), the logo-backfill worker, and the witness-update job.
func (ch *YiviClientHandler) CredentialsChanged() {
	defer recoverFromPanic("CredentialsChanged panicked")
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
