package irmagobridge

import (
	"encoding/json"

	"github.com/go-errors/errors"
)

func DispatchFromNative(name, payloadString string) {
	payloadBytes := []byte(payloadString)
	var err error

	switch name {
	case "AppReadyEvent":
		sendEnrollmentStatus()
		sendConfiguration()
		sendPreferences()
		sendCredentials()
	case "EnrollEvent":
		event := &EnrollEvent{}
		if err = json.Unmarshal(payloadBytes, event); err == nil {
			err = eventHandler.Enroll(event)
		}
	}

	if err != nil {
		logError(errors.New(err))
	}
}

// func recoveredReceiveAction(actionJSONString string) {
// 	actionJSON := []byte(actionJSONString)

// 	actionType, err := getActionType(actionJSON)
// 	if err != nil {
// 		logError(err)
// 		return
// 	}

// 	logDebug("Received action with type " + actionType)

// 	switch actionType {
// 	case "Enroll":
// 		action := &EnrollAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.Enroll(action)
// 		}

// 	case "Authenticate":
// 		action := &AuthenticateAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.Authenticate(action)
// 		}

// 	case "ChangePin":
// 		action := &ChangePinAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.ChangePin(action)
// 		}

// 	case "NewSession":
// 		action := &NewSessionAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.NewSession(action)
// 		}

// 	case "RespondPermission":
// 		action := &RespondPermissionAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.RespondPermission(action)
// 		}

// 	case "RespondPin":
// 		action := &RespondPinAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.RespondPin(action)
// 		}

// 	case "DeleteAllCredentials":
// 		err = actionHandler.DeleteAllCredentials()

// 	case "DeleteCredential":
// 		action := &DeleteCredentialAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.DeleteCredential(action)
// 		}

// 	case "DismissSession":
// 		action := &DismissSessionAction{}
// 		if err = json.Unmarshal(actionJSON, action); err == nil {
// 			err = actionHandler.DismissSession(action)
// 		}

// 	case "SetCrashReportingPreference":
// 		action := &SetCrashReportingPreferenceAction{}
// 		if err = json.Unmarshal(actionJSON, &action); err == nil {
// 			err = actionHandler.SetCrashReportingPreference(action)
// 		}

// 	case "UpdateSchemes":
// 		err = actionHandler.updateSchemes()

// 	default:
// 		err = errors.Errorf("Unrecognized action type %s", actionType)
// 	}

// 	if err != nil {
// 		logError(errors.New(err))
// 	}
// }

// func getActionType(actionJSON []byte) (actionType string, err error) {
// 	action := new(struct{ Type string })
// 	err = json.Unmarshal(actionJSON, action)
// 	if err != nil {
// 		return "", errors.Errorf("Could not parse action type: %s", err)
// 	}

// 	return action.Type, nil
// }
