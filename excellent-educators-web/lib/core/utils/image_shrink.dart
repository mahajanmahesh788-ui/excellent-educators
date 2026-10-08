import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Shrinks an image so the JPEG payload is at most [maxBytes] (default 1 MB).
///
/// Returns the original bytes when already under the limit. Always encodes as
/// JPEG after decode so oversized PNGs/WebPs become smaller uploads.
Uint8List shrinkImageToMaxBytes(
  Uint8List bytes, {
  int maxBytes = 1024 * 1024,
  int maxEdge = 1280,
}) {
  if (bytes.lengthInBytes <= maxBytes) {
    return bytes;
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Could not decode the selected image.');
  }

  var image = decoded;
  final longest = math.max(image.width, image.height);
  if (longest > maxEdge) {
    final scale = maxEdge / longest;
    image = img.copyResize(
      image,
      width: math.max(1, (image.width * scale).round()),
      height: math.max(1, (image.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  var quality = 85;
  var encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
  while (encoded.lengthInBytes > maxBytes && quality > 45) {
    quality -= 10;
    encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  var edge = math.max(image.width, image.height);
  while (encoded.lengthInBytes > maxBytes && edge > 320) {
    edge = (edge * 0.75).round();
    final scale = edge / math.max(image.width, image.height);
    image = img.copyResize(
      image,
      width: math.max(1, (image.width * scale).round()),
      height: math.max(1, (image.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
    encoded = Uint8List.fromList(img.encodeJpg(image, quality: 70));
  }

  if (encoded.lengthInBytes > maxBytes) {
    throw StateError(
      'Image is still larger than 1 MB after shrinking. Try a smaller photo.',
    );
  }

  return encoded;
}
