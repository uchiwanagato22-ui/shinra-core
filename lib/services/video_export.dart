import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../models/rig.dart';

/// Real MP4 export: captures the timeline frame by frame (same technique as
/// GifExporter), writes them as a numbered PNG sequence, then calls a real
/// H.264 encoder (FFmpeg, via ffmpeg_kit_flutter_new) to mux them into an
/// actual .mp4 file — not a metadata stub.
///
/// Honest limits, read before shipping:
/// - `ffmpeg_kit_flutter_new` is a native plugin (Android/iOS/macOS). It
///   needs `flutter pub get` plus a real device/emulator build to verify —
///   nothing here has been compiled, since this sandbox has no Flutter
///   toolchain. Android's minSdkVersion may need to be 24+; check
///   android/app/build.gradle if the build fails on that.
/// - This targets libx264 (the standard, broadly-compatible codec TikTok/
///   YouTube expect). x264 is GPL-licensed — using the "Full-GPL" FFmpegKit
///   build pulls that obligation into your app if you ship it. Worth
///   knowing before you publish, not something I can decide for you.
/// - No audio track is muxed in yet (the timeline's audio cues aren't
///   baked into the export) — video only for now.
class Mp4Exporter {
  static Future<String> export(
    GlobalKey boundaryKey,
    ProjectState project, {
    int fps = 30,
    void Function(String phase, int current, int total)? onProgress,
  }) async {
    final clip = project.selectedAnimation;
    final totalFrames = (clip.duration * fps).ceil().clamp(1, 1800).toInt();

    final dir = await getTemporaryDirectory();
    final basename = clip.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    final framesDir = Directory('${dir.path}/shinra_mp4_frames_${basename}_${DateTime.now().millisecondsSinceEpoch}');
    await framesDir.create(recursive: true);

    // --- Phase 1: capture the frames (same approach as GifExporter) ---
    for (var i = 0; i < totalFrames; i++) {
      final t = i / fps;
      project.loadAt(t);
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 16));

      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image shot = await boundary.toImage(pixelRatio: 1);
      final ByteData? bytes = await shot.toByteData(format: ui.ImageByteFormat.rawRgba);
      shot.dispose();
      if (bytes == null) continue;

      final frame = img.Image.fromBytes(width: shot.width, height: shot.height, bytes: bytes.buffer, numChannels: 4, order: img.ChannelOrder.rgba);
      final png = img.encodePng(frame);
      final file = File('${framesDir.path}/frame_${i.toString().padLeft(5, '0')}.png');
      await file.writeAsBytes(png);
      onProgress?.call('capture', i + 1, totalFrames);
    }

    // --- Phase 2: real H.264 encode ---
    // Frame-capture workspace stays in temp (intermediate files only). The
    // final .mp4 goes to Downloads when available (Windows/macOS/Linux via
    // path_provider) so it's somewhere the user can actually find it —
    // Android has no generic Downloads path this way, falls back to temp.
    final outDir = await getDownloadsDirectory() ?? dir;
    final outFile = File('${outDir.path}/shinra_${basename}_${DateTime.now().millisecondsSinceEpoch}.mp4');
    onProgress?.call('encode', 0, 1);
    final cmd = '-y -framerate $fps -i "${framesDir.path}/frame_%05d.png" '
        '-c:v libx264 -pix_fmt yuv420p -movflags +faststart "${outFile.path}"';
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    onProgress?.call('encode', 1, 1);

    if (!ReturnCode.isSuccess(rc)) {
      final logs = await session.getLogsAsString();
      throw Exception('FFmpeg encode failed (code $rc). Last logs:\n${logs.length > 800 ? logs.substring(logs.length - 800) : logs}');
    }
    return outFile.path;
  }
}
