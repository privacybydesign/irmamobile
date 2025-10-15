package irmagobridge

import (
	irma "github.com/privacybydesign/irmago"
	"github.com/privacybydesign/irmago/irmaclient"
)

type sessionHandler struct {
	sessionID                int
	dismisser                irmaclient.SessionDismisser
	permissionHandler        irmaclient.PermissionHandler
	authorizationCodeHandler irmaclient.AuthorizationCodeHandler
	pinHandler               irmaclient.PinHandler
}

// SessionHandler implements irmaclient.Handler
var _ irmaclient.Handler = (*sessionHandler)(nil)

func (sh *sessionHandler) StatusUpdate(action irma.Action, status irma.ClientStatus) {
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
	dispatchCredentialsEvent()
}

func (sh *sessionHandler) Failure(err *irma.SessionError) {
	dispatchEvent(&failureSessionEvent{
		SessionID: sh.sessionID,
		Error:     &sessionError{err},
	})
	dispatchCredentialsEvent()
}

func (sh *sessionHandler) Cancelled() {
	dispatchEvent(&canceledSessionEvent{
		SessionID: sh.sessionID,
	})
	dispatchCredentialsEvent()
}

func (sh *sessionHandler) RequestIssuancePermission(request *irma.IssuanceRequest, satisfiable bool, candidates [][]irmaclient.DisclosureCandidates, serverName *irma.RequestorInfo, ph irmaclient.PermissionHandler) {
	disclose := request.Disclose
	if disclose == nil {
		disclose = irma.AttributeConDisCon{}
	}

	sh.permissionHandler = ph

	issuedCreds := []rawMultiFormatCredential{}
	for _, cred := range request.CredentialInfoList {
		mfCred := rawMultiFormatCredential{
			ID:              cred.ID,
			IssuerID:        cred.IssuerID,
			SchemeManagerID: cred.SchemeManagerID,
			Revoked:         cred.Revoked,
			Attributes:      cred.Attributes,
			HashByFormat: map[irmaclient.CredentialFormat]string{
				irmaclient.Format_Idemix: cred.Hash,
			},
			SignedOn:      cred.SignedOn,
			Expires:       cred.Expires,
			InstanceCount: cred.InstanceCount,
		}

		if cred.InstanceCount != nil {
			attrs := map[string]any{}
			for id, att := range cred.Attributes {
				attrs[id.Name()] = att[""]
			}

			hash, err := irmaclient.CreateHashForSdJwtVc(cred.Identifier().String(), attrs)
			if err == nil {
				mfCred.HashByFormat[irmaclient.Format_SdJwtVc] = hash
			}
		}

		issuedCreds = append(issuedCreds, mfCred)
	}

	dispatchEvent(&requestIssuancePermissionSessionEvent{
		SessionID:             sh.sessionID,
		ServerName:            serverName,
		Satisfiable:           satisfiable,
		IssuedCredentials:     issuedCreds,
		Disclosures:           disclose,
		DisclosuresLabels:     request.Labels,
		DisclosuresCandidates: candidates,
	})
}

func (sh *sessionHandler) RequestAuthorizationCodeFlowIssuancePermission(
	request *irma.AuthorizationCodeIssuanceRequest,
	requestorInfo *irma.RequestorInfo,
	ph irmaclient.AuthorizationCodeHandler,
) {
	action := requestAuthorizationCodeFlowIssuancePermission{
		SessionID:           sh.sessionID,
		AuthorizationServer: request.AuthorizationServer,
		CredentialInfoList:  request.CredentialInfoList,
	}
	sh.authorizationCodeHandler = ph
	dispatchEvent(action)
}

func (sh *sessionHandler) RequestVerificationPermission(request *irma.DisclosureRequest, satisfiable bool, candidates [][]irmaclient.DisclosureCandidates, serverName *irma.RequestorInfo, ph irmaclient.PermissionHandler) {
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

func (sh *sessionHandler) RequestSignaturePermission(request *irma.SignatureRequest, satisfiable bool, candidates [][]irmaclient.DisclosureCandidates, serverName *irma.RequestorInfo, ph irmaclient.PermissionHandler) {
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

func (sh *sessionHandler) PairingRequired(pairingCode string) {
	dispatchEvent(&pairingRequiredSessionEvent{
		SessionID:   sh.sessionID,
		PairingCode: pairingCode,
	})
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
