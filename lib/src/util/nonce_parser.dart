import 'dart:typed_data';

Uint8List stringToUint8List(String input) {
  if (input.length != 16) {
    throw ArgumentError('Input must be exactly 16 characters long');
  }

  // input is hex representation of byte[8]
  final result = Uint8List(8); // 16 hex chars -> 8 bytes
  for (int i = 0; i < 8; i++) {
    final hexPair = input.substring(i * 2, i * 2 + 2);
    result[i] = int.parse(hexPair, radix: 16);
  }
  return result;
}
