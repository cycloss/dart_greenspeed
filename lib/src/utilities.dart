import 'dart:math';
import 'dart:typed_data';

Uint8List generateRandomBytes(int length) {
  if (length < 0) {
    throw Exception('Byte list length must be greater than 0');
  }

  final random = Random();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

void main() {
  var bytes = generateRandomBytes(16);
  print(bytes);
}
