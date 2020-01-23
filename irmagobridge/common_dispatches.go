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
