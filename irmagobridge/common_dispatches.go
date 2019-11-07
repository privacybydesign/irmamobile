package irmagobridge

func dispatchConfigurationEvent() {
	dispatchEvent(&irmaConfigurationEvent{
		SchemeManagers:  client.Configuration.SchemeManagers,
		Issuers:         client.Configuration.Issuers,
		CredentialTypes: client.Configuration.CredentialTypes,
		AttributeTypes:  client.Configuration.AttributeTypes,
	})
}

func dispatchCredentialsEvent() {
	dispatchEvent(&credentialsEvent{
		Credentials: client.CredentialInfoList(),
	})
}

func dispatchPreferencesEvent() {
	dispatchEvent(&preferencesEvent{
		Preferences: client.Preferences,
	})
}

func dispatchEnrollmentStatusEvent() {
	dispatchEvent(&enrollmentStatusEvent{
		EnrolledSchemeManagerIds:   client.EnrolledSchemeManagers(),
		UnenrolledSchemeManagerIds: client.UnenrolledSchemeManagers(),
	})
}
