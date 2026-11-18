package irmagobridge

import (
	"encoding/json"
	"testing"

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
