package irmagobridge

import (
	"context"
	"encoding/json"
	"fmt"
	"slices"

	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/common/clientmodels"
	"github.com/privacybydesign/irmago/irma"
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
	yiviClient.NewSession(event.SessionId, string(event.Request))
	return nil
}

// previewSession answers with what the pointer would start and who it is
// from, worked out locally: no server is contacted.
func (ah *eventHandler) previewSession(event *previewSessionEvent) error {
	preview, err := yiviClient.PreviewSession(string(event.Request))
	if err != nil {
		return err
	}
	dispatchEvent(&sessionPreviewEvent{Key: event.Key, Preview: preview})
	return nil
}

func (ah *eventHandler) handleUserInteraction(event *sessionUserInteractionEvent) error {
	interaction := clientmodels.SessionUserInteraction{
		SessionId: event.SessionId,
		Type:      event.Type,
	}

	switch event.Type {
	case clientmodels.UI_Permission:
		var payload clientmodels.SessionPermissionInteractionPayload
		if err := json.Unmarshal(event.Payload, &payload); err != nil {
			return err
		}
		interaction.Payload = payload
	case clientmodels.UI_EnteredPin:
		var payload clientmodels.PinInteractionPayload
		if err := json.Unmarshal(event.Payload, &payload); err != nil {
			return err
		}
		interaction.Payload = payload
	case clientmodels.UI_DismissSession:
		// No payload needed
	case clientmodels.UI_PreAuthorizedCode:
		var payload clientmodels.SessionPreAuthorizedCodeInteractionPayload
		if err := json.Unmarshal(event.Payload, &payload); err != nil {
			return err
		}
		interaction.Payload = payload
	case clientmodels.UI_AuthorizationCode:
		var payload clientmodels.SessionAuthCodeInteractionPayload
		if err := json.Unmarshal(event.Payload, &payload); err != nil {
			return err
		}
		interaction.Payload = payload
	}

	yiviClient.HandleUserInteraction(interaction)
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

// Drop the in-memory keyshare session tokens (no unenrollment), forcing the
// next session to re-authenticate with the PIN.
func (ah *eventHandler) deleteKeyshareTokens() error {
	yiviClient.DeleteKeyshareTokens()
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

// Force a Token Status List refresh, so a test can drive a sweep instead of
// waiting on the client's job. Per-list failures are logged and swallowed inside
// RefreshStatuses, so an error here means the sweep could not run at all.
//
// Dispatching is RefreshStatuses' own job: it signals CredentialsChanged when a
// status moved, and stays silent when the sweep only re-confirmed what the
// wallet already had.
func (ah *eventHandler) refreshCredentialStatuses() error {
	return yiviClient.RefreshStatuses(context.Background())
}

func (ah *eventHandler) updateSchemes() error {
	err := yiviClient.GetIrmaConfiguration().UpdateSchemes()
	if err != nil {
		return err
	}

	dispatchConfigurationEvent()
	return nil
}

// The log questions always answer, with the error in the answer when there
// is one, so the app is never left waiting on a request id.

func errorText(err error) string {
	if err == nil {
		return ""
	}
	return err.Error()
}

func (ah *eventHandler) queryLogs(event *queryLogsEvent) error {
	answerLog("Answering QueryLogsEvent panicked", func() {
		page, err := yiviClient.QueryLogs(event.Query)
		if page.Entries == nil {
			page.Entries = []clientmodels.LogInfo{}
		}
		dispatchEvent(&logPageEvent{RequestId: event.RequestId, Page: page, Error: errorText(err)})
	})
	return nil
}

func (ah *eventHandler) getLog(event *getLogEvent) error {
	answerLog("Answering GetLogEvent panicked", func() {
		entry, err := yiviClient.GetLog(event.Id)
		dispatchEvent(&logEntryEvent{RequestId: event.RequestId, Entry: entry, Error: errorText(err)})
	})
	return nil
}

func (ah *eventHandler) credentialActivity(event *credentialActivityEvent) error {
	answerLog("Answering CredentialActivityEvent panicked", func() {
		activity, err := yiviClient.CredentialActivity(event.Hashes)
		dispatchEvent(&credentialActivityResultEvent{RequestId: event.RequestId, Activity: activity, Error: errorText(err)})
	})
	return nil
}

func (ah *eventHandler) countLogs(event *countLogsEvent) error {
	answerLog("Answering CountLogsEvent panicked", func() {
		counts := make([]int, len(event.Filters))
		var err error
		for i, f := range event.Filters {
			var page clientmodels.LogPage
			page, err = yiviClient.QueryLogs(clientmodels.LogQuery{Filter: f, Limit: 1, WithCounts: true})
			if err != nil {
				break
			}
			if page.Counts != nil {
				counts[i] = page.Counts.Total
			}
		}
		dispatchEvent(&logCountsEvent{RequestId: event.RequestId, Counts: counts, Error: errorText(err)})
	})
	return nil
}

func (ah *eventHandler) listParties(event *listPartiesEvent) error {
	answerLog("Answering ListPartiesEvent panicked", func() {
		parties, err := yiviClient.ListParties(event.Filter, event.Limit)
		if parties == nil {
			parties = []clientmodels.PartySummary{}
		}
		dispatchEvent(&partiesEvent{RequestId: event.RequestId, Parties: parties, Error: errorText(err)})
	})
	return nil
}

// answerLog answers a question about the log on a goroutine of its own. The
// app asks them on its main thread, which on iOS is also the thread its UI
// runs on: a question that reads the whole log (the filter sheet counts one
// per option) would freeze the app until it is answered. They only read,
// and each answer carries its request id, so they may run side by side.
// An error is in the answer, so there is nothing to return.
func answerLog(panicMessage string, answer func()) {
	go func() {
		defer recoverFromPanic(panicMessage)
		answer()
	}()
}

func (ah *eventHandler) setPreferences(event *clientPreferencesEvent) error {
	yiviClient.SetPreferences(event.Preferences)
	return nil
}

// setLocale changes the effective app language in irmago and re-dispatches the
// credentials so already-delivered data is re-resolved to the new language.
// The background logo backfill (started by SetLocale) may push a further
// refresh once logos land. The app asks for the activity log again itself.
func (ah *eventHandler) setLocale(event *setLocaleEvent) error {
	yiviClient.SetLocale(event.Locale)
	dispatchCredentialsEvent()
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

func (ah *eventHandler) removeCertificate(event *removeCertificateEvent) error {
	conf := yiviClient.GetEudiConfiguration()

	switch event.Type {
	case "issuer":
		if err := conf.Issuers.RemoveCertificate(event.Thumbprint); err != nil {
			return err
		}
	case "verifier":
		if err := conf.Verifiers.RemoveCertificate(event.Thumbprint); err != nil {
			return err
		}
	}

	// Reload configuration to drop the removed certificate
	conf.Reload()

	dispatchConfigurationEvent()
	return nil
}
