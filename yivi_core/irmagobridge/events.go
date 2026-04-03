package irmagobridge

import (
	"encoding/json"

	"github.com/privacybydesign/irmago/client/clientsettings"
	"github.com/privacybydesign/irmago/common/clientmodels"
	"github.com/privacybydesign/irmago/irma"
)

// //
// Incoming events
// //
type enrollEvent struct {
	Email    *string                      `json:"email"`
	Pin      string                       `json:"pin"`
	Language string                       `json:"language"`
	SchemeID irma.SchemeManagerIdentifier `json:"scheme_id"`
}

type authenticateEvent struct {
	Pin      string                       `json:"pin"`
	SchemeID irma.SchemeManagerIdentifier `json:"scheme_id"`
}

type changePinEvent struct {
	OldPin string `json:"old_pin"`
	NewPin string `json:"new_pin"`
}

type newSessionEvent struct {
	Request json.RawMessage `json:"request"`
}

type sessionUserInteractionEvent struct {
	SessionId int                              `json:"session_id"`
	Type      clientmodels.UserInteractionType `json:"type"`
	Payload   json.RawMessage                  `json:"payload"`
}

type deleteCredentialEvent struct {
	HashByFormat map[clientmodels.CredentialFormat]string `json:"hash_by_format"`
}

type loadLogsEvent struct {
	Before *uint64 `json:"before"`
	Max    int     `json:"max"`
}

type clientPreferencesEvent struct {
	Preferences clientsettings.Preferences `json:"client_preferences"`
}

type installSchemeEvent struct {
	URL       string `json:"url"`
	PublicKey string `json:"public_key"`
}

type removeSchemeEvent struct {
	SchemeID irma.SchemeManagerIdentifier `json:"scheme_id"`
}

type removeRequestorSchemeEvent struct {
	SchemeID irma.RequestorSchemeIdentifier `json:"scheme_id"`
}

type installCertificateEvent struct {
	Type       string `json:"type"`
	PemContent string `json:"pem_content"`
}

// //
// Outgoing events
// //
type errorEvent struct {
	Exception string `json:"exception"`
	Stack     string `json:"stack"`
	Fatal     bool   `json:"fatal"`
}

type irmaConfigurationEvent struct {
	IrmaConfiguration *WrappedConfiguration `json:"irma_configuration"`
}

type eudiConfigurationEvent struct {
	EudiConfiguration *WrappedEudiConfiguration `json:"eudi_configuration"`
}

type schemalessCredentialsEvent struct {
	Credentials []*clientmodels.Credential `json:"credentials"`
}

type schemalessCredentialStoreEvent struct {
	Credentials []*clientmodels.CredentialStoreItem `json:"credentials"`
}

type enrollmentStatusEvent struct {
	EnrolledSchemeManagerIds   []irma.SchemeManagerIdentifier `json:"enrolled_scheme_manager_ids"`
	UnenrolledSchemeManagerIds []irma.SchemeManagerIdentifier `json:"unenrolled_scheme_manager_ids"`
}

type authenticationSuccessEvent struct{}

type authenticationFailedEvent struct {
	RemainingAttempts int `json:"remaining_attempts"`
	BlockedDuration   int `json:"blocked_duration"`
}

type authenticationErrorEvent struct {
	Error *sessionError `json:"error"`
}

type enrollmentFailureEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier `json:"scheme_manager_id"`
	Error           *sessionError                `json:"error"`
}

type enrollmentSuccessEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier `json:"scheme_manager_id"`
}

type changePinErrorEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier `json:"scheme_manager_id"`
	Error           *sessionError                `json:"error"`
}

type changePinSuccessEvent struct{}

type changePinFailedEvent struct {
	SchemeManagerID   irma.SchemeManagerIdentifier `json:"scheme_manager_id"`
	RemainingAttempts int                          `json:"remaining_attempts"`
	Timeout           int                          `json:"timeout"`
}

// //
// Session events
// //

type sessionStateEvent struct {
	SessionState clientmodels.SessionState `json:"session_state"`
}

type logsEvent struct {
	LogEntries []clientmodels.LogInfo `json:"log_entries"`
}

// //
// Embedded types
// //
type sessionError struct {
	*irma.SessionError
}

func (err *sessionError) MarshalJSON() ([]byte, error) {
	return json.Marshal(&map[string]any{
		"error_type":    err.ErrorType,
		"wrapped_error": err.WrappedError(),
		"info":          err.Info,
		"stack":         err.Stack(),
		"remote_status": err.RemoteStatus,
		"remote_error":  err.RemoteError,
	})
}
