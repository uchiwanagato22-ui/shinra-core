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
    final center = Offset(size.width / 2 + p.camera.x, size.height / 2 + p.camera.y);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF090B11));
    final grid = Paint()
      ..color = const Color(0xFF181C27)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (var y = 0.0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
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
      canvas.drawOval(Rect.fromCenter(center: torso, width: 110, height: 150), Paint()..color = p.clothesColor);
      canvas.drawOval(Rect.fromCenter(center: head, width: 88, height: 98), Paint()..color = p.skinColor);
      _drawHair(canvas, head, p.hairStyle, p.hairColor);
      canvas.drawCircle(head.translate(-17, 0), 6, Paint()..color = Colors.white);
      canvas.drawCircle(head.translate(17, 0), 6, Paint()..color = Colors.white);
      final eye = Paint()..color = p.expression == 'Terrifying' ? const Color(0xFFFF3030) : p.eyeColor;
      canvas.drawCircle(head.translate(-17, 0), 3, eye);
      canvas.drawCircle(head.translate(17, 0), 3, eye);
      canvas.drawLine(head.translate(-9, 24), head.translate(9, 24), Paint()..color = const Color(0xFF7C3030)..strokeWidth = 3);
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
    canvas.restore();
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
      default:
        canvas.drawArc(Rect.fromCenter(center: head.translate(0, -8), width: 98, height: 90), math.pi, math.pi, true, hair);
    }
  }

  double _worldRotation(Bone b, Map<String, Bone> bones) {
    var r = b.rotation;
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
