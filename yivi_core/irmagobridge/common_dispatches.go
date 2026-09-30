package irmagobridge

import (
	"encoding/json"
	"fmt"

	"github.com/go-errors/errors"
	"github.com/privacybydesign/irmago/eudi"
	"github.com/privacybydesign/irmago/eudi/utils"
	"github.com/privacybydesign/irmago/irma"
)

// needed to inject logo into issuers
type WrappedConfiguration irma.Configuration
type WrappedCredentialType struct {
	Logo string `json:",omitempty"`
	irma.CredentialType
}

func (conf *WrappedConfiguration) MarshalJSON() ([]byte, error) {
	var encodedData struct {
		CredentialTypes map[irma.CredentialTypeIdentifier]*WrappedCredentialType
		irma.Configuration
	}

	encodedData.Configuration = *(*irma.Configuration)(conf)
	encodedData.CredentialTypes = make(map[irma.CredentialTypeIdentifier]*WrappedCredentialType)

	for k, v := range conf.CredentialTypes {
		if v == nil {
			encodedData.CredentialTypes[k] = nil
			continue
		}
		encodedData.CredentialTypes[k] = &WrappedCredentialType{
			Logo:           v.Logo((*irma.Configuration)(conf)),
			CredentialType: *v,
		}
	}

	return json.Marshal(encodedData)
}

type WrappedEudiConfiguration eudi.Configuration
type Cert struct {
	Thumbprint string `json:"thumbprint"`
	Subject    string `json:"subject"`
	ChildCert  *Cert  `json:"childCert,omitempty"`
	Deleteable bool   `json:"deleteable"`
}

func (conf *WrappedEudiConfiguration) MarshalJSON() ([]byte, error) {
	var encodedData struct {
		Issuers   []Cert `json:"issuers"`
		Verifiers []Cert `json:"verifiers"`
	}

	encodedData.Issuers = []Cert{}
	encodedData.Verifiers = []Cert{}

	// Get issuer certs
	issuerCerts, err := conf.Issuers.GetSavedTrustChains()
	if err != nil {
		return nil, err
	}

	// Read the bytes as certs
	for _, chain := range issuerCerts {
		chain, err := utils.ParsePemCertificateChain(chain)
		if err != nil {
			return nil, err
		}

		var parentCert *Cert
		for _, cert := range chain {
			c := &Cert{
				Thumbprint: fmt.Sprintf("%x", cert.Signature),
				Subject:    cert.Subject.CommonName,
				// Only the chain's top-level (leaf) certificate is removable:
				// its thumbprint names the chain's file on disk, and removing
				// it removes the whole chain.
				Deleteable: parentCert == nil,
			}

			if parentCert != nil {
				parentCert.ChildCert = c
			} else {
				encodedData.Issuers = append(encodedData.Issuers, *c)
			}
			parentCert = c
		}
	}

	// Get issuer certs
	verifierCerts, err := conf.Verifiers.GetSavedTrustChains()
	if err != nil {
		return nil, err
	}

	// Read the bytes as certs
	for _, chain := range verifierCerts {
		chain, err := utils.ParsePemCertificateChain(chain)
		if err != nil {
			return nil, err
		}

		var parentCert *Cert
		for _, cert := range chain {
			c := &Cert{
				Thumbprint: fmt.Sprintf("%x", cert.Signature),
				Subject:    cert.Subject.CommonName,
				// Only the chain's top-level (leaf) certificate is removable:
				// its thumbprint names the chain's file on disk, and removing
				// it removes the whole chain.
				Deleteable: parentCert == nil,
			}

			if parentCert != nil {
				parentCert.ChildCert = c
			} else {
				encodedData.Verifiers = append(encodedData.Verifiers, *c)
			}
			parentCert = c
		}
	}

	return json.Marshal(encodedData)
}

func dispatchConfigurationEvent() {
	t := WrappedConfiguration(*yiviClient.GetIrmaConfiguration())
	dispatchEvent(&irmaConfigurationEvent{
		IrmaConfiguration: &t,
	})
	e := WrappedEudiConfiguration(*yiviClient.GetEudiConfiguration())
	dispatchEvent(&eudiConfigurationEvent{
		EudiConfiguration: &e,
	})
	dispatchCredentialsEvent()
}

func dispatchSchemalessCredentialsEvent() {
	storeItems, err := yiviClient.GetCredentialStore()
	if err != nil {
		reportError(errors.Errorf("Failed to get credential store: %w", err), false)
	}
	dispatchEvent(&schemalessCredentialStoreEvent{
		Credentials: storeItems,
	})

	creds, problematic, err := yiviClient.GetCredentials()
	if err != nil {
		reportError(errors.Errorf("Failed to get credentials: %w", err), false)
	}
	// Even when the read above failed for the EUDI half, `creds` still holds the
	// IRMA credentials that did load, and `problematic` surfaces stored
	// credentials the wallet cannot render so the app can show and delete them.
	dispatchEvent(&schemalessCredentialsEvent{
		Credentials: creds,
		Problematic: problematic,
	})
}

func dispatchCredentialsEvent() {
	dispatchSchemalessCredentialsEvent()
	dispatchDcApiRegistrationEvent()
}

// dispatchDcApiRegistrationEvent hands the Android layer a fresh credential
// database for Credential Manager.
//
// Deliberately bound to dispatchCredentialsEvent rather than to irmago's
// ClientHandler.CredentialsChanged. That signal is raised from three places --
// logo backfill, revocation refresh and removal -- and none of them covers a
// credential just issued, so a freshly obtained credential would stay invisible
// to the picker until something unrelated happened. This function runs wherever
// the app already re-reads its credential list, which includes every finished
// session (YiviSessionHandler.UpdateSession) and a locale change.
//
// A failure is reported and swallowed. Registration is not part of any session
// the user is waiting on: the cost of failing is that the wallet keeps whatever
// the platform last accepted, which is the same outcome as never having
// registered, and failing a credential refresh over it would take the wallet's
// own UI down with it.
func dispatchDcApiRegistrationEvent() {
	database, err := yiviClient.CredentialManagerDatabase()
	if err != nil {
		reportError(errors.Errorf("Failed to build the credential manager database: %w", err), false)
		return
	}
	dispatchEvent(&dcApiRegistrationEvent{
		Database: database,
	})
}

func dispatchEnrollmentStatusEvent() {
	dispatchEvent(&enrollmentStatusEvent{
		EnrolledSchemeManagerIds:   yiviClient.EnrolledSchemeManagers(),
		UnenrolledSchemeManagerIds: yiviClient.UnenrolledSchemeManagers(),
	})
}

func dispatchPreferencesEvent() {
	dispatchEvent(&clientPreferencesEvent{
		Preferences: yiviClient.GetPreferences(),
	})
}
