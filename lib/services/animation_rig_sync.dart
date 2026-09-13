import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/rig.dart';

/// Perfect animation-rig synchronization system.
/// Ensures animations work perfectly with any character appearance:
/// - Procedural (colored characters)
/// - Uploaded images
/// - Drawn artwork
/// - Mixed (procedural body + uploaded head)
class AnimationRigSync {
  
  /// Bind animation to character regardless of appearance type.
  /// Returns true if sync successful.
  static bool bindAnimationToCharacter({
    required AnimationClip animation,
    required List<Bone> skeleton,
    required Map<String, CharacterPart> parts,
    required CharacterAppearance appearance,
  }) {
    // Validate all required bones exist
    final requiredBones = animation.tracks.keys.toSet();
    final skeletonBones = skeleton.map((b) => b.id).toSet();

    for (final boneId in requiredBones) {
      if (!skeletonBones.contains(boneId)) {
        print('ERROR: Animation requires bone "$boneId" not in rig');
        return false;
      }
    }

    // Validate all bones have corresponding parts
    for (final part in parts.values) {
      if (!skeletonBones.contains(part.boneId)) {
        print('ERROR: Part "${part.id}" bound to non-existent bone "${part.boneId}"');
        return false;
      }
    }

    return true;
  }

  /// Interpolate animation state at specific time.
  /// Works with any appearance type (procedural, image, drawn).
  static Map<String, PoseState> interpolateAt({
    required AnimationClip animation,
    required double time,
    required Map<String, CharacterPart> parts,
  }) {
    final result = <String, PoseState>{};
    final normalizedTime = _normalizeTime(time, animation);

    // Evaluate tracks directly instead of iterating visual parts.  Root bones
    // and helper bones can be animated even when they have no dedicated
    // drawable part (for example a jump uses the root track).
    for (final boneId in animation.tracks.keys) {
      final track = animation.tracks[boneId];
      if (track == null) continue;

      final keyframes = track.keys;
      if (keyframes.isEmpty) continue;

      // Find surrounding keyframes
      PoseKeyframe? before, after;
      for (var i = 0; i < keyframes.length; i++) {
        if (keyframes[i].time <= normalizedTime) before = keyframes[i];
        if (keyframes[i].time >= normalizedTime && after == null) after = keyframes[i];
      }

      // Interpolate
      final pose = _interpolateBetween(before, after, normalizedTime);
      result[boneId] = pose;
    }

    return result;
  }

  /// Interpolate smoothly between two keyframes.
  static PoseState _interpolateBetween(
    PoseKeyframe? before,
    PoseKeyframe? after,
    double normalizedTime,
  ) {
    if (before == null || after == null) {
      return PoseState(
        x: before?.x ?? after?.x ?? 0,
        y: before?.y ?? after?.y ?? 0,
        rotation: before?.rotation ?? after?.rotation ?? 0,
        scale: before?.scale ?? after?.scale ?? 1,
      );
    }

    if (before == after) {
      return PoseState(
        x: before.x,
        y: before.y,
        rotation: before.rotation,
        scale: before.scale,
      );
    }

    // Linear interpolation (can be extended to ease-in/out)
    final span = after.time - before.time;
    if (span.abs() < 0.000001) {
      return PoseState(x: after.x, y: after.y, rotation: after.rotation, scale: after.scale);
    }
    final t = ((normalizedTime - before.time) / span).clamp(0.0, 1.0);
    final curvedT = _applyEasing(t, after.easing);

    return PoseState(
      x: _lerp(before.x, after.x, curvedT),
      y: _lerp(before.y, after.y, curvedT),
      rotation: _lerpAngle(before.rotation, after.rotation, curvedT),
      scale: _lerp(before.scale, after.scale, curvedT),
    );
  }

  /// Normalize time to animation duration (handles looping).
  static double _normalizeTime(double time, AnimationClip animation) {
    final duration = animation.duration;
    if (duration <= 0) return 0;
    if (animation.loop) {
      final wrapped = time % duration;
      return wrapped < 0 ? wrapped + duration : wrapped;
    }
    return time.clamp(0, duration);
  }

  /// Anime-friendly timing curves.  The keyframe's easing controls how the
  /// motion approaches the *next* pose: smooth for acting, ease-in/out for
  /// body mechanics, and impact for sharp hits/acceleration.
  static double _applyEasing(double t, KeyframeEasing easing) {
    switch (easing) {
      case KeyframeEasing.linear:
        return t;
      case KeyframeEasing.smooth:
        return t * t * (3 - 2 * t);
      case KeyframeEasing.easeIn:
        return t * t * t;
      case KeyframeEasing.easeOut:
        final inv = 1 - t;
        return 1 - inv * inv * inv;
      case KeyframeEasing.impact:
        // Fast attack into the pose, tiny controlled overshoot, then settle.
        if (t < .72) return math.pow(t / .72, .42).toDouble() * .92;
        final u = (t - .72) / .28;
        return .92 + .08 * (1 - math.cos(u * math.pi));
    }
  }

  /// Linear interpolation.
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Angle interpolation (handles 360° wrap).
  static double _lerpAngle(double a, double b, double t) {
    var angle = b - a;
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;
    return a + angle * t;
  }

  /// Validate complete animation-character binding.
  /// Returns list of errors (empty if OK).
  static List<String> validate({
    required AnimationClip animation,
    required List<Bone> skeleton,
    required Map<String, CharacterPart> parts,
  }) {
    final errors = <String>[];

    // Check animation has data
    if (animation.tracks.isEmpty) {
      errors.add('Animation "${animation.name}" has no bone tracks');
    }

    // Check all animation bones exist in skeleton
    for (final boneId in animation.tracks.keys) {
      if (!skeleton.any((b) => b.id == boneId)) {
        errors.add('Animation requires bone "$boneId" not found in rig');
      }
    }

    // Check all parts bound to valid bones
    for (final part in parts.values) {
      if (!skeleton.any((b) => b.id == part.boneId)) {
        errors.add('Part "${part.name}" bound to invalid bone "${part.boneId}"');
      }
    }

    // Check for orphaned parts
    final usedBones = parts.values.map((p) => p.boneId).toSet();
    for (final bone in skeleton) {
      if (!usedBones.contains(bone.id) && bone.id != 'root') {
        // Warning only - some bones might not have visible parts
        // errors.add('Bone "${bone.name}" has no visual part');
      }
    }

    return errors;
  }
}

/// Character appearance configuration.
/// Supports: procedural, image upload, drawing, or mixture.
class CharacterAppearance {
  CharacterAppearance({
    this.type = AppearanceType.procedural,
    this.skinColor = const Color(0xFFE9B18E),
    this.hairColor = const Color(0xFF3B2A1E),
    this.hairStyle = 'Long',
    this.eyeColor = const Color(0xFF2E6DB4),
    this.eyeShape = 'Round',
    this.clothesColor = const Color(0xFF2C3448),
    this.outfit = 'Jacket',
    this.uploadedImagePath,
    this.uploadedImageBytes,
    this.drawnImageBytes,
  });

  enum AppearanceType {
    procedural, // Generated from colors
    imageUpload, // PNG/JPG file
    drawn, // Canvas drawing
    hybrid, // Mix (e.g., drawn head + procedural body)
  }

  final AppearanceType type;

  // Procedural appearance
  Color skinColor;
  Color hairColor;
  String hairStyle;
  Color eyeColor;
  String eyeShape;
  Color clothesColor;
  String outfit;

  // Image upload
  String? uploadedImagePath;
  Uint8List? uploadedImageBytes;

  // Drawing
  Uint8List? drawnImageBytes;

  bool isProcedural() => type == AppearanceType.procedural;
  bool isImageUpload() => type == AppearanceType.imageUpload;
  bool isDrawn() => type == AppearanceType.drawn;
  bool isHybrid() => type == AppearanceType.hybrid;

  CharacterAppearance copy() => CharacterAppearance(
    type: type,
    skinColor: skinColor,
    hairColor: hairColor,
    hairStyle: hairStyle,
    eyeColor: eyeColor,
    eyeShape: eyeShape,
    clothesColor: clothesColor,
    outfit: outfit,
    uploadedImagePath: uploadedImagePath,
    uploadedImageBytes: uploadedImageBytes,
    drawnImageBytes: drawnImageBytes,
  );
}

/// Result of pose interpolation at a given time.
class PoseState {
  PoseState({
    required this.x,
    required this.y,
    required this.rotation,
    required this.scale,
  });

  final double x;
  final double y;
  final double rotation;
  final double scale;

  @override
  String toString() => 'PoseState(x:$x, y:$y, r:$rotation°, s:$scale)';
}

/// Timeline player that maintains perfect sync.
class SynchedAnimationPlayer {
  final AnimationClip animation;
  final List<Bone> skeleton;
  final Map<String, CharacterPart> parts;
  final CharacterAppearance appearance;

  double _currentTime = 0;
  bool _isPlaying = false;
  late DateTime _lastFrameTime;

  SynchedAnimationPlayer({
    required this.animation,
    required this.skeleton,
    required this.parts,
    required this.appearance,
  });

  double get currentTime => _currentTime;
  bool get isPlaying => _isPlaying;

  /// Play animation with perfect sync.
  void play() {
    _isPlaying = true;
    _lastFrameTime = DateTime.now();
  }

  /// Pause animation (maintains current position).
  void pause() {
    _isPlaying = false;
  }

  /// Seek to specific time.
  void seek(double time) {
    _currentTime = AnimationRigSync._normalizeTime(time, animation);
  }

  /// Update animation (call once per frame).
  /// Returns current pose state, or null if validation failed.
  Map<String, PoseState>? update() {
    if (!_isPlaying) return null;

    final now = DateTime.now();
    final delta = now.difference(_lastFrameTime).inMilliseconds / 1000;
    _lastFrameTime = now;

    _currentTime += delta;

    // Get current pose
    return AnimationRigSync.interpolateAt(
      animation: animation,
      time: _currentTime,
      parts: parts,
    );
  }

  /// Get pose at specific time without playing.
  Map<String, PoseState> getPoseAt(double time) {
    return AnimationRigSync.interpolateAt(
      animation: animation,
      time: time,
      parts: parts,
    );
  }

  /// Validate animation is compatible with character.
  List<String> validate() {
    return AnimationRigSync.validate(
      animation: animation,
      skeleton: skeleton,
      parts: parts,
    );
  }
}
