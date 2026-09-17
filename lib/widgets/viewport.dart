import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/rig.dart';

class ShinraViewport extends StatelessWidget {
  const ShinraViewport({super.key, required this.project, this.showBones = true, this.poseMode = false});
  final ProjectState project;
  final bool showBones;
  /// When true, dragging on the canvas moves/rotates the selected bone
  /// (project.poseTool: 'move'/'rotate'/'scale') instead of panning the
  /// camera — lets someone actually pose a hand/foot/head before capturing
  /// a keyframe, as an alternative to typing numbers in the Inspector.
  /// Free pan/zoom is disabled while posing so the drag isn't ambiguous.
  final bool poseMode;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => InteractiveViewer(
          minScale: .35,
          maxScale: 3.5,
          panEnabled: !poseMode,
          scaleEnabled: !poseMode,
          child: Center(
            child: SizedBox(
              width: math.max(360, c.maxWidth - 30),
              height: math.max(420, c.maxHeight - 30),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: poseMode ? (d) => _dragBone(project, d.delta) : null,
                child: Stack(children: [
                  if (project.background == 'Custom' && project.sceneBackgroundImagePath.isNotEmpty)
                    Positioned.fill(child: Image.file(File(project.sceneBackgroundImagePath), fit: BoxFit.cover)),
                  CustomPaint(painter: _CharacterPainter(project, showBones), size: Size.infinite),
                  if (project.useImageAsBody && project.importedImagePath.isNotEmpty)
                    _ImageBody(project: project),
                ]),
              ),
            ),
          ),
        ),
      );

  void _dragBone(ProjectState p, Offset screenDelta) {
    if (p.poseTool == 'ik') { p.moveSelectedIKTargetByScreenDelta(screenDelta); return; }
    final bone = p.selectedBone;
    if (p.poseTool == 'rotate') {
      p.setBone(rotation: bone.rotation + screenDelta.dx * .012);
      return;
    }
    if (p.poseTool == 'scale') {
      p.setBone(scale: bone.scale + screenDelta.dy * -.006);
      return;
    }
    final parentRot = p.worldRotationOf(bone.id);
    final cos = math.cos(-parentRot), sin = math.sin(-parentRot);
    final dx = screenDelta.dx / p.camera.zoom;
    final dy = screenDelta.dy / p.camera.zoom;
    final localDx = dx * cos - dy * sin;
    final localDy = dx * sin + dy * cos;
    p.setBone(x: bone.x + localDx, y: bone.y + localDy);
  }
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
/// the source image and drawn following its own bone ÔÇö so arms/legs/head can
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

    // Same squash & stretch as the drawn-body renderer — the imported/drawn
    // image has to react to an Impact FX exactly like the procedural body
    // does, otherwise the effect would only work for some character types.
    final torsoBone = bones['torso'];
    if (torsoBone != null) {
      final tw = _worldTransform(torsoBone, bones);
      final squash = squashFactor(p, p.selectedActor);
      canvas.translate(tw.dx, tw.dy);
      canvas.scale(squash.sx, squash.sy);
      canvas.translate(-tw.dx, -tw.dy);
    }

    void drawPiece(Rect crop, String boneId, double partScale) {
      final bone = bones[boneId];
      if (bone == null) return;
      final w = _worldTransform(bone, bones);
      final src = Rect.fromLTWH(crop.left * iw, crop.top * ih, crop.width * iw, crop.height * ih);
      final destW = src.width * .6 * partScale;
      final destH = src.height * .6 * partScale;

      // If this piece's bone has a child bone that's *also* a mapped part
      // (e.g. arm_l → forearm_l), the bottom edge is warped toward the
      // child's transform instead of staying rigidly attached to the
      // parent — a real bend at the joint (2-bone weighted mesh) instead of
      // two flat rectangles hinging apart with a gap at the elbow/knee.
      String? childId;
      for (final part in p.parts) {
        if (part.crop == null || !part.visible) continue;
        final b = bones[part.boneId];
        if (b != null && b.parentId == boneId) { childId = part.boneId; break; }
      }
      final child = childId == null ? null : bones[childId];
      if (child == null) {
        canvas.save();
        canvas.translate(w.dx, w.dy);
        canvas.rotate(w.rotation);
        final dest = Rect.fromCenter(center: Offset.zero, width: destW * w.scale, height: destH * w.scale);
        canvas.drawImageRect(image, src, dest, paint);
        canvas.restore();
        return;
      }
      final cw = _worldTransform(child, bones);
      // Which local edge (top or bottom) is actually nearest the joint
      // varies with how autoMapImageParts cropped this part, so measure it
      // instead of assuming — get this backwards and the mesh twists into a
      // bowtie instead of bending cleanly.
      Offset ownOnly(double ly) {
        final cos = math.cos(w.rotation), sin = math.sin(w.rotation);
        final sy = ly * w.scale;
        return Offset(w.dx - sy * sin, w.dy + sy * cos);
      }
      final topDist = (ownOnly(-destH / 2) - Offset(cw.dx, cw.dy)).distanceSquared;
      final bottomDist = (ownOnly(destH / 2) - Offset(cw.dx, cw.dy)).distanceSquared;
      final bottomIsNearJoint = bottomDist <= topDist;
      const rows = 7, cols = 2;
      final positions = <Offset>[];
      final uvs = <Offset>[];
      for (var r = 0; r < rows; r++) {
        final t = r / (rows - 1);
        final bendT = bottomIsNearJoint ? t : (1 - t);
        final bend = bendT * bendT * (3 - 2 * bendT); // smoothstep — soft hinge, no crease at the seam
        for (var c = 0; c < cols; c++) {
          final lx = (c == 0 ? -destW / 2 : destW / 2);
          final ly = -destH / 2 + t * destH;
          Offset xform(_World tr) {
            final cos = math.cos(tr.rotation), sin = math.sin(tr.rotation);
            final sx = lx * tr.scale, sy = ly * tr.scale;
            return Offset(tr.dx + sx * cos - sy * sin, tr.dy + sx * sin + sy * cos);
          }
          final pOwn = xform(w);
          final pChild = xform(cw);
          positions.add(Offset(pOwn.dx + (pChild.dx - pOwn.dx) * bend, pOwn.dy + (pChild.dy - pOwn.dy) * bend));
          uvs.add(Offset(src.left + (c == 0 ? 0 : src.width), src.top + t * src.height));
        }
      }
      final indices = <int>[];
      for (var r = 0; r < rows - 1; r++) {
        final a = r * cols, b0 = a + 1, c0 = a + cols, d = c0 + 1;
        indices.addAll([a, b0, c0, b0, d, c0]);
      }
      final shaderPaint = Paint()
        ..shader = ui.ImageShader(image, ui.TileMode.clamp, ui.TileMode.clamp, Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]))
        ..filterQuality = FilterQuality.medium;
      canvas.drawVertices(ui.Vertices(ui.VertexMode.triangles, positions, textureCoordinates: uvs, indices: indices), BlendMode.srcOver, shaderPaint);
    }

    if (p.hasAnyPartCrop) {
      for (final part in p.parts) {
        if (!part.visible || part.crop == null) continue;
        drawPiece(part.crop!, part.boneId, part.scale);
      }
    } else {
      // Fallback: no parts mapped yet ÔÇö show the whole upload as a single
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
    _drawBackground(canvas, size, p.background, p.sceneBackgroundImagePath, p.camera.x, p.camera.zoom);
    _drawWeather(canvas, size, p.weather, p.playhead);
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
    for (final actor in p.actors) {
      // Per-piece fallback: only the bones that actually have an image crop
      // mapped get replaced by the imported artwork — everything else still
      // draws the procedural body. Old behaviour hid the *entire* body the
      // moment any image was attached, so someone who only mapped a face
      // crop from a portrait ended up with a floating head and no limbs at
      // all instead of a posable body wearing their face.
      final imagedBoneIds = (actor.id == p.selectedActorId && actor.useImageAsBody && actor.importedImagePath.isNotEmpty)
          ? {for (final part in p.parts) if (part.crop != null) part.boneId}
          : const <String>{};
      canvas.save();
      canvas.translate(actor.offsetX, actor.offsetY);
      canvas.scale(actor.facing, 1);
      _paintActor(canvas, p, actor, showBones && actor.id == p.selectedActorId, imagedBoneIds);
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintActor(Canvas canvas, ProjectState p, SceneActor actor, bool showActorBones, Set<String> imagedBoneIds) {
    final bones = {for (final b in actor.bones) b.id: b};
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
    final headImaged = imagedBoneIds.contains('head');
    final torsoImaged = imagedBoneIds.contains('torso');
    if (!headImaged || !torsoImaged) {
      // Signature move: the body squashes/stretches automatically around an
      // Impact FX on this actor — classic squash & stretch, but nobody has
      // to hand-key it. Anticipation stretch just before, hard squash at the
      // hit, springy rebound after — the "anime punch" feel other tools
      // (MiniMuse, Anime Pose Creator, even CapCut) don't do at the rig level.
      final squash = squashFactor(p, actor);
      canvas.save();
      canvas.translate(torso.dx, torso.dy);
      canvas.scale(squash.sx, squash.sy);
      canvas.translate(-torso.dx, -torso.dy);
      if (!torsoImaged) _drawOutfit(canvas, torso, head, actor.outfitStyle, actor.clothesColor);
      DialogueCue? dlg;
      if (!headImaged) {
        canvas.drawOval(Rect.fromCenter(center: head, width: 88, height: 98), Paint()..color = actor.skinColor);
        _drawHair(canvas, head, actor.hairStyle, actor.hairColor);
        dlg = p.activeDialogueFor(actor.id);
        _drawFace(canvas, head, actor, actor.expression, p.playhead, dlg);
        if (dlg != null) _drawSpeechBubble(canvas, head, dlg.text);
      }
      final armLEnd = point(bones['arm_l']!) + Offset(math.sin(bones['arm_l']!.rotation + _worldRotation(bones['arm_l']!, bones)) * bones['arm_l']!.length * bones['arm_l']!.scale, -math.cos(bones['arm_l']!.rotation + _worldRotation(bones['arm_l']!, bones)) * bones['arm_l']!.length * bones['arm_l']!.scale);
      final armREnd = point(bones['arm_r']!) + Offset(math.sin(bones['arm_r']!.rotation + _worldRotation(bones['arm_r']!, bones)) * bones['arm_r']!.length * bones['arm_r']!.scale, -math.cos(bones['arm_r']!.rotation + _worldRotation(bones['arm_r']!, bones)) * bones['arm_r']!.length * bones['arm_r']!.scale);
      if (!torsoImaged) _drawAccessories(canvas, head, torso, armLEnd, armREnd, actor);
      final limbColor = Color.lerp(actor.skinColor, Colors.black, .25)!;
      // One image-cropped piece no longer blanks the whole limb: an arm
      // whose upper segment is mapped to the photo but whose forearm isn't
      // still gets its forearm/hand drawn procedurally instead of leaving a
      // gap, and vice versa.
      void limbUnlessImaged(String boneId, double width, Color color) { if (!imagedBoneIds.contains(boneId)) limb(bones[boneId]!, width, color); }
      limbUnlessImaged('arm_l', 24, limbColor);
      limbUnlessImaged('forearm_l', 20, limbColor);
      limbUnlessImaged('arm_r', 24, limbColor);
      limbUnlessImaged('forearm_r', 20, limbColor);
      // Hands and feet are separate rig parts, not decoration. Drawing them
      // from their own bones makes punches, pointing and planted steps read
      // clearly when the animator keys hand_l/hand_r/foot_l/foot_r.
      limbUnlessImaged('hand_l', 16, limbColor);
      limbUnlessImaged('hand_r', 16, limbColor);
      limbUnlessImaged('leg_l', 30, actor.clothesColor);
      limbUnlessImaged('shin_l', 26, actor.clothesColor);
      limbUnlessImaged('leg_r', 30, actor.clothesColor);
      limbUnlessImaged('shin_r', 26, actor.clothesColor);
      limbUnlessImaged('foot_l', 24, Color.lerp(actor.clothesColor, Colors.black, .35)!);
      limbUnlessImaged('foot_r', 24, Color.lerp(actor.clothesColor, Colors.black, .35)!);
      canvas.restore();
    }

    if (showActorBones) {
      for (final b in actor.bones) {
        final a = point(b);
        final paint = Paint()
          ..color = b.id == p.selectedBoneId ? const Color(0xFFD4A73B) : const Color(0xFF65B7FF)
          ..strokeWidth = b.id == p.selectedBoneId ? 5 : 3;
        canvas.drawCircle(a, b.id == p.selectedBoneId ? 7 : 4, paint);
        if (b.parentId != null) canvas.drawLine(point(bones[b.parentId]!), a, paint);
      }
      canvas.drawCircle(point(root), 9, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFD4A73B));
      // IK target handles — diamonds so they read as "draggable goal" at a
      // glance, distinct from the round bone joints.
      for (final t in p.ikTargets) {
        final selected = t.id == p.selectedIKTargetId;
        final tp = Offset(t.x, t.y);
        final size = selected ? 10.0 : 7.0;
        final path = Path()
          ..moveTo(tp.dx, tp.dy - size)
          ..lineTo(tp.dx + size, tp.dy)
          ..lineTo(tp.dx, tp.dy + size)
          ..lineTo(tp.dx - size, tp.dy)
          ..close();
        canvas.drawPath(path, Paint()..color = (t.enabled ? const Color(0xFFE0507A) : const Color(0xFF6B6B78)).withValues(alpha: selected ? 1 : .75));
        canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = selected ? 2.5 : 1.5..color = Colors.white.withValues(alpha: .85));
      }
    }
    _drawFx(canvas, torso, head, p);
  }

  /// FX added on the timeline previously only sat in a list with a
  /// timestamp ÔÇö nothing ever appeared on screen. Each one now renders a
  /// real (procedural, no external asset needed) effect while the playhead
  /// is inside its trigger window.
  void _drawFx(Canvas canvas, Offset torso, Offset head, ProjectState p) {
    const window = 0.4;
    for (final e in p.activeFx) {
      final t = (p.playhead - e.time) / window;
      if (t < 0 || t > 1) continue;
      final fade = (1 - t).clamp(0, 1).toDouble();
      switch (e.name) {
        case 'Impact':
          // Anime-style hit: a hard white flash on the first frames of the
          // window (not just a growing ring) ÔÇö the classic Naruto/DBS "big
          // hit" beat ÔÇö fading out fast.
          if (t < .18) canvas.drawRect(Rect.fromLTWH(-2000, -2000, 4000, 4000), Paint()..color = Colors.white.withValues(alpha: (1 - t / .18) * .85));
          canvas.drawCircle(torso, 20 + t * 70, Paint()..color = Colors.white.withValues(alpha: fade * .8)..style = PaintingStyle.stroke..strokeWidth = 6 * fade + 1);
          canvas.drawCircle(torso, 8 + t * 30, Paint()..color = const Color(0xFFFFD34D).withValues(alpha: fade * .6));
          break;
        case 'Dust':
          for (var i = 0; i < 5; i++) {
            final a = i * (math.pi * 2 / 5);
            final r = 10 + t * 34;
            canvas.drawCircle(torso.translate(math.cos(a) * r, 70 + math.sin(a) * 8), 5 * fade + 1, Paint()..color = const Color(0xFFB9A67E).withValues(alpha: fade * .5));
          }
          break;
        case 'Speed Lines':
          for (var i = 0; i < 8; i++) {
            final a = i * (math.pi * 2 / 8);
            final inner = torso + Offset(math.cos(a), math.sin(a)) * (30 + t * 10);
            final outer = torso + Offset(math.cos(a), math.sin(a)) * (30 + t * 90);
            canvas.drawLine(inner, outer, Paint()..color = Colors.white.withValues(alpha: fade * .55)..strokeWidth = 2);
          }
          break;
        case 'Energy Burst':
          for (var i = 1; i <= 3; i++) {
            canvas.drawCircle(torso, 18 * i + t * 26, Paint()..color = const Color(0xFF6FC7FF).withValues(alpha: fade * .18)..style = PaintingStyle.stroke..strokeWidth = 3);
          }
          break;
        case 'Smoke':
          for (var i = 0; i < 3; i++) {
            canvas.drawCircle(head.translate((i - 1) * 14.0, -50 - t * 40), 12 + t * 10, Paint()..color = Colors.white.withValues(alpha: fade * .25));
          }
          break;
        case 'Spark':
          for (var i = 0; i < 6; i++) {
            final a = i * (math.pi * 2 / 6) + t * 2;
            final p1 = torso + Offset(math.cos(a), math.sin(a)) * (10 + t * 40);
            canvas.drawLine(torso, p1, Paint()..color = const Color(0xFFFFE97A).withValues(alpha: fade)..strokeWidth = 2);
          }
          break;
        case 'Camera Shake':
          // Rendered as a screen-space jitter applied to the whole scene ÔÇö
          // see the translate offset added before this canvas.save() block.
          break;
      }
    }
  }

  /// Every expression actually changes the face (brows, eye shape, mouth
  /// curve) instead of only swapping a label ÔÇö previously only "Terrifying"
  /// did anything visible (red eyes), the rest were cosmetic no-ops.
  void _drawFace(Canvas canvas, Offset head, SceneActor actor, String expression, double timeline, DialogueCue? dialogue) {
    double browAngle = 0, browLift = 0, mouthCurve = 0, eyeScale = 1;
    if(actor.facialRigEnabled){browAngle=(actor.browRight-actor.browLeft)*.45;browLift=-(actor.browLeft+actor.browRight)*5;eyeScale=1+(((actor.eyeOpenLeft+actor.eyeOpenRight)/2)-1)*.45;}
    var mouthOpen = false;
    var mouthWidth = 20.0;
    var mouthHeight = 14.0;
    var asymmetric = false;
    switch (expression) {
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
    // Speech visemes can override the expression while a line is spoken.
    // A = open jaw, O = rounded lips, B = closed lips.
    if (dialogue != null) {
      // Auto-cycle visemes while a dialogue line is active — deterministic
      // (driven by timeline, not Random()) so exported frames stay
      // consistent, not real phoneme timing since there's no audio/TTS
      // analysis here, just a readable "talking" flap.
      final cyclePos = ((timeline - dialogue.time) / .12).floor() % 3;
      final shape = ['A', 'B', 'O'][cyclePos];
      if (shape == 'A') { mouthOpen = true; mouthWidth = 22; mouthHeight = 20; }
      if (shape == 'O') { mouthOpen = true; mouthWidth = 12; mouthHeight = 19; }
      if (shape == 'B') { mouthOpen = true; mouthWidth = 24; mouthHeight = 5; }
    } else {
      switch (actor.mouthShape) {
        case 'A':
          mouthOpen = true; mouthWidth = 22; mouthHeight = 20;
          break;
        case 'O':
          mouthOpen = true; mouthWidth = 12; mouthHeight = 19;
          break;
        case 'B':
          mouthOpen = true; mouthWidth = 24; mouthHeight = 5;
          break;
      }
    }

    final browPaint = Paint()
      ..color = actor.hairColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Two short deterministic blinks every few seconds add life without
    // Random() flicker during repaint or affecting exported frames.
    final blinkPhase = timeline % 3.6;
    final blinking = blinkPhase > 3.15 && blinkPhase < 3.30;
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
    final eyeColor = Paint()..color = expression == 'Terrifying' ? const Color(0xFFFF3030) : actor.eyeColor;
    final lidPaint = Paint()..color = actor.skinColor;
    for (final side in [-1, 1]) {
      final ecx = head.dx + side * 17;
      final c = Offset(ecx, head.dy);
      final pupil = c.translate(actor.eyeLookX.clamp(-1,1).toDouble()*2.5, actor.eyeLookY.clamp(-1,1).toDouble()*2.5);
      final openness=side<0?actor.eyeOpenLeft:actor.eyeOpenRight;
      if (blinking || openness < .08) {
        canvas.drawLine(c.translate(-8, 0), c.translate(8, 0), Paint()..color = actor.hairColor..strokeWidth = 2.5..strokeCap = StrokeCap.round);
        continue;
      }
      switch (actor.eyeShape) {
        case 'Sharp':
          final path = Path()
            ..moveTo(c.dx - 9 * eyeScale, c.dy)
            ..quadraticBezierTo(c.dx, c.dy - 5 * eyeScale, c.dx + 9 * eyeScale, c.dy - 2 * eyeScale)
            ..quadraticBezierTo(c.dx, c.dy + 4 * eyeScale, c.dx - 9 * eyeScale, c.dy);
          canvas.drawPath(path, eyeWhite);
          canvas.drawCircle(pupil.translate(1.0 * side, 0), 3 * eyeScale * actor.pupilScale, eyeColor);
          break;
        case 'Sleepy':
          canvas.drawOval(Rect.fromCenter(center: c, width: 14 * eyeScale, height: 6 * eyeScale), eyeWhite);
          canvas.drawCircle(pupil, 3 * eyeScale * actor.pupilScale, eyeColor);
          canvas.drawRect(Rect.fromLTWH(c.dx - 8 * eyeScale, c.dy - 6 * eyeScale, 16 * eyeScale, 4 * eyeScale), lidPaint);
          break;
        case 'Wide':
          canvas.drawCircle(c, 8 * eyeScale, eyeWhite);
          canvas.drawCircle(pupil, 4.2 * eyeScale * actor.pupilScale, eyeColor);
          canvas.drawCircle(pupil.translate(-1.5, -1.5), 1.4 * eyeScale, Paint()..color = Colors.white);
          break;
        case 'Cat':
          final path = Path()
            ..moveTo(c.dx - 8 * eyeScale, c.dy + 3 * eyeScale)
            ..quadraticBezierTo(c.dx - 2 * eyeScale, c.dy - 6 * eyeScale, c.dx + 9 * eyeScale, c.dy - 3 * eyeScale)
            ..quadraticBezierTo(c.dx, c.dy + 5 * eyeScale, c.dx - 8 * eyeScale, c.dy + 3 * eyeScale);
          canvas.drawPath(path, eyeWhite);
          canvas.drawOval(Rect.fromCenter(center: pupil, width: 3 * eyeScale, height: 6 * eyeScale), eyeColor);
          break;
        default: // Round
          canvas.drawCircle(c, 6 * eyeScale, eyeWhite);
          canvas.drawCircle(pupil, 3 * eyeScale * actor.pupilScale, eyeColor);
      }
    }

    mouthWidth*=actor.mouthWidth; if(actor.mouthOpen>.05){mouthOpen=true;mouthHeight=math.max(mouthHeight,8+actor.mouthOpen*18);}
    final mouthPaint = Paint()
      ..color = const Color(0xFF7C3030)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.save(); canvas.translate(head.dx,head.dy); canvas.rotate(actor.headTilt); canvas.translate(-head.dx,-head.dy);
    // Real per-side corner lift, driven by the actual facial rig values
    // (actor.mouthCornerLeft/Right — settable via sliders, keyframes, or
    // an expression preset) instead of the old hardcoded "asymmetric"
    // flag that only reacted to the literal 'Smirk' label. This is what
    // makes a smirk/evil grin actually render instead of just being
    // stored, silently, in the model.
    const cornerScale = 9.0;
    final liftL = mouthCurve + actor.mouthCornerLeft * cornerScale;
    final liftR = mouthCurve + actor.mouthCornerRight * cornerScale;
    final mCenter = head.translate(asymmetric ? 3 : 0, 24);
    if (mouthOpen) {
      canvas.drawOval(Rect.fromCenter(center: mCenter, width: mouthWidth, height: mouthHeight), Paint()..color = const Color(0xFF3A1414));
      canvas.drawOval(Rect.fromCenter(center: mCenter, width: mouthWidth, height: mouthHeight), mouthPaint);
    } else {
      final path = Path()
        ..moveTo(mCenter.dx - 9, mCenter.dy - liftL)
        ..quadraticBezierTo(mCenter.dx, mCenter.dy - mouthCurve, mCenter.dx + 9, mCenter.dy - liftR);
      canvas.drawPath(path, mouthPaint);
    }
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

  /// Generic silhouette shapes for the torso ÔÇö original outlines, not based
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
        canvas.drawPath(hood, paint..color = color.withValues(alpha: .9));
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
      case 'Suit':
        canvas.drawOval(Rect.fromCenter(center: torso, width: 104, height: 148), paint);
        canvas.drawRect(Rect.fromCenter(center: torso.translate(0, -30), width: 14, height: 60), Paint()..color = Colors.white);
        final lapel = Paint()..color = Color.lerp(color, Colors.black, .35)!;
        canvas.drawLine(torso.translate(-4, -60), torso.translate(-22, -10), lapel..strokeWidth = 8);
        canvas.drawLine(torso.translate(4, -60), torso.translate(22, -10), Paint()..color = Color.lerp(color, Colors.black, .35)!..strokeWidth = 8);
        break;
      case 'Tactical Vest':
        canvas.drawOval(Rect.fromCenter(center: torso, width: 108, height: 146), paint);
        final strap = Paint()..color = Color.lerp(color, Colors.black, .4)!;
        for (final dx in [-24.0, 0.0, 24.0]) {
          canvas.drawRect(Rect.fromCenter(center: torso.translate(dx, 0), width: 10, height: 110), strap);
        }
        canvas.drawRect(Rect.fromCenter(center: torso.translate(0, -50), width: 70, height: 10), strap);
        break;
      case 'Battle Cloak':
        canvas.drawOval(Rect.fromCenter(center: torso, width: 100, height: 142), paint);
        final cloak = Path()
          ..moveTo(torso.dx - 26, torso.dy - 64)
          ..lineTo(torso.dx + 26, torso.dy - 64)
          ..lineTo(torso.dx + 60, torso.dy + 130)
          ..quadraticBezierTo(torso.dx, torso.dy + 150, torso.dx - 60, torso.dy + 130)
          ..close();
        canvas.drawPath(cloak, Paint()..color = Color.lerp(color, Colors.black, .25)!);
        canvas.drawCircle(torso.translate(0, -58), 6, Paint()..color = const Color(0xFFC9A227));
        break;
      default: // Tank
        canvas.drawOval(Rect.fromCenter(center: torso, width: 92, height: 140), paint);
    }
  }

  /// Small procedural extras ÔÇö none tied to any specific character design.
  /// Speech bubble above the speaking actor's head — doubles as an on-screen
  /// caption once exported, useful for TikTok/YouTube-style clips.
  void _drawSpeechBubble(Canvas canvas, Offset head, String text) {
    final span = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 160);
    final w = span.width + 20, h = span.height + 16;
    final center = head.translate(0, -84 - h / 2);
    final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: w, height: h), const Radius.circular(10));
    final bubble = Paint()..color = Colors.white.withValues(alpha: .95);
    canvas.drawRRect(rect, bubble);
    canvas.drawRRect(rect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.black26);
    final tail = Path()
      ..moveTo(head.dx - 8, center.dy + h / 2)
      ..lineTo(head.dx + 8, center.dy + h / 2)
      ..lineTo(head.dx, center.dy + h / 2 + 12)
      ..close();
    canvas.drawPath(tail, bubble);
    span.paint(canvas, Offset(center.dx - span.width / 2, center.dy - span.height / 2));
  }

  void _drawAccessories(Canvas canvas, Offset head, Offset torso, Offset handL, Offset handR, SceneActor actor) {
    if (actor.accHeadband) {
      canvas.drawRect(Rect.fromCenter(center: head.translate(0, -26), width: 80, height: 12), Paint()..color = const Color(0xFF2C3448));
      canvas.drawCircle(head.translate(0, -26), 4, Paint()..color = const Color(0xFFB0B8C8));
    }
    if (actor.accGlasses) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF1A1A1A);
      canvas.drawCircle(head.translate(-17, 0), 10, ring);
      canvas.drawCircle(head.translate(17, 0), 10, ring);
      canvas.drawLine(head.translate(-7, 0), head.translate(7, 0), ring);
    }
    if (actor.accScarf) {
      canvas.drawOval(Rect.fromCenter(center: head.translate(0, 46), width: 64, height: 26), Paint()..color = const Color(0xFF7C2431));
      canvas.drawRect(Rect.fromCenter(center: head.translate(14, 74), width: 16, height: 40), Paint()..color = const Color(0xFF7C2431));
    }
    if (actor.accHat) {
      final hatColor = Paint()..color = Color.lerp(actor.clothesColor, Colors.black, .2)!;
      canvas.drawOval(Rect.fromCenter(center: head.translate(0, -46), width: 76, height: 22), hatColor);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: head.translate(0, -60), width: 54, height: 30), const Radius.circular(8)), hatColor);
    }
    if (actor.accGloves) {
      final gloveColor = Paint()..color = Color.lerp(actor.clothesColor, Colors.black, .3)!;
      canvas.drawCircle(handL, 11, gloveColor);
      canvas.drawCircle(handR, 11, gloveColor);
    }
    if (actor.accBelt) {
      canvas.drawRect(Rect.fromCenter(center: torso.translate(0, 52), width: 96, height: 14), Paint()..color = const Color(0xFF2A1E14));
      canvas.drawRect(Rect.fromCenter(center: torso.translate(0, 52), width: 16, height: 12), Paint()..color = const Color(0xFFC9A227));
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

/// Deterministic (not random) jitter so repaints are stable frame to frame ÔÇö
/// driven by playhead time, not Random(), otherwise the shake would flicker
/// inconsistently between rebuilds instead of reading as a camera shake.
/// Simple generic flat-shape backdrops (gradients + a few silhouettes) ÔÇö
/// original, not depicting any real or copyrighted place, just enough
/// atmosphere so the viewport isn't always a plain void.
void _drawWeather(Canvas canvas, Size size, String weather, double time) {
  if (weather == 'Clear') return;
  final paint = Paint()..strokeWidth = 1.5;
  for (var i = 0; i < 80; i++) {
    final seed = i * 17.0;
    final x = (seed * 37 + time * 120) % size.width;
    final y = (seed * 53 + time * 280) % size.height;
    if (weather == 'Rain') {
      paint.color = Colors.white.withValues(alpha: .35);
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 14), paint);
    } else {
      paint.color = Colors.white.withValues(alpha: .55);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }
}

void _drawBackground(Canvas canvas, Size size, String style, String customPath, double cameraX, double cameraZoom) {
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
    case 'Rainy City':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), style == 'Rainy City' ? [const Color(0xFF1A2233), const Color(0xFF2A3348)] : [const Color(0xFF10131F), const Color(0xFF262B45)]));
      final b = Paint()..color = const Color(0xFF0B0E17);
      final win = Paint()..color = (style == 'Rainy City' ? const Color(0xFF8EB4FF) : const Color(0xFFFFD98A)).withValues(alpha: .45);
      for (var i = 0; i < 7; i++) {
        final w = 40.0 + (i % 3) * 14;
        final x = i * (size.width / 7);
        final h = 120.0 + (i % 4) * 40;
        canvas.drawRect(Rect.fromLTWH(x, size.height - h, w, h), b);
        for (var wy = size.height - h + 12; wy < size.height - 12; wy += 18) {
          for (var wx = x + 6; wx < x + w - 6; wx += 14) canvas.drawRect(Rect.fromLTWH(wx, wy, 6, 8), win);
        }
      }
      // Multi-plane 2.5D depth: distant silhouettes move less than the
      // foreground when the camera pans. Everything remains lightweight 2D.
      final far = Paint()..color = const Color(0xFF080A12).withValues(alpha: .42);
      final near = Paint()..color = const Color(0xFF05060A).withValues(alpha: .72);
      final parallaxFar = (cameraX * .18) % 180;
      final parallaxNear = (cameraX * .55) % 220;
      for (var i = -1; i < 7; i++) {
        final x = i * 180.0 - parallaxFar;
        final h = 55.0 + (i.abs() % 4) * 18;
        canvas.drawRect(Rect.fromLTWH(x, size.height - 95 - h, 120, h), far);
      }
      for (var i = -1; i < 6; i++) {
        final x = i * 220.0 - parallaxNear;
        canvas.drawRect(Rect.fromLTWH(x, size.height - 42, 170, 42), near);
      }
      if (style == 'Rainy City') canvas.drawRect(Rect.fromLTWH(0, size.height - 36, size.width, 36), Paint()..color = const Color(0xFF1E2838).withValues(alpha: .7));
      break;
    case 'Neon Street':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [const Color(0xFF120818), const Color(0xFF2A1038)]));
      final neon = [const Color(0xFFFF4FD8), const Color(0xFF4FD8FF), const Color(0xFF9DFF4F)];
      for (var i = 0; i < 5; i++) {
        final x = size.width * (i + .3) / 5;
        canvas.drawRect(Rect.fromLTWH(x, size.height * .35, 8, size.height * .65), Paint()..color = neon[i % 3].withValues(alpha: .35));
        canvas.drawCircle(Offset(x + 4, size.height * .3), 18, Paint()..color = neon[i % 3].withValues(alpha: .5));
      }
      break;
    case 'Dojo':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [const Color(0xFF2B1E16), const Color(0xFF16100B)]));
      final floor = Paint()..color = const Color(0xFF120C08);
      for (var y = size.height * .6; y < size.height; y += 22) canvas.drawLine(Offset(0, y), Offset(size.width, y), floor..strokeWidth = 2);
      canvas.drawCircle(Offset(size.width / 2, size.height * .22), 46, Paint()..color = const Color(0xFFFFD98A).withValues(alpha: .18));
      break;
    case 'Sunset Sky':
      canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [const Color(0xFFFF8A4D), const Color(0xFF3A2151)]));
      canvas.drawCircle(Offset(size.width / 2, size.height * .42), 60, Paint()..color = const Color(0xFFFFE1A8).withValues(alpha: .85));
      break;
    case 'Custom':
      break; // drawn as a separate Image.file widget layer beneath this canvas — see ShinraViewport
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

/// Deterministic (playhead-driven, not Random()) squash & stretch curve
/// around an active "Impact" FX on this actor: a light stretch just before
/// (anticipation), a hard squash right at the hit, then a springy
/// overshoot/rebound back to normal — the classic animation principle,
/// applied automatically so nobody has to hand-key scale keyframes for it.
/// Top-level (not a painter method) so both the drawn-body painter and the
/// imported/drawn-image painter apply the exact same deformation — it needs
/// to look identical no matter which of the three character types is active.
({double sx, double sy}) squashFactor(ProjectState p, SceneActor actor) {
  for (final e in p.activeFx) {
    if (e.name != 'Impact') continue;
    const window = .4;
    final t = (p.playhead - e.time) / window;
    if (t < -.12 || t > 1) continue;
    if (t < 0) {
      // anticipation: slight stretch leading into the hit
      final a = (1 + t / .12).clamp(0.0, 1.0);
      return (sx: 1 - .08 * a, sy: 1 + .12 * a);
    }
    // squash on impact, damped spring back to 1.0
    final decay = math.exp(-t * 6);
    final wobble = math.sin(t * 22) * decay;
    return (sx: 1 + .22 * decay - wobble * .05, sy: 1 - .28 * decay + wobble * .05);
  }
  return (sx: 1.0, sy: 1.0);
}
