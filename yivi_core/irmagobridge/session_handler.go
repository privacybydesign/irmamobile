package irmagobridge

import (
	"github.com/privacybydesign/irmago/client"
)

type YiviSessionHandler struct {
}

func (handler *YiviSessionHandler) UpdateSession(session client.SessionState) {
	dispatchEvent(&sessionStateEvent{
		SessionState: session,
	})
	if session.Status == client.Status_Success ||
		session.Status == client.Status_Error ||
		session.Status == client.Status_Dismissed {
		dispatchCredentialsEvent()
	}
}
