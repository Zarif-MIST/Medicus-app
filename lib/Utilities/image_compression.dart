import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Thrown when a picked image can't be compressed under [compressImageToBase64]'s
/// size cap even at the most aggressive resize/quality pass.
class ImageTooLargeException implements Exception {
  const ImageTooLargeException();
}

/// Resizes/re-encodes [rawBytes] so the base64 payload fits comfortably in a
/// Firestore document (capped at ~1 MiB) — the shared strategy behind every
/// "store a photo inline, no Storage bucket needed" flow in this app.
String compressImageToBase64(
  Uint8List rawBytes, {
  int maxEncodedBytes = 700 * 1024,
}) {
  final img.Image? decoded = img.decodeImage(rawBytes);
  if (decoded == null) {
    throw const ImageTooLargeException();
  }

  for (final int maxDimension in [1000, 700, 500]) {
    final img.Image resized = decoded.width > maxDimension || decoded.height > maxDimension
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxDimension : null,
            height: decoded.height > decoded.width ? maxDimension : null,
          )
        : decoded;

    for (final int quality in [70, 50, 35]) {
      final Uint8List encoded = img.encodeJpg(resized, quality: quality);
      final String base64Str = base64Encode(encoded);
      if (base64Str.length <= maxEncodedBytes) {
        return base64Str;
      }
    }
  }

  throw const ImageTooLargeException();
}
