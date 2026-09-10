import 'dart:math' as math;
import 'package:flutter/material.dart' show Color, Rect;

enum BoneType { root, head, torso, arm, hand, leg, foot }

enum PartType { body, face, hair, eyes, mouth, clothes, hand, shoes, accessory }

enum AnimCategory { movement, combat, face, fx }

const skinPalette = [Color(0xFFE9B18E), Color(0xFFF6D3B0), Color(0xFFC98A5B), Color(0xFF8D5A3C), Color(0xFF5C3A28)];
const hairPalette = [Color(0xFF151722), Color(0xFF3B2A1E), Color(0xFF8A4B2A), Color(0xFFC9A227), Color(0xFFB23A48), Color(0xFF4A6FE0), Color(0xFFE0E0E0)];
const eyePalette = [Color(0xFF151722), Color(0xFF2E6DB4), Color(0xFF3E8E4F), Color(0xFF7C4DBE), Color(0xFFB23A48), Color(0xFFC9A227)];
const clothesPalette = [Color(0xFF2C3448), Color(0xFF7C2431), Color(0xFF1F5C4C), Color(0xFF2F4A7C), Color(0xFF4A4A52), Color(0xFF8C6A2F)];
const hairStyles = ['Court', 'Long', 'Spike', 'Queue', 'Chauve'];

class Bone {
  Bone({required this.id, required this.name, required this.type, this.parentId, this.x = 0, this.y = 0, this.rotation = 0, this.length = 60, this.scale = 1});
  final String id;
  final String name;
  final BoneType type;
  String? parentId;
  double x;
  double y;
  double rotation;
  double length;
  double scale;

  Bone copy() => Bone(id: id, name: name, type: type, parentId: parentId, x: x, y: y, rotation: rotation, length: length, scale: scale);
}

class CharacterPart {
  CharacterPart({required this.id, required this.name, required this.type, required this.boneId, this.visible = true, this.locked = false, this.x = 0, this.y = 0, this.rotation = 0, this.scale = 1, this.crop});
  final String id;
  final String name;
  final PartType type;
  String boneId;
  bool visible;
  bool locked;
  double x;
  double y;
  double rotation;
  double scale;
  /// Normalized (0..1) crop region within the uploaded image for this part,
  /// so a single uploaded artwork can be sliced into pieces that each follow
  /// their own bone instead of moving as one rigid block.
  Rect? crop;
}

class PoseKeyframe {
  PoseKeyframe({required this.time, required this.x, required this.y, required this.rotation, required this.scale});
  final double time;
  final double x;
  final double y;
  final double rotation;
  final double scale;
}

class BoneTrack {
  BoneTrack({required this.boneId});
  final String boneId;
  final List<PoseKeyframe> keys = [];

  void upsert(PoseKeyframe key) {
    keys.removeWhere((k) => (k.time - key.time).abs() < 0.001);
    keys.add(key);
    keys.sort((a, b) => a.time.compareTo(b.time));
  }
}

class AnimationClip {
  AnimationClip({required this.id, required this.name, required this.category, this.duration = 2.0, this.loop = true});
  final String id;
  final String name;
  final AnimCategory category;
  double duration;
  bool loop;
  final Map<String, BoneTrack> tracks = {};

  BoneTrack track(String boneId) => tracks.putIfAbsent(boneId, () => BoneTrack(boneId: boneId));
}

class CameraState {
  double x = 0;
  double y = 0;
  double zoom = 1;
  double rotation = 0;
}

class FxEvent {
  FxEvent({required this.id, required this.name, required this.time});
  final String id;
  final String name;
  final double time;
}

class AudioCue {
  AudioCue({required this.id, required this.name, required this.time});
  final String id;
  final String name;
  final double time;
}

Bone makeBone(String id, String name, BoneType type, String? parent, double x, double y, double length, [double rotation = 0]) => Bone(id: id, name: name, type: type, parentId: parent, x: x, y: y, length: length, rotation: rotation);

List<Bone> defaultBones() => [
  makeBone('root', 'Root', BoneType.root, null, 0, 110, 20),
  makeBone('torso', 'Torso', BoneType.torso, 'root', 0, 0, 90),
  makeBone('head', 'Head', BoneType.head, 'torso', 0, -85, 45),
  makeBone('arm_l', 'Arm L', BoneType.arm, 'torso', -45, -15, 65, -0.35),
  makeBone('hand_l', 'Hand L', BoneType.hand, 'arm_l', -52, 55, 25, -0.15),
  makeBone('arm_r', 'Arm R', BoneType.arm, 'torso', 45, -15, 65, 0.35),
  makeBone('hand_r', 'Hand R', BoneType.hand, 'arm_r', 52, 55, 25, 0.15),
  makeBone('leg_l', 'Leg L', BoneType.leg, 'root', -22, 20, 90),
  makeBone('foot_l', 'Foot L', BoneType.foot, 'leg_l', -10, 88, 30),
  makeBone('leg_r', 'Leg R', BoneType.leg, 'root', 22, 20, 90),
  makeBone('foot_r', 'Foot R', BoneType.foot, 'leg_r', 10, 88, 30),
];

List<CharacterPart> defaultParts() => [
  CharacterPart(id: 'body', name: 'Body', type: PartType.body, boneId: 'torso'),
  CharacterPart(id: 'face', name: 'Face', type: PartType.face, boneId: 'head'),
  CharacterPart(id: 'hair', name: 'Hair', type: PartType.hair, boneId: 'head'),
  CharacterPart(id: 'eyes', name: 'Eyes', type: PartType.eyes, boneId: 'head'),
  CharacterPart(id: 'mouth', name: 'Mouth', type: PartType.mouth, boneId: 'head'),
  CharacterPart(id: 'clothes', name: 'Clothes', type: PartType.clothes, boneId: 'torso'),
  CharacterPart(id: 'hand_l', name: 'Hand L', type: PartType.hand, boneId: 'hand_l'),
  CharacterPart(id: 'hand_r', name: 'Hand R', type: PartType.hand, boneId: 'hand_r'),
  CharacterPart(id: 'shoes', name: 'Shoes', type: PartType.shoes, boneId: 'foot_l'),
];

class ProjectState extends ChangeNotifier {
  ProjectState() {
    bones = defaultBones();
    parts = defaultParts();
    animations = _presets();
    selectedBoneId = 'root';
    selectedAnimationId = animations.first.id;
    captureHistory();
  }

  List<Bone> bones = [];
  List<CharacterPart> parts = [];
  List<AnimationClip> animations = [];
  final CameraState camera = CameraState();
  final List<FxEvent> fx = [];
  final List<AudioCue> audio = [];
  String selectedBoneId = 'root';
  String selectedPartId = 'body';
  String selectedAnimationId = 'idle';
  String importedImagePath = '';
  bool useImageAsBody = false;
  Color skinColor = skinPalette.first;
  Color hairColor = hairPalette.first;
  Color eyeColor = eyePalette.first;
  Color clothesColor = clothesPalette.first;
  String hairStyle = hairStyles.first;
  double playhead = 0;
  bool playing = false;
  String tool = 'select';
  String expression = 'Neutral';
  String status = 'Ready';
  final List<Map<String, List<double>>> _undo = [];
  final List<Map<String, List<double>>> _redo = [];

  Bone get selectedBone => bones.firstWhere((b) => b.id == selectedBoneId, orElse: () => bones.first);
  AnimationClip get selectedAnimation => animations.firstWhere((a) => a.id == selectedAnimationId, orElse: () => animations.first);

  List<AnimationClip> _presets() {
    final movement = ['Idle', 'Walk', 'Run', 'Jump', 'Fall', 'Dodge Step'];
    final combat = ['Attack Windup', 'Attack', 'Attack Recovery', 'Block', 'Hit Reaction', 'Counter'];
    final list = <AnimationClip>[];
    for (var i = 0; i < movement.length; i++) { final clip = AnimationClip(id: 'mv_${movement[i].toLowerCase().replaceAll(' ', '_')}', name: movement[i], category: AnimCategory.movement, duration: i == 0 ? 2 : 1.2, loop: i < 3); _generateDefaultMotion(clip); list.add(clip); }
    for (var i = 0; i < combat.length; i++) { final clip = AnimationClip(id: 'cb_${combat[i].toLowerCase().replaceAll(' ', '_')}', name: combat[i], category: AnimCategory.combat, duration: 0.9, loop: false); _generateDefaultMotion(clip); list.add(clip); }
    return list;
  }

  /// Every built-in library clip ships with a real baseline motion instead of
  /// an empty track, so picking "Walk" from the Library actually walks
  /// instead of leaving the character frozen until someone hand-keys poses.
  void _generateDefaultMotion(AnimationClip clip) {
    final base = {for (final b in bones) b.id: b};
    void kf(String boneId, double time, {double dRot = 0, double dx = 0, double dy = 0, double scale = 1}) {
      final b = base[boneId];
      if (b == null) return;
      clip.track(boneId).upsert(PoseKeyframe(time: time, x: b.x + dx, y: b.y + dy, rotation: b.rotation + dRot, scale: b.scale * scale));
    }

    switch (clip.id) {
      case 'mv_idle':
        kf('torso', 0, dy: 0); kf('torso', 1.0, dy: -4); kf('torso', 2.0, dy: 0);
        kf('head', 0, dRot: 0); kf('head', 1.0, dRot: .04); kf('head', 2.0, dRot: 0);
        kf('arm_l', 0, dRot: 0); kf('arm_l', 1.0, dRot: -.06); kf('arm_l', 2.0, dRot: 0);
        kf('arm_r', 0, dRot: 0); kf('arm_r', 1.0, dRot: .06); kf('arm_r', 2.0, dRot: 0);
        break;
      case 'mv_walk':
        kf('leg_l', 0, dRot: -.5); kf('leg_l', .6, dRot: .5); kf('leg_l', 1.2, dRot: -.5);
        kf('leg_r', 0, dRot: .5); kf('leg_r', .6, dRot: -.5); kf('leg_r', 1.2, dRot: .5);
        kf('arm_l', 0, dRot: .4); kf('arm_l', .6, dRot: -.4); kf('arm_l', 1.2, dRot: .4);
        kf('arm_r', 0, dRot: -.4); kf('arm_r', .6, dRot: .4); kf('arm_r', 1.2, dRot: -.4);
        kf('torso', 0, dy: 0); kf('torso', .3, dy: -6); kf('torso', .6, dy: 0); kf('torso', .9, dy: -6); kf('torso', 1.2, dy: 0);
        break;
      case 'mv_run':
        kf('leg_l', 0, dRot: -.9); kf('leg_l', .4, dRot: .9); kf('leg_l', .8, dRot: -.9);
        kf('leg_r', 0, dRot: .9); kf('leg_r', .4, dRot: -.9); kf('leg_r', .8, dRot: .9);
        kf('arm_l', 0, dRot: .7); kf('arm_l', .4, dRot: -.7); kf('arm_l', .8, dRot: .7);
        kf('arm_r', 0, dRot: -.7); kf('arm_r', .4, dRot: .7); kf('arm_r', .8, dRot: -.7);
        kf('torso', 0, dy: 4, dRot: .08); kf('torso', .4, dy: -10, dRot: .08); kf('torso', .8, dy: 4, dRot: .08);
        break;
      case 'mv_jump':
        kf('root', 0, dy: 0); kf('root', .3, dy: -14); kf('root', .7, dy: -60); kf('root', 1.2, dy: 0);
        kf('leg_l', 0, dRot: .3); kf('leg_l', .3, dRot: -.2); kf('leg_l', .7, dRot: .1); kf('leg_l', 1.2, dRot: .3);
        kf('leg_r', 0, dRot: -.3); kf('leg_r', .3, dRot: .2); kf('leg_r', .7, dRot: -.1); kf('leg_r', 1.2, dRot: -.3);
        kf('arm_l', 0, dRot: 0); kf('arm_l', .7, dRot: -.8); kf('arm_l', 1.2, dRot: 0);
        kf('arm_r', 0, dRot: 0); kf('arm_r', .7, dRot: .8); kf('arm_r', 1.2, dRot: 0);
        break;
      case 'mv_fall':
        kf('torso', 0, dRot: 0); kf('torso', .6, dRot: .3); kf('torso', 1.2, dRot: .5);
        kf('root', 0, dy: 0); kf('root', 1.2, dy: 40);
        kf('arm_l', 0, dRot: 0); kf('arm_l', 1.2, dRot: -.6);
        kf('arm_r', 0, dRot: 0); kf('arm_r', 1.2, dRot: .6);
        break;
      case 'mv_dodge_step':
        kf('root', 0, dx: 0); kf('root', .3, dx: -40); kf('root', .6, dx: 0);
        kf('torso', 0, dRot: 0); kf('torso', .3, dRot: -.3); kf('torso', .6, dRot: 0);
        break;
      case 'cb_attack_windup':
        kf('arm_r', 0, dRot: 0); kf('arm_r', .4, dRot: -1.0);
        kf('torso', 0, dRot: 0); kf('torso', .4, dRot: -.15);
        break;
      case 'cb_attack':
        kf('arm_r', 0, dRot: -1.0); kf('arm_r', .2, dRot: 1.2);
        kf('torso', 0, dRot: -.15); kf('torso', .2, dRot: .2);
        break;
      case 'cb_attack_recovery':
        kf('arm_r', 0, dRot: 1.2); kf('arm_r', .4, dRot: 0);
        kf('torso', 0, dRot: .2); kf('torso', .4, dRot: 0);
        break;
      case 'cb_block':
        kf('arm_l', 0, dRot: 0); kf('arm_l', .2, dRot: -1.1);
        kf('arm_r', 0, dRot: 0); kf('arm_r', .2, dRot: 1.1);
        break;
      case 'cb_hit_reaction':
        kf('torso', 0, dRot: 0); kf('torso', .15, dRot: .3); kf('torso', .5, dRot: 0);
        kf('head', 0, dRot: 0); kf('head', .15, dRot: .4); kf('head', .5, dRot: 0);
        break;
      case 'cb_counter':
        kf('torso', 0, dRot: .2); kf('torso', .3, dRot: -.2); kf('torso', .6, dRot: 0);
        kf('arm_l', 0, dRot: .3); kf('arm_l', .3, dRot: -.9); kf('arm_l', .6, dRot: 0);
        break;
    }
  }

  void selectBone(String id) { selectedBoneId = id; notifyListeners(); }
  void setTool(String value) { tool = value; notifyListeners(); }
  void setExpression(String value) { expression = value; notifyListeners(); }
  void setAppearance({Color? skin, Color? hair, Color? eyes, Color? clothes, String? style}) {
    if (skin != null) skinColor = skin;
    if (hair != null) hairColor = hair;
    if (eyes != null) eyeColor = eyes;
    if (clothes != null) clothesColor = clothes;
    if (style != null) hairStyle = style;
    status = 'Appearance updated';
    notifyListeners();
  }
  void toggleUseImageAsBody(bool value) { useImageAsBody = value; status = value ? 'Using uploaded image as body' : 'Using drawn character'; notifyListeners(); }
  void setPartCrop(String partId, Rect? crop) { parts.firstWhere((p) => p.id == partId).crop = crop; status = crop == null ? 'Region cleared' : 'Region mapped'; notifyListeners(); }
  bool get hasAnyPartCrop => parts.any((p) => p.crop != null);
  void selectAnimation(String id) { selectedAnimationId = id; setPlayhead(0); }
  void setPlayhead(double value) { playhead = value.clamp(0, selectedAnimation.duration); notifyListeners(); }
  void setCamera({double? x, double? y, double? zoom, double? rotation}) { if (x != null) camera.x = x; if (y != null) camera.y = y; if (zoom != null) camera.zoom = zoom.clamp(.2, 4); if (rotation != null) camera.rotation = rotation; notifyListeners(); }

  void setBone({double? x, double? y, double? rotation, double? scale}) {
    final b = selectedBone;
    if (x != null) b.x = x;
    if (y != null) b.y = y;
    if (rotation != null) b.rotation = rotation;
    if (scale != null) b.scale = scale.clamp(.1, 3);
    status = 'Pose modified';
    notifyListeners();
  }

  void captureKeyframe() {
    final b = selectedBone;
    selectedAnimation.track(b.id).upsert(PoseKeyframe(time: playhead, x: b.x, y: b.y, rotation: b.rotation, scale: b.scale));
    captureHistory();
    status = 'Keyframe captured at ${playhead.toStringAsFixed(2)}s';
    notifyListeners();
  }

  void captureAll() {
    for (final b in bones) selectedAnimation.track(b.id).upsert(PoseKeyframe(time: playhead, x: b.x, y: b.y, rotation: b.rotation, scale: b.scale));
    captureHistory();
    status = 'Full pose keyframe captured';
    notifyListeners();
  }

  void addFx(String name) { fx.add(FxEvent(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, time: playhead)); status = '$name added'; notifyListeners(); }
  void addAudio(String name) { audio.add(AudioCue(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, time: playhead)); status = '$name cue added'; notifyListeners(); }

  void resetPose() { for (final b in bones) { final d = defaultBones().firstWhere((x) => x.id == b.id); b.x = d.x; b.y = d.y; b.rotation = d.rotation; b.scale = d.scale; } captureHistory(); notifyListeners(); }

  void loadAt(double time) {
    final clip = selectedAnimation;
    final local = clip.loop && clip.duration > 0 ? time % clip.duration : time.clamp(0, clip.duration);
    for (final b in bones) {
      final track = clip.tracks[b.id];
      if (track == null || track.keys.isEmpty) continue;
      final keys = track.keys;
      if (keys.length == 1) { _apply(b, keys.first); continue; }
      PoseKeyframe a = keys.first, c = keys.last;
      for (var i = 0; i < keys.length - 1; i++) { if (local >= keys[i].time && local <= keys[i + 1].time) { a = keys[i]; c = keys[i + 1]; break; } }
      final span = (c.time - a.time).abs();
      final t = span < .0001 ? 0.0 : _ease(((local - a.time) / span).clamp(0, 1));
      b.x = _lerp(a.x, c.x, t); b.y = _lerp(a.y, c.y, t); b.rotation = _lerpAngle(a.rotation, c.rotation, t); b.scale = _lerp(a.scale, c.scale, t);
    }
    playhead = time.clamp(0, clip.duration);
    notifyListeners();
  }

  void _apply(Bone b, PoseKeyframe k) { b.x = k.x; b.y = k.y; b.rotation = k.rotation; b.scale = k.scale; }
  double _lerp(double a, double b, double t) => a + (b - a) * t;
  double _lerpAngle(double a, double b, double t) { var d = (b - a + math.pi) % (2 * math.pi) - math.pi; return a + d * t; }
  /// Smoothstep ease-in-out so poses accelerate/decelerate instead of moving
  /// at a robotic constant speed between keyframes.
  double _ease(double t) => t * t * (3 - 2 * t);

  void captureHistory() {
    final snapshot = {for (final b in bones) b.id: [b.x, b.y, b.rotation, b.scale]};
    _undo.add(snapshot); if (_undo.length > 30) _undo.removeAt(0); _redo.clear();
  }
  void undo() { if (_undo.length < 2) return; _redo.add(_undo.removeLast()); _restore(_undo.last); status = 'Undo'; notifyListeners(); }
  void redo() { if (_redo.isEmpty) return; final s = _redo.removeLast(); _undo.add(s); _restore(s); status = 'Redo'; notifyListeners(); }
  void _restore(Map<String, List<double>> s) { for (final b in bones) { final v = s[b.id]; if (v != null) { b.x = v[0]; b.y = v[1]; b.rotation = v[2]; b.scale = v[3]; } } }

  void autoRig() { bones = defaultBones(); parts = defaultParts(); selectedBoneId = 'root'; status = 'Auto-rig rebuilt'; captureHistory(); notifyListeners(); }
  void bindPart(String partId, String boneId) { parts.firstWhere((p) => p.id == partId).boneId = boneId; status = 'Part bound to $boneId'; notifyListeners(); }
  void togglePart(String id) { final p = parts.firstWhere((p) => p.id == id); p.visible = !p.visible; notifyListeners(); }
}
