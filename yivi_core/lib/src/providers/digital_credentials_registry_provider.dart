import "package:flutter_riverpod/flutter_riverpod.dart";

import "../models/irma_configuration.dart";

/// The scheme whose credential types are offered through the Digital
/// Credentials API.
const digitalCredentialsSchemeId = "pbdf";

/// Tells the platform which credentials a website can ask Yivi for through the
/// W3C Digital Credentials API. The platform only routes a request to Yivi when
/// it matches an entry registered here.
///
/// Injected from the outside via `runYiviApp`: on Android the registration is
/// stored by Google Play services, through a proprietary library that must not
/// enter the FOSS (F-Droid) build. There the provider stays `null` and nothing
/// is registered.
abstract class DigitalCredentialsRegistry {
  /// Replaces what is registered with [entries].
  Future<void> register(List<DigitalCredentialsRegistryEntry> entries);
}

/// Null by default. Overridden in `runYiviApp` with a concrete implementation
/// in the Play Store build; left null in the F-Droid build.
final digitalCredentialsRegistryProvider =
    Provider<DigitalCredentialsRegistry?>((ref) => null);

/// A credential type a website can ask for, as the platform's credential
/// picker shows it.
class DigitalCredentialsRegistryEntry {
  /// What a request names the credential by: the `vct` of its SD-JWT, which is
  /// the full credential type id.
  final String credentialType;
  final String name;
  final String issuerName;

  /// Where the credential type's logo is on disk, if it has one.
  final String? logoPath;
  final List<DigitalCredentialsRegistryClaim> claims;

  const DigitalCredentialsRegistryEntry({
    required this.credentialType,
    required this.name,
    required this.issuerName,
    required this.logoPath,
    required this.claims,
  });

  Map<String, dynamic> toJson() => {
    "credential_type": credentialType,
    "name": name,
    "issuer_name": issuerName,
    "logo_path": logoPath,
    "claims": claims.map((claim) => claim.toJson()).toList(),
  };
}

/// An attribute of a credential type a website can ask for.
class DigitalCredentialsRegistryClaim {
  /// The claim's name in the SD-JWT, which is the attribute id.
  final String id;
  final String name;

  const DigitalCredentialsRegistryClaim({required this.id, required this.name});

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

/// The entries to register for [configuration]: every credential type of the
/// scheme [schemeId], named in [language].
///
/// The list follows the scheme, not the wallet. It is the same for every user,
/// so registering it tells the platform nothing about what this user holds; a
/// user who is asked for a credential they do not have is taken through
/// obtaining it, as in any other disclosure.
List<DigitalCredentialsRegistryEntry> digitalCredentialsRegistryEntries(
  IrmaConfiguration configuration, {
  required String language,
  String schemeId = digitalCredentialsSchemeId,
}) {
  final attributesByCredentialType = <String, List<AttributeType>>{};
  for (final attribute in configuration.attributeTypes.values) {
    // A revocation attribute has no name and is never disclosed.
    if (attribute.schemeManagerId != schemeId || attribute.name.isEmpty) {
      continue;
    }
    attributesByCredentialType
        .putIfAbsent(attribute.fullCredentialId, () => [])
        .add(attribute);
  }

  final entries = <DigitalCredentialsRegistryEntry>[];
  for (final credentialType in configuration.credentialTypes.values) {
    if (credentialType.schemeManagerId != schemeId) continue;

    final attributes = attributesByCredentialType[credentialType.fullId];
    // Without a claim there is nothing a request could match on.
    if (attributes == null) continue;
    attributes.sort((a, b) => a.index.compareTo(b.index));

    final issuer = configuration.issuers[credentialType.fullIssuerId];
    entries.add(
      DigitalCredentialsRegistryEntry(
        credentialType: credentialType.fullId,
        name: credentialType.name.translate(language),
        issuerName: issuer?.name.translate(language) ?? "",
        logoPath: credentialType.logo,
        claims: [
          for (final attribute in attributes)
            DigitalCredentialsRegistryClaim(
              id: attribute.id,
              name: attribute.name.translate(language),
            ),
        ],
      ),
    );
  }

  // The configuration is a map; a stable order keeps an unchanged scheme from
  // looking like a change to whoever stores the registration.
  entries.sort((a, b) => a.credentialType.compareTo(b.credentialType));
  return entries;
}
