package irmagobridge

import (
	"sort"

	"github.com/privacybydesign/irmago/irma"
)

// supportDirectoryEvent answers a RequestSupportDirectoryEvent: where the
// organisations in the schemes offer support, for "Need help?". The app only
// asks for it when that opens; it is never sent unasked.
type supportDirectoryEvent struct {
	Requestors []supportRequestor `json:"requestors"`
	Issuers    []supportIssuer    `json:"issuers"`
}

// supportRequestor is a requestor in a requestor scheme, with what the scheme
// says about reaching it.
type supportRequestor struct {
	ID        string            `json:"id"` // "pbdf-requestors.cis"
	Name      map[string]string `json:"name"`
	Hostnames []string          `json:"hostnames"`
	LogoPath  string            `json:"logo_path,omitempty"`
	Verified  bool              `json:"verified"`
	Demo      bool              `json:"demo"`
	// Where end users reach the requestor's own support. Most requestors
	// have neither.
	SupportEmail string `json:"support_email,omitempty"`
	SupportURL   string `json:"support_url,omitempty"`
}

// supportIssuer is an issuer in a scheme, with its contact details.
type supportIssuer struct {
	ID             string            `json:"id"` // "pbdf.cis"
	Name           map[string]string `json:"name"`
	Demo           bool              `json:"demo"`
	ContactEmail   string            `json:"contact_email,omitempty"`
	ContactAddress string            `json:"contact_address,omitempty"`
}

// supportDirectory reads the support directory from the configuration, each
// list sorted by id.
func supportDirectory(conf *irma.Configuration) *supportDirectoryEvent {
	event := &supportDirectoryEvent{
		Requestors: []supportRequestor{},
		Issuers:    []supportIssuer{},
	}
	// The configuration has a requestor once per hostname: list it once.
	seen := map[string]bool{}
	for _, requestor := range conf.Requestors {
		if requestor == nil || seen[requestor.ID.String()] {
			continue
		}
		seen[requestor.ID.String()] = true
		scheme := conf.RequestorSchemes[requestor.Scheme]
		hostnames := requestor.Hostnames
		if hostnames == nil {
			hostnames = []string{}
		}
		email, url := requestorSupport(requestor)
		r := supportRequestor{
			ID:           requestor.ID.String(),
			Name:         translations(requestor.Name),
			Hostnames:    hostnames,
			Verified:     !requestor.Unverified,
			Demo:         scheme != nil && scheme.Demo,
			SupportEmail: email,
			SupportURL:   url,
		}
		if requestor.LogoPath != nil {
			r.LogoPath = *requestor.LogoPath
		}
		event.Requestors = append(event.Requestors, r)
	}
	sort.Slice(event.Requestors, func(i, j int) bool {
		return event.Requestors[i].ID < event.Requestors[j].ID
	})

	for id, issuer := range conf.Issuers {
		if issuer == nil {
			continue
		}
		scheme := conf.SchemeManagers[irma.NewSchemeManagerIdentifier(issuer.SchemeManagerID)]
		event.Issuers = append(event.Issuers, supportIssuer{
			ID:             id.String(),
			Name:           translations(issuer.Name),
			Demo:           scheme != nil && scheme.Demo,
			ContactEmail:   issuer.ContactEMail,
			ContactAddress: issuer.ContactAddress,
		})
	}
	sort.Slice(event.Issuers, func(i, j int) bool {
		return event.Issuers[i].ID < event.Issuers[j].ID
	})
	return event
}

// requestorSupport is the requestor's support address and page, from the
// support_email and support_url of requestors.json.
//
// TODO(need help): the irmago this bridge pins has no such fields yet
// (irmago ca8bf576 adds them). Once it is bumped, return
// requestor.SupportEmail, requestor.SupportURL.
func requestorSupport(requestor *irma.RequestorInfo) (email, url string) {
	return "", ""
}

// translations is a copy of [s] that is never nil, so it marshals as {}.
func translations(s irma.TranslatedString) map[string]string {
	out := make(map[string]string, len(s))
	for lang, text := range s {
		out[lang] = text
	}
	return out
}

// requestSupportDirectory answers "Need help?" with where organisations offer
// support.
func (ah *eventHandler) requestSupportDirectory() error {
	dispatchEvent(supportDirectory(yiviClient.GetIrmaConfiguration()))
	return nil
}
