package irmagobridge

import (
	"sort"
	"time"

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

// debugSchemesEvent answers a RequestDebugSchemesEvent: what the debug screens
// show of the schemes, and what they need to build issuance requests. The
// app only asks for it there; it is never sent unasked.
type debugSchemesEvent struct {
	SchemeManagers   []debugSchemeManager   `json:"scheme_managers"`
	RequestorSchemes []debugRequestorScheme `json:"requestor_schemes"`
	CredentialTypes  []debugCredentialType  `json:"credential_types"`
}

type debugSchemeManager struct {
	ID              string `json:"id"`
	Demo            bool   `json:"demo"`
	Timestamp       int64  `json:"timestamp"` // seconds since the epoch
	KeyshareServer  string `json:"keyshare_server"`
	TimestampServer string `json:"timestamp_server"`
}

type debugRequestorScheme struct {
	ID   string `json:"id"`
	Demo bool   `json:"demo"`
}

type debugCredentialType struct {
	ID              string               `json:"id"` // full id, "irma-demo.digidproef.personalData"
	SchemeManagerID string               `json:"scheme_manager_id"`
	Name            map[string]string    `json:"name"` // the scheme's translations
	Attributes      []debugAttributeType `json:"attributes"`
}

type debugAttributeType struct {
	ID          string            `json:"id"` // short id, as an issuance request names it
	Name        map[string]string `json:"name"`
	DisplayHint string            `json:"display_hint,omitempty"`
}

// debugSchemes reads the debug event from the configuration, each list sorted
// by id. Every attribute type is listed under its credential type, revocation
// attributes included.
func debugSchemes(conf *irma.Configuration) *debugSchemesEvent {
	event := &debugSchemesEvent{
		SchemeManagers:   []debugSchemeManager{},
		RequestorSchemes: []debugRequestorScheme{},
		CredentialTypes:  []debugCredentialType{},
	}
	for _, scheme := range conf.SchemeManagers {
		if scheme == nil {
			continue
		}
		event.SchemeManagers = append(event.SchemeManagers, debugSchemeManager{
			ID:              scheme.ID,
			Demo:            scheme.Demo,
			Timestamp:       time.Time(scheme.Timestamp).Unix(),
			KeyshareServer:  scheme.KeyshareServer,
			TimestampServer: scheme.TimestampServer,
		})
	}
	sort.Slice(event.SchemeManagers, func(i, j int) bool {
		return event.SchemeManagers[i].ID < event.SchemeManagers[j].ID
	})

	for _, scheme := range conf.RequestorSchemes {
		if scheme == nil {
			continue
		}
		event.RequestorSchemes = append(event.RequestorSchemes, debugRequestorScheme{
			ID:   scheme.ID.String(),
			Demo: scheme.Demo,
		})
	}
	sort.Slice(event.RequestorSchemes, func(i, j int) bool {
		return event.RequestorSchemes[i].ID < event.RequestorSchemes[j].ID
	})

	attributes := map[irma.CredentialTypeIdentifier][]debugAttributeType{}
	for id, attribute := range conf.AttributeTypes {
		if attribute == nil {
			continue
		}
		credentialID := id.CredentialTypeIdentifier()
		attributes[credentialID] = append(attributes[credentialID], debugAttributeType{
			ID:          attribute.ID,
			Name:        attribute.Name,
			DisplayHint: attribute.DisplayHint,
		})
	}
	for id, credentialType := range conf.CredentialTypes {
		if credentialType == nil {
			continue
		}
		credentialAttributes := attributes[id]
		if credentialAttributes == nil {
			credentialAttributes = []debugAttributeType{}
		}
		sort.Slice(credentialAttributes, func(i, j int) bool {
			return credentialAttributes[i].ID < credentialAttributes[j].ID
		})
		event.CredentialTypes = append(event.CredentialTypes, debugCredentialType{
			ID:              id.String(),
			SchemeManagerID: credentialType.SchemeManagerID,
			Name:            credentialType.Name,
			Attributes:      credentialAttributes,
		})
	}
	sort.Slice(event.CredentialTypes, func(i, j int) bool {
		return event.CredentialTypes[i].ID < event.CredentialTypes[j].ID
	})
	return event
}
