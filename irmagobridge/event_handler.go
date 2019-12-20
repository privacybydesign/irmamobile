package irmagobridge

import (
	"github.com/go-errors/errors"
	irma "github.com/privacybydesign/irmago"
)

type eventHandler struct {
	sessionLookup map[int]*sessionHandler
}

// Enrollment to a keyshare server
func (ah *eventHandler) enroll(event *enrollEvent) (err error) {
	unenrolled := client.UnenrolledSchemeManagers()

	if len(unenrolled) == 0 {
		return errors.Errorf("No unenrolled scheme manager available to enroll with")
	}

	// Irmago doesn't actually support multiple scheme managers with keyshare enrollment,
	// so we just pick the first unenrolled, which should be PBDF production
	client.KeyshareEnroll(unenrolled[0], event.Email, event.Pin, event.Language)
	return nil
}

// Authenticate to the keyshare server to get access to the app
func (ah *eventHandler) authenticate(event *authenticateEvent) (err error) {
	enrolled := client.EnrolledSchemeManagers()
	if len(enrolled) == 0 {
		dispatchEvent(&authenticationErrorEvent{
			Error: &sessionError{&irma.SessionError{
				Err:       errors.Errorf("Can't verify PIN, not enrolled"),
				ErrorType: irma.ErrorUnknownSchemeManager,
				Info:      "Can't verify PIN, not enrolled",
			}},
		})

		return
	}

	go func() {
		success, tries, blocked, err := client.KeyshareVerifyPin(event.Pin, enrolled[0])
		if err != nil {
			dispatchEvent(&authenticationErrorEvent{
				Error: &sessionError{err.(*irma.SessionError)},
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
	enrolled := client.EnrolledSchemeManagers()

	if len(enrolled) == 0 {
		return errors.Errorf("No enrolled scheme managers to change pin for")
	}

	// Irmago doesn't actually support multiple scheme managers with keyshare enrollment,
	// so we just pick the first enrolled, which should be PBDF production
	client.KeyshareChangePin(enrolled[0], event.OldPin, event.NewPin)
	return nil
}

// Start a new IRMA session
func (ah *eventHandler) newSession(event *newSessionEvent) (err error) {
	if event.SessionID < 1 {
		return errors.Errorf("Session id should be provided and larger than zero")
	}

	sessionHandler := &sessionHandler{sessionID: event.SessionID}
	ah.sessionLookup[sessionHandler.sessionID] = sessionHandler

	sessionHandler.dismisser = client.NewSession(string(event.Request), sessionHandler)
	return nil
}

// Responding to a permission prompt when disclosing, issuing or signing
func (ah *eventHandler) respondPermission(event *respondPermissionEvent) (err error) {
	sh, err := ah.findSessionHandler(event.SessionID)
	if err != nil {
		return err
	}
	if sh.permissionHandler == nil {
		return errors.Errorf("Unset permissionHandler in RespondPermission")
	}

	disclosureChoice := &irma.DisclosureChoice{Attributes: event.DisclosureChoices}
	sh.permissionHandler(event.Proceed, disclosureChoice)

	return nil
}

// Responding to a request for a pin code
func (ah *eventHandler) respondPin(event *respondPinEvent) (err error) {
	sh, err := ah.findSessionHandler(event.SessionID)
	if err != nil {
		return err
	}
	if sh.pinHandler == nil {
		return errors.Errorf("Unset pinHandler in RespondPin")
	}

	sh.pinHandler(event.Proceed, event.Pin)
	return nil
}

// Request to remove all attributes and keyshare enrollment
func (ah *eventHandler) deleteAllCredentials() (err error) {
	if err := client.RemoveAllCredentials(); err != nil {
		return err
	}
	if err := client.KeyshareRemoveAll(); err != nil {
		return err
	}

	dispatchCredentialsEvent()
	dispatchEnrollmentStatusEvent()
	return nil
}

// Delete an individual credential
func (ah *eventHandler) deleteCredential(event *deleteCredentialEvent) error {
	if err := client.RemoveCredentialByHash(event.Hash); err != nil {
		return err
	}

	dispatchCredentialsEvent()
	return nil
}

// Dismiss the current session
func (ah *eventHandler) dismissSession(event *dismissSessionEvent) error {
	sh, err := ah.findSessionHandler(event.SessionID)
	if err != nil {
		return err
	}
	if sh.dismisser != nil {
		sh.dismisser.Dismiss()
	}
	return nil
}

// Set the crash reporting preference, and returns the current preferences to irma_mobile
func (ah *eventHandler) setCrashReportingPreference(event *setCrashReportingPreferenceEvent) error {
	client.SetCrashReportingPreference(event.EnableCrashReporting)

	dispatchPreferencesEvent()
	return nil
}

// Set the qrScannOnStartup preference, and returns the current preferences to irma_mobile
func (ah *eventHandler) setQrScannerOnStartupPreference(event *setQrScannerOnStartupPreferenceEvent) error {
	client.SetQrScannerOnStartupPreference(event.QrScannerOnStartup);

	dispatchPreferencesEvent()
	return nil
}

// findSessionHandler is a helper function to find a session in the sessionLookup
func (ah *eventHandler) findSessionHandler(sessionID int) (*sessionHandler, error) {
	sh := ah.sessionLookup[sessionID]
	if sh == nil {
		return nil, errors.Errorf("Invalid session ID in RespondPermission: %d", sessionID)
	}

	return sh, nil
}

func (ah *eventHandler) updateSchemes() error {
	err := client.Configuration.UpdateSchemes()
	if err != nil {
		return err
	}

	dispatchConfigurationEvent()
	return nil
}
