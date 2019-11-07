package irmagobridge

import (
	"github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

type sessionHandler struct {
	sessionID         int
	dismisser         irmaclient.SessionDismisser
	permissionHandler irmaclient.PermissionHandler
	pinHandler        irmaclient.PinHandler
}

// TODO: Convert all the sendActions below to dispatchEvent
func sendAction(interface{}) {}

// SessionHandler implements irmaclient.Handler
var _ irmaclient.Handler = (*sessionHandler)(nil)

func (sh *sessionHandler) StatusUpdate(irmaAction irma.Action, status irma.Status) {
	action := &map[string]interface{}{
		"type":       "IrmaSession.StatusUpdate",
		"sessionId":  sh.sessionID,
		"irmaAction": irmaAction,
		"status":     status,
	}

	sendAction(action)
}

func (sh *sessionHandler) ClientReturnURLSet(clientReturnURL string) {
	action := &map[string]interface{}{
		"type":            "IrmaSession.ClientReturnURLSet",
		"sessionId":       sh.sessionID,
		"clientReturnUrl": clientReturnURL,
	}

	sendAction(action)
}

func (sh *sessionHandler) Success(result string) {
	action := &map[string]interface{}{
		"type":      "IrmaSession.Success",
		"sessionId": sh.sessionID,
		"result":    result,
	}

	sendAction(action)
}

func (sh *sessionHandler) Failure(err *irma.SessionError) {
	action := &map[string]interface{}{
		"type":      "IrmaSession.Failure",
		"sessionId": sh.sessionID,
		"error": &map[string]interface{}{
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

func (sh *sessionHandler) Cancelled() {
	action := &map[string]interface{}{
		"type":      "IrmaSession.Cancelled",
		"sessionId": sh.sessionID,
	}

	sendAction(action)
}

func (sh *sessionHandler) UnsatisfiableRequest(request irma.SessionRequest,
	serverName irma.TranslatedString, missing irmaclient.MissingAttributes) {
	action := &map[string]interface{}{
		"type":               "IrmaSession.UnsatisfiableRequest",
		"sessionId":          sh.sessionID,
		"serverName":         serverName,
		"missingDisclosures": missing,
		"disclosuresLabels":  request.Disclosure().Labels,
	}

	sendAction(action)
}

func (sh *sessionHandler) RequestIssuancePermission(request *irma.IssuanceRequest, candidates [][][]*irma.AttributeIdentifier, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	disclose := request.Disclose
	if disclose == nil {
		disclose = irma.AttributeConDisCon{}
	}
	action := &map[string]interface{}{
		"type":                  "IrmaSession.RequestIssuancePermission",
		"sessionId":             sh.sessionID,
		"serverName":            serverName,
		"issuedCredentials":     request.CredentialInfoList,
		"disclosures":           disclose,
		"disclosuresLabels":     request.Labels,
		"disclosuresCandidates": candidates,
	}

	sh.permissionHandler = ph
	sendAction(action)
}

func (sh *sessionHandler) RequestVerificationPermission(request *irma.DisclosureRequest, candidates [][][]*irma.AttributeIdentifier, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	action := &map[string]interface{}{
		"type":                  "IrmaSession.RequestVerificationPermission",
		"sessionId":             sh.sessionID,
		"serverName":            serverName,
		"disclosures":           request.Disclose,
		"disclosuresLabels":     request.Labels,
		"disclosuresCandidates": candidates,
	}

	sh.permissionHandler = ph
	sendAction(action)
}

func (sh *sessionHandler) RequestSignaturePermission(request *irma.SignatureRequest, candidates [][][]*irma.AttributeIdentifier, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	action := &map[string]interface{}{
		"type":                  "IrmaSession.RequestSignaturePermission",
		"sessionId":             sh.sessionID,
		"serverName":            serverName,
		"disclosures":           request.Disclose,
		"disclosuresLabels":     request.Labels,
		"disclosuresCandidates": candidates,
		"message":               request.Message,
	}

	sh.permissionHandler = ph
	sendAction(action)
}

func (sh *sessionHandler) RequestPin(remainingAttempts int, ph irmaclient.PinHandler) {
	action := &map[string]interface{}{
		"type":              "IrmaSession.RequestPin",
		"sessionId":         sh.sessionID,
		"remainingAttempts": remainingAttempts,
	}

	sh.pinHandler = ph
	sendAction(action)
}

func (sh *sessionHandler) RequestSchemeManagerPermission(manager *irma.SchemeManager, callback func(proceed bool)) {
	callback(false)
}

func (sh *sessionHandler) KeyshareEnrollmentMissing(manager irma.SchemeManagerIdentifier) {
	action := &map[string]interface{}{
		"type":            "IrmaSession.KeyshareEnrollmentMissing",
		"sessionId":       sh.sessionID,
		"schemeManagerId": manager,
	}

	sendAction(action)
}

func (sh *sessionHandler) KeyshareEnrollmentDeleted(manager irma.SchemeManagerIdentifier) {
	action := &map[string]interface{}{
		"type":            "IrmaSession.KeyshareEnrollmentDeleted",
		"sessionId":       sh.sessionID,
		"schemeManagerId": manager,
	}

	sendAction(action)
}

func (sh *sessionHandler) KeyshareBlocked(manager irma.SchemeManagerIdentifier, duration int) {
	action := &map[string]interface{}{
		"type":            "IrmaSession.KeyshareBlocked",
		"sessionId":       sh.sessionID,
		"schemeManagerId": manager,
		"duration":        duration,
	}

	sendAction(action)
}

func (sh *sessionHandler) KeyshareEnrollmentIncomplete(manager irma.SchemeManagerIdentifier) {
	action := &map[string]interface{}{
		"type":            "IrmaSession.KeyshareEnrollmentIncomplete",
		"sessionId":       sh.sessionID,
		"schemeManagerId": manager,
	}

	sendAction(action)
}
