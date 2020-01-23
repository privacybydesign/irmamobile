package irmagobridge

import (
	irma "github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

type sessionHandler struct {
	sessionID         int
	dismisser         irmaclient.SessionDismisser
	permissionHandler irmaclient.PermissionHandler
	pinHandler        irmaclient.PinHandler
}

// SessionHandler implements irmaclient.Handler
var _ irmaclient.Handler = (*sessionHandler)(nil)

func (sh *sessionHandler) StatusUpdate(action irma.Action, status irma.Status) {
	dispatchEvent(&statusUpdateSessionEvent{
		SessionID: sh.sessionID,
		Action:    action,
		Status:    status,
	})
}

func (sh *sessionHandler) ClientReturnURLSet(clientReturnURL string) {
	dispatchEvent(&clientReturnURLSetSessionEvent{
		SessionID:       sh.sessionID,
		ClientReturnURL: clientReturnURL,
	})
}

func (sh *sessionHandler) Success(result string) {
	dispatchEvent(&successSessionEvent{
		SessionID: sh.sessionID,
		Result:    result,
	})
}

func (sh *sessionHandler) Failure(err *irma.SessionError) {
	dispatchEvent(&failureSessionEvent{
		SessionID: sh.sessionID,
		Error:     &sessionError{err},
	})
}

func (sh *sessionHandler) Cancelled() {
	dispatchEvent(&canceledSessionEvent{
		SessionID: sh.sessionID,
	})
}

func (sh *sessionHandler) UnsatisfiableRequest(request irma.SessionRequest,
	serverName irma.TranslatedString, missing irmaclient.MissingAttributes) {
	dispatchEvent(&unsatisfiableRequestSessionEvent{
		SessionID:          sh.sessionID,
		ServerName:         serverName,
		MissingDisclosures: missing,
		DisclosuresLabels:  request.Disclosure().Labels,
	})
}

func (sh *sessionHandler) RequestIssuancePermission(request *irma.IssuanceRequest, candidates [][][]*irma.AttributeIdentifier, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	disclose := request.Disclose
	if disclose == nil {
		disclose = irma.AttributeConDisCon{}
	}

	sh.permissionHandler = ph
	dispatchEvent(&requestIssuancePermissionSessionEvent{
		SessionID:             sh.sessionID,
		ServerName:            serverName,
		IssuedCredentials:     request.CredentialInfoList,
		Disclosures:           disclose,
		DisclosuresLabels:     request.Labels,
		DisclosuresCandidates: candidates,
	})
}

func (sh *sessionHandler) RequestVerificationPermission(request *irma.DisclosureRequest, candidates [][][]*irma.AttributeIdentifier, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	action := &requestVerificationPermissionSessionEvent{
		SessionID:             sh.sessionID,
		ServerName:            serverName,
		Disclosures:           request.Disclose,
		DisclosuresLabels:     request.Labels,
		DisclosuresCandidates: candidates,
	}

	sh.permissionHandler = ph
	dispatchEvent(action)
}

func (sh *sessionHandler) RequestSignaturePermission(request *irma.SignatureRequest, candidates [][][]*irma.AttributeIdentifier, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	sh.permissionHandler = ph
	dispatchEvent(&requestSignaturePermissionSessionEvent{
		SessionID:             sh.sessionID,
		ServerName:            serverName,
		Disclosures:           request.Disclose,
		DisclosuresLabels:     request.Labels,
		DisclosuresCandidates: candidates,
		Message:               request.Message,
	})
}

func (sh *sessionHandler) RequestPin(remainingAttempts int, ph irmaclient.PinHandler) {
	sh.pinHandler = ph
	dispatchEvent(&requestPinSessionEvent{
		sessionID:         sh.sessionID,
		remainingAttempts: remainingAttempts,
	})
}

func (sh *sessionHandler) RequestSchemeManagerPermission(manager *irma.SchemeManager, callback func(proceed bool)) {
	callback(false)
}

func (sh *sessionHandler) KeyshareEnrollmentMissing(manager irma.SchemeManagerIdentifier) {
	dispatchEvent(&keyshareEnrollmentMissingSessionEvent{
		sessionID:       sh.sessionID,
		schemeManagerID: manager,
	})
}

func (sh *sessionHandler) KeyshareEnrollmentDeleted(manager irma.SchemeManagerIdentifier) {
	dispatchEvent(&keyshareEnrollmentDeletedSessionEvent{
		sessionID:       sh.sessionID,
		schemeManagerID: manager,
	})
}

func (sh *sessionHandler) KeyshareBlocked(manager irma.SchemeManagerIdentifier, duration int) {
	dispatchEvent(&keyshareBlockedSessionEvent{
		SessionID:       sh.sessionID,
		SchemeManagerID: manager,
		Duration:        duration,
	})
}

func (sh *sessionHandler) KeyshareEnrollmentIncomplete(manager irma.SchemeManagerIdentifier) {
	dispatchEvent(&keyshareEnrollmentIncompleteSessionEvent{
		SessionID:       sh.sessionID,
		SchemeManagerID: manager,
	})
}
