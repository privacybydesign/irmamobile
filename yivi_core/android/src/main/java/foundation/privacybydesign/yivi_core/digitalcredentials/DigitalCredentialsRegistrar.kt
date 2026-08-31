package foundation.privacybydesign.yivi_core.digitalcredentials

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
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
            setOf(VerificationEntryDisplayProperties("Email", "Yivi", icon(context)))
        // value = null: the wallet holds the value, it is not disclosed at match time.
        val claim = SdJwtClaim(listOf("email"), null, fieldDisplay, true)
        return listOf(SdJwtEntry("pbdf-staging.sidn-pbdf.email", listOf(claim), entryDisplay, "yivi-email"))
    }

    // Bundled logo of the credential this entry represents, shown next to the
    // entry in the platform's credential picker.
    // TODO(dc-api): once entries are driven by the wallet's held credentials,
    // load each credential type's logo from the scheme on disk rather than a
    // bundled per-credential asset.
    private const val CREDENTIAL_LOGO_ASSET = "digital_credentials/email_credential_logo.png"

    /**
     * The credential's logo for the picker: the bundled scheme logo, falling
     * back to the Yivi app icon, and finally to a solid Yivi-blue tile.
     */
    private fun icon(context: Context): Bitmap {
        try {
            context.assets.open(CREDENTIAL_LOGO_ASSET).use { stream ->
                BitmapFactory.decodeStream(stream)?.let { return it }
            }
        } catch (e: Throwable) {
            Log.w(TAG, "could not load credential logo asset: ${e.message}")
        }
        try {
            val drawable = context.packageManager.getApplicationIcon(context.packageName)
            if (drawable is BitmapDrawable) {
                drawable.bitmap?.let { return it }
            }
            val width = drawable.intrinsicWidth.coerceAtLeast(1)
            val height = drawable.intrinsicHeight.coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            return bitmap
        } catch (e: Throwable) {
            Log.w(TAG, "could not load app icon, using fallback: ${e.message}")
            val size = 96
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            Canvas(bitmap).drawColor(Color.rgb(0x00, 0x4C, 0x92))
            return bitmap
        }
    }
}
