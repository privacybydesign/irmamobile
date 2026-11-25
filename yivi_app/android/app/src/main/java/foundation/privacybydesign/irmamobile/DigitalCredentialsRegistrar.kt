package foundation.privacybydesign.irmamobile

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
import androidx.credentials.registry.provider.digitalcredentials.VerificationEntryDisplayProperties
import androidx.credentials.registry.provider.digitalcredentials.VerificationFieldDisplayProperties
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import org.json.JSONArray

/**
 * Registers Yivi with the Android Credential Manager as an OpenID4VP Digital
 * Credentials provider, so a verifier's `navigator.credentials.get({digital})`
 * surfaces Yivi in the platform's credential picker.
 *
 * The registration lists the credentials a verifier can ask Yivi for; the
 * OpenID4VP library's bundled matcher decides at request time whether a
 * `dcql_query` is satisfied by any of them. What is listed comes from Dart,
 * which knows the scheme: every credential type of it, as an SD-JWT with its
 * attributes as claims. See `digitalCredentialsRegistryEntries` in `yivi_core`.
 *
 * The list follows the scheme and not what the wallet holds, so it is the same
 * for every user and tells Play services, which stores it, nothing about this
 * one. The picker therefore also offers Yivi to a user who does not have the
 * credential that is asked for.
 *
 * Only builds that set `digital_credentials_provider_enabled` register, which
 * is the alpha build; the same switch keeps [DigitalCredentialsActivity]
 * disabled elsewhere.
 *
 * It lives in this app rather than in the shared `yivi_core` plugin because the
 * registration is stored by Google Play services: the library that does so is
 * proprietary, and `yivi_core` is also built into the F-Droid app, which must
 * not carry it. The Activity the platform launches for a request,
 * [DigitalCredentialsActivity], is in this app for the same reason, so an app
 * registers exactly when it can also answer.
 */
object DigitalCredentialsRegistrar {
    private const val TAG = "DigitalCredentials"

    // The Dart side is MethodChannelDigitalCredentialsRegistry.
    private const val CHANNEL = "irma.app/digital_credentials_registry"

    // Stable per-registry id: re-registering with it upserts rather than adds.
    private const val REGISTRY_ID = "yivi-openid4vp"

    // The picker shows the logo as a small icon, and the whole registration is
    // handed to Play services in one go. Scheme logos are up to 512 px.
    private const val LOGO_SIZE_PX = 96

    // Decoding a logo per credential type is too much for the platform thread.
    private val worker = Executors.newSingleThreadExecutor()

    // What was registered last, so that an unchanged scheme is not registered
    // again by every engine and every scheme update. Only read and written on
    // [worker].
    private var registeredEntriesJson: String? = null

    /** Lets the Dart side of [flutterEngine] say what to register. */
    @JvmStatic
    fun attach(flutterEngine: FlutterEngine, context: Context) {
        val applicationContext = context.applicationContext
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "register") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val entriesJson = call.arguments as? String
            if (entriesJson == null) {
                result.error("invalid_argument", "expected the entries as a JSON string", null)
                return@setMethodCallHandler
            }
            register(applicationContext, entriesJson)
            result.success(null)
        }
    }

    private fun register(context: Context, entriesJson: String) {
        if (!context.resources.getBoolean(R.bool.digital_credentials_provider_enabled)) {
            return
        }
        worker.execute {
            if (entriesJson == registeredEntriesJson) {
                return@execute
            }
            try {
                val entries = entries(context, entriesJson)
                registeredEntriesJson = entriesJson
                RegistryManager.create(context).registerCredentialsAsync(
                    OpenId4VpRegistry(entries, REGISTRY_ID),
                    CancellationSignal(),
                    Executor { it.run() },
                    object : CredentialManagerCallback<RegisterCredentialsResponse, RegisterCredentialsException> {
                        override fun onResult(result: RegisterCredentialsResponse) {
                            Log.i(TAG, "registered ${entries.size} OpenID4VP credentials with the Credential Manager")
                        }

                        override fun onError(e: RegisterCredentialsException) {
                            // Leave it retriable: a failed attempt should not stick.
                            worker.execute { registeredEntriesJson = null }
                            Log.e(TAG, "failed to register OpenID4VP credentials", e)
                        }
                    },
                )
            } catch (e: Throwable) {
                // No GMS / library missing / older platform — the app runs without DC.
                registeredEntriesJson = null
                Log.w(TAG, "Digital Credentials registration unavailable: ${e.message}")
            }
        }
    }

    /** The registry entries for what Dart sent; see `DigitalCredentialsRegistryEntry.toJson`. */
    private fun entries(context: Context, entriesJson: String): List<SdJwtEntry> {
        val json = JSONArray(entriesJson)
        // Most credential types have a logo of their own, the rest share this one.
        val fallbackIcon by lazy { appIcon(context) }

        return (0 until json.length()).map { i ->
            val entry = json.getJSONObject(i)
            val credentialType = entry.getString("credential_type")
            val claimsJson = entry.getJSONArray("claims")

            val claims = (0 until claimsJson.length()).map { j ->
                val claim = claimsJson.getJSONObject(j)
                SdJwtClaim(
                    listOf(claim.getString("id")),
                    // The wallet holds the value, it is not disclosed at match time.
                    null,
                    setOf(VerificationFieldDisplayProperties(claim.getString("name"), null)),
                    true,
                )
            }

            val logoPath = if (entry.isNull("logo_path")) null else entry.getString("logo_path")
            val display = VerificationEntryDisplayProperties(
                entry.getString("name"),
                entry.getString("issuer_name"),
                logoPath?.let(::logo) ?: fallbackIcon,
            )
            // The credential type id is both what a request asks for (the vct)
            // and what tells the entries apart.
            SdJwtEntry(credentialType, claims, setOf(display), credentialType)
        }
    }

    /** The scheme logo at [path], scaled down for the picker, or null if it cannot be read. */
    private fun logo(path: String): Bitmap? {
        try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                return null
            }

            // Decode at the smallest power-of-two reduction that still covers
            // the target, then scale to it exactly.
            var sampleSize = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / (sampleSize * 2) >= LOGO_SIZE_PX) {
                sampleSize *= 2
            }
            val decoded = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sampleSize })
                ?: return null

            val scale = LOGO_SIZE_PX.toFloat() / maxOf(decoded.width, decoded.height)
            if (scale >= 1f) {
                return decoded
            }
            return Bitmap.createScaledBitmap(
                decoded,
                (decoded.width * scale).toInt().coerceAtLeast(1),
                (decoded.height * scale).toInt().coerceAtLeast(1),
                true,
            )
        } catch (e: Throwable) {
            Log.w(TAG, "could not load credential logo $path: ${e.message}")
            return null
        }
    }

    /** The Yivi app icon, falling back to a solid Yivi-blue tile. */
    private fun appIcon(context: Context): Bitmap {
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
            val bitmap = Bitmap.createBitmap(LOGO_SIZE_PX, LOGO_SIZE_PX, Bitmap.Config.ARGB_8888)
            Canvas(bitmap).drawColor(Color.rgb(0x00, 0x4C, 0x92))
            return bitmap
        }
    }
}
