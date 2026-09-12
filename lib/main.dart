import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'models/rig.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'services/ai_director.dart';
import 'services/image_edit_service.dart' as ie;
import 'package:image/image.dart' as img;
import 'services/audio_cue_service.dart';
import 'services/gif_export.dart';
import 'services/project_store.dart';
import 'services/video_export.dart';
import 'widgets/draw_canvas.dart';
import 'widgets/viewport.dart';

/// SHINRA CORE design tokens. A studio console for choreographing anime-style
/// motion, not a dress-up toy — so the palette stays disciplined dark neutrals
/// with exactly one bold accent (crimson, shared with the wider Shinra family)
/// and a sparse gold for secondary emphasis, rather than a generated Material
/// seed-color scheme.
class Ink {
  static const void_ = Color(0xFF0A0C12); // canvas / scaffold
  static const panel = Color(0xFF12151F); // side panels, nav rail
  static const surface = Color(0xFF181C29); // cards
  static const surfaceRaised = Color(0xFF20263A); // hovered/active surface
  static const line = Color(0x1FFFFFFF); // hairline borders
  static const crimson = Color(0xFFE23349); // single bold accent — primary actions, active state
  static const crimsonDim = Color(0xFF7A1B29);
  static const gold = Color(0xFFD4A73B); // sparse secondary — markers, highlights
  static const ink = Color(0xFFEDEAE3); // primary text
  static const inkMuted = Color(0xFF8A8FA3); // secondary text
}

void main() => runApp(ChangeNotifierProvider(create: (_) => ProjectState(), child: const ShinraApp()));

class ShinraApp extends StatelessWidget {
  const ShinraApp({super.key});
  @override
  Widget build(BuildContext context) {
    final display = GoogleFonts.rajdhaniTextTheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SHINRA CORE',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Ink.void_,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: Ink.surface,
          primary: Ink.crimson,
          secondary: Ink.gold,
          onSurface: Ink.ink,
          error: Color(0xFFE85D5D),
        ),
        fontFamily: GoogleFonts.workSans().fontFamily,
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Ink.ink, displayColor: Ink.ink).copyWith(
              headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: .2, color: Ink.ink),
              titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: Ink.ink),
              titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Ink.ink),
            ),
        cardColor: Ink.surface,
        dividerColor: Ink.line,
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Ink.panel,
          indicatorColor: Ink.crimson.withOpacity(.18),
          selectedIconTheme: const IconThemeData(color: Ink.crimson),
          unselectedIconTheme: IconThemeData(color: Ink.inkMuted),
          selectedLabelTextStyle: const TextStyle(color: Ink.crimson, fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelTextStyle: TextStyle(color: Ink.inkMuted, fontSize: 11),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: Ink.crimson, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: Ink.ink, side: const BorderSide(color: Ink.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        chipTheme: ChipThemeData(
          backgroundColor: Ink.surface,
          selectedColor: Ink.crimson.withOpacity(.22),
          labelStyle: const TextStyle(color: Ink.ink, fontSize: 12),
          side: const BorderSide(color: Ink.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        sliderTheme: const SliderThemeData(activeTrackColor: Ink.crimson, thumbColor: Ink.crimson, inactiveTrackColor: Ink.line),
        switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Ink.crimson : Ink.inkMuted)),
      ),
      home: const Shell(),
    );
  }
}

enum Page { home, studio, scene, character, library, rig, animate, face, fx, camera, audio, ai, export }

class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  Page page = Page.home; Timer? timer;
  final audioCues = AudioCueService();
  @override void dispose() { timer?.cancel(); audioCues.dispose(); super.dispose(); }
  void togglePlay(ProjectState p) { if (p.playing) { timer?.cancel(); p.playing = false; p.status = 'Paused'; p.notifyListeners(); return; } p.playing = true; p.status = 'Playing'; p.notifyListeners(); timer?.cancel(); timer = Timer.periodic(const Duration(milliseconds: 33), (_) { if (!mounted) return; final next = p.playhead + 1 / 30; if (next >= p.selectedAnimation.duration && !p.selectedAnimation.loop) { if (p.advanceQueue()) return; p.playing = false; timer?.cancel(); p.setPlayhead(p.selectedAnimation.duration); } else { p.loadAt(next); } }); }
  void playQueue(ProjectState p, List<String> clipIds) { p.startQueue(clipIds); togglePlay(p); }
  @override Widget build(BuildContext context) => Consumer<ProjectState>(builder: (ctx, p, __) {
        p.onAudioCue ??= (name) {
          audioCues.play(name);
          ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
            width: 260,
            content: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.volume_up, size: 18), const SizedBox(width: 8), Text(name)]),
          ));
        };
        return Scaffold(body: Row(children: [NavigationRail(selectedIndex: page.index, onDestinationSelected: (i) => setState(() => page = Page.values[i]), labelType: NavigationRailLabelType.all, destinations: const [NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Home')), NavigationRailDestination(icon: Icon(Icons.movie_outlined), label: Text('Studio')), NavigationRailDestination(icon: Icon(Icons.groups_outlined), label: Text('Scene')), NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Character')), NavigationRailDestination(icon: Icon(Icons.video_library_outlined), label: Text('Library')), NavigationRailDestination(icon: Icon(Icons.account_tree_outlined), label: Text('Rig')), NavigationRailDestination(icon: Icon(Icons.timeline_outlined), label: Text('Animate')), NavigationRailDestination(icon: Icon(Icons.face_outlined), label: Text('Face')), NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), label: Text('FX')), NavigationRailDestination(icon: Icon(Icons.videocam_outlined), label: Text('Camera')), NavigationRailDestination(icon: Icon(Icons.audiotrack_outlined), label: Text('Audio')), NavigationRailDestination(icon: Icon(Icons.smart_toy_outlined), label: Text('AI Director')), NavigationRailDestination(icon: Icon(Icons.file_upload_outlined), label: Text('Export'))]), Expanded(child: _page(p))]));
      });
  Widget _page(ProjectState p) { switch (page) { case Page.home: return HomePage(onOpen: (x) => setState(() => page = x)); case Page.studio: return StudioPage(p: p, onPlay: () => togglePlay(p)); case Page.scene: return ScenePage(p: p, onPlay: () => togglePlay(p)); case Page.character: return CharacterPage(p: p); case Page.library: return LibraryPage(p: p, onUse: () => setState(() => page = Page.animate)); case Page.rig: return RigPage(p: p); case Page.animate: return AnimatePage(p: p, onPlay: () => togglePlay(p)); case Page.face: return FacePage(p: p); case Page.fx: return FxPage(p: p); case Page.camera: return CameraPage(p: p); case Page.audio: return AudioPage(p: p); case Page.ai: return AiPage(p: p, onPlaySequence: (ids) => playQueue(p, ids)); case Page.export: return ExportPage(p: p); } }
}

class Top extends StatelessWidget {
  const Top({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 4, height: subtitle != null ? 40 : 26, margin: const EdgeInsets.only(right: 12, top: 3), decoration: BoxDecoration(color: Ink.crimson, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(c).textTheme.headlineSmall),
              if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: const TextStyle(color: Ink.inkMuted, fontSize: 13))),
            ]),
          ),
        ]),
      );
}

class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext c) => Container(
        padding: padding,
        decoration: BoxDecoration(color: Ink.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Ink.line)),
        child: child,
      );
}

class HomePage extends StatelessWidget { const HomePage({super.key, required this.onOpen}); final void Function(Page) onOpen; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'SHINRA CORE', subtitle: '2D anime animation workspace'), Expanded(child: GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(24), crossAxisSpacing: 16, mainAxisSpacing: 16, children: [for (final x in [(Page.studio, Icons.movie, 'Studio', 'Compose a scene'), (Page.scene, Icons.groups, 'Scene', '3-6 characters, city, combat'), (Page.character, Icons.person, 'Character', 'Build parts and import art'), (Page.rig, Icons.account_tree, 'Rig Studio', 'Bones and bindings'), (Page.animate, Icons.timeline, 'Animation Lab', 'Keyframes and playback'), (Page.face, Icons.face, 'Expressions', 'Anime facial acting'), (Page.fx, Icons.auto_awesome, 'FX', 'Impacts and particles'), (Page.camera, Icons.videocam, 'Camera', 'Shots and framing'), (Page.ai, Icons.smart_toy, 'AI Director', 'Turn direction into timeline')]) CardBox(child: InkWell(onTap: () => onOpen(x.$1), borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(x.$2, size: 36, color: const Color(0xFFE23349)), const Spacer(), Text(x.$3, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(x.$4, style: TextStyle(color: Colors.white.withOpacity(.55))) ]))))]) )]); }

class ScenePage extends StatefulWidget {
  const ScenePage({super.key, required this.p, required this.onPlay});
  final ProjectState p;
  final VoidCallback onPlay;
  @override
  State<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<ScenePage> {
  final picker = ImagePicker();

  @override
  Widget build(BuildContext c) {
    final p = widget.p;
    return Column(children: [
      const Top(title: 'Scene Director', subtitle: 'Up to 6 characters — city, rain, combat presets'),
      Expanded(child: Row(children: [
        Expanded(flex: 7, child: CardBox(child: Column(children: [
          Expanded(child: ShinraViewport(project: p)),
          const SizedBox(height: 8),
          _Transport(p: p, onPlay: widget.onPlay),
        ]))),
        SizedBox(width: 320, child: CardBox(child: ListView(children: [
          const Text('SCENE PRESETS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final preset in [('walk_dance_rain', 'Marche + danse pluie'), ('city_stroll', '2 persos ville'), ('triple_combat', '3 combat'), ('six_battle', '6 combat')])
              ActionChip(label: Text(preset.$2), onPressed: () => p.applyScenePreset(preset.$1)),
          ]),
          const Divider(height: 24),
          const Text('ENVIRONMENT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final s in backgroundStyles) ChoiceChip(label: Text(s), selected: p.background == s, onSelected: (_) => p.setBackground(s))]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final w in weatherStyles) ChoiceChip(label: Text(w), selected: p.weather == w, onSelected: (_) => p.setWeather(w))]),
          OutlinedButton.icon(
            onPressed: () async {
              final x = await picker.pickImage(source: ImageSource.gallery);
              if (x != null) { setState(() { p.sceneBackgroundImagePath = x.path; p.status = 'Scene background imported'; p.notifyListeners(); }); }
            },
            icon: const Icon(Icons.landscape),
            label: const Text('Import scene background'),
          ),
          const Divider(height: 24),
          Row(children: [
            const Text('CHARACTERS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const Spacer(),
            IconButton(onPressed: p.actors.length >= maxSceneActors ? null : () => p.addActor(), icon: const Icon(Icons.person_add)),
          ]),
          for (final actor in p.actors)
            ListTile(
              selected: actor.id == p.selectedActorId,
              title: Text(actor.name),
              subtitle: Text('Anim: ${p.animations.where((a) => a.id == actor.animationId).map((a) => a.name).firstOrNull ?? actor.animationId}'),
              trailing: p.actors.length > 1 ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => p.removeActor(actor.id)) : null,
              onTap: () => p.selectActor(actor.id),
            ),
          if (p.selectedActorId.isNotEmpty) ...[
            _Num('Position X', p.selectedActor.offsetX, (v) => p.setActorOffset(p.selectedActorId, x: v)),
            _Num('Position Y', p.selectedActor.offsetY, (v) => p.setActorOffset(p.selectedActorId, y: v)),
            DropdownButtonFormField<String>(
              value: p.selectedActor.animationId,
              decoration: const InputDecoration(labelText: 'Animation for this character'),
              items: [for (final a in p.animations) DropdownMenuItem(value: a.id, child: Text(a.name))],
              onChanged: (v) { if (v != null) p.setActorAnimation(p.selectedActorId, v); },
            ),
          ],
          const SizedBox(height: 8),
          Text(p.status, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.5))),
        ]))),
      ])),
    ]);
  }
}

class StudioPage extends StatelessWidget { const StudioPage({super.key, required this.p, required this.onPlay}); final ProjectState p; final VoidCallback onPlay; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'Studio', subtitle: 'Scene viewport + timeline'), Expanded(child: Row(children: [Expanded(flex: 7, child: CardBox(child: Column(children: [Expanded(child: ShinraViewport(project: p)), const SizedBox(height: 10), _Transport(p: p, onPlay: onPlay)]))), const SizedBox(width: 14), SizedBox(width: 270, child: _Inspector(p: p))])),]); }
class _KeyframeTimeline extends StatelessWidget {
  const _KeyframeTimeline({required this.p, this.boneId});
  final ProjectState p;
  /// null = show every bone's keyframes on this timeline; a bone id = only
  /// that bone's — useful when focused on posing one limb.
  final String? boneId;

  @override
  Widget build(BuildContext c) {
    final duration = p.selectedAnimation.duration <= 0 ? 1.0 : p.selectedAnimation.duration;
    final times = <double>{};
    if (boneId != null) {
      for (final k in p.selectedAnimation.tracks[boneId]?.keys ?? const <PoseKeyframe>[]) times.add(k.time);
    } else {
      for (final track in p.selectedAnimation.tracks.values) {
        for (final k in track.keys) times.add(k.time);
      }
    }
    return LayoutBuilder(builder: (_, constraints) {
      const inset = 12.0; // rough match for the Slider's thumb radius so markers line up with the track, not exact but close
      final trackWidth = constraints.maxWidth - inset * 2;
      return SizedBox(
        height: 30,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(top: 4, left: 0, right: 0, child: Slider(value: p.playhead, min: 0, max: duration, onChanged: p.setPlayhead)),
          for (final t in times)
            Positioned(
              left: inset + (t / duration) * trackWidth - 5,
              top: 0,
              child: GestureDetector(
                onTap: () => p.setPlayhead(t),
                child: Transform.rotate(
                  angle: .785398,
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(color: (t - p.playhead).abs() < .02 ? Ink.crimson : Ink.gold, border: Border.all(color: Ink.void_, width: 1.2))),
                ),
              ),
            ),
        ]),
      );
    });
  }
}

class _Transport extends StatelessWidget { const _Transport({required this.p, required this.onPlay}); final ProjectState p; final VoidCallback onPlay; @override Widget build(BuildContext c) => Column(children: [Row(children: [IconButton(onPressed: p.undo, icon: const Icon(Icons.undo)), IconButton(onPressed: p.redo, icon: const Icon(Icons.redo)), IconButton(onPressed: () => p.setPlayhead(0), icon: const Icon(Icons.stop)), IconButton(onPressed: onPlay, icon: Icon(p.playing ? Icons.pause : Icons.play_arrow)), const SizedBox(width: 8), Text('${p.playhead.toStringAsFixed(2)} / ${p.selectedAnimation.duration.toStringAsFixed(2)}s'), const Spacer(), DropdownButton<String>(value: p.selectedAnimationId, items: [for (final a in p.animations) DropdownMenuItem(value: a.id, child: Text(a.name))], onChanged: (v) { if (v != null) { p.selectedAnimationId = v; p.setPlayhead(0); } })]), _KeyframeTimeline(p: p)]); }
class _Inspector extends StatelessWidget { const _Inspector({required this.p}); final ProjectState p; @override Widget build(BuildContext c) => CardBox(child: ListView(children: [const Text('INSPECTOR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(height: 18), Text('Bone: ${p.selectedBone.name}'), const SizedBox(height: 10), _Num('X', p.selectedBone.x, (v) => p.setBone(x: v)), _Num('Y', p.selectedBone.y, (v) => p.setBone(y: v)), _Num('Rotation', p.selectedBone.rotation, (v) => p.setBone(rotation: v)), _Num('Scale', p.selectedBone.scale, (v) => p.setBone(scale: v)), const SizedBox(height: 14), FilledButton.icon(onPressed: p.captureKeyframe, icon: const Icon(Icons.key), label: const Text('Capture Keyframe')), OutlinedButton(onPressed: p.captureAll, child: const Text('Capture Full Pose')), const SizedBox(height: 10), Text(p.status, style: TextStyle(color: Colors.white.withOpacity(.5)))])); }
class _Num extends StatelessWidget { const _Num(this.label, this.value, this.onChanged); final String label; final double value; final ValueChanged<double> onChanged; @override Widget build(BuildContext c) => Row(children: [SizedBox(width: 72, child: Text(label)), Expanded(child: Slider(value: value.clamp(-200, 200), min: -200, max: 200, onChanged: onChanged))]); }

class CharacterPage extends StatefulWidget { const CharacterPage({super.key, required this.p}); final ProjectState p; @override State<CharacterPage> createState() => _CharacterPageState(); }
class _CharacterPageState extends State<CharacterPage> {
  final picker = ImagePicker();
  bool autoMapping = false;
  bool imageEditing = false;

  Future<void> _applyImageEdit(ProjectState p, img.Image Function(img.Image) transform) async {
    setState(() => imageEditing = true);
    try {
      final source = await ie.ImageUploadService.loadImage(p.importedImagePath);
      if (source == null) { p.status = 'Could not read image'; p.notifyListeners(); return; }
      final edited = transform(source);
      final path = await ie.ImageUploadService.saveImage(edited, 'edited');
      p.importedImagePath = path;
      p.status = 'Image edited';
      p.notifyListeners();
    } catch (err) {
      p.status = 'Image edit failed: $err';
      p.notifyListeners();
    } finally {
      if (mounted) setState(() => imageEditing = false);
    }
  }

  static const starterCharacters = ['female_adventurer', 'male_adventurer', 'female_person', 'male_person', 'zombie', 'robot'];

  Future<void> _pickStarterCharacter(BuildContext c, ProjectState p) async {
    final chosen = await showDialog<String>(
      context: c,
      builder: (dc) => AlertDialog(
        title: const Text('Starter characters (Kenney, CC0)'),
        content: SizedBox(
          width: 320,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              for (final name in starterCharacters)
                GestureDetector(
                  onTap: () => Navigator.pop(dc, name),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/starter_characters/$name.png', fit: BoxFit.cover)),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Cancel'))],
      ),
    );
    if (chosen == null) return;
    final bytes = await rootBundle.load('assets/starter_characters/$chosen.png');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/shinra_starter_${chosen}_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    p.importedImagePath = file.path;
    p.status = 'Starter character "$chosen" loaded (Kenney, CC0)';
    p.notifyListeners();
  }

  Widget _swatchRow(String label, List<Color> palette, Color current, void Function(Color) onPick) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final color in palette)
              GestureDetector(
                onTap: () => onPick(color),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: color == current ? Colors.white : Colors.white24, width: color == current ? 3 : 1)),
                ),
              ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext c) {
    final p = widget.p;
    return Column(children: [
      const Top(title: 'Character Creator', subtitle: 'Draw your own via presets, or upload art and animate it'),
      Expanded(
        child: Row(children: [
          Expanded(child: CardBox(child: ShinraViewport(project: p))),
          SizedBox(
            width: 320,
            child: CardBox(
              child: ListView(children: [
                const Text('ARTWORK', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final path = await Navigator.push<String>(c, MaterialPageRoute(builder: (_) => const DrawCanvasPage()));
                        if (path != null) { p.importedImagePath = path; p.useImageAsBody = true; p.status = 'Drawing ready'; p.notifyListeners(); }
                      },
                      icon: const Icon(Icons.brush),
                      label: const Text('Draw'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
                        if (x != null) { p.importedImagePath = x.path; p.status = 'Imported ${x.name}'; p.notifyListeners(); }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Upload'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickStarterCharacter(c, p),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Or pick a starter character (Kenney, CC0)'),
                ),
                if (p.importedImagePath.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(p.importedImagePath), height: 130, fit: BoxFit.cover)),
                  const SizedBox(height: 8),
                  Text(p.importedImagePath.split(Platform.pathSeparator).last, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Animate my uploaded image', style: TextStyle(fontSize: 13)),
                    value: p.useImageAsBody,
                    onChanged: p.toggleUseImageAsBody,
                  ),
                ],
                const Divider(height: 28),
                const Text('DRAWN CHARACTER (no image needed)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 10),
                _swatchRow('Skin', skinPalette, p.skinColor, (v) => p.setAppearance(skin: v)),
                _swatchRow('Hair color', hairPalette, p.hairColor, (v) => p.setAppearance(hair: v)),
                _swatchRow('Eyes', eyePalette, p.eyeColor, (v) => p.setAppearance(eyes: v)),
                const Text('Eye shape', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final s in eyeShapes) ChoiceChip(label: Text(s), selected: p.eyeShape == s, onSelected: (_) => p.setAppearance(eyeShape: s))]),
                const SizedBox(height: 10),
                _swatchRow('Clothes', clothesPalette, p.clothesColor, (v) => p.setAppearance(clothes: v)),
                const SizedBox(height: 4),
                const Text('Hair style', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final s in hairStyles) ChoiceChip(label: Text(s), selected: p.hairStyle == s, onSelected: (_) => p.setAppearance(style: s))]),
                const SizedBox(height: 12),
                const Text('Outfit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final s in outfitStyles) ChoiceChip(label: Text(s), selected: p.outfitStyle == s, onSelected: (_) => p.setOutfit(s))]),
                const SizedBox(height: 12),
                const Text('Accessories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilterChip(label: const Text('Glasses'), selected: p.accGlasses, onSelected: (v) => p.setAccessory('glasses', v)),
                  FilterChip(label: const Text('Headband'), selected: p.accHeadband, onSelected: (v) => p.setAccessory('headband', v)),
                  FilterChip(label: const Text('Scarf'), selected: p.accScarf, onSelected: (v) => p.setAccessory('scarf', v)),
                  FilterChip(label: const Text('Hat'), selected: p.accHat, onSelected: (v) => p.setAccessory('hat', v)),
                  FilterChip(label: const Text('Gloves'), selected: p.accGloves, onSelected: (v) => p.setAccessory('gloves', v)),
                  FilterChip(label: const Text('Belt'), selected: p.accBelt, onSelected: (v) => p.setAccessory('belt', v)),
                ]),
                const SizedBox(height: 12),
                const Text('Scene / background', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final s in backgroundStyles) ChoiceChip(label: Text(s), selected: p.background == s, onSelected: (_) { p.setBackground(s); p.notifyListeners(); })]),
                const Divider(height: 28),
                const Text('PARTS', style: TextStyle(fontWeight: FontWeight.w800)),
                for (final part in p.parts) ListTile(dense: true, leading: Icon(part.visible ? Icons.visibility : Icons.visibility_off), title: Text(part.name), subtitle: Text(part.boneId), onTap: () => p.togglePart(part.id)),
                if (p.importedImagePath.isNotEmpty) ...[
                  const Divider(height: 28),
                  const Text('IMAGE TOOLS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Applied directly to the imported/drawn artwork.', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.5))),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(onPressed: imageEditing ? null : () => _applyImageEdit(p, (i) => ie.ImageUploadService.removeBackground(i)), icon: const Icon(Icons.auto_fix_normal), label: const Text('Remove background')),
                    OutlinedButton.icon(onPressed: imageEditing ? null : () => _applyImageEdit(p, (i) => ie.ImageUploadService.flipHorizontal(i)), icon: const Icon(Icons.flip), label: const Text('Flip')),
                    OutlinedButton.icon(onPressed: imageEditing ? null : () => _applyImageEdit(p, (i) => ie.ImageUploadService.tint(i, p.clothesColor)), icon: const Icon(Icons.format_color_fill), label: const Text('Tint (clothes color)')),
                    OutlinedButton.icon(onPressed: imageEditing ? null : () => _applyImageEdit(p, (i) => ie.ImageUploadService.adjustBrightness(i, 1.15)), icon: const Icon(Icons.brightness_6), label: const Text('Brighter')),
                  ]),
                  if (imageEditing) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
                ],
                if (p.useImageAsBody && p.importedImagePath.isNotEmpty) ...[
                  const Divider(height: 28),
                  const Text('IMAGE → PART MAPPING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Draw a region for each part so it moves on its own bone instead of the whole image moving as one block.', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.5))),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: autoMapping ? null : () async {
                      setState(() => autoMapping = true);
                      await p.autoMapImageParts();
                      if (mounted) setState(() => autoMapping = false);
                    },
                    icon: autoMapping ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_fix_high),
                    label: Text(autoMapping ? 'Analyzing image edges…' : 'Auto-guess regions (edge-assisted — still nudge them)'),
                  ),
                  const SizedBox(height: 8),
                  for (final part in p.parts)
                    ListTile(
                      dense: true,
                      leading: Icon(part.crop != null ? Icons.check_box : Icons.check_box_outline_blank, color: part.crop != null ? const Color(0xFFE23349) : null),
                      title: Text(part.name),
                      subtitle: Text(part.crop == null ? 'No region mapped yet' : 'Region mapped'),
                      trailing: Wrap(spacing: 4, children: [
                        TextButton(onPressed: () => _pickCropRegion(c, p, part), child: const Text('Set region')),
                        if (part.crop != null) IconButton(onPressed: () => p.setPartCrop(part.id, null), icon: const Icon(Icons.close, size: 18)),
                      ]),
                    ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class RigPage extends StatefulWidget {
  const RigPage({super.key, required this.p});
  final ProjectState p;
  @override
  State<RigPage> createState() => _RigPageState();
}

class _RigPageState extends State<RigPage> {
  bool poseMode = false;

  @override
  Widget build(BuildContext c) {
    final p = widget.p;
    return Column(children: [
      const Top(title: 'Rig Studio', subtitle: 'Bones, hierarchy, part binding — and posing'),
      Expanded(child: Row(children: [
        Expanded(child: CardBox(child: Column(children: [
          Row(children: [
            FilterChip(label: const Text('Pose mode (drag to move)'), selected: poseMode, onSelected: (v) => setState(() => poseMode = v)),
            const SizedBox(width: 8),
            if (poseMode) ...[
              ChoiceChip(label: const Text('Move'), selected: p.poseTool == 'move', onSelected: (_) => p.setPoseTool('move')),
              const SizedBox(width: 6),
              ChoiceChip(label: const Text('Rotate'), selected: p.poseTool == 'rotate', onSelected: (_) => p.setPoseTool('rotate')),
              const SizedBox(width: 6),
              ChoiceChip(label: const Text('Scale'), selected: p.poseTool == 'scale', onSelected: (_) => p.setPoseTool('scale')),
            ],
          ]),
          const SizedBox(height: 8),
          Expanded(child: ShinraViewport(project: p, poseMode: poseMode)),
        ]))),
        SizedBox(width: 320, child: CardBox(child: ListView(children: [
          FilledButton.icon(onPressed: p.autoRig, icon: const Icon(Icons.refresh), label: const Text('Rebuild Auto-Rig')),
          const SizedBox(height: 12),
          Text('Bone: ${p.selectedBone.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
          _Num('X', p.selectedBone.x, (v) => p.setBone(x: v)),
          _Num('Y', p.selectedBone.y, (v) => p.setBone(y: v)),
          _Num('Rotation', p.selectedBone.rotation, (v) => p.setBone(rotation: v)),
          _Num('Scale', p.selectedBone.scale, (v) => p.setBone(scale: v)),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: p.captureKeyframe, icon: const Icon(Icons.key), label: const Text('Keyframe'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: p.captureAll, child: const Text('Full Pose'))),
          ]),
          const Divider(height: 24),
          const Text('SKELETON', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final b in p.bones) ListTile(selected: b.id == p.selectedBoneId, leading: const Icon(Icons.circle, size: 10), title: Text(b.name), subtitle: Text(b.parentId == null ? 'Root' : '↳ ${b.parentId}'), onTap: () => p.selectBone(b.id)),
          const Divider(),
          const Text('PART BINDING', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final part in p.parts) DropdownButtonFormField<String>(value: part.boneId, decoration: InputDecoration(labelText: part.name), items: [for (final b in p.bones) DropdownMenuItem(value: b.id, child: Text(b.name))], onChanged: (v) { if (v != null) p.bindPart(part.id, v); }),
        ]))),
      ])),
    ]);
  }
}

class AnimatePage extends StatelessWidget {
  const AnimatePage({super.key, required this.p, required this.onPlay});
  final ProjectState p;
  final VoidCallback onPlay;

  Future<void> _newAnimation(BuildContext c) async {
    final nameCtrl = TextEditingController(text: 'My Animation');
    final durationCtrl = TextEditingController(text: '3');
    var loop = false;
    final ok = await showDialog<bool>(
      context: c,
      builder: (dc) => StatefulBuilder(builder: (dc, setS) => AlertDialog(
            title: const Text('New animation'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: 'Duration (seconds)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Loop'), value: loop, onChanged: (v) => setS(() => loop = v)),
            ]),
            actions: [TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dc, true), child: const Text('Create'))],
          )),
    );
    if (ok == true) {
      final d = double.tryParse(durationCtrl.text.replaceAll(',', '.')) ?? 3.0;
      p.createAnimation(nameCtrl.text.trim().isEmpty ? 'My Animation' : nameCtrl.text.trim(), d, loop: loop);
    }
  }

  @override
  Widget build(BuildContext c) => Column(children: [
        const Top(title: 'Animation Lab', subtitle: 'Keyframe animation on the rig — build your own or edit a preset'),
        CardBox(
          child: Column(children: [
            Row(children: [
              Expanded(child: DropdownButton<String>(isExpanded: true, value: p.selectedAnimationId, items: [for (final a in p.animations) DropdownMenuItem(value: a.id, child: Text('${a.name}  (${a.duration.toStringAsFixed(1)}s)'))], onChanged: (v) { if (v != null) { p.selectedAnimationId = v; p.setPlayhead(0); } })),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () => _newAnimation(c), icon: const Icon(Icons.add), label: const Text('New')),
              if (p.selectedAnimationId.startsWith('custom_')) IconButton(onPressed: () => p.deleteAnimation(p.selectedAnimationId), icon: const Icon(Icons.delete_outline)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton.icon(onPressed: onPlay, icon: Icon(p.playing ? Icons.pause : Icons.play_arrow), label: Text(p.playing ? 'Pause' : 'Play')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: p.captureKeyframe, child: const Text('Keyframe')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: p.captureAll, child: const Text('Capture Full Pose')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: p.resetPose, child: const Text('Reset')),
            ]),
            const SizedBox(height: 8),
            _KeyframeTimeline(p: p, boneId: p.selectedBoneId),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Motion curve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                for (final easing in KeyframeEasing.values)
                  ChoiceChip(
                    label: Text(easing.name),
                    selected: _easingAtPlayhead(p) == easing,
                    onSelected: (_) => p.setKeyframeEasing(easing),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Row(children: [for (final b in p.bones.take(6)) Expanded(child: Text('${b.name}\n${p.selectedAnimation.tracks[b.id]?.keys.length ?? 0} keys', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))]),
          ]),
        ),
        Expanded(child: Padding(padding: const EdgeInsets.all(16), child: ShinraViewport(project: p))),
      ]);
}

KeyframeEasing? _easingAtPlayhead(ProjectState p) {
  final track = p.selectedAnimation.tracks[p.selectedBoneId];
  if (track == null) return null;
  for (final key in track.keys) {
    if ((key.time - p.playhead).abs() < .001) return key.easing;
  }
  return null;
}

class FacePage extends StatelessWidget {
  const FacePage({super.key, required this.p});
  final ProjectState p;

  @override
  Widget build(BuildContext c) => Column(children: [
        const Top(title: 'Expression Studio', subtitle: 'Expressions, eye direction and natural blinking'),
        Expanded(child: Row(children: [
          Expanded(child: CardBox(child: ShinraViewport(project: p, showBones: false))),
          SizedBox(
            width: 320,
            child: CardBox(
              child: ListView(children: [
                const Text('EXPRESSION', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in ['Neutral', 'Happy', 'Angry', 'Sad', 'Surprised', 'Terrifying', 'Determined', 'Smirk'])
                    ChoiceChip(label: Text(e), selected: p.expression == e, onSelected: (_) => p.setExpression(e)),
                ]),
                const Divider(height: 28),
                const Text('EYE DIRECTION', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('The eyes also blink naturally during playback.', style: TextStyle(fontSize: 11)),
                Slider(value: p.eyeLookX, min: -1, max: 1, divisions: 8, label: p.eyeLookX.toStringAsFixed(1), onChanged: (v) => p.setEyeDirection(x: v)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Left'), Text('Right')]),
                Slider(value: p.eyeLookY, min: -1, max: 1, divisions: 8, label: p.eyeLookY.toStringAsFixed(1), onChanged: (v) => p.setEyeDirection(y: v)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Up'), Text('Down')]),
                Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => p.setEyeDirection(x: 0, y: 0), icon: const Icon(Icons.center_focus_strong), label: const Text('Center eyes'))),
                const Divider(height: 28),
                const Text('TALKING MOUTH', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  for (final shape in ['Auto', 'A', 'O', 'B'])
                    ChoiceChip(label: Text(shape), selected: p.mouthShape == shape, onSelected: (_) => p.setMouthShape(shape)),
                ]),
                const SizedBox(height: 4),
                const Text('Use A, O and B as simple dialogue mouth poses; Auto follows the expression.', style: TextStyle(fontSize: 11)),
              ]),
            ),
          ),
        ])),
      ]);
}
class FxPage extends StatelessWidget { const FxPage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => _ListTool(title: 'FX Studio', subtitle: 'Combat impacts and cinematic effects', items: ['Impact', 'Dust', 'Speed Lines', 'Energy Burst', 'Smoke', 'Spark', 'Camera Shake'], onAdd: p.addFx, entries: p.activeFx.map((e) => '${e.name}  •  ${e.time.toStringAsFixed(2)}s').toList()); }
class AudioPage extends StatelessWidget { const AudioPage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => _ListTool(title: 'Audio', subtitle: 'Timeline cues for SFX and music', items: ['Impact SFX', 'Footsteps', 'Whoosh', 'Voice Cue', 'Music Start', 'Music Stop'], onAdd: p.addAudio, entries: p.activeAudio.map((e) => '${e.name}  •  ${e.time.toStringAsFixed(2)}s').toList()); }
class _ListTool extends StatelessWidget { const _ListTool({required this.title, required this.subtitle, required this.items, required this.onAdd, required this.entries}); final String title, subtitle; final List<String> items, entries; final void Function(String) onAdd; @override Widget build(BuildContext c) => Column(children: [Top(title: title, subtitle: subtitle), Expanded(child: Row(children: [Expanded(child: CardBox(child: ListView(children: [for (final x in items) ListTile(leading: const Icon(Icons.add_circle_outline), title: Text(x), trailing: FilledButton(onPressed: () => onAdd(x), child: const Text('Add')))]))), SizedBox(width: 300, child: CardBox(child: ListView(children: [const Text('TIMELINE EVENTS', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), for (final x in entries) ListTile(title: Text(x))])))]))]); }

class CameraPage extends StatelessWidget { const CameraPage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'Camera', subtitle: 'Cinematic framing and motion'), Expanded(child: Row(children: [Expanded(child: CardBox(child: ShinraViewport(project: p, showBones: false))), SizedBox(width: 320, child: CardBox(child: ListView(children: [_Num('X', p.camera.x, (v) => p.setCamera(x: v)), _Num('Y', p.camera.y, (v) => p.setCamera(y: v)), _Num('Zoom', p.camera.zoom, (v) => p.setCamera(zoom: v)), _Num('Rotation', p.camera.rotation, (v) => p.setCamera(rotation: v)), FilledButton(onPressed: () => p.setCamera(x: 0, y: 0, zoom: 1, rotation: 0), child: const Text('Reset Camera'))])))]))]); }


class AiPage extends StatefulWidget {
  const AiPage({super.key, required this.p, required this.onPlaySequence});
  final ProjectState p;
  final void Function(List<String> clipIds) onPlaySequence;
  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final controller = TextEditingController();
  List<DirectorAction> actions = [];

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  IconData _icon(DirectorAction a) => switch (a.kind) { 'clip' => Icons.directions_run, 'expression' => Icons.face, 'fx' => Icons.auto_awesome, _ => Icons.circle };

  void _applyAndPlay() {
    final expr = actions.where((a) => a.kind == 'expression').firstOrNull;
    if (expr != null) widget.p.setExpression(expr.value!);
    for (final a in actions.where((a) => a.kind == 'fx')) widget.p.addFx(a.value!);
    final clipIds = [for (final a in actions.where((a) => a.kind == 'clip')) a.clipId!];
    if (clipIds.isNotEmpty) widget.onPlaySequence(clipIds);
  }

  @override
  Widget build(BuildContext c) => Column(children: [
        const Top(title: 'AI Director', subtitle: 'Direction in, real playback out — chains your existing clips'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CardBox(
              child: Column(children: [
                TextField(controller: controller, minLines: 4, maxLines: 6, decoration: const InputDecoration(labelText: 'Direction', hintText: 'Ex: fais courir mon personnage, arrête-le, puis frappe', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: () { setState(() => actions = AiDirector.parse(controller.text, widget.p)); }, icon: const Icon(Icons.auto_awesome), label: const Text('Plan scene'))),
                const SizedBox(height: 12),
                Expanded(child: ListView(children: [for (final a in actions) ListTile(leading: Icon(_icon(a)), title: Text(a.label), subtitle: Text(a.kind == 'clip' ? 'plays this clip in sequence' : a.kind == 'expression' ? 'sets facial expression' : 'triggered once at start'))])),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _applyAndPlay, icon: const Icon(Icons.play_arrow), label: const Text('Apply & Play'))),
                ],
              ]),
            ),
          ),
        ),
      ]);
}

/// Browsable library of everything already available in the project: ready-made
/// movement/combat animations, facial expressions, FX and audio cues — so the
/// user can find and reuse assets instead of building every clip from scratch.
Future<void> _pickCropRegion(BuildContext context, ProjectState p, CharacterPart part) async {
  final result = await showDialog<Rect>(
    context: context,
    builder: (_) => _CropPickerDialog(imagePath: p.importedImagePath, partName: part.name, initial: part.crop),
  );
  if (result != null) p.setPartCrop(part.id, result);
}

/// Lets the user draw a rectangle (drag to select) on the uploaded image to
/// mark which region belongs to a given part (head, arm, leg...). The box is
/// shown with BoxFit.fill so drag coordinates map 1:1 to normalized image
/// coordinates regardless of the source image's aspect ratio.
class _CropPickerDialog extends StatefulWidget {
  const _CropPickerDialog({required this.imagePath, required this.partName, this.initial});
  final String imagePath;
  final String partName;
  final Rect? initial;
  @override
  State<_CropPickerDialog> createState() => _CropPickerDialogState();
}

class _CropPickerDialogState extends State<_CropPickerDialog> {
  static const boxSize = 320.0;
  Offset? start;
  Rect? rect;

  @override
  void initState() {
    super.initState();
    rect = widget.initial;
  }

  Offset _clamp(Offset o) => Offset(o.dx.clamp(0, boxSize), o.dy.clamp(0, boxSize));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Map region — ${widget.partName}'),
      content: SizedBox(
        width: boxSize,
        height: boxSize + 40,
        child: Column(children: [
          Text('Drag to draw the region for this part', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.6))),
          const SizedBox(height: 8),
          GestureDetector(
            onPanStart: (d) => setState(() { start = _clamp(d.localPosition); rect = Rect.fromPoints(start!, start!); }),
            onPanUpdate: (d) => setState(() { if (start != null) rect = Rect.fromPoints(start!, _clamp(d.localPosition)); }),
            child: SizedBox(
              width: boxSize,
              height: boxSize,
              child: Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(widget.imagePath), width: boxSize, height: boxSize, fit: BoxFit.fill)),
                if (rect != null)
                  Positioned.fromRect(rect: rect!, child: Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE23349), width: 2), color: const Color(0xFFE23349).withOpacity(.15)))),
              ]),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: rect == null || rect!.width < 4 || rect!.height < 4
              ? null
              : () => Navigator.pop(context, Rect.fromLTWH(rect!.left / boxSize, rect!.top / boxSize, rect!.width / boxSize, rect!.height / boxSize)),
          child: const Text('Save region'),
        ),
      ],
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.p, required this.onUse});
  final ProjectState p;
  final VoidCallback onUse;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  late final tab = TabController(length: 4, vsync: this);
  static const expressions = ['Neutral', 'Happy', 'Angry', 'Sad', 'Surprised', 'Terrifying', 'Determined', 'Smirk'];
  static const fxItems = ['Impact', 'Dust', 'Speed Lines', 'Energy Burst', 'Smoke', 'Spark', 'Camera Shake'];
  static const audioItems = ['Impact SFX', 'Footsteps', 'Whoosh', 'Voice Cue', 'Music Start', 'Music Stop'];

  @override
  void dispose() { tab.dispose(); super.dispose(); }

  Widget _grid(List<Widget> tiles) => GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(4), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.6, children: tiles);

  Widget _tile(String title, String subtitle, IconData icon, VoidCallback onTap) => CardBox(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(children: [
            Icon(icon, color: const Color(0xFFE23349)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.5)))])),
          ]),
        ),
      );

  bool importing = false;

  @override
  Widget build(BuildContext c) {
    final p = widget.p;
    return Column(children: [
      const Top(title: 'Library', subtitle: 'Ready-made animations, expressions, FX and audio to reuse on any rig'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: importing ? null : () async {
              setState(() => importing = true);
              await p.importLibraryAnimations();
              if (mounted) setState(() => importing = false);
            },
            icon: importing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_outlined),
            label: Text(importing ? 'Importing…' : 'Import bundled JSON animations (hand-authored, more detailed)'),
          ),
        ),
      ),
      const SizedBox(height: 4),
      TabBar(controller: tab, isScrollable: true, tabs: const [Tab(text: 'Movement'), Tab(text: 'Combat'), Tab(text: 'Face'), Tab(text: 'FX & Audio')]),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TabBarView(controller: tab, children: [
            _grid([for (final a in p.animations.where((a) => a.category == AnimCategory.movement)) _tile(a.name, '${a.duration.toStringAsFixed(1)}s • ${a.loop ? 'loop' : 'one-shot'}', Icons.directions_run, () { p.selectAnimation(a.id); widget.onUse(); })]),
            _grid([for (final a in p.animations.where((a) => a.category == AnimCategory.combat)) _tile(a.name, '${a.duration.toStringAsFixed(1)}s • ${a.loop ? 'loop' : 'one-shot'}', Icons.sports_martial_arts, () { p.selectAnimation(a.id); widget.onUse(); })]),
            _grid([for (final e in expressions) _tile(e, 'Facial expression', Icons.face, () { p.setExpression(e); widget.onUse(); })]),
            _grid([
              for (final f in fxItems) _tile(f, 'FX — added at playhead', Icons.auto_awesome, () => p.addFx(f)),
              for (final a in audioItems) _tile(a, 'Audio cue — added at playhead', Icons.audiotrack, () => p.addAudio(a)),
            ]),
          ]),
        ),
      ),
    ]);
  }
}

class ExportPage extends StatefulWidget {
  const ExportPage({super.key, required this.p});
  final ProjectState p;
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final boundaryKey = GlobalKey();
  int fps = 12;
  bool exporting = false;
  String phase = '';
  int frameDone = 0;
  int frameTotal = 0;
  String? resultPath;
  bool lastWasMp4 = false;

  Future<void> _exportGif() async {
    setState(() { exporting = true; lastWasMp4 = false; resultPath = null; phase = ''; frameDone = 0; frameTotal = 0; });
    try {
      final path = await GifExporter.export(boundaryKey, widget.p, fps: fps, onProgress: (a, b) { if (mounted) setState(() { frameDone = a; frameTotal = b; }); });
      if (mounted) setState(() => resultPath = path);
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GIF export failed: $err')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _exportMp4() async {
    setState(() { exporting = true; lastWasMp4 = true; resultPath = null; phase = 'capture'; frameDone = 0; frameTotal = 0; });
    try {
      final path = await Mp4Exporter.export(boundaryKey, widget.p, fps: fps >= 24 ? fps : 24, onProgress: (ph, a, b) { if (mounted) setState(() { phase = ph; frameDone = a; frameTotal = b; }); });
      if (mounted) setState(() => resultPath = path);
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('MP4 export failed: $err')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  String get _buttonLabel {
    if (!exporting) return lastWasMp4 ? 'Export as MP4' : 'Export as GIF';
    if (phase == 'encode') return 'Encoding H.264…';
    return 'Capturing frame $frameDone / $frameTotal…';
  }

  @override
  Widget build(BuildContext c) {
    final p = widget.p;
    return Column(children: [
      const Top(title: 'Project', subtitle: 'Save, restore and export a real GIF or MP4'),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: CardBox(
                child: ListView(children: [
                  const Text('SHINRA PROJECT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Bones: ${p.bones.length}   Parts: ${p.parts.length}   Animations: ${p.animations.length}'),
                  Text('FX: ${p.fx.length}   Audio cues: ${p.audio.length}'),
                  const SizedBox(height: 24),
                  FilledButton.icon(onPressed: () => ProjectStore.save(p), icon: const Icon(Icons.save), label: const Text('Save Project')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () => ProjectStore.load(p), icon: const Icon(Icons.folder_open), label: const Text('Load Project')),
                  const SizedBox(height: 20),
                  const Text('Export', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Exports the clip currently selected in Animation Lab ("${p.selectedAnimation.name}") — captured frame by frame from the render below.', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(.6))),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('FPS'),
                    const SizedBox(width: 10),
                    for (final f in [8, 12, 24, 30])
                      Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text('$f'), selected: fps == f, onSelected: exporting ? null : (_) => setState(() => fps = f))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: exporting ? null : _exportGif,
                        icon: exporting && !lastWasMp4 ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.gif_box_outlined),
                        label: Text(exporting && !lastWasMp4 ? _buttonLabel : 'Export as GIF'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: exporting ? null : _exportMp4,
                        icon: exporting && lastWasMp4 ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.movie_creation_outlined),
                        label: Text(exporting && lastWasMp4 ? _buttonLabel : 'Export as MP4'),
                      ),
                    ),
                  ]),
                  if (resultPath != null) ...[
                    const SizedBox(height: 14),
                    SelectableText('Saved to:\n$resultPath', style: const TextStyle(fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'MP4 uses a real H.264 encode (FFmpeg via ffmpeg_kit_flutter_new) — not a metadata stub. Honest caveats: this needs flutter pub get + a real device/emulator build to confirm (no compiler in the sandbox that wrote this); Android minSdkVersion may need to be 24+; the x264 encoder is GPL-licensed, which carries redistribution obligations if you ship the app; no audio track is muxed into the export yet.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.45)),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 260,
              child: CardBox(
                child: Column(children: [
                  const Text('Export render target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  RepaintBoundary(key: boundaryKey, child: SizedBox(width: 220, height: 260, child: ShinraViewport(project: p, showBones: false))),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
