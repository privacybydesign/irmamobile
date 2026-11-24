package irmagobridge

import (
	"encoding/json"
	"testing"

	"github.com/privacybydesign/irmago/irma"
)

func supportConfiguration() *irma.Configuration {
	logo := "/schemes/pbdf-requestors/assets/cis.png"
	return &irma.Configuration{
		SchemeManagers: map[irma.SchemeManagerIdentifier]*irma.SchemeManager{
			irma.NewSchemeManagerIdentifier("pbdf"):      {ID: "pbdf"},
			irma.NewSchemeManagerIdentifier("irma-demo"): {ID: "irma-demo", Demo: true},
		},
		RequestorSchemes: map[irma.RequestorSchemeIdentifier]*irma.RequestorScheme{
			irma.NewRequestorSchemeIdentifier("pbdf-requestors"):      {ID: irma.NewRequestorSchemeIdentifier("pbdf-requestors")},
			irma.NewRequestorSchemeIdentifier("irma-demo-requestors"): {ID: irma.NewRequestorSchemeIdentifier("irma-demo-requestors"), Demo: true},
		},
		Requestors: map[string]*irma.RequestorInfo{
			"inzage.stichtingcis.nl": {
				ID:        irma.NewRequestorIdentifier("pbdf-requestors.cis"),
				Scheme:    irma.NewRequestorSchemeIdentifier("pbdf-requestors"),
				Name:      irma.TranslatedString{"en": "CIS", "nl": "Stichting CIS"},
				Hostnames: []string{"inzage.stichtingcis.nl", "yivi.stichtingcis.nl"},
				LogoPath:  &logo,
			},
			// The same requestor under its second hostname.
			"yivi.stichtingcis.nl": {
				ID:        irma.NewRequestorIdentifier("pbdf-requestors.cis"),
				Scheme:    irma.NewRequestorSchemeIdentifier("pbdf-requestors"),
				Name:      irma.TranslatedString{"en": "CIS", "nl": "Stichting CIS"},
				Hostnames: []string{"inzage.stichtingcis.nl", "yivi.stichtingcis.nl"},
				LogoPath:  &logo,
			},
			"demo.example.com": {
				ID:         irma.NewRequestorIdentifier("irma-demo-requestors.demo"),
				Scheme:     irma.NewRequestorSchemeIdentifier("irma-demo-requestors"),
				Name:       irma.TranslatedString{"en": "Demo"},
				Unverified: true,
			},
		},
		Issuers: map[irma.IssuerIdentifier]*irma.Issuer{
			irma.NewIssuerIdentifier("pbdf.cis"): {
				ID: "cis", SchemeManagerID: "pbdf", Name: irma.TranslatedString{"en": "CIS"},
				ContactEMail: "info@stichtingcis.nl", ContactAddress: "https://stichtingcis.nl",
			},
			irma.NewIssuerIdentifier("irma-demo.gemeente"): {
				ID: "gemeente", SchemeManagerID: "irma-demo", Name: irma.TranslatedString{"en": "Municipality"},
			},
		},
	}
}

func TestSupportDirectory(t *testing.T) {
	event := supportDirectory(supportConfiguration())

	if len(event.Requestors) != 2 {
		t.Fatalf("requestors: got %+v", event.Requestors)
	}
	demo, cis := event.Requestors[0], event.Requestors[1]
	if demo.ID != "irma-demo-requestors.demo" || !demo.Demo || demo.Verified || demo.Hostnames == nil || demo.LogoPath != "" {
		t.Errorf("demo requestor: got %+v", demo)
	}
	if cis.ID != "pbdf-requestors.cis" || cis.Demo || !cis.Verified || cis.Name["nl"] != "Stichting CIS" ||
		len(cis.Hostnames) != 2 || cis.LogoPath != "/schemes/pbdf-requestors/assets/cis.png" {
		t.Errorf("cis requestor: got %+v", cis)
	}

	if len(event.Issuers) != 2 {
		t.Fatalf("issuers: got %+v", event.Issuers)
	}
	gemeente, cisIssuer := event.Issuers[0], event.Issuers[1]
	if gemeente.ID != "irma-demo.gemeente" || !gemeente.Demo || gemeente.ContactEmail != "" {
		t.Errorf("demo issuer: got %+v", gemeente)
	}
	if cisIssuer.ID != "pbdf.cis" || cisIssuer.Demo || cisIssuer.ContactEmail != "info@stichtingcis.nl" ||
		cisIssuer.ContactAddress != "https://stichtingcis.nl" {
		t.Errorf("cis issuer: got %+v", cisIssuer)
	}
}

func TestSupportDirectoryWithoutSchemes(t *testing.T) {
	event := supportDirectory(&irma.Configuration{})
	if event.Requestors == nil || event.Issuers == nil || len(event.Requestors)+len(event.Issuers) != 0 {
		t.Errorf("got %#v, want empty lists", event)
	}
}

// The field names the app's SupportDirectoryEvent.fromJson reads.
func TestSupportDirectoryJSON(t *testing.T) {
	event := &supportDirectoryEvent{
		Requestors: []supportRequestor{{
			ID: "pbdf-requestors.cis", Name: map[string]string{"en": "CIS"}, Hostnames: []string{"cis.nl"},
			LogoPath: "/l.png", Verified: true, SupportEmail: "help@cis.nl", SupportURL: "https://cis.nl/help",
		}},
		Issuers: []supportIssuer{{
			ID: "pbdf.cis", Name: map[string]string{}, Demo: true,
			ContactEmail: "info@cis.nl", ContactAddress: "https://cis.nl",
		}},
	}
	got, err := json.Marshal(event)
	if err != nil {
		t.Fatal(err)
	}
	const want = `{"requestors":[{"id":"pbdf-requestors.cis","name":{"en":"CIS"},"hostnames":["cis.nl"],` +
		`"logo_path":"/l.png","verified":true,"demo":false,"support_email":"help@cis.nl","support_url":"https://cis.nl/help"}],` +
		`"issuers":[{"id":"pbdf.cis","name":{},"demo":true,"contact_email":"info@cis.nl","contact_address":"https://cis.nl"}]}`
	if string(got) != want {
		t.Errorf("got  %s\nwant %s", got, want)
	}
}
