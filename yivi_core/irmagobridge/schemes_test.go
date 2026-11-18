package irmagobridge

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/privacybydesign/irmago/irma"
)

func credentialType(ul bool) *irma.CredentialType {
	return &irma.CredentialType{IsULIssueURL: ul}
}

func TestSchemeRules(t *testing.T) {
	conf := &irma.Configuration{
		SchemeManagers: map[irma.SchemeManagerIdentifier]*irma.SchemeManager{
			irma.NewSchemeManagerIdentifier("pbdf"): {
				MinimumAppVersion: irma.SchemeAppVersion{Android: 101, IOS: 90},
			},
			irma.NewSchemeManagerIdentifier("irma-demo"): {
				MinimumAppVersion: irma.SchemeAppVersion{Android: 50, IOS: 120},
			},
		},
		CredentialTypes: map[irma.CredentialTypeIdentifier]*irma.CredentialType{
			irma.NewCredentialTypeIdentifier("pbdf.bzkpilot.personalData"):        credentialType(true),
			irma.NewCredentialTypeIdentifier("irma-demo.digidproef.personalData"): credentialType(true),
			irma.NewCredentialTypeIdentifier("pbdf.pbdf.idin"):                    credentialType(false),
		},
	}

	rules := schemeRules(conf)

	if rules.MinimumAppVersion != (appVersion{Android: 101, IOS: 120}) {
		t.Errorf("minimum app version: got %+v, want the highest per platform", rules.MinimumAppVersion)
	}
	want := []string{"irma-demo.digidproef.personalData", "pbdf.bzkpilot.personalData"}
	if len(rules.ULIssueCredentialIDs) != len(want) {
		t.Fatalf("universal-link ids: got %v, want %v", rules.ULIssueCredentialIDs, want)
	}
	for i := range want {
		if rules.ULIssueCredentialIDs[i] != want[i] {
			t.Errorf("universal-link ids: got %v, want %v", rules.ULIssueCredentialIDs, want)
		}
	}
}

func TestSchemeRulesWithoutSchemes(t *testing.T) {
	rules := schemeRules(&irma.Configuration{})
	if rules.MinimumAppVersion != (appVersion{}) {
		t.Errorf("minimum app version: got %+v, want zero", rules.MinimumAppVersion)
	}
	if rules.ULIssueCredentialIDs == nil || len(rules.ULIssueCredentialIDs) != 0 {
		t.Errorf("universal-link ids: got %#v, want an empty list", rules.ULIssueCredentialIDs)
	}
}

// The field names the app's SchemeRulesEvent.fromJson reads.
func TestSchemeRulesJSON(t *testing.T) {
	rules := &schemeRulesEvent{
		MinimumAppVersion:    appVersion{Android: 4194468, IOS: 4194469},
		ULIssueCredentialIDs: []string{"pbdf.bzkpilot.personalData"},
	}
	got, err := json.Marshal(rules)
	if err != nil {
		t.Fatal(err)
	}
	const want = `{"minimum_app_version":{"android":4194468,"ios":4194469},"ul_issue_credential_ids":["pbdf.bzkpilot.personalData"]}`
	if string(got) != want {
		t.Errorf("got %s, want %s", got, want)
	}

	empty, err := json.Marshal(schemeRules(&irma.Configuration{}))
	if err != nil {
		t.Fatal(err)
	}
	const wantEmpty = `{"minimum_app_version":{"android":0,"ios":0},"ul_issue_credential_ids":[]}`
	if string(empty) != wantEmpty {
		t.Errorf("got %s, want %s", empty, wantEmpty)
	}
}

func debugConfiguration() *irma.Configuration {
	attribute := func(id, hint string) *irma.AttributeType {
		return &irma.AttributeType{ID: id, Name: irma.TranslatedString{"en": id}, DisplayHint: hint}
	}
	return &irma.Configuration{
		SchemeManagers: map[irma.SchemeManagerIdentifier]*irma.SchemeManager{
			irma.NewSchemeManagerIdentifier("pbdf"): {
				ID:              "pbdf",
				Timestamp:       irma.Timestamp(time.Unix(1700000000, 0)),
				KeyshareServer:  "https://keyshare.example.com",
				TimestampServer: "https://timestamp.example.com",
			},
			irma.NewSchemeManagerIdentifier("irma-demo"): {
				ID:        "irma-demo",
				Demo:      true,
				Timestamp: irma.Timestamp(time.Unix(1600000000, 0)),
			},
		},
		RequestorSchemes: map[irma.RequestorSchemeIdentifier]*irma.RequestorScheme{
			irma.NewRequestorSchemeIdentifier("pbdf-requestors"): {
				ID: irma.NewRequestorSchemeIdentifier("pbdf-requestors"),
			},
			irma.NewRequestorSchemeIdentifier("irma-demo-requestors"): {
				ID:   irma.NewRequestorSchemeIdentifier("irma-demo-requestors"),
				Demo: true,
			},
		},
		CredentialTypes: map[irma.CredentialTypeIdentifier]*irma.CredentialType{
			irma.NewCredentialTypeIdentifier("irma-demo.digidproef.personalData"): {
				ID:              "personalData",
				SchemeManagerID: "irma-demo",
				Name:            irma.TranslatedString{"en": "Personal data", "nl": "Persoonsgegevens"},
			},
			irma.NewCredentialTypeIdentifier("irma-demo.gemeente.address"): {
				ID:              "address",
				SchemeManagerID: "irma-demo",
				Name:            irma.TranslatedString{"en": "Address"},
			},
		},
		AttributeTypes: map[irma.AttributeTypeIdentifier]*irma.AttributeType{
			irma.NewAttributeTypeIdentifier("irma-demo.digidproef.personalData.surname"):  attribute("surname", ""),
			irma.NewAttributeTypeIdentifier("irma-demo.digidproef.personalData.photo"):    attribute("photo", "portraitPhoto"),
			irma.NewAttributeTypeIdentifier("irma-demo.digidproef.personalData.initials"): attribute("initials", ""),
		},
	}
}

func TestDebugSchemes(t *testing.T) {
	event := debugSchemes(debugConfiguration())

	if len(event.SchemeManagers) != 2 || event.SchemeManagers[0].ID != "irma-demo" || event.SchemeManagers[1].ID != "pbdf" {
		t.Fatalf("scheme managers: got %+v, want irma-demo then pbdf", event.SchemeManagers)
	}
	pbdf := event.SchemeManagers[1]
	if pbdf.Demo || pbdf.Timestamp != 1700000000 || pbdf.KeyshareServer != "https://keyshare.example.com" ||
		pbdf.TimestampServer != "https://timestamp.example.com" {
		t.Errorf("pbdf: got %+v", pbdf)
	}
	if demo := event.SchemeManagers[0]; !demo.Demo || demo.Timestamp != 1600000000 || demo.KeyshareServer != "" {
		t.Errorf("irma-demo: got %+v", demo)
	}

	if len(event.RequestorSchemes) != 2 ||
		event.RequestorSchemes[0] != (debugRequestorScheme{ID: "irma-demo-requestors", Demo: true}) ||
		event.RequestorSchemes[1] != (debugRequestorScheme{ID: "pbdf-requestors"}) {
		t.Errorf("requestor schemes: got %+v", event.RequestorSchemes)
	}

	if len(event.CredentialTypes) != 2 {
		t.Fatalf("credential types: got %+v", event.CredentialTypes)
	}
	personalData := event.CredentialTypes[0]
	if personalData.ID != "irma-demo.digidproef.personalData" || personalData.SchemeManagerID != "irma-demo" ||
		personalData.Name["nl"] != "Persoonsgegevens" {
		t.Errorf("personal data: got %+v", personalData)
	}
	var ids []string
	for _, a := range personalData.Attributes {
		ids = append(ids, a.ID)
	}
	if len(ids) != 3 || ids[0] != "initials" || ids[1] != "photo" || ids[2] != "surname" {
		t.Errorf("attributes: got %v, want initials, photo, surname", ids)
	}
	if personalData.Attributes[1].DisplayHint != "portraitPhoto" {
		t.Errorf("photo: got %+v", personalData.Attributes[1])
	}
	address := event.CredentialTypes[1]
	if address.ID != "irma-demo.gemeente.address" || address.Attributes == nil || len(address.Attributes) != 0 {
		t.Errorf("address: got %#v, want no attributes as an empty list", address)
	}
}

// The field names the app's DebugSchemesEvent.fromJson reads.
func TestDebugSchemesJSON(t *testing.T) {
	event := &debugSchemesEvent{
		SchemeManagers: []debugSchemeManager{{
			ID: "pbdf", Timestamp: 1700000000, KeyshareServer: "https://k", TimestampServer: "https://t",
		}},
		RequestorSchemes: []debugRequestorScheme{{ID: "pbdf-requestors", Demo: true}},
		CredentialTypes: []debugCredentialType{{
			ID: "pbdf.pbdf.email", SchemeManagerID: "pbdf", Name: map[string]string{"en": "E-mail"},
			Attributes: []debugAttributeType{
				{ID: "email", Name: map[string]string{"en": "E-mail"}},
				{ID: "photo", Name: map[string]string{}, DisplayHint: "portraitPhoto"},
			},
		}},
	}
	got, err := json.Marshal(event)
	if err != nil {
		t.Fatal(err)
	}
	const want = `{"scheme_managers":[{"id":"pbdf","demo":false,"timestamp":1700000000,"keyshare_server":"https://k","timestamp_server":"https://t"}],` +
		`"requestor_schemes":[{"id":"pbdf-requestors","demo":true}],` +
		`"credential_types":[{"id":"pbdf.pbdf.email","scheme_manager_id":"pbdf","name":{"en":"E-mail"},"attributes":[` +
		`{"id":"email","name":{"en":"E-mail"}},{"id":"photo","name":{},"display_hint":"portraitPhoto"}]}]}`
	if string(got) != want {
		t.Errorf("got  %s\nwant %s", got, want)
	}

	empty, err := json.Marshal(debugSchemes(&irma.Configuration{}))
	if err != nil {
		t.Fatal(err)
	}
	const wantEmpty = `{"scheme_managers":[],"requestor_schemes":[],"credential_types":[]}`
	if string(empty) != wantEmpty {
		t.Errorf("got %s, want %s", empty, wantEmpty)
	}
}
