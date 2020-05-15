package irmagobridge

func dispatchConfigurationEvent() {
	dispatchEvent(&irmaConfigurationEvent{
		IrmaConfiguration: client.Configuration,
	})
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
		Preferences: client.Preferences,
	})
}
