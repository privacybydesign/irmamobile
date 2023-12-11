package irmagobridge

import (
	"fmt"

	"github.com/go-errors/errors"
	irma "github.com/privacybydesign/irmago"
	irmaclient "github.com/privacybydesign/irmago/irmaclient"
)

type eventHandler struct {
	sessionLookup map[int]*sessionHandler
}

// Enrollment to a keyshare server
func (ah *eventHandler) enroll(event *enrollEvent) (err error) {
	found := false
	for _, schemeID := range client.UnenrolledSchemeManagers() {
		if schemeID == event.SchemeID {
			found = true
			break
		}
	}

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

	client.KeyshareEnroll(event.SchemeID, event.Email, event.Pin, event.Language)
	return
}

// Authenticate to the keyshare server to get access to the app
func (ah *eventHandler) authenticate(event *authenticateEvent) error {
	enrolled := false
	for _, schemeID := range client.EnrolledSchemeManagers() {
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
		success, tries, blocked, err := client.KeyshareVerifyPin(event.Pin, event.SchemeID)
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
	enrolled := client.EnrolledSchemeManagers()

	if len(enrolled) == 0 {
		return errors.Errorf("No enrolled scheme managers to change pin for")
	}

	client.KeyshareChangePin(event.OldPin, event.NewPin)
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

	go func() {
		defer recoverFromPanic("Handling respondPermission event panicked")
		disclosureChoice := &irma.DisclosureChoice{Attributes: event.DisclosureChoices}
		sh.permissionHandler(event.Proceed, disclosureChoice)
	}()

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

	go func() {
		defer recoverFromPanic("Handling respondPin event panicked")
		sh.pinHandler(event.Proceed, event.Pin)
	}()
	return nil
}

func (ah *eventHandler) clearAllData() (err error) {
	if err := client.RemoveStorage(); err != nil {
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

func (ah *eventHandler) loadLogs(action *loadLogsEvent) error {
	var logEntries []*irmaclient.LogEntry
	var err error

	// When before is not sent, it gets Go's default value 0 and 0 is never a valid id
	if action.Before == nil {
		logEntries, err = client.LoadNewestLogs(action.Max)
	} else {
		logEntries, err = client.LoadLogsBefore(*action.Before, action.Max)
	}
	if err != nil {
		return err
	}

	logsOutgoing := make([]*logEntry, len(logEntries))
	for i, entry := range logEntries {
		var removedCredentials = make(map[irma.CredentialTypeIdentifier]map[irma.AttributeTypeIdentifier]irma.TranslatedString)
		if entry.Type == irmaclient.ActionRemoval {
			for credentialTypeId, attributeValues := range entry.Removed {
				var removedCredential = make(map[irma.AttributeTypeIdentifier]irma.TranslatedString)
				attributeTypes := client.Configuration.CredentialTypes[credentialTypeId].AttributeTypes
				for index, attributeValue := range attributeValues {
					typ := attributeTypes[index]
					if typ.RevocationAttribute {
						continue
					}
					removedCredential[typ.GetAttributeTypeIdentifier()] = attributeValue
				}
				removedCredentials[credentialTypeId] = removedCredential
			}
		}
		disclosedCredentials, err := entry.GetDisclosedCredentials(client.Configuration)
		if err != nil {
			return err
		}
		issuedCredentials, err := entry.GetIssuedCredentials(client.Configuration)
		if err != nil {
			return err
		}
		signedMessage, err := entry.GetSignedMessage()
		if err != nil {
			return err
		}
		logsOutgoing[i] = &logEntry{
			ID:                   entry.ID,
			Type:                 entry.Type,
			Time:                 entry.Time,
			ServerName:           entry.ServerName,
			IssuedCredentials:    issuedCredentials,
			DisclosedCredentials: disclosedCredentials,
			SignedMessage:        signedMessage,
			RemovedCredentials:   removedCredentials,
		}
	}

	dispatchEvent(&logsEvent{
		LogEntries: logsOutgoing,
	})

	return nil
}

func (ah *eventHandler) setPreferences(event *clientPreferencesEvent) error {
	client.SetPreferences(event.Preferences)
	return nil
}

func (ah *eventHandler) getIssueWizardContents(event *getIssueWizardContentsEvent) error {
	wizard := client.Configuration.IssueWizards[event.ID]
	if wizard == nil {
		return errors.New("issue wizard not found")
	}
	contents, err := wizard.Path(client.Configuration, client.CredentialInfoList())
	if err != nil {
		return errors.WrapPrefix(err, "failed to process issue wizard", 0)
	}
	dispatchEvent(&issueWizardContentsEvent{
		ID:             event.ID,
		WizardContents: contents,
	})
	return nil
}

func (ah *eventHandler) installScheme(event *installSchemeEvent) error {
	err := client.Configuration.InstallScheme(event.URL, []byte(event.PublicKey))
	if err != nil {
		return err
	}
	dispatchConfigurationEvent()
	dispatchEnrollmentStatusEvent()
	return nil
}

func (ah *eventHandler) removeScheme(event *removeSchemeEvent) error {
	err := client.RemoveScheme(event.SchemeID)
	if err != nil {
		return err
	}
	dispatchConfigurationEvent()
	dispatchEnrollmentStatusEvent()
	return nil
}

func (ah *eventHandler) removeRequestorScheme(event *removeRequestorSchemeEvent) error {
	err := client.RemoveRequestorScheme(event.SchemeID)
	if err != nil {
		return err
	}
	dispatchConfigurationEvent()
	dispatchEnrollmentStatusEvent()
	return nil
}
