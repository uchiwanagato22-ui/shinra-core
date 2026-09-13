import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/rig.dart';

/// Renders the current animation clip frame by frame off the live
/// RepaintBoundary and stitches the frames into a real, shareable animated
/// GIF file. No native video encoder involved (that's a separate, bigger
/// piece of work for real MP4 export) — this is pure Dart end to end.
class GifExporter {
  /// Progress callback receives (currentFrame, totalFrames).
  static Future<String> export(GlobalKey boundaryKey, ProjectState p, {int fps = 12, void Function(int, int)? onProgress}) async {
    final clip = p.selectedAnimation;
    final totalFrames = (clip.duration * fps).ceil().clamp(1, 600).toInt();
    img.Image? base;

    for (var i = 0; i < totalFrames; i++) {
      final t = i / fps;
      p.loadAt(t);
      // Let the widget tree actually rebuild/repaint with the new pose
      // before we grab a snapshot of it.
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 16));

      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image shot = await boundary.toImage(pixelRatio: 1);
      final ByteData? bytes = await shot.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) continue;

      final frame = img.Image.fromBytes(
        width: shot.width,
        height: shot.height,
        bytes: bytes.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      frame.frameDuration = (1000 / fps).round();

      if (base == null) {
        base = frame;
      } else {
        base.frames.add(frame);
      }
      onProgress?.call(i + 1, totalFrames);
      shot.dispose();
    }

    if (base == null) throw Exception('Nothing captured — is the export viewport actually on screen?');
    final gifBytes = img.encodeGif(base);
    final dir = await getTemporaryDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/shinra_${clip.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.gif');
    await file.writeAsBytes(gifBytes);
    return file.path;
  }
}
