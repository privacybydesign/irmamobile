package foundation.privacybydesign.irmamobile;

import android.app.PendingIntent;
import android.content.Intent;
import android.os.CancellationSignal;
import android.os.OutcomeReceiver;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.credentials.exceptions.ClearCredentialException;
import androidx.credentials.exceptions.GetCredentialException;
import androidx.credentials.exceptions.GetCredentialUnknownException;
import androidx.credentials.exceptions.CreateCredentialUnknownException;
import androidx.credentials.provider.BeginCreateCredentialRequest;
import androidx.credentials.provider.BeginCreateCredentialResponse;
import androidx.credentials.provider.BeginGetCredentialOption;
import androidx.credentials.provider.BeginGetCredentialRequest;
import androidx.credentials.provider.BeginGetCredentialResponse;
import androidx.credentials.provider.Action;
import androidx.credentials.provider.AuthenticationAction;
import androidx.credentials.provider.CredentialEntry;
import androidx.credentials.provider.CustomCredentialEntry;
import androidx.credentials.provider.CredentialProviderService;
import androidx.credentials.provider.ProviderClearCredentialStateRequest;

import java.util.ArrayList;
import java.util.List;

/**
 * @deprecated This service is NOT used for Digital Credentials API.
 * The Digital Credentials API uses the registry-based provider pattern with GetCredentialActivity.
 * This class is kept for reference only and is not registered in AndroidManifest.xml.
 *
 * NOTE: CredentialProviderService is for generic Credential Manager APIs (passwords, passkeys),
 * not for Digital Credentials API which requires the registry provider pattern.
 */
@Deprecated
public class YiviCredentialProviderService extends CredentialProviderService {
    private static final String TAG = "YiviCredentialProvider";

    @Override
    public void onBeginGetCredentialRequest(
        @NonNull BeginGetCredentialRequest request,
        @NonNull CancellationSignal cancellationSignal,
        @NonNull OutcomeReceiver<BeginGetCredentialResponse, GetCredentialException> callback
    ) {
        Log.i(TAG, "onBeginGetCredentialRequest called");

        try {
            // Log all the credential options we received
            Log.i(TAG, "onBeginGetCredentialRequest called with " + request.getBeginGetCredentialOptions().size() + " options");

            boolean hasDigitalCredentialRequest = false;
            for (BeginGetCredentialOption option : request.getBeginGetCredentialOptions()) {
                String type = option.getType();
                Log.i(TAG, "Credential option type: " + type);
                Log.i(TAG, "Candidate query data: " + option.getCandidateQueryData());

                // Check if this is a digital credential or OpenID4VP request
                if (type.contains("DigitalCredential") || type.contains("openid4vp") ||
                    type.equals("androidx.credentials.TYPE_DIGITAL_CREDENTIAL")) {
                    hasDigitalCredentialRequest = true;
                }
            }

            BeginGetCredentialResponse.Builder responseBuilder = new BeginGetCredentialResponse.Builder();

            // Add an authentication action that launches Yivi to handle the request
            // This makes Yivi appear in the credential selector
            Intent intent = new Intent(this, MainActivity.class);
            intent.setAction("android.credentials.provider.action.GET_CREDENTIAL");
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);

            PendingIntent pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );

            AuthenticationAction authAction = new AuthenticationAction(
                "Use Yivi",  // Title shown in credential selector
                pendingIntent
            );

            responseBuilder.setAuthenticationActions(List.of(authAction));

            Log.i(TAG, "Returning response with authentication action. Has digital credential request: " + hasDigitalCredentialRequest);
            callback.onResult(responseBuilder.build());

        } catch (Exception e) {
            Log.e(TAG, "Error in onBeginGetCredentialRequest", e);
            callback.onError(new GetCredentialUnknownException("Error processing request: " + e.getMessage()));
        }
    }

    @Override
    public void onBeginCreateCredentialRequest(
        @NonNull BeginCreateCredentialRequest request,
        @NonNull CancellationSignal cancellationSignal,
        @NonNull OutcomeReceiver<BeginCreateCredentialResponse, androidx.credentials.exceptions.CreateCredentialException> callback
    ) {
        // Yivi is a wallet, not a credential issuer via Android Credential Manager
        // We don't support credential creation through this API
        Log.i(TAG, "onBeginCreateCredentialRequest called - not supported");
        callback.onError(new CreateCredentialUnknownException(
            "Credential creation not supported"
        ));
    }

    @Override
    public void onClearCredentialStateRequest(
        @NonNull ProviderClearCredentialStateRequest request,
        @NonNull CancellationSignal cancellationSignal,
        @NonNull OutcomeReceiver<Void, ClearCredentialException> callback
    ) {
        // Nothing to clear - Yivi manages its own credential storage
        Log.i(TAG, "onClearCredentialStateRequest called");
        callback.onResult(null);
    }
}
