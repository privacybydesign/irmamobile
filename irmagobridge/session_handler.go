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

func (sh *sessionHandler) RequestIssuancePermission(request *irma.IssuanceRequest, satisfiable bool, candidates [][]irmaclient.DisclosureCandidates, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	disclose := request.Disclose
	if disclose == nil {
		disclose = irma.AttributeConDisCon{}
	}

	sh.permissionHandler = ph
	dispatchEvent(&requestIssuancePermissionSessionEvent{
		SessionID:             sh.sessionID,
		ServerName:            serverName,
		Satisfiable:           satisfiable,
		IssuedCredentials:     request.CredentialInfoList,
		Disclosures:           disclose,
		DisclosuresLabels:     request.Labels,
		DisclosuresCandidates: candidates,
	})
}

func (sh *sessionHandler) RequestVerificationPermission(request *irma.DisclosureRequest, satisfiable bool, candidates [][]irmaclient.DisclosureCandidates, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	action := &requestVerificationPermissionSessionEvent{
		SessionID:             sh.sessionID,
		ServerName:            serverName,
		Satisfiable:           satisfiable,
		Disclosures:           request.Disclose,
		DisclosuresLabels:     request.Labels,
		DisclosuresCandidates: candidates,
		IsSignatureSession:    false,
	}

	sh.permissionHandler = ph
	dispatchEvent(action)
}

func (sh *sessionHandler) RequestSignaturePermission(request *irma.SignatureRequest, satisfiable bool, candidates [][]irmaclient.DisclosureCandidates, serverName irma.TranslatedString, ph irmaclient.PermissionHandler) {
	sh.permissionHandler = ph
	dispatchEvent(&requestVerificationPermissionSessionEvent{
		SessionID:             sh.sessionID,
		ServerName:            serverName,
		Satisfiable:           satisfiable,
		Disclosures:           request.Disclose,
		DisclosuresLabels:     request.Labels,
		DisclosuresCandidates: candidates,
		IsSignatureSession:    true,
		SignedMessage:         request.Message,
	})
}

func (sh *sessionHandler) RequestPin(remainingAttempts int, ph irmaclient.PinHandler) {
	sh.pinHandler = ph
	dispatchEvent(&requestPinSessionEvent{
		SessionID:         sh.sessionID,
		RemainingAttempts: remainingAttempts,
	})
}

func (sh *sessionHandler) RequestSchemeManagerPermission(manager *irma.SchemeManager, callback func(proceed bool)) {
	callback(false)
}

func (sh *sessionHandler) KeyshareEnrollmentMissing(manager irma.SchemeManagerIdentifier) {
	dispatchEvent(&keyshareEnrollmentMissingSessionEvent{
		SessionID:       sh.sessionID,
		SchemeManagerID: manager,
	})
}

func (sh *sessionHandler) KeyshareEnrollmentDeleted(manager irma.SchemeManagerIdentifier) {
	dispatchEvent(&keyshareEnrollmentDeletedSessionEvent{
		SessionID:       sh.sessionID,
		SchemeManagerID: manager,
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
