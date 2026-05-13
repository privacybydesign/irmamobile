package irmagobridge

import (
	"github.com/privacybydesign/irmago/common/clientmodels"
)

type YiviSessionHandler struct {
}

func (handler *YiviSessionHandler) UpdateSession(session clientmodels.SessionState) {
	dispatchEvent(&sessionStateEvent{
		SessionState: session,
	})
	if session.Status == clientmodels.Status_Success ||
		session.Status == clientmodels.Status_Error ||
		session.Status == clientmodels.Status_Dismissed {
		dispatchCredentialsEvent()
	}
}
