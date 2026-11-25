package foundation.privacybydesign.yivi_core.irma_mobile_bridge

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * [DigitalCredentialsRequestExtractor] sits between the platform and the core:
 * it picks the OpenID4VP request out of what the Credential Manager hands over
 * and pairs it with the caller origin the platform authenticated. The core
 * binds the response to that origin, so what these tests pin is that the origin
 * always comes from the platform and that the verifier's `data` reaches the
 * core as it was sent.
 */
internal class DigitalCredentialsRequestExtractorTest {
    private val origin = "https://verifier.example.com"

    private val unsignedData =
        """
        {
            "response_type": "vp_token",
            "response_mode": "dc_api",
            "nonce": "n-0S6_WzA2Mj",
            "dcql_query": {
                "credentials": [{
                    "id": "email_credential",
                    "format": "dc+sd-jwt",
                    "meta": {"vct_values": ["pbdf-staging.sidn-pbdf.email"]},
                    "claims": [{"path": ["email"]}]
                }]
            }
        }
        """.trimIndent()

    private fun entry(protocol: String, data: String = unsignedData) =
        """{"protocol": "$protocol", "data": $data}"""

    // The tests compile against the org.json of the android.jar, which has
    // neither keySet() nor similar(), so both are spelled out here.
    private fun keysOf(json: JSONObject): Set<String> = json.keys().asSequence().toSet()

    /** [value] as plain Kotlin collections, so two JSON trees compare by content. */
    private fun plain(value: Any?): Any? =
        when (value) {
            is JSONObject -> keysOf(value).associateWith { plain(value.get(it)) }
            is JSONArray -> (0 until value.length()).map { plain(value.get(it)) }
            else -> value
        }

    /** The `request` member of the event the extractor builds. */
    private fun extract(requestJson: String, origin: String = this.origin): JSONObject {
        val event = JSONObject(DigitalCredentialsRequestExtractor.toHandleEventJson(requestJson, origin))
        assertEquals(setOf("request"), keysOf(event))
        return event.getJSONObject("request")
    }

    private fun assertNoRequestFound(requestJson: String) {
        assertThrows(JSONException::class.java) {
            DigitalCredentialsRequestExtractor.toHandleEventJson(requestJson, origin)
        }
    }

    @Test
    fun aRequestsArrayYieldsItsOpenID4VPEntry() {
        val request = extract("""{"requests": [${entry("openid4vp-v1-unsigned")}]}""")

        assertEquals(setOf("protocol", "origin", "data"), keysOf(request))
        assertEquals("openid4vp-v1-unsigned", request.getString("protocol"))
        assertEquals(origin, request.getString("origin"))
        assertEquals(plain(JSONObject(unsignedData)), plain(request.getJSONObject("data")))
    }

    @Test
    fun theProvidersArrayOfOlderDraftsIsReadTheSameWay() {
        val request = extract("""{"providers": [${entry("openid4vp-v1-unsigned")}]}""")

        assertEquals("openid4vp-v1-unsigned", request.getString("protocol"))
        assertEquals(plain(JSONObject(unsignedData)), plain(request.getJSONObject("data")))
    }

    @Test
    fun aSingleRequestObjectAtTheTopLevelIsTakenAsIs() {
        val request = extract(entry("openid4vp-v1-unsigned"))

        assertEquals("openid4vp-v1-unsigned", request.getString("protocol"))
        assertEquals(plain(JSONObject(unsignedData)), plain(request.getJSONObject("data")))
    }

    @Test
    fun entriesOfOtherProtocolsAreSkipped() {
        val mdoc = """{"protocol": "org-iso-mdoc", "data": {"deviceRequest": "o2d2ZXJzaW9u"}}"""

        val request = extract("""{"requests": [$mdoc, ${entry("openid4vp-v1-signed", """{"request": "a.b.c"}""")}]}""")

        assertEquals("openid4vp-v1-signed", request.getString("protocol"))
    }

    @Test
    fun theFirstOpenID4VPEntryWinsWhenThereAreSeveral() {
        val signed = entry("openid4vp-v1-signed", """{"request": "a.b.c"}""")

        val request = extract("""{"requests": [$signed, ${entry("openid4vp-v1-unsigned")}]}""")

        assertEquals("openid4vp-v1-signed", request.getString("protocol"))
        assertEquals("a.b.c", request.getJSONObject("data").getString("request"))
    }

    @Test
    fun theDataOfASignedRequestIsPassedThroughUntouched() {
        // A compact JWS: the core verifies it, so it must arrive byte for byte.
        val jws = "eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUkiXX0.eyJub25jZSI6Im4ifQ.c2lnbmF0dXJl"

        val request = extract("""{"requests": [${entry("openid4vp-v1-signed", """{"request": "$jws"}""")}]}""")

        assertEquals(setOf("request"), keysOf(request.getJSONObject("data")))
        assertEquals(jws, request.getJSONObject("data").getString("request"))
    }

    @Test
    fun theOriginIsThePlatformsAndNeverTheRequests() {
        // A verifier that writes an origin into its own request must not get to
        // pick what the response is bound to.
        val spoofing =
            """{"protocol": "openid4vp-v1-unsigned", "origin": "https://bank.example.com", "data": $unsignedData}"""

        val request = extract("""{"origin": "https://bank.example.com", "requests": [$spoofing]}""")

        assertEquals(origin, request.getString("origin"))
    }

    @Test
    fun anOriginThePlatformCouldNotEstablishStaysEmpty() {
        // The core rejects a request without an origin; the extractor must not
        // fill one in.
        val request = extract("""{"requests": [${entry("openid4vp-v1-unsigned")}]}""", origin = "")

        assertTrue(request.has("origin"))
        assertEquals("", request.getString("origin"))
    }

    @Test
    fun aRequestsArrayWithoutAnOpenID4VPEntryIsRefused() {
        assertNoRequestFound("""{"requests": [{"protocol": "org-iso-mdoc", "data": {}}]}""")
        assertNoRequestFound("""{"requests": []}""")
    }

    @Test
    fun aPreFinalOpenID4VPProtocolIdentifierIsRefused() {
        // The identifiers of the drafts before OpenID4VP 1.0.
        assertNoRequestFound("""{"requests": [${entry("openid4vp")}]}""")
        assertNoRequestFound(entry("openid4vp"))
    }

    @Test
    fun aRequestsArrayIsNotBypassedByATopLevelRequest() {
        // With an array present, only its entries count.
        val topLevel = """"protocol": "openid4vp-v1-unsigned", "data": $unsignedData"""

        assertNoRequestFound("""{"requests": [{"protocol": "org-iso-mdoc", "data": {}}], $topLevel}""")
    }

    @Test
    fun aTopLevelObjectMissingProtocolOrDataIsRefused() {
        assertNoRequestFound("""{"protocol": "openid4vp-v1-unsigned"}""")
        assertNoRequestFound("""{"data": $unsignedData}""")
        assertNoRequestFound("{}")
    }

    @Test
    fun anOpenID4VPEntryWithoutDataIsRefused() {
        assertNoRequestFound("""{"requests": [{"protocol": "openid4vp-v1-unsigned"}]}""")
    }

    @Test
    fun aPayloadThatIsNotAJsonObjectIsRefused() {
        assertNoRequestFound("not json")
        assertNoRequestFound("[]")
    }

    @Test
    fun nonObjectEntriesInTheArrayAreSkippedRatherThanFatal() {
        val request = extract("""{"requests": ["junk", null, 7, ${entry("openid4vp-v1-unsigned")}]}""")

        assertEquals("openid4vp-v1-unsigned", request.getString("protocol"))
        assertFalse(request.getString("origin").isEmpty())
    }
}
