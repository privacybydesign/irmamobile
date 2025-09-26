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
	SchemeID irma.SchemeManagerIdentifier
}

type authenticateEvent struct {
	Pin      string
	SchemeID irma.SchemeManagerIdentifier
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
	HashByFormat map[irmaclient.CredentialFormat]string
}

type dismissSessionEvent struct {
	SessionID int
}

type loadLogsEvent struct {
	Before *uint64
	Max    int
}

type clientPreferencesEvent struct {
	Preferences irmaclient.Preferences
}

type getIssueWizardContentsEvent struct {
	ID irma.IssueWizardIdentifier
}

type installSchemeEvent struct {
	URL       string
	PublicKey string
}

type removeSchemeEvent struct {
	SchemeID irma.SchemeManagerIdentifier
}

type removeRequestorSchemeEvent struct {
	SchemeID irma.RequestorSchemeIdentifier
}

// //
// Outgoing events
// //
type errorEvent struct {
	Exception string
	Stack     string
	Fatal     bool
}

type irmaConfigurationEvent struct {
	IrmaConfiguration *WrappedConfiguration
}

type credentialsEvent struct {
	Credentials irma.CredentialInfoList
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
	Error           *sessionError
}

type enrollmentSuccessEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
}

type changePinErrorEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
	Error           *sessionError
}

type changePinSuccessEvent struct{}

type changePinFailedEvent struct {
	SchemeManagerID   irma.SchemeManagerIdentifier
	RemainingAttempts int
	Timeout           int
}

type issueWizardContentsEvent struct {
	ID             irma.IssueWizardIdentifier
	WizardContents []irma.IssueWizardItem
}

// //
// Session events
// //

// TODO: serverName as a TranslatedString doesn't make much sense
type statusUpdateSessionEvent struct {
	SessionID int
	Action    irma.Action
	Status    irma.ClientStatus
}

type clientReturnURLSetSessionEvent struct {
	SessionID       int
	ClientReturnURL string
}

type successSessionEvent struct {
	SessionID int
}

type failureSessionEvent struct {
	SessionID int
	Error     *sessionError
}

type canceledSessionEvent struct {
	SessionID int
}

type rawMultiFormatCredential struct {
	ID              string
	IssuerID        string
	SchemeManagerID string
	Revoked         bool
	Attributes      map[irma.AttributeTypeIdentifier]irma.TranslatedString
	HashByFormat    map[irmaclient.CredentialFormat]string
	SignedOn        irma.Timestamp
	Expires         irma.Timestamp
	InstanceCount   *uint
}

type requestIssuancePermissionSessionEvent struct {
	SessionID             int
	ServerName            *irma.RequestorInfo
	Satisfiable           bool
	IssuedCredentials     []rawMultiFormatCredential
	Disclosures           irma.AttributeConDisCon
	DisclosuresLabels     map[int]irma.TranslatedString
	DisclosuresCandidates [][]irmaclient.DisclosureCandidates
}

type requestVerificationPermissionSessionEvent struct {
	SessionID             int
	ServerName            *irma.RequestorInfo
	Satisfiable           bool
	Disclosures           irma.AttributeConDisCon
	DisclosuresLabels     map[int]irma.TranslatedString
	DisclosuresCandidates [][]irmaclient.DisclosureCandidates
	IsSignatureSession    bool
	SignedMessage         string
}

type requestPinSessionEvent struct {
	SessionID         int
	RemainingAttempts int
}

type pairingRequiredSessionEvent struct {
	SessionID   int
	PairingCode string
}

type keyshareEnrollmentMissingSessionEvent struct {
	SessionID       int
	SchemeManagerID irma.SchemeManagerIdentifier
}

type keyshareEnrollmentDeletedSessionEvent struct {
	SessionID       int
	SchemeManagerID irma.SchemeManagerIdentifier
}

type keyshareBlockedSessionEvent struct {
	SessionID       int
	SchemeManagerID irma.SchemeManagerIdentifier
	Duration        int
}

type keyshareEnrollmentIncompleteSessionEvent struct {
	SessionID       int
	SchemeManagerID irma.SchemeManagerIdentifier
}

type logsEvent struct {
	LogEntries []irmaclient.LogInfo
}

// //
// Embedded types
// //
type sessionError struct {
	*irma.SessionError
}

func (err *sessionError) MarshalJSON() ([]byte, error) {
	return json.Marshal(&map[string]interface{}{
		"ErrorType":    err.ErrorType,
		"WrappedError": err.WrappedError(),
		"Info":         err.Info,
		"Stack":        err.Stack(),
		"RemoteStatus": err.RemoteStatus,
		"RemoteError":  err.RemoteError,
	})
}
