part of 'yivi_pin_screen.dart';

List<Widget> _listBuilder(BuildContext context, EnterPinState state) {
  final attributes = state.attributes;
  final tiles = [
    _UnsecurePinDescriptionTile(
      followsRule: attributes.contains(SecurePinAttribute.containsThreeUnique),
      descriptionKey: 'secure_pin.rules.contains_3_unique',
    ),
    _UnsecurePinDescriptionTile(
      followsRule: attributes.contains(SecurePinAttribute.mustNotAscNorDesc),
      descriptionKey: 'secure_pin.rules.must_not_asc_or_desc',
    ),
    _UnsecurePinDescriptionTile(
      followsRule: attributes.contains(SecurePinAttribute.notAbcabNorAbcba),
      descriptionKey: 'secure_pin.rules.not_abcab_nor_abcba',
    ),
    if (state.pin.length > shortPinSize)
      _UnsecurePinDescriptionTile(
        followsRule: attributes.contains(SecurePinAttribute.mustContainValidSubset),
        descriptionKey: 'secure_pin.rules.must_contain_valid_subset',
      ),
  ];

  return ListTile.divideTiles(context: context, tiles: tiles).toList();
}
