package irmagobridge

import (
	"sort"

	"github.com/privacybydesign/irmago/irma"
)

// schemeRulesEvent is what the app needs from the schemes: the lowest app
// build they accept, and the credential types whose issue URL is a universal
// link (opened by the OS, which may hand it to a registered app).
type schemeRulesEvent struct {
	MinimumAppVersion    appVersion `json:"minimum_app_version"`
	ULIssueCredentialIDs []string   `json:"ul_issue_credential_ids"`
}

// appVersion is an app build number per platform.
type appVersion struct {
	Android int `json:"android"`
	IOS     int `json:"ios"`
}

// schemeRules reads the rules from the configuration: the highest minimum per
// platform over all scheme managers, and the sorted ids of the credential
// types with IsULIssueURL.
func schemeRules(conf *irma.Configuration) *schemeRulesEvent {
	rules := &schemeRulesEvent{ULIssueCredentialIDs: []string{}}
	for _, scheme := range conf.SchemeManagers {
		if scheme == nil {
			continue
		}
		rules.MinimumAppVersion.Android = max(rules.MinimumAppVersion.Android, scheme.MinimumAppVersion.Android)
		rules.MinimumAppVersion.IOS = max(rules.MinimumAppVersion.IOS, scheme.MinimumAppVersion.IOS)
	}
	for id, credentialType := range conf.CredentialTypes {
		if credentialType != nil && credentialType.IsULIssueURL {
			rules.ULIssueCredentialIDs = append(rules.ULIssueCredentialIDs, id.String())
		}
	}
	sort.Strings(rules.ULIssueCredentialIDs)
	return rules
}
