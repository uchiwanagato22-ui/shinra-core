import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/rig.dart';

/// Loads the hand-authored animation JSON files bundled under
/// assets/animations/ into real AnimationClip objects. This data is
/// genuinely more detailed than the procedural defaults in rig.dart (e.g.
/// walk_forward.json has 9 keyframes on each leg vs 3 in the built-in
/// "Walk" preset) — it just needed two compatibility fixes to actually
/// play correctly, which is why it wasn't wired in as-is:
///
/// 1. Bone names: the JSON uses "leg_left"/"arm_right" etc.; the live rig
///    (see defaultBones() in rig.dart) uses "leg_l"/"arm_r". Without
///    remapping, track lookups would silently find nothing and the clip
///    would play completely frozen.
/// 2. Rotation units: the JSON stores rotation in degrees (e.g. -20, 30);
///    every Bone.rotation in this app is radians (rendering multiplies it
///    straight into cos/sin). Without conversion, a "20" would be read as
///    ~1146 degrees — the limb would spin wildly instead of swinging.
class AnimationImport {
  static const _boneAliases = {
    'leg_left': 'leg_l', 'leg_right': 'leg_r',
    'arm_left': 'arm_l', 'arm_right': 'arm_r',
    'hand_left': 'hand_l', 'hand_right': 'hand_r',
    'foot_left': 'foot_l', 'foot_right': 'foot_r',
  };

  static AnimCategory _category(String cat) {
    switch (cat.toLowerCase()) {
      case 'movement': return AnimCategory.movement;
      case 'combat': return AnimCategory.combat;
      case 'face': case 'facial': return AnimCategory.face;
      case 'fx': case 'effect': return AnimCategory.fx;
      default: return AnimCategory.movement;
    }
  }

  /// Returns the imported clips (id prefixed "lib_" so they can never
  /// collide with the built-in "mv_"/"cb_" presets) plus how many entries
  /// in index.json failed to load, so the caller can report both honestly.
  static Future<({List<AnimationClip> clips, int failed})> loadAll() async {
    final clips = <AnimationClip>[];
    var failed = 0;
    Map<String, dynamic> index;
    try {
      index = jsonDecode(await rootBundle.loadString('assets/animations/index.json'));
    } catch (_) {
      return (clips: clips, failed: 0); // index itself missing/unreadable — nothing to import, not an error state
    }
    for (final entry in (index['animations'] as List? ?? const [])) {
      try {
        final file = entry['file'] as String;
        final raw = jsonDecode(await rootBundle.loadString('assets/animations/$file')) as Map<String, dynamic>;
        final clip = AnimationClip(
          id: 'lib_${raw['id']}',
          name: (raw['name'] as String?) ?? raw['id'],
          category: _category((raw['category'] as String?) ?? 'movement'),
          duration: (raw['duration'] as num?)?.toDouble() ?? 1.0,
          loop: (raw['loop'] as bool?) ?? true,
        );
        final tracks = Map<String, dynamic>.from(raw['tracks'] as Map? ?? const {});
        for (final t in tracks.entries) {
          final boneId = _boneAliases[t.key] ?? t.key;
          final track = clip.track(boneId);
          for (final k in (t.value as List)) {
            final m = Map<String, dynamic>.from(k);
            track.keys.add(PoseKeyframe(
              time: (m['time'] as num).toDouble(),
              x: (m['x'] as num).toDouble(),
              y: (m['y'] as num).toDouble(),
              rotation: (m['rotation'] as num).toDouble() * 3.14159265 / 180, // degrees -> radians
              scale: (m['scale'] as num?)?.toDouble() ?? 1.0,
            ));
          }
          track.keys.sort((a, b) => a.time.compareTo(b.time));
        }
        clips.add(clip);
      } catch (_) {
        failed++; // one bad/missing file shouldn't block the rest
      }
    }
    return (clips: clips, failed: failed);
  }
}
