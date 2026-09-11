import 'package:audioplayers/audioplayers.dart';

/// Plays a real sound file when a timeline audio cue fires, instead of just
/// flashing a name on screen. Looks for `assets/audio/<slugified name>.mp3`
/// bundled by the user (declared in pubspec.yaml under flutter/assets).
///
/// Honest limitation: this repo ships with NO actual sound files — I have no
/// network access to fetch real anime SFX (impact hits, whooshes, aura
/// hums...) from here. Drop your own .mp3 files in assets/audio/ named
/// exactly like the cues (e.g. "Impact SFX" -> impact_sfx.mp3) and this will
/// play them. Until then it fails silently (logged, not crashed) so a
/// missing file never breaks playback.
class AudioCueService {
  final AudioPlayer _player = AudioPlayer();

  String _slug(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

  Future<void> play(String cueName) async {
    final path = 'audio/${_slug(cueName)}.mp3';
    try {
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {
      // No matching file bundled yet — silent no-op rather than a crash.
      // ignore: avoid_print
      print('[Shinra audio] no sound file for "$cueName" (looked for assets/$path)');
    }
  }

  void dispose() => _player.dispose();
}
