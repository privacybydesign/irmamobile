package foundation.privacybydesign.irmamobile;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.credentials.CredentialOption;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialException;
import androidx.credentials.exceptions.GetCredentialUnknownException;
import androidx.credentials.exceptions.GetCredentialUnsupportedException;
import androidx.credentials.provider.CallingAppInfo;
import androidx.credentials.provider.PendingIntentHandler;
import androidx.credentials.provider.ProviderGetCredentialRequest;
import androidx.credentials.DigitalCredential;
import androidx.credentials.GetDigitalCredentialOption;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * Activity that handles Digital Credentials API requests from Chrome and other credential consumers.
 * This activity is invoked when a website calls navigator.identity.get() with OpenID4VP protocol.
 *
 * This implementation follows the registry-based provider pattern for Digital Credentials API.
 * Implements OpenID4VP over Digital Credentials API as per Appendix A of the spec.
 *
 * Supported protocol values:
 * - openid4vp-v1-unsigned: Unsigned requests (client_id must be omitted)
 * - openid4vp-v1-signed: Signed requests using JWS Compact Serialization
 * - openid4vp-v1-multisigned: Signed requests using JWS JSON Serialization
 */
public class GetCredentialActivity extends FlutterActivity {
    private static final String TAG = "GetCredentialActivity";
    private static final String CHANNEL_NAME = "irma.app/digital_credentials";

    // Supported OpenID4VP protocol values for DC API (Appendix A)
    private static final Set<String> SUPPORTED_PROTOCOLS = new HashSet<>(Arrays.asList(
        "openid4vp-v1-unsigned",
        "openid4vp-v1-signed",
        "openid4vp-v1-multisigned"
    ));

    private MethodChannel methodChannel;
    private ProviderGetCredentialRequest credentialRequest;
    private Intent resultIntent;
    private String callingOrigin;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        resultIntent = new Intent();

        try {
            Log.i(TAG, "GetCredentialActivity onCreate - retrieving credential request");

            // Extract the credential request from the intent using the registry provider API
            credentialRequest = PendingIntentHandler.retrieveProviderGetCredentialRequest(getIntent());

            if (credentialRequest == null) {
                Log.e(TAG, "No credential request found in intent");
                returnError(new GetCredentialUnknownException("No credential request found"));
                return;
            }

            Log.i(TAG, "Credential request retrieved successfully");
            Log.i(TAG, "Number of credential options: " + credentialRequest.getCredentialOptions().size());

            // Log calling app info
            CallingAppInfo callingApp = credentialRequest.getCallingAppInfo();
            Log.i(TAG, "Calling package: " + callingApp.getPackageName());

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
     * Process the credential request and send it to Flutter for handling.
     * This method extracts the Digital Credential request and forwards it to Flutter.
     *
     * Implements OpenID4VP over DC API (Appendix A) request validation:
     * - Validates protocol is one of: openid4vp-v1-unsigned, openid4vp-v1-signed, openid4vp-v1-multisigned
     * - For signed requests, validates expected_origins against the authenticated origin
     * - Extracts origin from CallingAppInfo for audience binding
     */
    private void processCredentialRequest() {
        try {
            CallingAppInfo callingApp = credentialRequest.getCallingAppInfo();
            Log.i(TAG, "Processing credential request from: " + callingApp.getPackageName());

            // Extract origin from calling app - this is the authenticated origin from the platform
            try {
                callingOrigin = callingApp.getOrigin(null);
                Log.i(TAG, "Authenticated origin: " + callingOrigin);
            } catch (Exception e) {
                Log.w(TAG, "Could not get origin from CallingAppInfo", e);
                callingOrigin = null;
            }

            // Find the digital credential option
            GetDigitalCredentialOption digitalCredOption = null;
            for (CredentialOption option : credentialRequest.getCredentialOptions()) {
                String type = option.getType();
                Log.i(TAG, "Examining credential option type: " + type);

                // Check if this is a GetDigitalCredentialOption
                if (option instanceof GetDigitalCredentialOption) {
                    digitalCredOption = (GetDigitalCredentialOption) option;
                    Log.i(TAG, "Found GetDigitalCredentialOption");
                    break;
                }
            }

            if (digitalCredOption == null) {
                Log.e(TAG, "No GetDigitalCredentialOption found in request");
                Log.e(TAG, "Available options: ");
                for (CredentialOption option : credentialRequest.getCredentialOptions()) {
                    Log.e(TAG, "  - " + option.getType() + " (" + option.getClass().getName() + ")");
                }
                returnError(new GetCredentialUnknownException("No digital credential option found"));
                return;
            }

            // Extract the request JSON from the digital credential option
            String requestJson = digitalCredOption.getRequestJson();
            Log.i(TAG, "Digital credential requestJson: " + requestJson);

            // Parse the request JSON according to OpenID4VP DC API format (Appendix A)
            // Expected structure:
            // {
            //   "protocol": "openid4vp-v1-unsigned|openid4vp-v1-signed|openid4vp-v1-multisigned",
            //   "request": {
            //     "nonce": "...",
            //     "dcql_query": {...},
            //     "response_mode": "dc_api|dc_api.jwt",
            //     "client_metadata": {...},
            //     "expected_origins": [...],  // Required for signed requests
            //     "request": "..."  // For signed requests (JWS)
            //   }
            // }
            JSONObject requestObject = new JSONObject(requestJson);

            String protocol = requestObject.optString("protocol", "");
            Log.i(TAG, "Protocol: " + protocol);

            // Validate protocol is supported
            if (!SUPPORTED_PROTOCOLS.contains(protocol)) {
                Log.e(TAG, "Unsupported protocol: " + protocol);
                returnError(new GetCredentialUnsupportedException(
                    "Unsupported protocol: " + protocol + ". Expected one of: " + SUPPORTED_PROTOCOLS));
                return;
            }

            // Get the request object (contains the actual OpenID4VP parameters)
            JSONObject request = requestObject.optJSONObject("request");
            if (request == null) {
                // Try 'data' field for backwards compatibility
                request = requestObject.optJSONObject("data");
            }

            // For signed requests, validate expected_origins
            if (protocol.equals("openid4vp-v1-signed") || protocol.equals("openid4vp-v1-multisigned")) {
                if (!validateExpectedOrigins(request)) {
                    return; // Error already returned in validateExpectedOrigins
                }
            }

            // Forward the complete request to Flutter for processing
            sendRequestToFlutter(requestJson, protocol, callingApp);

        } catch (JSONException e) {
            Log.e(TAG, "Error parsing credential request JSON", e);
            returnError(new GetCredentialUnknownException("Error parsing request: " + e.getMessage()));
        } catch (Exception e) {
            Log.e(TAG, "Unexpected error processing credential request", e);
            returnError(new GetCredentialUnknownException("Unexpected error: " + e.getMessage()));
        }
    }

    /**
     * Validate expected_origins for signed requests.
     * Per Appendix A, the wallet must compare expected_origins against the authenticated origin
     * to detect replay attacks.
     *
     * @param request The OpenID4VP request object
     * @return true if validation passes, false if it fails (error is returned)
     */
    private boolean validateExpectedOrigins(JSONObject request) {
        if (request == null) {
            returnError(new GetCredentialUnknownException("Missing request object in signed request"));
            return false;
        }

        JSONArray expectedOrigins = request.optJSONArray("expected_origins");
        if (expectedOrigins == null || expectedOrigins.length() == 0) {
            // Per spec: expected_origins is required for signed requests
            returnError(new GetCredentialUnknownException(
                "expected_origins is required for signed requests"));
            return false;
        }

        if (callingOrigin == null || callingOrigin.isEmpty()) {
            Log.w(TAG, "Could not verify expected_origins: authenticated origin not available");
            // We continue anyway as the platform should have authenticated the caller
            return true;
        }

        // Check if the authenticated origin matches any of the expected origins
        boolean originMatched = false;
        for (int i = 0; i < expectedOrigins.length(); i++) {
            String expectedOrigin = expectedOrigins.optString(i);
            if (callingOrigin.equals(expectedOrigin)) {
                originMatched = true;
                Log.i(TAG, "Origin matched: " + callingOrigin);
                break;
            }
        }

        if (!originMatched) {
            Log.e(TAG, "Origin mismatch: " + callingOrigin + " not in expected_origins");
            returnError(new GetCredentialUnknownException(
                "Origin validation failed: " + callingOrigin + " not in expected_origins"));
            return false;
        }

        return true;
    }

    /**
     * Send the credential request to Flutter for processing.
     *
     * The message includes:
     * - requestJson: The original DC API request JSON
     * - protocol: The validated protocol (openid4vp-v1-unsigned/signed/multisigned)
     * - callingPackage: The package name of the calling app
     * - origin: The authenticated origin (for audience binding in responses)
     */
    private void sendRequestToFlutter(String requestJson, String protocol, CallingAppInfo callingApp) {
        try {
            Log.i(TAG, "Sending Digital Credential request to Flutter");

            // Build message for Flutter with all necessary information
            JSONObject messageToFlutter = new JSONObject();
            messageToFlutter.put("requestJson", requestJson);
            messageToFlutter.put("protocol", protocol);
            messageToFlutter.put("callingPackage", callingApp.getPackageName());

            // Include the authenticated origin for audience binding
            // Per Appendix A: "The audience for the response must be the Origin, prefixed with origin:"
            if (callingOrigin != null && !callingOrigin.isEmpty()) {
                messageToFlutter.put("origin", callingOrigin);
                Log.i(TAG, "Origin for audience binding: " + callingOrigin);
            }

            if (methodChannel != null) {
                Log.i(TAG, "Invoking handleDigitalCredentialRequest on Flutter channel");
                methodChannel.invokeMethod("handleDigitalCredentialRequest", messageToFlutter.toString());
            } else {
                Log.e(TAG, "MethodChannel not initialized yet");
                returnError(new GetCredentialUnknownException("Internal error: channel not ready"));
            }

        } catch (JSONException e) {
            Log.e(TAG, "Error building Flutter message", e);
            returnError(new GetCredentialUnknownException("Error building request: " + e.getMessage()));
        }
    }

    /**
     * Return the credential response to the calling app.
     * The responseJson should contain the protocol-specific response (e.g., OpenID4VP vp_token).
     */
    private void returnCredential(String responseJson) {
        try {
            Log.i(TAG, "Returning credential response to caller");
            Log.i(TAG, "Response JSON length: " + responseJson.length());

            // Create a DigitalCredential with the response JSON
            // The responseJson should be in the format expected by the Digital Credentials API
            DigitalCredential credential = new DigitalCredential(responseJson);
            GetCredentialResponse response = new GetCredentialResponse(credential);

            PendingIntentHandler.setGetCredentialResponse(resultIntent, response);
            setResult(Activity.RESULT_OK, resultIntent);

            Log.i(TAG, "Credential response set successfully, finishing activity");
            finish();

        } catch (Exception e) {
            Log.e(TAG, "Error returning credential", e);
            returnError(new GetCredentialUnknownException("Error returning credential: " + e.getMessage()));
        }
    }

    /**
     * Return an error to the calling app.
     */
    private void returnError(GetCredentialException exception) {
        Log.e(TAG, "Returning error to caller: " + exception.getMessage());
        PendingIntentHandler.setGetCredentialException(resultIntent, exception);
        setResult(Activity.RESULT_OK, resultIntent);
        finish();
    }
}
