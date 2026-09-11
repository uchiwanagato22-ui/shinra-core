import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import '../models/rig.dart';

/// Handles image upload, segmentation, and animation rigging.
/// Allows users to upload their own image and animate it on the character rig.
class ImageUploadService {
  
  /// Load image from file path
  static Future<img.Image?> loadImage(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return img.decodeImage(bytes);
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  /// Save image bytes to file
  static Future<String> saveImageToTemp(Uint8List imageBytes, String name) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/shinra_$name.png');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  /// Simple automatic segmentation: divide image into body parts based on height.
  /// This is a basic heuristic — for production use ML-based segmentation.
  static Map<PartType, Rect> segmentImage(img.Image image) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    
    // Rough division of a standing character:
    // - Head: top 25%
    // - Torso: 25% to 60%
    // - Legs: 60% to 100%
    // - Arms: positioned on torso sides
    
    return {
      PartType.face: Rect.fromLTWH(0.25 * width, 0, 0.5 * width, 0.25 * height),
      PartType.body: Rect.fromLTWH(0.2 * width, 0.25 * height, 0.6 * width, 0.35 * height),
      PartType.hand: Rect.fromLTWH(0, 0.3 * height, 0.2 * width, 0.2 * height),
      PartType.shoes: Rect.fromLTWH(0.2 * width, 0.6 * height, 0.6 * width, 0.4 * height),
    };
  }

  /// Crop a region from the image (for isolated part animation)
  static img.Image? cropRegion(img.Image image, Rect normalizedRegion) {
    try {
      final x = (normalizedRegion.left * image.width).toInt();
      final y = (normalizedRegion.top * image.height).toInt();
      final w = (normalizedRegion.width * image.width).toInt();
      final h = (normalizedRegion.height * image.height).toInt();
      
      return img.copyCrop(image, x: x, y: y, width: w, height: h);
    } catch (e) {
      print('Error cropping region: $e');
      return null;
    }
  }

  /// Resize image to match target bone or viewport dimensions
  static img.Image? resizeImage(img.Image image, int width, int height) {
    try {
      return img.copyResize(image, width: width, height: height);
    } catch (e) {
      print('Error resizing image: $e');
      return null;
    }
  }

  /// Remove background (simple color-based, for better results use ML model)
  static img.Image? removeBackground(img.Image image, {Color? bgColor}) {
    try {
      final bgCol = bgColor ?? Color.fromARGB(255, 255, 255, 255);
      final threshold = 30;

      for (var i = 0; i < image.data!.length; i++) {
        final pixel = image.data![i];
        final a = img.getAlpha(pixel);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);

        // Check if pixel is close to background color
        if ((r - bgCol.red).abs() < threshold && 
            (g - bgCol.green).abs() < threshold && 
            (b - bgCol.blue).abs() < threshold) {
          image.data![i] = img.getColor(r, g, b, 0); // Transparent
        }
      }
      return image;
    } catch (e) {
      print('Error removing background: $e');
      return null;
    }
  }

  /// Apply tint/color overlay to image
  static img.Image? tintImage(img.Image image, Color color) {
    try {
      final tinted = img.Image(width: image.width, height: image.height);
      
      for (var i = 0; i < image.data!.length; i++) {
        final pixel = image.data![i];
        final a = img.getAlpha(pixel);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        // Blend with tint color
        final tintedR = ((r * color.red) ~/ 255).clamp(0, 255);
        final tintedG = ((g * color.green) ~/ 255).clamp(0, 255);
        final tintedB = ((b * color.blue) ~/ 255).clamp(0, 255);
        
        tinted.data![i] = img.getColor(tintedR, tintedG, tintedB, a);
      }
      return tinted;
    } catch (e) {
      print('Error tinting image: $e');
      return null;
    }
  }

  /// Flip image horizontally (for mirror pose)
  static img.Image? flipHorizontal(img.Image image) {
    try {
      return img.flipHorizontal(image);
    } catch (e) {
      print('Error flipping image: $e');
      return null;
    }
  }

  /// Flip image vertically
  static img.Image? flipVertical(img.Image image) {
    try {
      return img.flipVertical(image);
    } catch (e) {
      print('Error flipping image: $e');
      return null;
    }
  }

  /// Convert image to grayscale
  static img.Image? toGrayscale(img.Image image) {
    try {
      return img.grayscale(image);
    } catch (e) {
      print('Error converting to grayscale: $e');
      return null;
    }
  }

  /// Adjust brightness
  static img.Image? adjustBrightness(img.Image image, double factor) {
    try {
      for (var i = 0; i < image.data!.length; i++) {
        final pixel = image.data![i];
        final a = img.getAlpha(pixel);
        var r = (img.getRed(pixel) * factor).toInt().clamp(0, 255);
        var g = (img.getGreen(pixel) * factor).toInt().clamp(0, 255);
        var b = (img.getBlue(pixel) * factor).toInt().clamp(0, 255);
        
        image.data![i] = img.getColor(r, g, b, a);
      }
      return image;
    } catch (e) {
      print('Error adjusting brightness: $e');
      return null;
    }
  }

  /// Apply edge detection for outline effect
  static img.Image? detectEdges(img.Image image) {
    try {
      return img.sobel(image);
    } catch (e) {
      print('Error detecting edges: $e');
      return null;
    }
  }

  /// Export processed image to bytes
  static Uint8List? imageToBytes(img.Image? image, {bool asPng = true}) {
    if (image == null) return null;
    try {
      if (asPng) {
        return Uint8List.fromList(img.encodePng(image));
      } else {
        return Uint8List.fromList(img.encodeJpg(image));
      }
    } catch (e) {
      print('Error encoding image: $e');
      return null;
    }
  }
}

/// Animated image wrapper for display on rig bones.
class AnimatedImagePart {
  AnimatedImagePart({
    required this.boneId,
    required this.imageBytes,
    this.scale = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final String boneId;
  final Uint8List imageBytes;
  double scale;
  double offsetX;
  double offsetY;

  AnimatedImagePart copy() => AnimatedImagePart(
    boneId: boneId,
    imageBytes: imageBytes,
    scale: scale,
    offsetX: offsetX,
    offsetY: offsetY,
  );
}
