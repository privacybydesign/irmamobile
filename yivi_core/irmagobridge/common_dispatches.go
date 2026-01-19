package irmagobridge

import (
	"encoding/json"

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
	Thumbprint string
	Subject    string
	ChildCert  *Cert
	Deleteable bool
}

func (conf *WrappedEudiConfiguration) MarshalJSON() ([]byte, error) {
	var encodedData struct {
		Issuers   []Cert
		Verifiers []Cert
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
				Thumbprint: string(cert.Signature),
				Subject:    cert.Subject.CommonName,
				Deleteable: false,
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
				Thumbprint: string(cert.Signature),
				Subject:    cert.Subject.CommonName,
				Deleteable: false,
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
	t := WrappedConfiguration(*client.GetIrmaConfiguration())
	dispatchEvent(&irmaConfigurationEvent{
		IrmaConfiguration: &t,
	})
	e := WrappedEudiConfiguration(*client.GetEudiConfiguration())
	dispatchEvent(&eudiConfigurationEvent{
		EudiConfiguration: &e,
	})
	dispatchCredentialsEvent()
}

func dispatchCredentialsEvent() {
	dispatchEvent(&credentialsEvent{
		Credentials: client.CredentialInfoList(),
	})
}

func dispatchEnrollmentStatusEvent() {
	dispatchEvent(&enrollmentStatusEvent{
		EnrolledSchemeManagerIds:   client.EnrolledSchemeManagers(),
		UnenrolledSchemeManagerIds: client.UnenrolledSchemeManagers(),
	})
}

func dispatchPreferencesEvent() {
	dispatchEvent(&clientPreferencesEvent{
		Preferences: client.GetPreferences(),
	})
}
