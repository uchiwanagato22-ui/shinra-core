import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart' show Color, Rect;
import '../services/image_segmentation.dart';
import '../services/animation_import.dart';

enum BoneType { root, head, torso, arm, hand, leg, foot }

enum PartType { body, face, hair, eyes, mouth, clothes, hand, shoes, accessory }

enum AnimCategory { movement, combat, face, fx }

/// Controls how motion arrives at an incoming pose.  This lets one clip mix
/// calm dialogue, anticipation, and sharp anime impacts.
enum KeyframeEasing { linear, smooth, easeIn, easeOut, impact }

const skinPalette = [Color(0xFFE9B18E), Color(0xFFF6D3B0), Color(0xFFC98A5B), Color(0xFF8D5A3C), Color(0xFF5C3A28)];
const hairPalette = [Color(0xFF151722), Color(0xFF3B2A1E), Color(0xFF8A4B2A), Color(0xFFC9A227), Color(0xFFB23A48), Color(0xFF4A6FE0), Color(0xFFE0E0E0)];
const eyePalette = [Color(0xFF151722), Color(0xFF2E6DB4), Color(0xFF3E8E4F), Color(0xFF7C4DBE), Color(0xFFB23A48), Color(0xFFC9A227)];
const clothesPalette = [Color(0xFF2C3448), Color(0xFF7C2431), Color(0xFF1F5C4C), Color(0xFF2F4A7C), Color(0xFF4A4A52), Color(0xFF8C6A2F)];
const hairStyles = ['Court', 'Long', 'Spike', 'Queue', 'Chauve', 'Frange', 'Afro', 'Mohawk'];
const eyeShapes = ['Round', 'Sharp', 'Sleepy', 'Wide', 'Cat'];
/// Generic silhouettes only — no outfit is modeled after a specific franchise
/// character, on purpose.
const outfitStyles = ['Hoodie', 'Jacket', 'Robe', 'Dress', 'Tank', 'Armor', 'Cape', 'Suit', 'Tactical Vest', 'Battle Cloak'];
const accessorySlots = ['glasses', 'headband', 'scarf', 'hat', 'gloves', 'belt'];
const backgroundStyles = ['Void', 'Forest', 'Rooftop City', 'Rainy City', 'Neon Street', 'Dojo', 'Sunset Sky', 'Custom'];
const weatherStyles = ['Clear', 'Rain', 'Snow'];
const maxSceneActors = 6;

/// One character placed in a multi-actor scene — each has its own pose,
/// appearance, optional imported art, and animation clip.
class SceneActor {
  SceneActor({required this.id, required this.name, this.offsetX = 0, this.offsetY = 0, this.facing = 1});
  final String id;
  String name;
  double offsetX;
  double offsetY;
  double facing;
  String animationId = 'mv_idle';
  String importedImagePath = '';
  bool useImageAsBody = false;
  Color skinColor = skinPalette.first;
  Color hairColor = hairPalette.first;
  Color eyeColor = eyePalette.first;
  Color clothesColor = clothesPalette.first;
  String hairStyle = hairStyles.first;
  String eyeShape = eyeShapes.first;
  String outfitStyle = outfitStyles.first;
  String expression = 'Neutral';
  String mouthShape = 'Auto';
  double eyeLookX = 0;
  double eyeLookY = 0;
  bool accGlasses = false;
  bool accHeadband = false;
  bool accScarf = false;
  bool accHat = false;
  bool accGloves = false;
  bool accBelt = false;
  List<Bone> bones = [for (final b in defaultBones()) b.copy()];
  List<CharacterPart> parts = [for (final p in defaultParts()) CharacterPart(id: p.id, name: p.name, type: p.type, boneId: p.boneId, visible: p.visible, crop: p.crop)];

  void captureFrom(ProjectState p) {
    importedImagePath = p.importedImagePath;
    useImageAsBody = p.useImageAsBody;
    skinColor = p.skinColor;
    hairColor = p.hairColor;
    eyeColor = p.eyeColor;
    clothesColor = p.clothesColor;
    hairStyle = p.hairStyle;
    eyeShape = p.eyeShape;
    outfitStyle = p.outfitStyle;
    expression = p.expression;
    mouthShape = p.mouthShape;
    eyeLookX = p.eyeLookX;
    eyeLookY = p.eyeLookY;
    accGlasses = p.accGlasses;
    accHeadband = p.accHeadband;
    accScarf = p.accScarf;
    accHat = p.accHat;
    accGloves = p.accGloves;
    accBelt = p.accBelt;
    animationId = p.selectedAnimationId;
    bones = [for (final b in p.bones) b.copy()];
    parts = [for (final pt in p.parts) CharacterPart(id: pt.id, name: pt.name, type: pt.type, boneId: pt.boneId, visible: pt.visible, locked: pt.locked, x: pt.x, y: pt.y, rotation: pt.rotation, scale: pt.scale, crop: pt.crop)];
  }

  void applyTo(ProjectState p) {
    p.importedImagePath = importedImagePath;
    p.useImageAsBody = useImageAsBody;
    p.skinColor = skinColor;
    p.hairColor = hairColor;
    p.eyeColor = eyeColor;
    p.clothesColor = clothesColor;
    p.hairStyle = hairStyle;
    p.eyeShape = eyeShape;
    p.outfitStyle = outfitStyle;
    p.expression = expression;
    p.mouthShape = mouthShape;
    p.eyeLookX = eyeLookX;
    p.eyeLookY = eyeLookY;
    p.accGlasses = accGlasses;
    p.accHeadband = accHeadband;
    p.accScarf = accScarf;
    p.accHat = accHat;
    p.accGloves = accGloves;
    p.accBelt = accBelt;
    if (p.animations.any((a) => a.id == animationId)) p.selectedAnimationId = animationId;
    for (final b in bones) {
      final target = p.bones.where((x) => x.id == b.id).firstOrNull;
      if (target != null) { target.x = b.x; target.y = b.y; target.rotation = b.rotation; target.scale = b.scale; }
    }
    for (final pt in parts) {
      final target = p.parts.where((x) => x.id == pt.id).firstOrNull;
      if (target != null) { target.boneId = pt.boneId; target.visible = pt.visible; target.crop = pt.crop; }
    }
  }
}

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
  PoseKeyframe({required this.time, required this.x, required this.y, required this.rotation, required this.scale, this.easing = KeyframeEasing.smooth});
  final double time;
  final double x;
  final double y;
  final double rotation;
  final double scale;
  KeyframeEasing easing;
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
  FxEvent({required this.id, required this.name, required this.time, required this.clipId});
  final String id;
  final String name;
  final double time;
  final String clipId;
}

class AudioCue {
  AudioCue({required this.id, required this.name, required this.time, required this.clipId});
  final String id;
  final String name;
  final double time;
  final String clipId;
}

/// A line of dialogue attached to one actor at a point on the timeline.
/// While the playhead is within [time, time + duration], that actor's mouth
/// cycles open/closed (a simple lip-flap, not real phoneme-accurate lip
/// sync — there's no audio/TTS timing data here to sync against) and the
/// text shows as a speech bubble above their head, doubling as an on-screen
/// caption for exported clips.
class DialogueCue {
  DialogueCue({required this.id, required this.actorId, required this.text, required this.time, required this.duration, required this.clipId});
  final String id;
  final String actorId;
  final String text;
  final double time;
  final double duration;
  final String clipId;
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
  CharacterPart(id: 'arm_l', name: 'Arm L', type: PartType.body, boneId: 'arm_l'),
  CharacterPart(id: 'arm_r', name: 'Arm R', type: PartType.body, boneId: 'arm_r'),
  CharacterPart(id: 'leg_l', name: 'Leg L', type: PartType.body, boneId: 'leg_l'),
  CharacterPart(id: 'leg_r', name: 'Leg R', type: PartType.body, boneId: 'leg_r'),
  CharacterPart(id: 'hand_l', name: 'Hand L', type: PartType.hand, boneId: 'hand_l'),
  CharacterPart(id: 'hand_r', name: 'Hand R', type: PartType.hand, boneId: 'hand_r'),
  CharacterPart(id: 'shoes_l', name: 'Shoe L', type: PartType.shoes, boneId: 'foot_l'),
  CharacterPart(id: 'shoes_r', name: 'Shoe R', type: PartType.shoes, boneId: 'foot_r'),
];

extension _IterableFirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }

class ProjectState extends ChangeNotifier {
  ProjectState() {
    bones = defaultBones();
    parts = defaultParts();
    animations = _presets();
    selectedBoneId = 'root';
    selectedAnimationId = animations.first.id;
    actors = [SceneActor(id: 'actor_1', name: 'Hero')];
    selectedActorId = actors.first.id;
    captureHistory();
  }

  List<Bone> bones = [];
  List<CharacterPart> parts = [];
  List<AnimationClip> animations = [];
  final CameraState camera = CameraState();
  final List<FxEvent> fx = [];
  final List<AudioCue> audio = [];
  final List<DialogueCue> dialogue = [];
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
  String eyeShape = eyeShapes.first;
  String outfitStyle = outfitStyles.first;
  String background = backgroundStyles.first;
  String weather = weatherStyles.first;
  String sceneBackgroundImagePath = '';
  List<SceneActor> actors = [];
  String selectedActorId = 'actor_1';
  bool poseDragMode = false;
  bool accGlasses = false;
  bool accHeadband = false;
  bool accScarf = false;
  bool accHat = false;
  bool accGloves = false;
  bool accBelt = false;
  double playhead = 0;
  bool playing = false;
  String tool = 'select';
  String expression = 'Neutral';
  /// Auto follows the selected expression; A/O/B are speech visemes that an
  /// animator can key or switch while previewing dialogue.
  String mouthShape = 'Auto';
  /// Normalized look direction for procedural eyes (-1..1 on both axes).
  /// It belongs to the selected character, so each actor can look elsewhere.
  double eyeLookX = 0;
  double eyeLookY = 0;
  String status = 'Ready';
  final List<Map<String, List<double>>> _undo = [];
  final List<Map<String, List<double>>> _redo = [];

  Bone get selectedBone => bones.firstWhere((b) => b.id == selectedBoneId, orElse: () => bones.first);
  AnimationClip get selectedAnimation => animations.firstWhere((a) => a.id == selectedAnimationId, orElse: () => animations.first);
  SceneActor get selectedActor => actors.firstWhere((a) => a.id == selectedActorId, orElse: () => actors.first);

  void persistSelectedActor() { if (actors.isEmpty) return; selectedActor.captureFrom(this); }

  void _persistSelectedActor() => persistSelectedActor();

  void selectActor(String id) {
    if (id == selectedActorId) return;
    _persistSelectedActor();
    selectedActorId = id;
    selectedActor.applyTo(this);
    status = 'Editing ${selectedActor.name}';
    notifyListeners();
  }

  void addActor({String? name, bool select = true}) {
    if (actors.length >= maxSceneActors) { status = 'Max $maxSceneActors characters in scene'; notifyListeners(); return; }
    _persistSelectedActor();
    final n = actors.length + 1;
    final actor = SceneActor(id: 'actor_$n', name: name ?? 'Character $n', offsetX: (n - 1) * 90.0 - 90);
    actors.add(actor);
    if (select) selectActor(actor.id);
    status = '${actor.name} added to scene';
    if (!select) notifyListeners();
  }

  void removeActor(String id) {
    if (actors.length <= 1) return;
    _persistSelectedActor();
    actors.removeWhere((a) => a.id == id);
    if (!actors.any((a) => a.id == selectedActorId)) selectedActorId = actors.first.id;
    selectedActor.applyTo(this);
    status = 'Character removed';
    notifyListeners();
  }

  void setActorOffset(String id, {double? x, double? y, double? facing}) {
    final actor = actors.firstWhere((a) => a.id == id);
    if (x != null) actor.offsetX = x;
    if (y != null) actor.offsetY = y;
    if (facing != null) actor.facing = facing >= 0 ? 1 : -1;
    notifyListeners();
  }

  void setActorAnimation(String id, String animationId) {
    actors.firstWhere((a) => a.id == id).animationId = animationId;
    if (id == selectedActorId && animations.any((a) => a.id == animationId)) selectedAnimationId = animationId;
    notifyListeners();
  }

  void setWeather(String v) { weather = v; notifyListeners(); }

  void applyScenePreset(String preset) {
    _persistSelectedActor();
    switch (preset) {
      case 'walk_dance_rain':
        background = 'Rainy City';
        weather = 'Rain';
        while (actors.length < 2) addActor(name: actors.length == 1 ? 'Dancer' : null, select: false);
        actors[0].name = 'Walker'; actors[0].offsetX = -70; actors[0].animationId = 'mv_walk';
        actors[1].name = 'Dancer'; actors[1].offsetX = 70; actors[1].animationId = 'mv_dance';
        selectActor(actors.first.id);
        status = 'Scene: walk + dance in rainy city';
        break;
      case 'triple_combat':
        background = 'Dojo';
        weather = 'Clear';
        while (actors.length < 3) addActor(select: false);
        for (var i = 0; i < 3; i++) {
          actors[i].offsetX = (i - 1) * 100.0;
          actors[i].animationId = i == 1 ? 'cb_attack' : 'cb_block';
          actors[i].name = 'Fighter ${i + 1}';
        }
        selectActor(actors.first.id);
        status = 'Scene: 3-fighter combat lineup';
        break;
      case 'six_battle':
        background = 'Neon Street';
        weather = 'Rain';
        while (actors.length < 6) addActor(select: false);
        for (var i = 0; i < 6; i++) {
          actors[i].offsetX = (i % 3 - 1) * 110.0;
          actors[i].offsetY = (i ~/ 3) * 40.0 - 20;
          actors[i].animationId = i.isEven ? 'cb_combo_strike' : 'cb_block';
          actors[i].name = 'Fighter ${i + 1}';
        }
        selectActor(actors.first.id);
        status = 'Scene: 6-character battle royale';
        break;
      case 'city_stroll':
        background = 'Rooftop City';
        weather = 'Clear';
        while (actors.length < 2) addActor(select: false);
        actors[0].offsetX = -50; actors[0].animationId = 'mv_walk';
        actors[1].offsetX = 50; actors[1].animationId = 'mv_walk';
        selectActor(actors.first.id);
        status = 'Scene: duo city walk';
        break;
    }
    notifyListeners();
  }

  List<AnimationClip> _presets() {
    final movement = ['Idle', 'Walk', 'Run', 'Jump', 'Fall', 'Dodge Step', 'Dance', 'Bow', 'Celebrate', 'Wave', 'Point'];
    final combat = ['Attack Windup', 'Attack', 'Attack Recovery', 'Block', 'Hit Reaction', 'Counter', 'Combo Strike', 'Uppercut', 'Spin Attack', 'Air Kick', 'Grapple', 'Team Rush', 'Guard Stance'];
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
      case 'mv_dance':
        kf('torso', 0, dy: 0, dRot: 0); kf('torso', .3, dy: -8, dRot: .12); kf('torso', .6, dy: 0, dRot: -.12); kf('torso', .9, dy: -8, dRot: .12); kf('torso', 1.2, dy: 0, dRot: 0);
        kf('arm_l', 0, dRot: -.3); kf('arm_l', .3, dRot: -1.1); kf('arm_l', .6, dRot: .2); kf('arm_l', .9, dRot: -1.1); kf('arm_l', 1.2, dRot: -.3);
        kf('arm_r', 0, dRot: .3); kf('arm_r', .3, dRot: 1.1); kf('arm_r', .6, dRot: -.2); kf('arm_r', .9, dRot: 1.1); kf('arm_r', 1.2, dRot: .3);
        kf('leg_l', 0, dRot: -.2); kf('leg_l', .6, dRot: .35); kf('leg_l', 1.2, dRot: -.2);
        kf('leg_r', 0, dRot: .2); kf('leg_r', .6, dRot: -.35); kf('leg_r', 1.2, dRot: .2);
        break;
      case 'mv_bow':
        kf('torso', 0, dRot: 0); kf('torso', .4, dRot: .45); kf('torso', .9, dRot: 0);
        kf('head', 0, dRot: 0); kf('head', .4, dRot: .25); kf('head', .9, dRot: 0);
        break;
      case 'mv_celebrate':
        kf('arm_l', 0, dRot: 0); kf('arm_l', .25, dRot: -1.4); kf('arm_l', .5, dRot: -.3); kf('arm_l', .75, dRot: -1.4); kf('arm_l', 1.0, dRot: 0);
        kf('arm_r', 0, dRot: 0); kf('arm_r', .25, dRot: 1.4); kf('arm_r', .5, dRot: .3); kf('arm_r', .75, dRot: 1.4); kf('arm_r', 1.0, dRot: 0);
        kf('root', 0, dy: 0); kf('root', .5, dy: -20); kf('root', 1.0, dy: 0);
        break;
      case 'mv_wave':
        kf('arm_r', 0, dRot: .2); kf('arm_r', .25, dRot: 1.3); kf('arm_r', .5, dRot: .9); kf('arm_r', .75, dRot: 1.35); kf('arm_r', 1.2, dRot: .2);
        kf('hand_r', 0, dRot: 0); kf('hand_r', .25, dRot: .35); kf('hand_r', .5, dRot: -.35); kf('hand_r', .75, dRot: .35); kf('hand_r', 1.2, dRot: 0);
        break;
      case 'mv_point':
        kf('arm_r', 0, dRot: .1); kf('arm_r', .3, dRot: 1.05); kf('arm_r', 1.0, dRot: 1.05);
        kf('hand_r', 0, dRot: 0); kf('hand_r', .3, dRot: .15); kf('hand_r', 1.0, dRot: .15);
        break;
      case 'cb_combo_strike':
        kf('arm_r', 0, dRot: 0); kf('arm_r', .15, dRot: -1.0); kf('arm_r', .35, dRot: 1.3); kf('arm_r', .55, dRot: -.8); kf('arm_r', .75, dRot: 1.1); kf('arm_r', .9, dRot: 0);
        kf('torso', 0, dRot: 0); kf('torso', .35, dRot: .25); kf('torso', .75, dRot: -.15); kf('torso', .9, dRot: 0);
        kf('leg_l', 0, dRot: 0); kf('leg_l', .35, dRot: .4); kf('leg_l', .9, dRot: 0);
        break;
      case 'cb_uppercut':
        kf('arm_r', 0, dRot: .5); kf('arm_r', .2, dRot: -1.6); kf('arm_r', .45, dRot: 1.8); kf('arm_r', .9, dRot: 0);
        kf('root', 0, dy: 0); kf('root', .2, dy: 8); kf('root', .45, dy: -25); kf('root', .9, dy: 0);
        kf('torso', 0, dRot: 0); kf('torso', .45, dRot: -.2); kf('torso', .9, dRot: 0);
        break;
      case 'cb_spin_attack':
        kf('root', 0, dx: 0); kf('root', .45, dx: 0);
        kf('torso', 0, dRot: 0); kf('torso', .25, dRot: 1.2); kf('torso', .5, dRot: 2.4); kf('torso', .75, dRot: 3.6); kf('torso', .9, dRot: 0);
        kf('arm_l', 0, dRot: 0); kf('arm_l', .45, dRot: 1.0); kf('arm_l', .9, dRot: 0);
        kf('arm_r', 0, dRot: 0); kf('arm_r', .45, dRot: -1.0); kf('arm_r', .9, dRot: 0);
        break;
      case 'cb_air_kick':
        kf('root', 0, dy: 0); kf('root', .25, dy: -35); kf('root', .6, dy: -35); kf('root', .9, dy: 0);
        kf('leg_r', 0, dRot: 0); kf('leg_r', .25, dRot: -.9); kf('leg_r', .45, dRot: 1.4); kf('leg_r', .9, dRot: 0);
        kf('arm_l', 0, dRot: 0); kf('arm_l', .45, dRot: -.7); kf('arm_l', .9, dRot: 0);
        break;
      case 'cb_grapple':
        kf('arm_l', 0, dRot: 0); kf('arm_l', .3, dRot: -.9); kf('arm_l', .6, dRot: -.9); kf('arm_l', .9, dRot: 0);
        kf('arm_r', 0, dRot: 0); kf('arm_r', .3, dRot: .9); kf('arm_r', .6, dRot: .9); kf('arm_r', .9, dRot: 0);
        kf('torso', 0, dy: 0); kf('torso', .3, dy: 10); kf('torso', .6, dy: 10); kf('torso', .9, dy: 0);
        break;
      case 'cb_team_rush':
        kf('root', 0, dx: 0); kf('root', .4, dx: 60); kf('root', .9, dx: 0);
        kf('arm_r', 0, dRot: 0); kf('arm_r', .2, dRot: -1.0); kf('arm_r', .4, dRot: 1.2); kf('arm_r', .9, dRot: 0);
        kf('leg_l', 0, dRot: -.4); kf('leg_l', .4, dRot: .5); kf('leg_l', .9, dRot: -.4);
        kf('leg_r', 0, dRot: .4); kf('leg_r', .4, dRot: -.5); kf('leg_r', .9, dRot: .4);
        break;
      case 'cb_guard_stance':
        kf('arm_l', 0, dRot: -.1); kf('arm_l', .2, dRot: -1.15); kf('arm_l', .9, dRot: -1.15);
        kf('arm_r', 0, dRot: .1); kf('arm_r', .2, dRot: 1.15); kf('arm_r', .9, dRot: 1.15);
        kf('hand_l', 0, dRot: 0); kf('hand_l', .2, dRot: -.15); kf('hand_l', .9, dRot: -.15);
        kf('hand_r', 0, dRot: 0); kf('hand_r', .2, dRot: .15); kf('hand_r', .9, dRot: .15);
        break;
    }
  }

  void selectBone(String id) { selectedBoneId = id; notifyListeners(); }
  String poseTool = 'move';
  void setPoseTool(String t) { poseTool = t; notifyListeners(); }
  double worldRotationOf(String boneId) {
    var r = 0.0;
    final byId = {for (final b in bones) b.id: b};
    var id = byId[boneId]?.parentId;
    var guard = 0;
    while (id != null && guard++ < 20) {
      final b = byId[id];
      if (b == null) break;
      r += b.rotation;
      id = b.parentId;
    }
    return r;
  }
  void setTool(String value) { tool = value; notifyListeners(); }
  void setExpression(String value) { expression = value; persistSelectedActor(); notifyListeners(); }
  void setMouthShape(String value) { mouthShape = value; persistSelectedActor(); notifyListeners(); }
  void setEyeDirection({double? x, double? y}) {
    if (x != null) eyeLookX = x.clamp(-1, 1).toDouble();
    if (y != null) eyeLookY = y.clamp(-1, 1).toDouble();
    status = 'Eye direction updated';
    persistSelectedActor();
    notifyListeners();
  }
  void setAppearance({Color? skin, Color? hair, Color? eyes, Color? clothes, String? style, String? eyeShape}) {
    if (skin != null) skinColor = skin;
    if (hair != null) hairColor = hair;
    if (eyes != null) eyeColor = eyes;
    if (clothes != null) clothesColor = clothes;
    if (style != null) hairStyle = style;
    if (eyeShape != null) this.eyeShape = eyeShape;
    status = 'Appearance updated';
    persistSelectedActor();
    notifyListeners();
  }
  void toggleUseImageAsBody(bool value) { useImageAsBody = value; status = value ? 'Using uploaded image as body' : 'Using drawn character'; notifyListeners(); }
  void setOutfit(String v) { outfitStyle = v; notifyListeners(); }
  void setBackground(String v) { background = v; notifyListeners(); }
  void setAccessory(String name, bool v) {
    switch (name) { case 'glasses': accGlasses = v; break; case 'headband': accHeadband = v; break; case 'scarf': accScarf = v; break; case 'hat': accHat = v; break; case 'gloves': accGloves = v; break; case 'belt': accBelt = v; break; }
    notifyListeners();
  }
  void setPartCrop(String partId, Rect? crop) { parts.firstWhere((p) => p.id == partId).crop = crop; status = crop == null ? 'Region cleared' : 'Region mapped'; notifyListeners(); }
  bool get hasAnyPartCrop => parts.any((p) => p.crop != null);

  /// Rough starting guess based on standard standing-figure proportions,
  /// refined with real edge-detection for the head/torso/legs boundaries
  /// (see ImageSegmentation) — NOT full ML detection (no model available
  /// here), and left/right splits + hands/feet stay proportion-based. Meant
  /// to save time versus drawing every rectangle from a blank image; the
  /// user is expected to nudge each region afterwards via "Set region".
  Future<void> autoMapImageParts() async {
    var headSplit = .18;
    var legSplit = .52;
    if (importedImagePath.isNotEmpty) {
      final bounds = await ImageSegmentation.findBoundaries(importedImagePath);
      headSplit = bounds.headSplit;
      legSplit = bounds.legSplit;
    }
    void set(String id, double l, double t, double w, double h) => parts.firstWhere((p) => p.id == id).crop = Rect.fromLTWH(l, t, w, h);
    set('face', .32, .0, .36, headSplit);
    set('hair', .28, .0, .44, headSplit * .9);
    set('body', .25, headSplit, .50, legSplit - headSplit);
    set('clothes', .25, headSplit, .50, legSplit - headSplit);
    set('arm_l', .04, headSplit + .02, .24, (legSplit - headSplit) + .02);
    set('arm_r', .72, headSplit + .02, .24, (legSplit - headSplit) + .02);
    set('hand_l', .02, legSplit - .04, .14, .10);
    set('hand_r', .84, legSplit - .04, .14, .10);
    set('leg_l', .27, legSplit, .22, 1 - legSplit - .08);
    set('leg_r', .51, legSplit, .22, 1 - legSplit - .08);
    set('shoes_l', .27, .90, .22, .10);
    set('shoes_r', .51, .90, .22, .10);
    status = 'Regions guessed from image edges — still nudge each one, this is not full detection';
    persistSelectedActor();
    notifyListeners();
  }
  void selectAnimation(String id) { selectedAnimationId = id; _playedAudioIds.clear(); _lastAudioPlayhead = -1; setPlayhead(0); }
  /// Lets the user build their own animation from scratch instead of being
  /// limited to the 12 built-in presets — key poses by hand at whatever
  /// duration the scene actually needs.
  Future<int> importLibraryAnimations() async {
    final result = await AnimationImport.loadAll();
    var added = 0;
    for (final clip in result.clips) {
      if (animations.any((c) => c.id == clip.id)) continue; // already imported
      animations.add(clip);
      added++;
    }
    status = added == 0 ? 'No new bundled animations to import' : '$added bundled animation(s) imported${result.failed > 0 ? " (${result.failed} skipped)" : ""}';
    notifyListeners();
    return added;
  }

  void createAnimation(String name, double duration, {bool loop = false}) {
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final clip = AnimationClip(id: id, name: name, category: AnimCategory.movement, duration: duration.clamp(0.2, 120), loop: loop);
    for (final b in bones) clip.track(b.id).upsert(PoseKeyframe(time: 0, x: b.x, y: b.y, rotation: b.rotation, scale: b.scale));
    animations.add(clip);
    selectAnimation(id);
    status = '"$name" created ($duration s)';
  }
  void deleteAnimation(String id) {
    if (animations.length <= 1) return;
    animations.removeWhere((c) => c.id == id);
    fx.removeWhere((e) => e.clipId == id);
    audio.removeWhere((e) => e.clipId == id);
    if (selectedAnimationId == id) selectAnimation(animations.first.id);
    notifyListeners();
  }

  /// A queued sequence of clip ids to play back to back — what lets the AI
  /// Director actually direct the character (courir puis frapper) instead of
  /// only listing text nobody can run.
  List<String> queue = [];
  int queueIndex = 0;
  void startQueue(List<String> clipIds) {
    queue = List.of(clipIds);
    queueIndex = 0;
    if (queue.isNotEmpty) selectAnimation(queue.first);
  }

  /// Called by the playback timer when the current clip finishes. Returns
  /// true if it advanced to the next queued clip (caller should keep
  /// playing), false if the queue is exhausted (caller should stop).
  bool advanceQueue() {
    if (queue.isEmpty || queueIndex >= queue.length - 1) { queue = []; queueIndex = 0; return false; }
    queueIndex++;
    selectAnimation(queue[queueIndex]);
    return true;
  }
  void setPlayhead(double value) { playhead = value.clamp(0, selectedAnimation.duration).toDouble(); if (value <= 0) { _playedAudioIds.clear(); _lastAudioPlayhead = -1; } notifyListeners(); }
  void setCamera({double? x, double? y, double? zoom, double? rotation}) { if (x != null) camera.x = x; if (y != null) camera.y = y; if (zoom != null) camera.zoom = zoom.clamp(.2, 4); if (rotation != null) camera.rotation = rotation; notifyListeners(); }

  void setBone({double? x, double? y, double? rotation, double? scale}) {
    final b = selectedBone;
    if (x != null) b.x = x;
    if (y != null) b.y = y;
    if (rotation != null) b.rotation = rotation;
    if (scale != null) b.scale = scale.clamp(.1, 3);
    status = 'Pose modified';
    persistSelectedActor();
    notifyListeners();
  }

  void captureKeyframe() {
    final b = selectedBone;
    selectedAnimation.track(b.id).upsert(PoseKeyframe(time: playhead, x: b.x, y: b.y, rotation: b.rotation, scale: b.scale));
    captureHistory();
    status = 'Keyframe captured at ${playhead.toStringAsFixed(2)}s';
    persistSelectedActor();
    notifyListeners();
  }

  /// Changes the curve on the key at the current playhead. We never create a
  /// hidden key here: the animator must deliberately capture the pose first.
  void setKeyframeEasing(KeyframeEasing easing) {
    final track = selectedAnimation.track(selectedBoneId);
    PoseKeyframe? key;
    for (final candidate in track.keys) {
      if ((candidate.time - playhead).abs() < .001) {
        key = candidate;
        break;
      }
    }
    if (key == null) {
      status = 'Add a keyframe first';
      notifyListeners();
      return;
    }
    key.easing = easing;
    status = 'Motion curve: ${easing.name}';
    persistSelectedActor();
    notifyListeners();
  }

  void captureAll() {
    for (final b in bones) selectedAnimation.track(b.id).upsert(PoseKeyframe(time: playhead, x: b.x, y: b.y, rotation: b.rotation, scale: b.scale));
    captureHistory();
    status = 'Full pose keyframe captured';
    notifyListeners();
  }

  void addFx(String name) { fx.add(FxEvent(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, time: playhead, clipId: selectedAnimationId)); status = '$name added'; notifyListeners(); }
  void addAudio(String name) { audio.add(AudioCue(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, time: playhead, clipId: selectedAnimationId)); status = '$name cue added'; notifyListeners(); }

  /// Adds a line of dialogue for [actorId] at the current playhead. Duration
  /// defaults to a rough reading-pace estimate (~14 characters/second, min
  /// 0.6s) when not given — not real speech timing, just a usable default
  /// until real audio is attached.
  void addDialogue(String actorId, String text, {double? duration}) {
    final d = duration ?? (text.length / 14).clamp(.6, 8.0);
    dialogue.add(DialogueCue(id: DateTime.now().microsecondsSinceEpoch.toString(), actorId: actorId, text: text, time: playhead, duration: d, clipId: selectedAnimationId));
    status = 'Dialogue added for ${d.toStringAsFixed(1)}s';
    notifyListeners();
  }

  void removeDialogue(String id) { dialogue.removeWhere((d) => d.id == id); notifyListeners(); }

  /// The dialogue line currently "speaking" for this actor, if any — drives
  /// both the mouth-flap animation and the on-screen speech bubble.
  DialogueCue? activeDialogueFor(String actorId) {
    for (final d in dialogue) {
      if (d.clipId != selectedAnimationId || d.actorId != actorId) continue;
      if (playhead >= d.time && playhead <= d.time + d.duration) return d;
    }
    return null;
  }

  /// FX/audio belonging to the animation clip currently open — previously fx
  /// and audio were one flat list shared by every clip, so switching clips
  /// still showed/triggered cues that were placed on a different animation.
  List<FxEvent> get activeFx => fx.where((e) => e.clipId == selectedAnimationId).toList();
  List<AudioCue> get activeAudio => audio.where((e) => e.clipId == selectedAnimationId).toList();
  List<DialogueCue> get activeDialogue => dialogue.where((d) => d.clipId == selectedAnimationId).toList();

  /// Called by the UI layer (which owns the actual audio player) whenever
  /// playback crosses an audio cue, so the sound only fires once per pass
  /// instead of every repaint while the playhead sits on top of it.
  void Function(String name)? onAudioCue;
  final Set<String> _playedAudioIds = {};
  double _lastAudioPlayhead = -1;

  void resetPose() { for (final b in bones) { final d = defaultBones().firstWhere((x) => x.id == b.id); b.x = d.x; b.y = d.y; b.rotation = d.rotation; b.scale = d.scale; } captureHistory(); notifyListeners(); }

  void _applyClipToBones(List<Bone> targetBones, AnimationClip clip, double time) {
    final local = clip.loop && clip.duration > 0 ? time % clip.duration : time.clamp(0, clip.duration).toDouble();
    for (final b in targetBones) {
      final track = clip.tracks[b.id];
      if (track == null || track.keys.isEmpty) continue;
      final keys = track.keys;
      if (keys.length == 1) { _apply(b, keys.first); continue; }
      PoseKeyframe a = keys.first, c = keys.last;
      for (var i = 0; i < keys.length - 1; i++) { if (local >= keys[i].time && local <= keys[i + 1].time) { a = keys[i]; c = keys[i + 1]; break; } }
      final span = (c.time - a.time).abs();
      // The incoming key controls how the movement arrives. This creates
      // readable anticipation and decisive impact without changing poses.
      final t = span < .0001 ? 0.0 : _ease(((local - a.time) / span).clamp(0, 1).toDouble(), c.easing);
      b.x = _lerp(a.x, c.x, t); b.y = _lerp(a.y, c.y, t); b.rotation = _lerpAngle(a.rotation, c.rotation, t); b.scale = _lerp(a.scale, c.scale, t);
    }
  }

  void loadAt(double time) {
    _persistSelectedActor();
    for (final actor in actors) {
      final clip = animations.firstWhere((a) => a.id == actor.animationId, orElse: () => selectedAnimation);
      _applyClipToBones(actor.bones, clip, time);
    }
    selectedActor.applyTo(this);
    final clip = selectedAnimation;
    final local = clip.loop && clip.duration > 0 ? time % clip.duration : time.clamp(0, clip.duration).toDouble();
    if (local < _lastAudioPlayhead) _playedAudioIds.clear(); // looped back to the start
    for (final cue in activeAudio) {
      if (cue.time <= local && cue.time > _lastAudioPlayhead && !_playedAudioIds.contains(cue.id)) {
        _playedAudioIds.add(cue.id);
        onAudioCue?.call(cue.name);
      }
    }
    _lastAudioPlayhead = local;
    // For looping clips the raw playback time grows unbounded while the pose
    // uses `local` (wrapped) — keep the displayed playhead wrapped too,
    // otherwise the timeline slider freezes at the end while the character
    // keeps animating.
    playhead = clip.loop ? local : time.clamp(0, clip.duration).toDouble();
    notifyListeners();
  }

  void _apply(Bone b, PoseKeyframe k) { b.x = k.x; b.y = k.y; b.rotation = k.rotation; b.scale = k.scale; }
  double _lerp(double a, double b, double t) => a + (b - a) * t;
  double _lerpAngle(double a, double b, double t) { var d = (b - a + math.pi) % (2 * math.pi) - math.pi; return a + d * t; }
  /// Dependency-free curves keep preview and export deterministic on every
  /// platform.
  double _ease(double t, KeyframeEasing easing) {
    switch (easing) {
      case KeyframeEasing.linear:
        return t;
      case KeyframeEasing.easeIn:
        return t * t * t;
      case KeyframeEasing.easeOut:
        final inverse = 1 - t;
        return 1 - inverse * inverse * inverse;
      case KeyframeEasing.impact:
        return t < .82 ? (t / .82) * .96 : .96 + ((t - .82) / .18) * .04;
      case KeyframeEasing.smooth:
        return t * t * (3 - 2 * t);
    }
  }

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
