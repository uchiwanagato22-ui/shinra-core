import 'dart:math' as math;
import '../models/rig.dart';

typedef BoneClipApplier = void Function(List<Bone> bones, AnimationClip clip, double time);

/// Runtime animation stack for Shinra Core.
///
/// The important rule is non-destructive composition: a base clip is applied
/// first, then optional layers, then secondary motion and finally IK.  This is
/// the foundation needed for anime-style animation without creating a unique
/// baked clip for every possible combination of movement, acting and face.
class AnimeMotionEngine {
  static void applyAnimationLayers(
    List<Bone> bones,
    List<AnimationClip> animations,
    List<AnimationLayer> layers,
    double time,
    BoneClipApplier applyClip,
  ) {
    if (layers.isEmpty) return;
    final base = {for (final b in bones) b.id: b.copy()};
    for (final layer in layers) {
      if (!layer.enabled || layer.weight <= 0 || layer.clipId.isEmpty) continue;
      final clip = animations.cast<AnimationClip?>().firstWhere(
        (a) => a?.id == layer.clipId,
        orElse: () => null,
      );
      if (clip == null) continue;
      final overlay = [for (final b in base.values) b.copy()];
      applyClip(overlay, clip, time);
      final byId = {for (final b in overlay) b.id: b};
      final w = layer.weight.clamp(0.0, 1.0);
      for (final bone in bones) {
        if (layer.maskedBones.isNotEmpty && !layer.maskedBones.contains(bone.id)) continue;
        final b = byId[bone.id];
        final original = base[bone.id];
        if (b == null || original == null) continue;
        // Overlay only the delta from the layer's neutral/base pose.
        bone.x += (b.x - original.x) * w;
        bone.y += (b.y - original.y) * w;
        bone.rotation += _angleDelta(original.rotation, b.rotation) * w;
        bone.scale += (b.scale - original.scale) * w;
      }
    }
  }

  static void applySecondaryMotion(List<Bone> bones, String clipId, double time) {
    Bone? find(String id) {
      for (final b in bones) { if (b.id == id) return b; }
      return null;
    }
    final torso = find('torso');
    final head = find('head');
    final hair = find('hair');
    final calm = clipId == 'mv_idle' || clipId.contains('walk') || clipId.contains('dance');
    if (calm && torso != null) {
      final breath = math.sin(time * math.pi * 2.0) * 0.018;
      torso.scale = (torso.scale + breath).clamp(.75, 1.35).toDouble();
      torso.y += math.sin(time * math.pi * 2.0) * .7;
    }
    if (head != null) {
      head.rotation += math.sin(time * 3.7 + .4) * (calm ? .012 : .006);
    }
    // If a future rig exposes a dedicated hair bone, it automatically gets
    // secondary follow-through without changing the renderer.
    if (hair != null) {
      hair.rotation += math.sin(time * 8.0) * .02;
    }
    final armL = find('arm_l');
    final handL = find('hand_l');
    final armR = find('arm_r');
    final handR = find('hand_r');
    if (armL != null && handL != null) handL.rotation += math.sin(time * 6.0) * .018;
    if (armR != null && handR != null) handR.rotation -= math.sin(time * 6.0) * .018;

    // Readable anticipation for sharp attacks: the torso gets a tiny recoil
    // and settle, avoiding a completely mechanical one-key impact.
    if (clipId.startsWith('cb_') && torso != null) {
      final phase = (time % 0.9) / 0.9;
      final recoil = math.sin(phase * math.pi * 2) * .025;
      torso.scale = (torso.scale + recoil).clamp(.7, 1.4).toDouble();
    }
  }

  /// Two-bone planar IK for arm/leg chains. Targets are optional; the normal
  /// procedural rig remains unchanged when no target is present.
  static void solveIK(List<Bone> bones, List<IKTarget> targets) {
    if (targets.isEmpty) return;
    final byId = {for (final b in bones) b.id: b};
    for (final target in targets) {
      if (!target.enabled || target.weight <= 0) continue;
      final end = byId[target.endBoneId];
      if (end == null || end.parentId == null) continue;
      final mid = byId[end.parentId!];
      if (mid == null || mid.parentId == null) continue;
      final root = byId[mid.parentId!];
      if (root == null) continue;
      final rootWorld = _world(root, byId);
      final midWorld = _world(mid, byId);
      final dx = target.x - rootWorld.x;
      final dy = target.y - rootWorld.y;
      final distance = math.sqrt(dx * dx + dy * dy).clamp(.001, mid.length * mid.scale + end.length * end.scale);
      final a = mid.length * mid.scale;
      final b = end.length * end.scale;
      final cosMid = ((a * a + distance * distance - b * b) / (2 * a * distance)).clamp(-1.0, 1.0);
      final cosEnd = ((a * a + b * b - distance * distance) / (2 * a * b)).clamp(-1.0, 1.0);
      final baseAngle = math.atan2(dy, dx);
      final rootWorldAngle = rootWorld.rotation;
      final desiredMid = baseAngle - math.acos(cosMid);
      final desiredEnd = math.pi - math.acos(cosEnd);
      final w = target.weight.clamp(0.0, 1.0);
      mid.rotation += _angleDelta(midWorld.rotation, desiredMid) * w;
      end.rotation += _angleDelta(end.rotation, desiredEnd) * w;
      // Keep the root stable while allowing a small directional adjustment.
      root.rotation += _angleDelta(rootWorldAngle, rootWorldAngle + _angleDelta(rootWorldAngle, baseAngle) * .12) * w;
    }
  }

  static _World _world(Bone b, Map<String, Bone> byId) {
    var x = b.x;
    var y = b.y;
    var r = b.rotation;
    var s = b.scale;
    var parent = b.parentId;
    var guard = 0;
    while (parent != null && guard++ < 20) {
      final p = byId[parent];
      if (p == null) break;
      final c = math.cos(p.rotation), sn = math.sin(p.rotation);
      final nx = p.x + x * c - y * sn;
      final ny = p.y + x * sn + y * c;
      x = nx; y = ny; r += p.rotation; s *= p.scale; parent = p.parentId;
    }
    return _World(x, y, r, s);
  }

  static double _angleDelta(double a, double b) => (b - a + math.pi) % (2 * math.pi) - math.pi;
}

class _World {
  _World(this.x, this.y, this.rotation, this.scale);
  final double x, y, rotation, scale;
}
