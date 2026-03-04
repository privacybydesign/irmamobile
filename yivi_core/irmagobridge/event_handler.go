package irmagobridge

import (
	"fmt"
	"slices"

	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/client"
	"github.com/privacybydesign/irmago/irma"
	"github.com/privacybydesign/irmago/irma/irmaclient"
)

type eventHandler struct{}

// Enrollment to a keyshare server
func (ah *eventHandler) enroll(event *enrollEvent) (err error) {
	found := slices.Contains(yiviClient.UnenrolledSchemeManagers(), event.SchemeID)

	if !found {
		msg := fmt.Sprintf("no unenrolled scheme manager found with name %s", event.SchemeID)
		dispatchEvent(&enrollmentFailureEvent{
			SchemeManagerID: event.SchemeID,
			Error: &sessionError{&irma.SessionError{
				Err:       errors.New(msg),
				ErrorType: irma.ErrorUnknownSchemeManager,
				Info:      msg,
			}},
		})
		return
	}

	yiviClient.KeyshareEnroll(event.SchemeID, event.Email, event.Pin, event.Language)
	return
}

// Authenticate to the keyshare server to get access to the app
func (ah *eventHandler) authenticate(event *authenticateEvent) error {
	enrolled := false
	for _, schemeID := range yiviClient.EnrolledSchemeManagers() {
		if schemeID == event.SchemeID {
			enrolled = true
		}
	}

	if !enrolled {
		dispatchEvent(&authenticationErrorEvent{
			Error: &sessionError{&irma.SessionError{
				Err:       errors.Errorf("Can't verify PIN, not enrolled"),
				ErrorType: irma.ErrorUnknownSchemeManager,
				Info:      "Can't verify PIN, not enrolled",
			}},
		})
		return nil
	}

	go func() {
		defer recoverFromPanic("Handling authenticate event panicked")
		success, tries, blocked, err := yiviClient.KeyshareVerifyPin(event.Pin, event.SchemeID)
		if err != nil {
			serr, ok := err.(*irma.SessionError)
			if !ok {
				serr = &irma.SessionError{
					Err:       err,
					ErrorType: irma.ErrorType("unknown"),
					Info:      "Error while verifying PIN",
				}
			}
			dispatchEvent(&authenticationErrorEvent{
				Error: &sessionError{serr},
			})
		} else if success {
			dispatchEvent(&authenticationSuccessEvent{})
		} else {
			dispatchEvent(&authenticationFailedEvent{
				RemainingAttempts: tries,
				BlockedDuration:   blocked,
			})
		}
	}()

	return nil
}

// Change keyshare server PIN
func (ah *eventHandler) changePin(event *changePinEvent) (err error) {
	enrolled := yiviClient.EnrolledSchemeManagers()

	if len(enrolled) == 0 {
		return errors.Errorf("No enrolled scheme managers to change pin for")
	}

	yiviClient.KeyshareChangePin(event.OldPin, event.NewPin)
	return nil
}

// Start a new IRMA session
func (ah *eventHandler) newSession(event *newSessionEvent) (err error) {
	yiviClient.NewSession(string(event.Request))
	return nil
}

func (ah *eventHandler) respondAuthorizationCode(event *respondAuthorizationCodeEvent) error {
	// sh, err := ah.findSessionHandler(event.SessionID)
	// if err != nil {
	// 	return err
	// }
	// if sh.codeHandler == nil {
	// 	return errors.Errorf("Unset authorizationCodeHandler in RespondAuthorizationCode")
	// }
	//
	// go func() {
	// 	defer recoverFromPanic("Handling ResponseAuthorizationCode event panicked")
	// 	sh.codeHandler(event.Proceed, event.Code)
	// }()

	// TODO: Create new user interaction type in client.Client to handle this case
	return nil
}

func (ah *eventHandler) respondPreAuthorizedCodeFlowPermission(event *respondPreAuthorizedCodeFlowPermissionEvent) error {
	// sh, err := ah.findSessionHandler(event.SessionID)
	// if err != nil {
	// 	return err
	// }
	// if sh.preAuthCodePermissionHandler == nil {
	// 	return errors.Errorf("Unset preAuthCodePermissionHandler in RespondPreAuthorizedCodeFlowPermission")
	// }
	//
	// go func() {
	// 	defer recoverFromPanic("Handling ResponsePreAuthorizedCodePermission event panicked")
	// 	sh.preAuthCodePermissionHandler(event.Proceed, event.TransactionCode)
	// }()

	// TODO: Create new user interaction type in client.Client to handle this case
	return nil
}

// Responding to a permission prompt when disclosing, issuing or signing
func (ah *eventHandler) respondPermission(event *respondPermissionEvent) (err error) {
	yiviClient.HandleUserInteraction(client.SessionUserInteraction{
		SessionId: event.SessionID,
		Type:      client.UI_Permission,
		Payload:   event.SessionPermissionInteractionPayload,
	})
	return nil
}

// Responding to a request for a pin code
func (ah *eventHandler) respondPin(event *respondPinEvent) (err error) {
	yiviClient.HandleUserInteraction(client.SessionUserInteraction{
		SessionId: event.SessionID,
		Type:      client.UI_EnteredPin,
		Payload: client.PinInteractionPayload{
			Proceed: event.Proceed,
			Pin:     event.Pin,
		},
	})
	return nil
}

func (ah *eventHandler) clearAllData() (err error) {
	if err := yiviClient.RemoveStorage(); err != nil {
		return err
	}

	dispatchCredentialsEvent()
	dispatchEnrollmentStatusEvent()
	return nil
}

// Delete an individual credential
func (ah *eventHandler) deleteCredential(event *deleteCredentialEvent) error {
	if err := yiviClient.RemoveCredentialsByHash(event.HashByFormat); err != nil {
		return err
	}

	dispatchCredentialsEvent()
	return nil
}

// Dismiss the current session
func (ah *eventHandler) dismissSession(event *dismissSessionEvent) error {
	yiviClient.HandleUserInteraction(client.SessionUserInteraction{
		SessionId: event.SessionID,
		Type:      client.UI_DismissSession,
	})
	return nil
}

func (ah *eventHandler) updateSchemes() error {
	err := yiviClient.GetIrmaConfiguration().UpdateSchemes()
	if err != nil {
		return err
	}

	dispatchConfigurationEvent()
	return nil
}

func (ah *eventHandler) loadLogs(action *loadLogsEvent) error {
	var logEntries []irmaclient.LogInfo
	var err error

	// When before is not sent, it gets Go's default value 0 and 0 is never a valid id
	if action.Before == nil {
		logEntries, err = yiviClient.LoadNewestLogs(action.Max)
	} else {
		logEntries, err = yiviClient.LoadLogsBefore(*action.Before, action.Max)
	}
	if err != nil {
		return err
	}

	dispatchEvent(&logsEvent{
		LogEntries: logEntries,
	})

	return nil
}

func (ah *eventHandler) setPreferences(event *clientPreferencesEvent) error {
	yiviClient.SetPreferences(event.Preferences)
	return nil
}

func (ah *eventHandler) installScheme(event *installSchemeEvent) error {
	err := yiviClient.GetIrmaConfiguration().InstallScheme(event.URL, []byte(event.PublicKey))
	if err != nil {
		return err
	}
	dispatchConfigurationEvent()
	dispatchEnrollmentStatusEvent()
	return nil
}

func (ah *eventHandler) removeScheme(event *removeSchemeEvent) error {
	err := yiviClient.RemoveScheme(event.SchemeID)
	if err != nil {
		return err
	}
	dispatchConfigurationEvent()
	dispatchEnrollmentStatusEvent()
	return nil
}

func (ah *eventHandler) removeRequestorScheme(event *removeRequestorSchemeEvent) error {
	err := yiviClient.RemoveRequestorScheme(event.SchemeID)
	if err != nil {
		return err
	}
	dispatchConfigurationEvent()
	return nil
}

func (ah *eventHandler) installCertificate(event *installCertificateEvent) error {
	conf := yiviClient.GetEudiConfiguration()

	switch event.Type {
	case "issuer":
		if err := conf.Issuers.InstallCertificate([]byte(event.PemContent)); err != nil {
			return err
		}
	case "verifier":
		if err := conf.Verifiers.InstallCertificate([]byte(event.PemContent)); err != nil {
			return err
		}
	}

	// Reload configuration to pick up the new certificate
	conf.Reload()

	dispatchConfigurationEvent()
	return nil
}
