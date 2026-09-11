import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/rig.dart';

/// Export to MP4, GIF, or PNG sequence.
/// Supports multiple formats: TikTok (9:16), YouTube (16:9), Shorts (9:16), custom.
class VideoExporter {
  enum ExportFormat {
    tiktok(1080, 1920, 'video.mp4'),      // 9:16 vertical
    youtube(1920, 1080, 'video.mp4'),     // 16:9
    shorts(1080, 1920, 'video.mp4'),      // 9:16 (same as TikTok)
    gif(0, 0, 'animation.gif'),           // Auto-size
    png(0, 0, 'frames');                  // Auto-size, sequence
    
    const ExportFormat(this.width, this.height, this.filename);
    final int width;
    final int height;
    final String filename;
  }

  /// Main export function supporting all formats.
  static Future<String> export({
    required GlobalKey boundaryKey,
    required ProjectState project,
    required ExportFormat format,
    int fps = 30,
    void Function(int, int)? onProgress,
    int? customWidth,
    int? customHeight,
  }) async {
    final width = customWidth ?? format.width;
    final height = customHeight ?? format.height;

    if (format == ExportFormat.gif) {
      return exportGif(boundaryKey, project, fps: fps, onProgress: onProgress);
    } else if (format == ExportFormat.png) {
      return exportPngSequence(boundaryKey, project, fps: fps, onProgress: onProgress);
    } else {
      return exportMp4(boundaryKey, project, width, height, fps: fps, onProgress: onProgress);
    }
  }

  /// Export to MP4 (requires ffmpeg on device or native integration).
  /// For now, captures frames and instructs the app to use native encoder.
  static Future<String> exportMp4(
    GlobalKey boundaryKey,
    ProjectState project,
    int width,
    int height, {
    int fps = 30,
    void Function(int, int)? onProgress,
  }) async {
    final clip = project.selectedAnimation;
    final totalFrames = (clip.duration * fps).ceil().clamp(1, 600);
    final frames = <img.Image>[];

    for (var i = 0; i < totalFrames; i++) {
      final t = i / fps;
      project.loadAt(t);
      await Future.delayed(const Duration(milliseconds: 16));

      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) continue;

      final ui.Image shot = await boundary.toImage(pixelRatio: 1);
      final ByteData? bytes = await shot.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) {
        shot.dispose();
        continue;
      }

      var frame = img.Image.fromBytes(
        width: shot.width,
        height: shot.height,
        bytes: bytes.buffer.asUint8List(),
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );

      // Resize to target resolution if needed
      if (shot.width != width || shot.height != height) {
        frame = img.copyResize(frame, width: width, height: height);
      }

      frames.add(frame);
      onProgress?.call(i + 1, totalFrames);
      shot.dispose();
    }

    if (frames.isEmpty) throw Exception('No frames captured');

    // For production: integrate ffmpeg via platform channel or use FFmpeg.wasm on web
    // For now: return path of first frame and instruction to use native encoder
    final dir = await getTemporaryDirectory();
    final basename = clip.name.replaceAll(' ', '_');
    final framesDir = Directory('${dir.path}/shinra_frames_$basename');
    await framesDir.create(recursive: true);

    // Save all frames as PNGs
    for (var i = 0; i < frames.length; i++) {
      final png = img.encodePng(frames[i]);
      final file = File('${framesDir.path}/frame_${i.toString().padLeft(4, '0')}.png');
      await file.writeAsBytes(png);
    }

    // Return marker file with metadata for native encoder
    final metaFile = File('${framesDir.path}/_export_meta.json');
    await metaFile.writeAsString('''{
  "type": "mp4",
  "width": $width,
  "height": $height,
  "fps": $fps,
  "totalFrames": ${frames.length},
  "framesDir": "${framesDir.path}",
  "outputName": "${basename}_${DateTime.now().millisecondsSinceEpoch}.mp4"
}''');

    return metaFile.path;
  }

  /// Export as GIF (pure Dart, works on all platforms).
  static Future<String> exportGif(
    GlobalKey boundaryKey,
    ProjectState project, {
    int fps = 12,
    void Function(int, int)? onProgress,
  }) async {
    final clip = project.selectedAnimation;
    final totalFrames = (clip.duration * fps).ceil().clamp(1, 600);
    img.Image? base;

    for (var i = 0; i < totalFrames; i++) {
      final t = i / fps;
      project.loadAt(t);
      await Future.delayed(const Duration(milliseconds: 16));

      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) continue;

      final ui.Image shot = await boundary.toImage(pixelRatio: 1);
      final ByteData? bytes = await shot.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) {
        shot.dispose();
        continue;
      }

      final frame = img.Image.fromBytes(
        width: shot.width,
        height: shot.height,
        bytes: bytes.buffer.asUint8List(),
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

    if (base == null) throw Exception('No frames captured');

    final gifBytes = img.encodeGif(base);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/shinra_${clip.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.gif');
    await file.writeAsBytes(gifBytes);
    return file.path;
  }

  /// Export as PNG sequence for external video editing.
  static Future<String> exportPngSequence(
    GlobalKey boundaryKey,
    ProjectState project, {
    int fps = 30,
    void Function(int, int)? onProgress,
  }) async {
    final clip = project.selectedAnimation;
    final totalFrames = (clip.duration * fps).ceil().clamp(1, 600);
    
    final dir = await getTemporaryDirectory();
    final seqDir = Directory('${dir.path}/shinra_seq_${clip.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}');
    await seqDir.create(recursive: true);

    for (var i = 0; i < totalFrames; i++) {
      final t = i / fps;
      project.loadAt(t);
      await Future.delayed(const Duration(milliseconds: 16));

      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) continue;

      final ui.Image shot = await boundary.toImage(pixelRatio: 1);
      final ByteData? bytes = await shot.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) {
        shot.dispose();
        continue;
      }

      final frame = img.Image.fromBytes(
        width: shot.width,
        height: shot.height,
        bytes: bytes.buffer.asUint8List(),
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );

      final png = img.encodePng(frame);
      final file = File('${seqDir.path}/frame_${i.toString().padLeft(4, '0')}.png');
      await file.writeAsBytes(png);

      onProgress?.call(i + 1, totalFrames);
      shot.dispose();
    }

    return seqDir.path;
  }
}
