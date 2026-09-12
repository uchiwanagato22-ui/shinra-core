import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Image editing utilities for uploaded/drawn character art — background
/// removal, recolor, mirror, brightness. Written against package:image v4's
/// real Pixel-based API (the version actually in pubspec.yaml); an earlier
/// draft of this file used the old v2/v3 API (img.getRed(), image.data as a
/// flat int list) which doesn't exist in v4 and would not have compiled.
class ImageUploadService {
  static Future<img.Image?> loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    return img.decodeImage(bytes);
  }

  static Future<String> saveImage(img.Image image, String baseName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/shinra_${baseName}_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(img.encodePng(image));
    return file.path;
  }

  /// Makes pixels close to [bgColor] (white by default) transparent. Simple
  /// color-distance threshold — works well for flat/solid-color backgrounds
  /// (most drawn or studio-photographed character art); it will not cleanly
  /// separate a busy photographic background from hair strands etc. — that
  /// needs real matting, out of scope here.
  static img.Image removeBackground(img.Image image, {Color bgColor = const Color(0xFFFFFFFF), int threshold = 30}) {
    final out = image.clone();
    final br = bgColor.red, bg = bgColor.green, bb = bgColor.blue;
    for (final pixel in out) {
      final dr = (pixel.r - br).abs();
      final dg = (pixel.g - bg).abs();
      final db = (pixel.b - bb).abs();
      if (dr < threshold && dg < threshold && db < threshold) {
        pixel.a = 0;
      }
    }
    return out;
  }

  /// Tints the image toward [color] — quick recolor for uploaded/generated
  /// art (e.g. matching an outfit color scheme) without repainting from
  /// scratch. [strength] 0 = no change, 1 = fully replaced by the tint color
  /// (alpha preserved either way).
  static img.Image tint(img.Image image, Color color, {double strength = .35}) {
    final out = image.clone();
    for (final pixel in out) {
      pixel.r = (pixel.r * (1 - strength) + color.red * strength).round();
      pixel.g = (pixel.g * (1 - strength) + color.green * strength).round();
      pixel.b = (pixel.b * (1 - strength) + color.blue * strength).round();
    }
    return out;
  }

  static img.Image adjustBrightness(img.Image image, double factor) {
    final out = image.clone();
    for (final pixel in out) {
      pixel.r = (pixel.r * factor).clamp(0, 255).round();
      pixel.g = (pixel.g * factor).clamp(0, 255).round();
      pixel.b = (pixel.b * factor).clamp(0, 255).round();
    }
    return out;
  }

  static img.Image flipHorizontal(img.Image image) => img.flipHorizontal(image);
  static img.Image grayscale(img.Image image) => img.grayscale(image);
}
