package foundation.privacybydesign.irmamobile;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.credentials.Credential;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.CredentialOption;
import androidx.credentials.exceptions.GetCredentialException;
import androidx.credentials.exceptions.GetCredentialUnknownException;
import androidx.credentials.provider.CallingAppInfo;
import androidx.credentials.provider.PendingIntentHandler;
import androidx.credentials.provider.ProviderGetCredentialRequest;

import org.json.JSONException;
import org.json.JSONObject;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * Activity that handles Digital Credentials API requests from Chrome and other credential consumers.
 * This activity is invoked when a website calls navigator.identity.get() with OpenID4VP protocol.
 */
public class GetCredentialActivity extends FlutterActivity {
    private static final String TAG = "GetCredentialActivity";
    private static final String CHANNEL_NAME = "irma.app/digital_credentials";
    private static final String CREDENTIAL_TYPE_OPENID4VP = "androidx.credentials.TYPE_DIGITAL_CREDENTIAL";

    private MethodChannel methodChannel;
    private ProviderGetCredentialRequest credentialRequest;
    private Intent resultIntent;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        resultIntent = new Intent();

        try {
            // Extract the credential request from the intent
            credentialRequest = PendingIntentHandler.retrieveProviderGetCredentialRequest(getIntent());

            if (credentialRequest == null) {
                Log.e(TAG, "No credential request found in intent");
                returnError(new GetCredentialUnknownException("No credential request found"));
                return;
            }

            Log.i(TAG, "GetCredentialActivity started successfully");

        } catch (Exception e) {
            Log.e(TAG, "Error in onCreate", e);
            returnError(new GetCredentialUnknownException("Error initializing: " + e.getMessage()));
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        methodChannel = new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            CHANNEL_NAME
        );

        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "returnCredential":
                    String responseJson = call.argument("responseJson");
                    returnCredential(responseJson);
                    result.success(null);
                    break;
                case "returnError":
                    String errorMessage = call.argument("message");
                    returnError(new GetCredentialUnknownException(errorMessage));
                    result.success(null);
                    break;
                case "cancelRequest":
                    setResult(Activity.RESULT_CANCELED, resultIntent);
                    finish();
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
            }
        });

        // Process the credential request after Flutter engine is ready
        processCredentialRequest();
    }

    /**
     * Process the credential request and send it to Flutter for handling
     */
    private void processCredentialRequest() {
        try {
            CallingAppInfo callingApp = credentialRequest.getCallingAppInfo();

            // Find the credential option - look for digital credential type
            CredentialOption credOption = null;
            for (CredentialOption option : credentialRequest.getCredentialOptions()) {
                // Check if this is a digital credential request
                String type = option.getType();
                Log.i(TAG, "Found credential option type: " + type);

                // Accept digital credential type or openid4vp custom type
                if (type.contains("digital") || type.contains("openid4vp") ||
                    type.equals(CREDENTIAL_TYPE_OPENID4VP)) {
                    credOption = option;
                    break;
                }
            }

            if (credOption == null) {
                Log.e(TAG, "No compatible credential option found in request");
                returnError(new GetCredentialUnknownException("No compatible credential option found"));
                return;
            }

            // Extract the request data from the credential option
            Bundle requestData = credOption.getRequestData();
            String requestJson = requestData.getString("requestJson", "{}");
            Log.i(TAG, "Digital credential request: " + requestJson);

            // Parse the request JSON to extract the openid4vp:// URL
            JSONObject requestObject = new JSONObject(requestJson);
            String protocol = requestObject.optString("protocol", "");

            if (protocol.isEmpty() || !protocol.equals("openid4vp")) {
                // Try alternative structure
                String request = requestObject.optString("request", "");
                if (request.isEmpty()) {
                    Log.e(TAG, "Could not find openid4vp request in JSON");
                    returnError(new GetCredentialUnknownException("Invalid request format"));
                    return;
                }

                // The request might be a URL directly
                if (request.startsWith("openid4vp://")) {
                    sendUrlToFlutter(request, requestJson, callingApp);
                    return;
                }
            }

            // Standard format with nested request object
            JSONObject nestedRequest = requestObject.optJSONObject("request");
            if (nestedRequest == null) {
                String requestStr = requestObject.optString("request", "");
                sendUrlToFlutter(requestStr, requestJson, callingApp);
                return;
            }

            // Build URL from request parameters
            String openid4vpUrl = buildOpenId4VpUrl(nestedRequest);
            sendUrlToFlutter(openid4vpUrl, requestJson, callingApp);

        } catch (JSONException e) {
            Log.e(TAG, "Error parsing credential request JSON", e);
            returnError(new GetCredentialUnknownException("Error parsing request: " + e.getMessage()));
        } catch (Exception e) {
            Log.e(TAG, "Unexpected error processing credential request", e);
            returnError(new GetCredentialUnknownException("Unexpected error: " + e.getMessage()));
        }
    }

    private String buildOpenId4VpUrl(JSONObject requestData) throws JSONException {
        String requestUri = requestData.optString("request_uri", "");
        String nonce = requestData.optString("nonce", "");
        String clientId = requestData.optString("client_id", "");

        StringBuilder urlBuilder = new StringBuilder("openid4vp://?");
        boolean hasParam = false;

        if (!requestUri.isEmpty()) {
            urlBuilder.append("request_uri=").append(requestUri);
            hasParam = true;
        }
        if (!nonce.isEmpty()) {
            if (hasParam) urlBuilder.append("&");
            urlBuilder.append("nonce=").append(nonce);
            hasParam = true;
        }
        if (!clientId.isEmpty()) {
            if (hasParam) urlBuilder.append("&");
            urlBuilder.append("client_id=").append(clientId);
        }

        return urlBuilder.toString();
    }

    private void sendUrlToFlutter(String url, String requestJson, CallingAppInfo callingApp) throws JSONException {
        Log.i(TAG, "Sending openid4vp URL to Flutter: " + url);

        // Send the request to Flutter
        JSONObject messageToFlutter = new JSONObject();
        messageToFlutter.put("url", url);
        messageToFlutter.put("requestJson", requestJson);
        messageToFlutter.put("callingPackage", callingApp.getPackageName());

        if (methodChannel != null) {
            methodChannel.invokeMethod("handleDigitalCredentialRequest", messageToFlutter.toString());
        } else {
            Log.e(TAG, "MethodChannel not initialized yet");
            returnError(new GetCredentialUnknownException("Internal error: channel not ready"));
        }
    }

    /**
     * Return the credential response to the calling app
     */
    private void returnCredential(String responseJson) {
        try {
            Log.i(TAG, "Returning credential response");

            // Create a custom credential with the response JSON
            Bundle credentialData = new Bundle();
            credentialData.putString("data", responseJson);

            CustomCredential credential = new CustomCredential(CREDENTIAL_TYPE_OPENID4VP, credentialData);
            GetCredentialResponse response = new GetCredentialResponse(credential);

            PendingIntentHandler.setGetCredentialResponse(resultIntent, response);
            setResult(Activity.RESULT_OK, resultIntent);
            finish();

        } catch (Exception e) {
            Log.e(TAG, "Error returning credential", e);
            returnError(new GetCredentialUnknownException("Error returning credential: " + e.getMessage()));
        }
    }

    /**
     * Return an error to the calling app
     */
    private void returnError(GetCredentialException exception) {
        Log.e(TAG, "Returning error: " + exception.getMessage());
        PendingIntentHandler.setGetCredentialException(resultIntent, exception);
        setResult(Activity.RESULT_OK, resultIntent);
        finish();
    }
}
