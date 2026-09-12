// Copy bundled Kenney parts + lightning VFX into asset folders; stub audio map.
// Run: dart run tools/fill_assets.dart
import 'dart:io';

void copyDirFiltered(Directory src, Directory dest, bool Function(File) keep) {
  if (!src.existsSync()) return;
  dest.createSync(recursive: true);
  for (final ent in src.listSync(recursive: true)) {
    if (ent is! File || !keep(ent)) continue;
    final rel = ent.path.substring(src.path.length + 1);
    final out = File('${dest.path}${Platform.pathSeparator}$rel');
    out.parent.createSync(recursive: true);
    ent.copySync(out.path);
  }
}

void main() {
  final root = Directory.current;
  if (!File('${root.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
    stderr.writeln('Run from shinra_core root');
    exit(1);
  }

  // Character parts from Kenney (already on disk)
  final kenney = Directory('assets/animation_assets/kenney_toon-characters');
  final charDir = Directory('assets/characters/parts');
  charDir.createSync(recursive: true);
  var n = 0;
  if (kenney.existsSync()) {
    for (final f in kenney.listSync(recursive: true).whereType<File>()) {
      if (!f.path.contains('${Platform.pathSeparator}Parts${Platform.pathSeparator}')) continue;
      if (!f.path.endsWith('.png')) continue;
      final parts = f.uri.pathSegments;
      final pack = parts[parts.length - 4].replaceAll(' ', '_').toLowerCase();
      final out = File('${charDir.path}${Platform.pathSeparator}${pack}_${f.uri.pathSegments.last}');
      f.copySync(out.path);
      n++;
    }
  }
  stdout.writeln('characters/parts: $n PNGs');

  // Pose sprites for animation reference
  final poseDir = Directory('assets/characters/poses');
  poseDir.createSync(recursive: true);
  var p = 0;
  if (kenney.existsSync()) {
    for (final f in kenney.listSync(recursive: true).whereType<File>()) {
      if (!f.path.contains('${Platform.pathSeparator}Poses${Platform.pathSeparator}')) continue;
      if (!f.path.endsWith('.png') || f.path.contains('Poses HD')) continue;
      final parts = f.uri.pathSegments;
      final pack = parts[parts.length - 4].replaceAll(' ', '_').toLowerCase();
      final out = File('${poseDir.path}${Platform.pathSeparator}${pack}_${f.uri.pathSegments.last}');
      f.copySync(out.path);
      p++;
    }
  }
  stdout.writeln('characters/poses: $p PNGs');

  // Lightning VFX frames
  final fxSrc = Directory('assets/animation_assets/Pixel Art Skill Animations - Lightning');
  final fxDest = Directory('assets/effects/sprites/lightning');
  if (fxSrc.existsSync()) {
    fxDest.createSync(recursive: true);
    for (final f in fxSrc.listSync(recursive: true).whereType<File>()) {
      if (!f.path.contains('Frames') || !f.path.endsWith('.png')) continue;
      final out = File('${fxDest.path}${Platform.pathSeparator}${f.uri.pathSegments.last}');
      f.copySync(out.path);
    }
    stdout.writeln('effects/sprites/lightning: copied frame PNGs');
  }

  stdout.writeln('fill_assets done. Run populate audio separately if Kenney zips downloaded.');
}
