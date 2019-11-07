package irmagobridge

import (
	"encoding/json"

	irma "github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

// //
// Incoming events
// //
type enrollEvent struct {
	Email    *string
	Pin      string
	Language string
}

type authenticateEvent struct {
	Pin string
}

type changePinEvent struct {
	OldPin string
	NewPin string
}

type newSessionEvent struct {
	SessionID int
	Request   json.RawMessage
}

type respondPermissionEvent struct {
	SessionID         int
	Proceed           bool
	DisclosureChoices [][]*irma.AttributeIdentifier
}

type respondPinEvent struct {
	SessionID int
	Proceed   bool
	Pin       string
}

type deleteCredentialEvent struct {
	Hash string
}

type dismissSessionEvent struct {
	SessionID int
}

type setCrashReportingPreferenceEvent struct {
	EnableCrashReporting bool
}

// //
// Outgoing events
// //
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

type authenticationSuccessEvent struct{}

type authenticationFailedEvent struct {
	RemainingAttempts int
	BlockedDuration   int
}

type authenticationErrorEvent struct {
	Error *sessionError
}

type enrollmentFailureEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
	error           *sessionError
}

type enrollmentSuccessEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
}

type changePinFailureEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
	error           *sessionError
}

type changePinSuccessEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
}

type changePinIncorrect struct {
	SchemeManagerID   irma.SchemeManagerIdentifier
	RemainingAttempts int
}

type changePinBlocked struct {
	SchemeManagerID irma.SchemeManagerIdentifier
	Timeout         int
}

// //
// Embedded types
// //
type sessionError struct {
	*irma.SessionError
}

func (err *sessionError) marshalSessionError() ([]byte, error) {
	return json.Marshal(&map[string]interface{}{
		"ErrorType":    err.ErrorType,
		"WrappedError": err.WrappedError(),
		"Info":         err.Info,
		"Stack":        err.Stack(),
		"RemoteStatus": err.RemoteStatus,
		"RemoteError":  err.RemoteError,
	})
}
