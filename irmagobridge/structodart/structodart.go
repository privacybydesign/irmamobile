package main

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strings"

	"github.com/privacybydesign/gabi/big"
	irma "github.com/privacybydesign/irmago"
	irmaclient "github.com/privacybydesign/irmago/irmaclient"
)

func main() {
	structs := []interface{}{
		irmaclient.DisclosureCandidate{},
		requestVerificationPermissionSessionEvent{},
		requestIssuancePermissionSessionEvent{},
	}

	for i := 0; i < len(structs); i++ {
		fmt.Println(structToDart(structs[i]))
	}

}

func structToDart(x interface{}) string {
	t := reflect.TypeOf(x)
	for t.Kind() == reflect.Ptr || t.Kind() == reflect.Interface {
		// dereference pointers or interfaces
		t = t.Elem()
	}
	if t.Kind() != reflect.Struct {
		panic("only structs supported")
	}
	return fmt.Sprintf("@JsonSerializable()\nclass %s {\n  %s\n%s\n%s}\n", strings.Title(t.Name()), memberInitializer(t), members(t), jsonGenerator(t))
}

func memberInitializer(t reflect.Type) string {
	b := strings.Builder{}

	b.WriteString(strings.Title(t.Name()) + "({")
	for i := 0; i < t.NumField(); i++ {
		b.WriteString("this." + detitle(t.Field(i).Name))

		if i < t.NumField()-1 {
			b.WriteString(", ")
		}
	}
	b.WriteString("});\n")
	return b.String()
}

func members(t reflect.Type) string {
	b := strings.Builder{}
	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)

		b.WriteString("  ")
		b.WriteString("@JsonKey(name: '" + field.Name + "')")
		b.WriteString("\n")

		if field.Type.Kind() == reflect.Struct && field.Anonymous {
			// if the field is anonymous, embed its fields
			b.WriteString(members(field.Type))
		} else {
			b.WriteString("  final ")
			b.WriteString(member(field))
			b.WriteString("\n")

			if i < t.NumField()-1 {
				b.WriteString("\n")
			}
		}
	}
	return b.String()
}

func jsonGenerator(t reflect.Type) string {
	b := strings.Builder{}
	className := strings.Title(t.Name())

	b.WriteString("  factory " + className + ".fromJson(Map<String, dynamic> json) => _$" + className + "FromJson(json);\n")
	b.WriteString("  Map<String, dynamic> toJson() => _$" + className + "ToJson(this);\n")
	return b.String()
}

// ---

func member(field reflect.StructField) string {
	return typename(field.Type) + " " + detitle(field.Name) + ";"
}

func typename(typ reflect.Type) string {
	switch typ.Kind() {
	case reflect.Struct:
		return typ.Name()
	case reflect.Ptr:
		switch typ {
		case reflect.TypeOf((*big.Int)(nil)):
			return "BigInt"
		}
		return typename(typ.Elem()) // discard pointer, just use its type
	case reflect.String:
		return "String"
	case reflect.Slice, reflect.Array:
		return "List<" + typename(typ.Elem()) + ">"
	case reflect.Map:
		return fmt.Sprintf("Map<%s, %s>", typename(typ.Key()), typename(typ.Elem()))
	case reflect.Interface:
		// Type is unknown at compile time
		// Instead we could also (1) panic, or (2) emit the interface name,
		// and then elsewhere also emit a Dart interface definition
		return "dynamic"
	case reflect.Func, reflect.Chan, reflect.Invalid:
		panic("unsupported type: " + typ.Kind().String())
	default:
		// don't know what can end up here, so always check the output
		return typ.Name()
	}
}

func detitle(s string) string {
	return strings.ToLower(s[0:1]) + s[1:]
}

/// -----

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
	Path            string
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
	Error           *sessionError
}

type enrollmentSuccessEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
}

type changePinFailureEvent struct {
	SchemeManagerID irma.SchemeManagerIdentifier
	Error           *sessionError
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
// Session events
// //

// TODO: serverName as a TranslatedString doesn't make much sense
type statusUpdateSessionEvent struct {
	SessionID int
	Action    irma.Action
	Status    irma.Status
}

type clientReturnURLSetSessionEvent struct {
	SessionID       int
	ClientReturnURL string
}

type successSessionEvent struct {
	SessionID int
	Result    string
}

type failureSessionEvent struct {
	SessionID int
	Error     *sessionError
}

type canceledSessionEvent struct {
	SessionID int
}

type requestIssuancePermissionSessionEvent struct {
	SessionID             int
	ServerName            irma.TranslatedString
	Satisfiable           bool
	IssuedCredentials     irma.CredentialInfoList
	Disclosures           irma.AttributeConDisCon
	DisclosuresLabels     map[int]irma.TranslatedString
	DisclosuresCandidates [][]irmaclient.DisclosureCandidates
}

type requestVerificationPermissionSessionEvent struct {
	SessionID             int
	ServerName            irma.TranslatedString
	Satisfiable           bool
	Disclosures           irma.AttributeConDisCon
	DisclosuresLabels     map[int]irma.TranslatedString
	DisclosuresCandidates [][]irmaclient.DisclosureCandidates
	IsSignatureSession    bool
	SignedMessage         string
}

type requestPinSessionEvent struct {
	sessionID         int
	remainingAttempts int
}

type keyshareEnrollmentMissingSessionEvent struct {
	sessionID       int
	schemeManagerID irma.SchemeManagerIdentifier
}

type keyshareEnrollmentDeletedSessionEvent struct {
	sessionID       int
	schemeManagerID irma.SchemeManagerIdentifier
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
