import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import '../models/rig.dart';

/// Image import helpers using the image 4.x Pixel API.
class ImageUploadService {
  static Future<img.Image?> loadImage(String filePath) async {
    try { return img.decodeImage(await File(filePath).readAsBytes()); }
    catch (e) { print('Error loading image: $e'); return null; }
  }

  static Future<String> saveImageToTemp(Uint8List imageBytes, String name) async {
    final file = File('${Directory.systemTemp.path}/shinra_$name.png');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  static Map<PartType, Rect> segmentImage(img.Image image) {
    final width = image.width.toDouble(), height = image.height.toDouble();
    return {
      PartType.face: Rect.fromLTWH(.25 * width, 0, .5 * width, .25 * height),
      PartType.body: Rect.fromLTWH(.2 * width, .25 * height, .6 * width, .35 * height),
      PartType.hand: Rect.fromLTWH(0, .3 * height, .2 * width, .2 * height),
      PartType.shoes: Rect.fromLTWH(.2 * width, .6 * height, .6 * width, .4 * height),
    };
  }

  static img.Image? cropRegion(img.Image image, Rect normalizedRegion) {
    try {
      final x = (normalizedRegion.left * image.width).round().clamp(0, image.width - 1);
      final y = (normalizedRegion.top * image.height).round().clamp(0, image.height - 1);
      final w = (normalizedRegion.width * image.width).round().clamp(1, image.width - x);
      final h = (normalizedRegion.height * image.height).round().clamp(1, image.height - y);
      return img.copyCrop(image, x: x, y: y, width: w, height: h);
    } catch (e) { print('Error cropping region: $e'); return null; }
  }

  static img.Image? resizeImage(img.Image image, int width, int height) {
    try { return img.copyResize(image, width: width, height: height); }
    catch (e) { print('Error resizing image: $e'); return null; }
  }

  static img.Image? removeBackground(img.Image image, {Color? bgColor}) {
    try {
      final bg = bgColor ?? const Color.fromARGB(255, 255, 255, 255);
      const threshold = 30;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final p = image.getPixel(x, y);
          final r = p.r.round(), g = p.g.round(), b = p.b.round();
          if ((r-bg.red).abs()<threshold && (g-bg.green).abs()<threshold && (b-bg.blue).abs()<threshold) {
            image.setPixel(x, y, img.ColorUint8.rgba(r, g, b, 0));
          }
        }
      }
      return image;
    } catch (e) { print('Error removing background: $e'); return null; }
  }

  static img.Image? tintImage(img.Image image, Color color) {
    try {
      final out = image.clone();
      for (var y=0; y<out.height; y++) {
        for (var x=0; x<out.width; x++) {
          final p=out.getPixel(x,y);
          final a=p.a.round();
          final r=(p.r*color.red/255).round().clamp(0,255);
          final g=(p.g*color.green/255).round().clamp(0,255);
          final b=(p.b*color.blue/255).round().clamp(0,255);
          out.setPixel(x,y,img.ColorUint8.rgba(r,g,b,a));
        }
      }
      return out;
    } catch(e) { print('Error tinting image: $e'); return null; }
  }
}
