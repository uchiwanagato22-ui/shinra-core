import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/rig.dart';

class ShinraViewport extends StatelessWidget {
  const ShinraViewport({super.key, required this.project, this.showBones = true});
  final ProjectState project;
  final bool showBones;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => InteractiveViewer(
          minScale: .35,
          maxScale: 3.5,
          child: Center(
            child: SizedBox(
              width: math.max(360, c.maxWidth - 30),
              height: math.max(420, c.maxHeight - 30),
              child: Stack(children: [
                CustomPaint(painter: _CharacterPainter(project, showBones), size: Size.infinite),
                if (project.useImageAsBody && project.importedImagePath.isNotEmpty)
                  _ImageBody(project: project),
              ]),
            ),
          ),
        ),
      );
}

_World _worldTransform(Bone b, Map<String, Bone> bones) {
  var x = b.x, y = b.y, r = b.rotation, s = b.scale;
  String? parent = b.parentId;
  var guard = 0;
  while (parent != null && guard++ < 20) {
    final par = bones[parent];
    if (par == null) break;
    final cos = math.cos(par.rotation), sin = math.sin(par.rotation);
    final nx = par.x + x * cos - y * sin;
    final ny = par.y + x * sin + y * cos;
    x = nx;
    y = ny;
    r += par.rotation;
    s *= par.scale;
    parent = par.parentId;
  }
  return _World(x, y, r, s);
}

class _World {
  _World(this.dx, this.dy, this.rotation, this.scale);
  final double dx, dy, rotation, scale;
}

/// Renders the uploaded artwork on the rig. If the user has mapped crop
/// regions to individual parts (Character page), each region is sliced from
/// the source image and drawn following its own bone — so arms/legs/head can
/// move independently. Otherwise the whole image follows the torso as one
/// rigid block (basic fallback for a not-yet-segmented upload).
class _ImageBody extends StatefulWidget {
  const _ImageBody({required this.project});
  final ProjectState project;
  @override
  State<_ImageBody> createState() => _ImageBodyState();
}

class _ImageBodyState extends State<_ImageBody> {
  ui.Image? _image;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(covariant _ImageBody old) {
    super.didUpdateWidget(old);
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    final path = widget.project.importedImagePath;
    if (path.isEmpty || path == _loadedPath) return;
    _loadedPath = path;
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    if (img == null) return const SizedBox.shrink();
    return CustomPaint(painter: _ImagePartsPainter(widget.project, img), size: Size.infinite);
  }
}

class _ImagePartsPainter extends CustomPainter {
  _ImagePartsPainter(this.p, this.image);
  final ProjectState p;
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2 + p.camera.x, size.height / 2 + p.camera.y);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(p.camera.zoom);
    canvas.rotate(p.camera.rotation);
    final bones = {for (final b in p.bones) b.id: b};
    final iw = image.width.toDouble(), ih = image.height.toDouble();
    final paint = Paint()..filterQuality = FilterQuality.medium;

    void drawPiece(Rect crop, String boneId, double partScale) {
      final bone = bones[boneId];
      if (bone == null) return;
      final w = _worldTransform(bone, bones);
      final src = Rect.fromLTWH(crop.left * iw, crop.top * ih, crop.width * iw, crop.height * ih);
      final destW = src.width * .6 * partScale;
      final destH = src.height * .6 * partScale;
      canvas.save();
      canvas.translate(w.dx, w.dy);
      canvas.rotate(w.rotation);
      final dest = Rect.fromCenter(center: Offset.zero, width: destW * w.scale, height: destH * w.scale);
      canvas.drawImageRect(image, src, dest, paint);
      canvas.restore();
    }

    if (p.hasAnyPartCrop) {
      for (final part in p.parts) {
        if (!part.visible || part.crop == null) continue;
        drawPiece(part.crop!, part.boneId, part.scale);
      }
    } else {
      // Fallback: no parts mapped yet — show the whole upload as a single
      // block following the torso, so there is still visible feedback.
      final w = _worldTransform(bones['torso'] ?? bones.values.first, bones);
      final destW = 180.0, destH = 220.0;
      canvas.save();
      canvas.translate(w.dx, w.dy);
      canvas.rotate(w.rotation);
      canvas.drawImageRect(image, Rect.fromLTWH(0, 0, iw, ih), Rect.fromCenter(center: Offset.zero, width: destW * w.scale, height: destH * w.scale), paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ImagePartsPainter old) => true;
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter(this.p, this.showBones);
  final ProjectState p;
  final bool showBones;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2 + p.camera.x, size.height / 2 + p.camera.y) + _shakeOffset(p);
    _drawBackground(canvas, size, p.background);
    if (p.background == 'Void') {
      final grid = Paint()
        ..color = const Color(0xFF181C27)
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      for (var y = 0.0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(p.camera.zoom);
    canvas.rotate(p.camera.rotation);
    final bones = {for (final b in p.bones) b.id: b};
    Offset point(Bone b) {
      var x = b.x, y = b.y;
      String? parent = b.parentId;
      var guard = 0;
      while (parent != null && guard++ < 20) {
        final par = bones[parent];
        if (par == null) break;
        final r = par.rotation;
        final cos = math.cos(r), sin = math.sin(r);
        final nx = par.x + x * cos - y * sin;
        final ny = par.y + x * sin + y * cos;
        x = nx;
        y = ny;
        parent = par.parentId;
      }
      return Offset(x, y);
    }

    void limb(Bone b, double width, Color color) {
      final a = point(b);
      final r = b.rotation + _worldRotation(b, bones);
      final end = a + Offset(math.sin(r) * b.length * b.scale, -math.cos(r) * b.length * b.scale);
      canvas.drawLine(a, end, Paint()..strokeWidth = width..strokeCap = StrokeCap.round..color = color);
    }

    final root = bones['root']!;
    final torso = point(bones['torso']!);
    final head = point(bones['head']!);

    // Hide the procedural body when the user is animating their own uploaded artwork.
    if (!(p.useImageAsBody && p.importedImagePath.isNotEmpty)) {
      _drawOutfit(canvas, torso, head, p.outfitStyle, p.clothesColor);
      canvas.drawOval(Rect.fromCenter(center: head, width: 88, height: 98), Paint()..color = p.skinColor);
      _drawHair(canvas, head, p.hairStyle, p.hairColor);
      _drawFace(canvas, head, p);
      _drawAccessories(canvas, head, p);
      final limbColor = Color.lerp(p.skinColor, Colors.black, .25)!;
      limb(bones['arm_l']!, 24, limbColor);
      limb(bones['arm_r']!, 24, limbColor);
      limb(bones['leg_l']!, 30, p.clothesColor);
      limb(bones['leg_r']!, 30, p.clothesColor);
    }

    if (showBones) {
      for (final b in p.bones) {
        final a = point(b);
        final paint = Paint()
          ..color = b.id == p.selectedBoneId ? const Color(0xFFFFA726) : const Color(0xFF65B7FF)
          ..strokeWidth = b.id == p.selectedBoneId ? 5 : 3;
        canvas.drawCircle(a, b.id == p.selectedBoneId ? 7 : 4, paint);
        if (b.parentId != null) {
          final par = bones[b.parentId]!;
          canvas.drawLine(point(par), a, paint);
        }
      }
    }
    canvas.drawCircle(point(root), 9, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFFFA726));
    _drawFx(canvas, torso, head, p);
    canvas.restore();
  }

  /// FX added on the timeline previously only sat in a list with a
  /// timestamp — nothing ever appeared on screen. Each one now renders a
  /// real (procedural, no external asset needed) effect while the playhead
  /// is inside its trigger window.
  void _drawFx(Canvas canvas, Offset torso, Offset head, ProjectState p) {
    const window = 0.4;
    for (final e in p.activeFx) {
      final t = (p.playhead - e.time) / window;
      if (t < 0 || t > 1) continue;
      final fade = (1 - t).clamp(0, 1);
      switch (e.name) {
        case 'Impact':
          // Anime-style hit: a hard white flash on the first frames of the
          // window (not just a growing ring) — the classic Naruto/DBS "big
          // hit" beat — fading out fast.
          if (t < .18) canvas.drawRect(Rect.fromLTWH(-2000, -2000, 4000, 4000), Paint()..color = Colors.white.withOpacity((1 - t / .18) * .85));
          canvas.drawCircle(torso, 20 + t * 70, Paint()..color = Colors.white.withOpacity(fade * .8)..style = PaintingStyle.stroke..strokeWidth = 6 * fade + 1);
          canvas.drawCircle(torso, 8 + t * 30, Paint()..color = const Color(0xFFFFD34D).withOpacity(fade * .6));
          break;
        case 'Dust':
          for (var i = 0; i < 5; i++) {
            final a = i * (math.pi * 2 / 5);
            final r = 10 + t * 34;
            canvas.drawCircle(torso.translate(math.cos(a) * r, 70 + math.sin(a) * 8), 5 * fade + 1, Paint()..color = const Color(0xFFB9A67E).withOpacity(fade * .5));
          }
          break;
        case 'Speed Lines':
          for (var i = 0; i < 8; i++) {
            final a = i * (math.pi * 2 / 8);
            final inner = torso + Offset(math.cos(a), math.sin(a)) * (30 + t * 10);
            final outer = torso + Offset(math.cos(a), math.sin(a)) * (30 + t * 90);
            canvas.drawLine(inner, outer, Paint()..color = Colors.white.withOpacity(fade * .55)..strokeWidth = 2);
          }
          break;
        case 'Energy Burst':
          for (var i = 1; i <= 3; i++) {
            canvas.drawCircle(torso, 18 * i + t * 26, Paint()..color = const Color(0xFF6FC7FF).withOpacity(fade * .18)..style = PaintingStyle.stroke..strokeWidth = 3);
          }
          break;
        case 'Smoke':
          for (var i = 0; i < 3; i++) {
            canvas.drawCircle(head.translate((i - 1) * 14.0, -50 - t * 40), 12 + t * 10, Paint()..color = Colors.white.withOpacity(fade * .25));
          }
          break;
        case 'Spark':
          for (var i = 0; i < 6; i++) {
            final a = i * (math.pi * 2 / 6) + t * 2;
            final p1 = torso + Offset(math.cos(a), math.sin(a)) * (10 + t * 40);
            canvas.drawLine(torso, p1, Paint()..color = const Color(0xFFFFE97A).withOpacity(fade)..strokeWidth = 2);
          }
          break;
        case 'Camera Shake':
          // Rendered as a screen-space jitter applied to the whole scene —
          // see the translate offset added before this canvas.save() block.
          break;
      }
    }
  }

  /// Every expression actually changes the face (brows, eye shape, mouth
  /// curve) instead of only swapping a label — previously only "Terrifying"
  /// did anything visible (red eyes), the rest were cosmetic no-ops.
  void _drawFace(Canvas canvas, Offset head, ProjectState p) {
    double browAngle = 0, browLift = 0, mouthCurve = 0, eyeScale = 1;
    var mouthOpen = false;
    var asymmetric = false;
    switch (p.expression) {
      case 'Happy':
        browLift = -3; mouthCurve = 11; eyeScale = .82;
        break;
      case 'Angry':
        browAngle = .35; browLift = 4; mouthCurve = -5; eyeScale = .78;
        break;
      case 'Sad':
        browAngle = -.3; browLift = -1; mouthCurve = -9; eyeScale = .88;
        break;
      case 'Surprised':
        browLift = -8; mouthOpen = true; eyeScale = 1.3;
        break;
      case 'Terrifying':
        browAngle = .45; browLift = 3; mouthOpen = true; eyeScale = 1.15;
        break;
      case 'Determined':
        browAngle = .22; browLift = 1; mouthCurve = -1; eyeScale = .84;
        break;
      case 'Smirk':
        asymmetric = true; mouthCurve = 7; eyeScale = .9; browLift = -1;
        break;
      default:
        break; // Neutral: all defaults
    }

    final browPaint = Paint()
      ..color = p.hairColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final side in [-1, 1]) {
      final cx = head.dx + side * 17;
      final cy = head.dy - 20 + browLift;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(side * browAngle);
      canvas.drawLine(const Offset(-9, 0), const Offset(9, 0), browPaint);
      canvas.restore();
    }

    final eyeWhite = Paint()..color = Colors.white;
    final eyeColor = Paint()..color = p.expression == 'Terrifying' ? const Color(0xFFFF3030) : p.eyeColor;
    final lidPaint = Paint()..color = p.skinColor;
    for (final side in [-1, 1]) {
      final ecx = head.dx + side * 17;
      final c = Offset(ecx, head.dy);
      switch (p.eyeShape) {
        case 'Sharp':
          final path = Path()
            ..moveTo(c.dx - 9 * eyeScale, c.dy)
            ..quadraticBezierTo(c.dx, c.dy - 5 * eyeScale, c.dx + 9 * eyeScale, c.dy - 2 * eyeScale)
            ..quadraticBezierTo(c.dx, c.dy + 4 * eyeScale, c.dx - 9 * eyeScale, c.dy);
          canvas.drawPath(path, eyeWhite);
          canvas.drawCircle(c.translate(1 * side, 0), 3 * eyeScale, eyeColor);
          break;
        case 'Sleepy':
          canvas.drawOval(Rect.fromCenter(center: c, width: 14 * eyeScale, height: 6 * eyeScale), eyeWhite);
          canvas.drawCircle(c, 3 * eyeScale, eyeColor);
          canvas.drawRect(Rect.fromLTWH(c.dx - 8 * eyeScale, c.dy - 6 * eyeScale, 16 * eyeScale, 4 * eyeScale), lidPaint);
          break;
        case 'Wide':
          canvas.drawCircle(c, 8 * eyeScale, eyeWhite);
          canvas.drawCircle(c, 4.2 * eyeScale, eyeColor);
          canvas.drawCircle(c.translate(-1.5, -1.5), 1.4 * eyeScale, Paint()..color = Colors.white);
          break;
        case 'Cat':
          final path = Path()
            ..moveTo(c.dx - 8 * eyeScale, c.dy + 3 * eyeScale)
            ..quadraticBezierTo(c.dx - 2 * eyeScale, c.dy - 6 * eyeScale, c.dx + 9 * eyeScale, c.dy - 3 * eyeScale)
            ..quadraticBezierTo(c.dx, c.dy + 5 * eyeScale, c.dx - 8 * eyeScale, c.dy + 3 * eyeScale);
          canvas.drawPath(path, eyeWhite);
          canvas.drawOval(Rect.fromCenter(center: c, width: 3 * eyeScale, height: 6 * eyeScale), eyeColor);
          break;
        default: // Round
          canvas.drawCircle(c, 6 * eyeScale, eyeWhite);
          canvas.drawCircle(c, 3 * eyeScale, eyeColor);
      }
    }

    final mouthPaint = Paint()
      ..color = const Color(0xFF7C3030)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mCenter = head.translate(asymmetric ? 3 : 0, 24);
    if (mouthOpen) {
      canvas.drawOval(Rect.fromCenter(center: mCenter, width: 20, height: 14), Paint()..color = const Color(0xFF3A1414));
      canvas.drawOval(Rect.fromCenter(center: mCenter, width: 20, height: 14), mouthPaint);
    } else {
      final path = Path()
        ..moveTo(mCenter.dx - 9, mCenter.dy)
        ..quadraticBezierTo(mCenter.dx, mCenter.dy - mouthCurve, mCenter.dx + 9, mCenter.dy - (asymmetric ? mouthCurve * 1.6 : 0));
      canvas.drawPath(path, mouthPaint);
    }
  }


  void _drawHair(Canvas canvas, Offset head, String style, Color color) {
    final hair = Paint()..color = color;
    switch (style) {
      case 'Long':
        canvas.drawArc(Rect.fromCenter(center: head.translate(0, -6), width: 100, height: 96), math.pi, math.pi, true, hair);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: head.translate(-40, 40), width: 18, height: 90), const Radius.circular(9)), hair);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: head.translate(40, 40), width: 18, height: 90), const Radius.circular(9)), hair);
        break;
      case 'Spike':
        canvas.drawArc(Rect.fromCenter(center: head.translate(0, -8), width: 98, height: 90), math.pi, math.pi, true, hair);
        for (var i = -2; i <= 2; i++) {
          final base = head.translate(i * 18.0, -44);
          final path = Path()
            ..moveTo(base.dx - 9, base.dy + 10)
            ..lineTo(base.dx, base.dy - 26)
            ..lineTo(base.dx + 9, base.dy + 10)
            ..close();
          canvas.drawPath(path, hair);
        }
        break;
      case 'Queue':
        canvas.drawArc(Rect.fromCenter(center: head.translate(0, -8), width: 98, height: 90), math.pi, math.pi, true, hair);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: head.translate(0, 60), width: 14, height: 80), const Radius.circular(7)), hair);
        break;
      case 'Chauve':
        break;
      case 'Frange':
        canvas.drawArc(Rect.fromCenter(center: head.translate(0, -6), width: 98, height: 94), math.pi, math.pi, true, hair);
        canvas.drawRect(Rect.fromLTWH(head.dx - 30, head.dy - 34, 60, 16), hair);
        break;
      case 'Afro':
        canvas.drawCircle(head.translate(0, -18), 52, hair);
        break;
      case 'Mohawk':
        final path = Path()
          ..moveTo(head.dx - 8, head.dy - 30)
          ..lineTo(head.dx - 12, head.dy - 70)
          ..lineTo(head.dx + 12, head.dy - 70)
          ..lineTo(head.dx + 8, head.dy - 30)
          ..close();
        canvas.drawPath(path, hair);
        break;
      default:
        canvas.drawArc(Rect.fromCenter(center: head.translate(0, -8), width: 98, height: 90), math.pi, math.pi, true, hair);
    }
  }

  /// Generic silhouette shapes for the torso — original outlines, not based
  /// on any specific franchise design.
  void _drawOutfit(Canvas canvas, Offset torso, Offset head, String style, Color color) {
    final paint = Paint()..color = color;
    switch (style) {
      case 'Hoodie':
        canvas.drawOval(Rect.fromCenter(center: torso, width: 114, height: 152), paint);
        final hood = Path()
          ..moveTo(head.dx - 30, head.dy - 6)
          ..quadraticBezierTo(head.dx, head.dy - 60, head.dx + 30, head.dy - 6)
          ..quadraticBezierTo(head.dx, head.dy + 4, head.dx - 30, head.dy - 6);
        canvas.drawPath(hood, paint..color = color.withOpacity(.9));
        break;
      case 'Jacket':
        canvas.drawOval(Rect.fromCenter(center: torso, width: 118, height: 150), paint);
        canvas.drawLine(torso.translate(-6, -60), torso.translate(-18, 30), Paint()..color = Colors.black26..strokeWidth = 3);
        canvas.drawLine(torso.translate(6, -60), torso.translate(18, 30), Paint()..color = Colors.black26..strokeWidth = 3);
        break;
      case 'Robe':
        final path = Path()
          ..moveTo(torso.dx - 44, torso.dy - 66)
          ..lineTo(torso.dx + 44, torso.dy - 66)
          ..lineTo(torso.dx + 70, torso.dy + 90)
          ..lineTo(torso.dx - 70, torso.dy + 90)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'Dress':
        canvas.drawOval(Rect.fromCenter(center: torso.translate(0, -20), width: 90, height: 90), paint);
        final skirt = Path()
          ..moveTo(torso.dx - 30, torso.dy + 10)
          ..lineTo(torso.dx + 30, torso.dy + 10)
          ..lineTo(torso.dx + 62, torso.dy + 95)
          ..lineTo(torso.dx - 62, torso.dy + 95)
          ..close();
        canvas.drawPath(skirt, paint);
        break;
      case 'Armor':
        canvas.drawOval(Rect.fromCenter(center: torso, width: 116, height: 148), paint);
        final plate = Paint()..color = Color.lerp(color, Colors.white, .25)!;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: torso.translate(0, -30), width: 70, height: 26), const Radius.circular(6)), plate);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: torso.translate(0, 10), width: 74, height: 26), const Radius.circular(6)), plate);
        break;
      case 'Cape':
        canvas.drawOval(Rect.fromCenter(center: torso, width: 96, height: 140), paint);
        final cape = Path()
          ..moveTo(torso.dx - 30, torso.dy - 60)
          ..lineTo(torso.dx + 30, torso.dy - 60)
          ..lineTo(torso.dx + 48, torso.dy + 120)
          ..lineTo(torso.dx - 48, torso.dy + 120)
          ..close();
        canvas.drawPath(cape, Paint()..color = Color.lerp(color, Colors.black, .3)!);
        break;
      default: // Tank
        canvas.drawOval(Rect.fromCenter(center: torso, width: 92, height: 140), paint);
    }
  }

  /// Small procedural extras — none tied to any specific character design.
  void _drawAccessories(Canvas canvas, Offset head, ProjectState p) {
    if (p.accHeadband) {
      canvas.drawRect(Rect.fromCenter(center: head.translate(0, -26), width: 80, height: 12), Paint()..color = const Color(0xFF2C3448));
      canvas.drawCircle(head.translate(0, -26), 4, Paint()..color = const Color(0xFFB0B8C8));
    }
    if (p.accGlasses) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF1A1A1A);
      canvas.drawCircle(head.translate(-17, 0), 10, ring);
      canvas.drawCircle(head.translate(17, 0), 10, ring);
      canvas.drawLine(head.translate(-7, 0), head.translate(7, 0), ring);
    }
    if (p.accScarf) {
      canvas.drawOval(Rect.fromCenter(center: head.translate(0, 46), width: 64, height: 26), Paint()..color = const Color(0xFF7C2431));
      canvas.drawRect(Rect.fromCenter(center: head.translate(14, 74), width: 16, height: 40), Paint()..color = const Color(0xFF7C2431));
    }
  }

  double _worldRotation(Bone b, Map<String, Bone> bones) {
    var parent = b.parentId;
    var guard = 0;
    while (parent != null && guard++ < 20) {
      final x = bones[parent];
      if (x == null) break;
      r += x.rotation;
      parent = x.parentId;
    }
    return r;
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter old) => true;
}

/// Deterministic (not random) jitter so repaints are stable frame to frame —
/// driven by playhead time, not Random(), otherwise the shake would flicker
/// inconsistently between rebuilds instead of reading as a camera shake.
/// Simple generic flat-shape backdrops (gradients + a few silhouettes) —
/// original, not depicting any real or copyrighted place, just enough
/// atmosphere so the viewport isn't always a plain void.
void _drawBackground(Canvas canvas, Size size, String style) {
  final rect = Offset.zero & size;
  switch (style) {
    case 'Forest':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [const Color(0xFF1B3B2E), const Color(0xFF0E1F17)]));
      final tree = Paint()..color = const Color(0xFF0A1712);
      for (var i = 0; i < 6; i++) {
        final x = size.width * (i + .5) / 6;
        final h = 90 + (i.isEven ? 30 : 0);
        final path = Path()..moveTo(x, size.height - 40 - h)..lineTo(x - 34, size.height - 40)..lineTo(x + 34, size.height - 40)..close();
        canvas.drawPath(path, tree);
      }
      break;
    case 'Rooftop City':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [const Color(0xFF10131F), const Color(0xFF262B45)]));
      final b = Paint()..color = const Color(0xFF0B0E17);
      final win = Paint()..color = const Color(0xFFFFD98A).withOpacity(.5);
      for (var i = 0; i < 7; i++) {
        final w = 40.0 + (i % 3) * 14;
        final x = i * (size.width / 7);
        final h = 120 + (i % 4) * 40;
        canvas.drawRect(Rect.fromLTWH(x, size.height - h, w, h), b);
        for (var wy = size.height - h + 12; wy < size.height - 12; wy += 18) {
          for (var wx = x + 6; wx < x + w - 6; wx += 14) canvas.drawRect(Rect.fromLTWH(wx, wy, 6, 8), win);
        }
      }
      break;
    case 'Dojo':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [const Color(0xFF2B1E16), const Color(0xFF16100B)]));
      final floor = Paint()..color = const Color(0xFF120C08);
      for (var y = size.height * .6; y < size.height; y += 22) canvas.drawLine(Offset(0, y), Offset(size.width, y), floor..strokeWidth = 2);
      canvas.drawCircle(Offset(size.width / 2, size.height * .22), 46, Paint()..color = const Color(0xFFFFD98A).withOpacity(.18));
      break;
    case 'Sunset Sky':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [const Color(0xFFFF8A4D), const Color(0xFF3A2151)]));
      canvas.drawCircle(Offset(size.width / 2, size.height * .42), 60, Paint()..color = const Color(0xFFFFE1A8).withOpacity(.85));
      break;
    default: // Void
      canvas.drawRect(rect, Paint()..color = const Color(0xFF090B11));
  }
}

Offset _shakeOffset(ProjectState p) {  const window = 0.4;
  for (final e in p.activeFx) {
    if (e.name != 'Camera Shake') continue;
    final t = (p.playhead - e.time) / window;
    if (t < 0 || t > 1) continue;
    final amp = (1 - t) * 10;
    final phase = p.playhead * 90;
    return Offset(math.sin(phase) * amp, math.cos(phase * 1.3) * amp);
  }
  return Offset.zero;
}
