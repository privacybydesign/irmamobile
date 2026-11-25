package foundation.privacybydesign.irmamobile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.os.CancellationSignal
import android.util.Base64
import android.util.Log
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.registry.digitalcredentials.mdoc.MdocEntry
import androidx.credentials.registry.digitalcredentials.mdoc.MdocField
import androidx.credentials.registry.digitalcredentials.openid4vp.OpenId4VpRegistry
import androidx.credentials.registry.digitalcredentials.sdjwt.SdJwtClaim
import androidx.credentials.registry.digitalcredentials.sdjwt.SdJwtEntry
import androidx.credentials.registry.provider.RegisterCredentialsException
import androidx.credentials.registry.provider.RegisterCredentialsResponse
import androidx.credentials.registry.provider.RegistryManager
import androidx.credentials.registry.provider.digitalcredentials.DigitalCredentialEntry
import androidx.credentials.registry.provider.digitalcredentials.VerificationEntryDisplayProperties
import androidx.credentials.registry.provider.digitalcredentials.VerificationFieldDisplayProperties
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import org.json.JSONArray
import org.json.JSONObject

/**
 * Registers Yivi with the Android Credential Manager as an OpenID4VP Digital
 * Credentials provider, so a verifier's `navigator.credentials.get({digital})`
 * surfaces Yivi in the platform's credential picker.
 *
 * The registration lists the credentials a verifier can ask Yivi for; the
 * OpenID4VP library's bundled matcher decides at request time whether a
 * `dcql_query` is satisfied by any of them. What is listed is decided by the Go
 * core (`GetDigitalCredentialsRegistry` in irmago) and reaches this class
 * through Dart, unread: the credential types of the scheme as SD-JWTs, and the
 * SD-JWT VC and mdoc credentials the wallet obtained over OpenID4VCI. This
 * class only turns an entry into the registry's type for its format, and
 * leaves out the formats the registry has no type for.
 *
 * The scheme's credential types are listed whether or not the wallet holds
 * them, so the picker also offers Yivi to a user who does not have the
 * credential that is asked for. For a credential obtained over OpenID4VCI
 * there is no scheme to list from: Play services, which stores the
 * registration, learns that the wallet holds that type and the names of its
 * claims. It never gets a value.
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

    // The credential formats of an entry the registry has a type for.
    private const val FORMAT_SD_JWT_VC = "dc+sd-jwt"
    private const val FORMAT_MSO_MDOC = "mso_mdoc"

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

    /**
     * The registry entries for what the Go core listed; see
     * `clientmodels.DigitalCredentialsRegistryEntry` in irmago.
     */
    private fun entries(context: Context, entriesJson: String): List<DigitalCredentialEntry> {
        val json = JSONArray(entriesJson)
        // Most credential types have a logo of their own, the rest share this one.
        val fallbackIcon by lazy { appIcon(context) }

        return (0 until json.length()).mapNotNull { i ->
            val entry = json.getJSONObject(i)
            val id = entry.getString("id")
            // What a request asks for: the vct of an SD-JWT, the docType of an mdoc.
            val type = entry.getString("type")
            val claims = entry.getJSONArray("claims").let { claimsJson ->
                (0 until claimsJson.length()).map { claimsJson.getJSONObject(it) }
            }
            val display by lazy {
                setOf(
                    VerificationEntryDisplayProperties(
                        entry.getString("name"),
                        entry.getString("issuer_name"),
                        logo(entry) ?: fallbackIcon,
                    ),
                )
            }

            // The wallet holds the values, none is disclosed at match time.
            when (val format = entry.getString("format")) {
                FORMAT_SD_JWT_VC -> SdJwtEntry(
                    type,
                    claims.map { claim ->
                        SdJwtClaim(path(claim), null, fieldDisplay(claim), true)
                    },
                    display,
                    id,
                )

                FORMAT_MSO_MDOC -> MdocEntry(
                    type,
                    claims.mapNotNull { claim ->
                        // Always the namespace and the element identifier.
                        val path = path(claim)
                        if (path.size != 2) null else MdocField(path[0], path[1], null, fieldDisplay(claim))
                    },
                    display,
                    id,
                )

                // The OpenID4VP registry has no entry type for it, so its
                // matcher could not match a request for one: vc+sd-jwt, and
                // whatever the core learns to list after this was written.
                else -> {
                    Log.i(TAG, "not registering $id: no registry entry type for $format")
                    null
                }
            }
        }
    }

    private fun path(claim: JSONObject): List<String> {
        val path = claim.getJSONArray("path")
        return (0 until path.length()).map(path::getString)
    }

    private fun fieldDisplay(claim: JSONObject) =
        setOf(VerificationFieldDisplayProperties(claim.getString("name"), null))

    /**
     * The logo of [entry], scaled down for the picker, or null if it has none
     * or it cannot be read. A scheme logo is a file, the logo of a credential
     * obtained over OpenID4VCI comes along as base64.
     */
    private fun logo(entry: JSONObject): Bitmap? {
        try {
            entry.optString("logo_path").takeIf { it.isNotEmpty() }?.let { path ->
                return scaledLogo { options -> BitmapFactory.decodeFile(path, options) }
            }
            val base64 = entry.optJSONObject("logo")?.optString("base64")
            if (base64.isNullOrEmpty()) {
                return null
            }
            val bytes = Base64.decode(base64, Base64.DEFAULT)
            return scaledLogo { options -> BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options) }
        } catch (e: Throwable) {
            Log.w(TAG, "could not load the logo of ${entry.optString("id")}: ${e.message}")
            return null
        }
    }

    /** The image [decode] reads, at most [LOGO_SIZE_PX] wide and high, or null if it is not a bitmap. */
    private fun scaledLogo(decode: (BitmapFactory.Options) -> Bitmap?): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        decode(bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            return null
        }

        // Decode at the smallest power-of-two reduction that still covers
        // the target, then scale to it exactly.
        var sampleSize = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sampleSize * 2) >= LOGO_SIZE_PX) {
            sampleSize *= 2
        }
        val decoded = decode(BitmapFactory.Options().apply { inSampleSize = sampleSize })
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
