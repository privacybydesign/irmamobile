package foundation.privacybydesign.yivi_core.digitalcredentials

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.os.CancellationSignal
import android.util.Log
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.registry.digitalcredentials.openid4vp.OpenId4VpRegistry
import androidx.credentials.registry.digitalcredentials.sdjwt.SdJwtClaim
import androidx.credentials.registry.digitalcredentials.sdjwt.SdJwtEntry
import androidx.credentials.registry.provider.RegisterCredentialsException
import androidx.credentials.registry.provider.RegisterCredentialsResponse
import androidx.credentials.registry.provider.RegistryManager
import androidx.credentials.registry.provider.digitalcredentials.EntryDisplayProperties
import androidx.credentials.registry.provider.digitalcredentials.FieldDisplayProperties
import androidx.credentials.registry.provider.digitalcredentials.VerificationEntryDisplayProperties
import androidx.credentials.registry.provider.digitalcredentials.VerificationFieldDisplayProperties
import java.util.concurrent.Executor
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Registers Yivi with the Android Credential Manager as an OpenID4VP Digital
 * Credentials provider, so a verifier's `navigator.credentials.get({digital})`
 * surfaces Yivi in the platform's credential picker.
 *
 * The registration lists the credentials the wallet can disclose; the OpenID4VP
 * library's bundled matcher decides at request time whether a `dcql_query` is
 * satisfied by any of them. This registers a single demo entry — the
 * `test.test.email` SD-JWT credential (claim `email`) — matching what the Go
 * core discloses over the DC API; enough for a verifier requesting that
 * credential to offer Yivi.
 *
 * TODO(dc-api): drive the entry list from the wallet's actual held credentials
 * (re-registering when they change) instead of this fixed demo entry.
 */
object DigitalCredentialsRegistrar {
    private const val TAG = "DigitalCredentials"

    // Stable per-registry id: re-registering with it upserts rather than adds.
    private const val REGISTRY_ID = "yivi-openid4vp"

    // Registration is an idempotent upsert, so once per process is enough.
    private val registered = AtomicBoolean(false)

    @JvmStatic
    fun register(context: Context) {
        if (!registered.compareAndSet(false, true)) {
            return
        }
        try {
            val registryManager = RegistryManager.create(context.applicationContext)
            registryManager.registerCredentialsAsync(
                OpenId4VpRegistry(demoEntries(context), REGISTRY_ID),
                CancellationSignal(),
                Executor { it.run() },
                object : CredentialManagerCallback<RegisterCredentialsResponse, RegisterCredentialsException> {
                    override fun onResult(result: RegisterCredentialsResponse) {
                        Log.i(TAG, "registered OpenID4VP credentials with the Credential Manager")
                    }

                    override fun onError(e: RegisterCredentialsException) {
                        // Leave it retriable: a failed attempt should not stick.
                        registered.set(false)
                        Log.e(TAG, "failed to register OpenID4VP credentials", e)
                    }
                },
            )
        } catch (e: Throwable) {
            // No GMS / library missing / older platform — the app runs without DC.
            registered.set(false)
            Log.w(TAG, "Digital Credentials registration unavailable: ${e.message}")
        }
    }

    private fun demoEntries(context: Context): List<SdJwtEntry> {
        val fieldDisplay: Set<FieldDisplayProperties> =
            setOf(VerificationFieldDisplayProperties("Email address", null))
        val entryDisplay: Set<EntryDisplayProperties> =
            setOf(VerificationEntryDisplayProperties("Email", "Yivi", icon()))
        // value = null: the wallet holds the value, it is not disclosed at match time.
        val claim = SdJwtClaim(listOf("email"), null, fieldDisplay, true)
        return listOf(SdJwtEntry("pbdf-staging.sidn-pbdf.email", listOf(claim), entryDisplay, "yivi-email"))
    }

    private fun icon(): Bitmap {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).drawColor(Color.rgb(0x00, 0x4C, 0x92))
        return bitmap
    }
}
