import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/rig.dart';

/// Animation files were authored with descriptive left/right names while the
/// live rig uses compact IDs. Keep both formats compatible so every supplied
/// animation actually drives the character.
String _canonicalBoneId(String id) {
  const aliases = <String, String>{
    'arm_left': 'arm_l',
    'arm_right': 'arm_r',
    'hand_left': 'hand_l',
    'hand_right': 'hand_r',
    'leg_left': 'leg_l',
    'leg_right': 'leg_r',
    'foot_left': 'foot_l',
    'foot_right': 'foot_r',
  };
  return aliases[id] ?? id;
}

/// Load animations from JSON asset files
class AnimationLoader {
  /// Load animation by ID from assets
  static Future<AnimationClip> loadAnimation(String id) async {
    try {
      final json = await rootBundle.loadString('assets/animations/$id.json');
      final data = jsonDecode(json) as Map<String, dynamic>;

      final clip = AnimationClip(
        id: data['id'] as String,
        name: data['name'] as String,
        category: _parseCategory(data['category'] as String),
        duration: (data['duration'] as num).toDouble(),
        loop: data['loop'] as bool? ?? true,
      );

      // Load tracks
      final tracks = data['tracks'] as Map<String, dynamic>?;
      if (tracks != null) {
        tracks.forEach((boneName, keyframesData) {
          final track = clip.track(_canonicalBoneId(boneName));
          if (keyframesData is List) {
            for (var kf in keyframesData) {
              track.upsert(PoseKeyframe(
                time: (kf['time'] as num).toDouble(),
                x: (kf['x'] as num).toDouble(),
                y: (kf['y'] as num).toDouble(),
                rotation: (kf['rotation'] as num).toDouble(),
                scale: (kf['scale'] as num).toDouble(),
              ));
            }
          }
        });
      }

      return clip;
    } catch (e) {
      print('Error loading animation $id: $e');
      throw Exception('Failed to load animation: $id');
    }
  }

  /// Load all animations from index.json
  static Future<List<AnimationClip>> loadAllAnimations() async {
    try {
      final json = await rootBundle.loadString('assets/animations/index.json');
      final data = jsonDecode(json) as Map<String, dynamic>;
      final animList = data['animations'] as List;

      final clips = <AnimationClip>[];
      for (var anim in animList) {
        final id = anim['id'] as String;
        try {
          final clip = await loadAnimation(id);
          clips.add(clip);
        } catch (e) {
          print('Warning: Could not load animation $id');
          // Continue with other animations
        }
      }

      return clips;
    } catch (e) {
      print('Error loading animations index: $e');
      return [];
    }
  }

  /// Load animations by category
  static Future<List<AnimationClip>> loadByCategory(AnimCategory category) async {
    final all = await loadAllAnimations();
    return all.where((c) => c.category == category).toList();
  }

  /// Load segmentation data for a test image
  static Future<Map<String, dynamic>> loadSegmentationData(String imageName) async {
    try {
      final json = await rootBundle.loadString('assets/test_images/${imageName}_segments.json');
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading segmentation data: $e');
      return {};
    }
  }

  /// Parse category string to enum
  static AnimCategory _parseCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'movement':
        return AnimCategory.movement;
      case 'combat':
        return AnimCategory.combat;
      case 'face':
      case 'facial':
        return AnimCategory.face;
      case 'fx':
      case 'effect':
        return AnimCategory.fx;
      default:
        return AnimCategory.movement;
    }
  }

  /// Create a default animation if loading fails
  static AnimationClip createDefaultAnimation(String id, String name) {
    return AnimationClip(
      id: id,
      name: name,
      category: AnimCategory.movement,
      duration: 2.0,
      loop: true,
    );
  }
}

/// Manager for animation library
class AnimationManager {
  static final AnimationManager _instance = AnimationManager._internal();

  factory AnimationManager() {
    return _instance;
  }

  AnimationManager._internal();

  final Map<String, AnimationClip> _cache = {};
  List<AnimationClip>? _allAnimations;
  bool _isLoading = false;

  /// Initialize and load all animations
  Future<void> initialize() async {
    if (_isLoading) return;
    if (_allAnimations != null) return;

    _isLoading = true;
    _allAnimations = await AnimationLoader.loadAllAnimations();
    _isLoading = false;

    // Cache all
    for (var clip in _allAnimations!) {
      _cache[clip.id] = clip;
    }
  }

  /// Get animation by ID
  Future<AnimationClip> getAnimation(String id) async {
    if (_cache.containsKey(id)) {
      return _cache[id]!;
    }

    final clip = await AnimationLoader.loadAnimation(id);
    _cache[id] = clip;
    return clip;
  }

  /// Get all animations
  Future<List<AnimationClip>> getAllAnimations() async {
    await initialize();
    return _allAnimations ?? [];
  }

  /// Get animations by category
  Future<List<AnimationClip>> getByCategory(AnimCategory category) async {
    final all = await getAllAnimations();
    return all.where((c) => c.category == category).toList();
  }

  /// Search animations by name
  Future<List<AnimationClip>> search(String query) async {
    final all = await getAllAnimations();
    final lower = query.toLowerCase();
    return all
        .where((c) => c.name.toLowerCase().contains(lower) || c.id.toLowerCase().contains(lower))
        .toList();
  }

  /// Get random animation from category
  Future<AnimationClip> getRandomFromCategory(AnimCategory category) async {
    final animations = await getByCategory(category);
    if (animations.isEmpty) {
      return AnimationLoader.createDefaultAnimation('default', 'Default Animation');
    }
    animations.shuffle();
    return animations.first;
  }

  /// Clear cache (useful for memory)
  void clearCache() {
    _cache.clear();
  }
}

/// Extension to AnimationClip for utility methods
extension AnimationClipExtensions on AnimationClip {
  /// Get total number of keyframes across all tracks
  int get totalKeyframes {
    int total = 0;
    tracks.forEach((_, track) {
      total += track.keys.length;
    });
    return total;
  }

  /// Get all bones that have animation data
  List<String> get animatedBones => tracks.keys.toList();

  /// Check if animation has data for a specific bone
  bool hasBone(String boneId) => tracks.containsKey(boneId);

  /// Duplicate this animation with new ID
  AnimationClip duplicate(String newId, String newName) {
    final dup = AnimationClip(
      id: newId,
      name: newName,
      category: category,
      duration: duration,
      loop: loop,
    );

    // Deep copy tracks
    tracks.forEach((boneName, track) {
      final newTrack = dup.track(boneName);
      for (var key in track.keys) {
        newTrack.upsert(PoseKeyframe(
          time: key.time,
          x: key.x,
          y: key.y,
          rotation: key.rotation,
          scale: key.scale,
        ));
      }
    });

    return dup;
  }

  /// Merge another animation at specified time
  void mergeAt(double time, AnimationClip other) {
    final timeDelta = time;
    other.tracks.forEach((boneName, otherTrack) {
      final track = this.track(boneName);
      for (var key in otherTrack.keys) {
        track.upsert(PoseKeyframe(
          time: key.time + timeDelta,
          x: key.x,
          y: key.y,
          rotation: key.rotation,
          scale: key.scale,
        ));
      }
    });
  }
}
