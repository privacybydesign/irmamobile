package irmagobridge

import (
	"encoding/json"
	"github.com/privacybydesign/irmago/client"

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
	SessionId int             `json:"session_id"`
	Request   json.RawMessage `json:"request"`
}

// previewSessionEvent asks what a session pointer would start, without
// starting it (the lock screen shows it while the session waits for the PIN).
type previewSessionEvent struct {
	Key     string          `json:"key"`
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

// The activity log is asked for with request/response pairs: each request
// carries a request id, which its answer echoes, so the app can have several
// questions out at once (the Activity tab and a card's details).

type queryLogsEvent struct {
	RequestId string                `json:"request_id"`
	Query     clientmodels.LogQuery `json:"query"`
}

type getLogEvent struct {
	RequestId string `json:"request_id"`
	Id        string `json:"id"`
}

type credentialActivityEvent struct {
	RequestId string   `json:"request_id"`
	Hashes    []string `json:"hashes"`
}

// countLogsEvent asks how many entries each filter matches: the app fades
// the options of its filter sheet that would match nothing.
type countLogsEvent struct {
	RequestId string                   `json:"request_id"`
	Filters   []clientmodels.LogFilter `json:"filters"`
}

type listPartiesEvent struct {
	RequestId string                 `json:"request_id"`
	Filter    clientmodels.LogFilter `json:"filter"`
	Limit     int                    `json:"limit"`
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

type removeCertificateEvent struct {
	Type       string `json:"type"`
	Thumbprint string `json:"thumbprint"`
}

type setLocaleEvent struct {
	Locale string `json:"locale"`
}

// //
// Outgoing events
// //
type errorEvent struct {
	Exception string `json:"exception"`
	Stack     string `json:"stack"`
	Fatal     bool   `json:"fatal"`
}

// sessionPreviewEvent answers a previewSessionEvent with the same key.
type sessionPreviewEvent struct {
	Key     string                 `json:"key"`
	Preview *client.SessionPreview `json:"preview"`
}

type irmaConfigurationEvent struct {
	IrmaConfiguration *WrappedConfiguration `json:"irma_configuration"`
}

type eudiConfigurationEvent struct {
	EudiConfiguration *WrappedEudiConfiguration `json:"eudi_configuration"`
}

type schemalessCredentialsEvent struct {
	Credentials []*clientmodels.Credential            `json:"credentials"`
	Problematic []*clientmodels.ProblematicCredential `json:"problematic"`
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

// logPageEvent answers a queryLogsEvent.
type logPageEvent struct {
	RequestId string               `json:"request_id"`
	Page      clientmodels.LogPage `json:"page"`
	Error     string               `json:"error,omitempty"`
}

// logEntryEvent answers a getLogEvent; Entry is nil when there is none.
type logEntryEvent struct {
	RequestId string                `json:"request_id"`
	Entry     *clientmodels.LogInfo `json:"entry"`
	Error     string                `json:"error,omitempty"`
}

// credentialActivityResultEvent answers a credentialActivityEvent.
type credentialActivityResultEvent struct {
	RequestId string                                     `json:"request_id"`
	Activity  map[string]clientmodels.CredentialActivity `json:"activity"`
	Error     string                                     `json:"error,omitempty"`
}

// logCountsEvent answers a countLogsEvent, one count per filter, in order.
type logCountsEvent struct {
	RequestId string `json:"request_id"`
	Counts    []int  `json:"counts"`
	Error     string `json:"error,omitempty"`
}

// partiesEvent answers a listPartiesEvent.
type partiesEvent struct {
	RequestId string                      `json:"request_id"`
	Parties   []clientmodels.PartySummary `json:"parties"`
	Error     string                      `json:"error,omitempty"`
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
