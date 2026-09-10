import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'models/rig.dart';
import 'services/ai_director.dart';
import 'services/project_store.dart';
import 'widgets/draw_canvas.dart';
import 'widgets/viewport.dart';

void main() => runApp(ChangeNotifierProvider(create: (_) => ProjectState(), child: const ShinraApp()));

class ShinraApp extends StatelessWidget {
  const ShinraApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'SHINRA CORE', theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF07090E), colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6D00), brightness: Brightness.dark), useMaterial3: true), home: const Shell());
}

enum Page { home, studio, character, library, rig, animate, face, fx, camera, audio, ai, export }

class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  Page page = Page.home; Timer? timer;
  @override void dispose() { timer?.cancel(); super.dispose(); }
  void togglePlay(ProjectState p) { if (p.playing) { timer?.cancel(); p.playing = false; p.status = 'Paused'; p.notifyListeners(); return; } p.playing = true; p.status = 'Playing'; p.notifyListeners(); timer?.cancel(); timer = Timer.periodic(const Duration(milliseconds: 33), (_) { if (!mounted) return; final next = p.playhead + 1 / 30; if (next >= p.selectedAnimation.duration && !p.selectedAnimation.loop) { p.playing = false; timer?.cancel(); p.setPlayhead(p.selectedAnimation.duration); } else { p.loadAt(next); } }); }
  @override Widget build(BuildContext context) => Consumer<ProjectState>(builder: (_, p, __) => Scaffold(body: Row(children: [NavigationRail(selectedIndex: page.index, onDestinationSelected: (i) => setState(() => page = Page.values[i]), labelType: NavigationRailLabelType.all, destinations: const [NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Home')), NavigationRailDestination(icon: Icon(Icons.movie_outlined), label: Text('Studio')), NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Character')), NavigationRailDestination(icon: Icon(Icons.video_library_outlined), label: Text('Library')), NavigationRailDestination(icon: Icon(Icons.account_tree_outlined), label: Text('Rig')), NavigationRailDestination(icon: Icon(Icons.timeline_outlined), label: Text('Animate')), NavigationRailDestination(icon: Icon(Icons.face_outlined), label: Text('Face')), NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), label: Text('FX')), NavigationRailDestination(icon: Icon(Icons.videocam_outlined), label: Text('Camera')), NavigationRailDestination(icon: Icon(Icons.audiotrack_outlined), label: Text('Audio')), NavigationRailDestination(icon: Icon(Icons.smart_toy_outlined), label: Text('AI Director')), NavigationRailDestination(icon: Icon(Icons.file_upload_outlined), label: Text('Export'))]), Expanded(child: _page(p)),])));
  Widget _page(ProjectState p) { switch (page) { case Page.home: return HomePage(onOpen: (x) => setState(() => page = x)); case Page.studio: return StudioPage(p: p, onPlay: () => togglePlay(p)); case Page.character: return CharacterPage(p: p); case Page.library: return LibraryPage(p: p, onUse: () => setState(() => page = Page.animate)); case Page.rig: return RigPage(p: p); case Page.animate: return AnimatePage(p: p, onPlay: () => togglePlay(p)); case Page.face: return FacePage(p: p); case Page.fx: return FxPage(p: p); case Page.camera: return CameraPage(p: p); case Page.audio: return AudioPage(p: p); case Page.ai: return AiPage(p: p); case Page.export: return ExportPage(p: p); } }
}

class Top extends StatelessWidget { const Top({super.key, required this.title, this.subtitle}); final String title; final String? subtitle; @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 14), child: Row(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), if (subtitle != null) Text(subtitle!, style: TextStyle(color: Colors.white.withOpacity(.55))) ]), const Spacer(), const Text('SHINRA CORE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFFFF8A00))) ])); }
class CardBox extends StatelessWidget { const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(16)}); final Widget child; final EdgeInsets padding; @override Widget build(BuildContext c) => Container(padding: padding, decoration: BoxDecoration(color: const Color(0xFF10141E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.07))), child: child); }

class HomePage extends StatelessWidget { const HomePage({super.key, required this.onOpen}); final void Function(Page) onOpen; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'SHINRA CORE', subtitle: '2D anime animation workspace'), Expanded(child: GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(24), crossAxisSpacing: 16, mainAxisSpacing: 16, children: [for (final x in [(Page.studio, Icons.movie, 'Studio', 'Compose a scene'), (Page.character, Icons.person, 'Character', 'Build parts and import art'), (Page.rig, Icons.account_tree, 'Rig Studio', 'Bones and bindings'), (Page.animate, Icons.timeline, 'Animation Lab', 'Keyframes and playback'), (Page.face, Icons.face, 'Expressions', 'Anime facial acting'), (Page.fx, Icons.auto_awesome, 'FX', 'Impacts and particles'), (Page.camera, Icons.videocam, 'Camera', 'Shots and framing'), (Page.ai, Icons.smart_toy, 'AI Director', 'Turn direction into timeline')]) CardBox(child: InkWell(onTap: () => onOpen(x.$1), borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(x.$2, size: 36, color: const Color(0xFFFF8A00)), const Spacer(), Text(x.$3, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(x.$4, style: TextStyle(color: Colors.white.withOpacity(.55))) ]))))]) )]); }

class StudioPage extends StatelessWidget { const StudioPage({super.key, required this.p, required this.onPlay}); final ProjectState p; final VoidCallback onPlay; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'Studio', subtitle: 'Scene viewport + timeline'), Expanded(child: Row(children: [Expanded(flex: 7, child: CardBox(child: Column(children: [Expanded(child: ShinraViewport(project: p)), const SizedBox(height: 10), _Transport(p: p, onPlay: onPlay)]))), const SizedBox(width: 14), SizedBox(width: 270, child: _Inspector(p: p))])),]); }
class _Transport extends StatelessWidget { const _Transport({required this.p, required this.onPlay}); final ProjectState p; final VoidCallback onPlay; @override Widget build(BuildContext c) => Column(children: [Row(children: [IconButton(onPressed: p.undo, icon: const Icon(Icons.undo)), IconButton(onPressed: p.redo, icon: const Icon(Icons.redo)), IconButton(onPressed: () => p.setPlayhead(0), icon: const Icon(Icons.stop)), IconButton(onPressed: onPlay, icon: Icon(p.playing ? Icons.pause : Icons.play_arrow)), const SizedBox(width: 8), Text('${p.playhead.toStringAsFixed(2)} / ${p.selectedAnimation.duration.toStringAsFixed(2)}s'), const Spacer(), DropdownButton<String>(value: p.selectedAnimationId, items: [for (final a in p.animations) DropdownMenuItem(value: a.id, child: Text(a.name))], onChanged: (v) { if (v != null) { p.selectedAnimationId = v; p.setPlayhead(0); } })]), Slider(value: p.playhead, min: 0, max: p.selectedAnimation.duration, onChanged: p.setPlayhead)]); }
class _Inspector extends StatelessWidget { const _Inspector({required this.p}); final ProjectState p; @override Widget build(BuildContext c) => CardBox(child: ListView(children: [const Text('INSPECTOR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(height: 18), Text('Bone: ${p.selectedBone.name}'), const SizedBox(height: 10), _Num('X', p.selectedBone.x, (v) => p.setBone(x: v)), _Num('Y', p.selectedBone.y, (v) => p.setBone(y: v)), _Num('Rotation', p.selectedBone.rotation, (v) => p.setBone(rotation: v)), _Num('Scale', p.selectedBone.scale, (v) => p.setBone(scale: v)), const SizedBox(height: 14), FilledButton.icon(onPressed: p.captureKeyframe, icon: const Icon(Icons.key), label: const Text('Capture Keyframe')), OutlinedButton(onPressed: p.captureAll, child: const Text('Capture Full Pose')), const SizedBox(height: 10), Text(p.status, style: TextStyle(color: Colors.white.withOpacity(.5)))])); }
class _Num extends StatelessWidget { const _Num(this.label, this.value, this.onChanged); final String label; final double value; final ValueChanged<double> onChanged; @override Widget build(BuildContext c) => Row(children: [SizedBox(width: 72, child: Text(label)), Expanded(child: Slider(value: value.clamp(-200, 200), min: -200, max: 200, onChanged: onChanged))]); }

class CharacterPage extends StatefulWidget { const CharacterPage({super.key, required this.p}); final ProjectState p; @override State<CharacterPage> createState() => _CharacterPageState(); }
class _CharacterPageState extends State<CharacterPage> {
  final picker = ImagePicker();

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
                _swatchRow('Clothes', clothesPalette, p.clothesColor, (v) => p.setAppearance(clothes: v)),
                const SizedBox(height: 4),
                const Text('Hair style', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final s in hairStyles) ChoiceChip(label: Text(s), selected: p.hairStyle == s, onSelected: (_) => p.setAppearance(style: s))]),
                const Divider(height: 28),
                const Text('PARTS', style: TextStyle(fontWeight: FontWeight.w800)),
                for (final part in p.parts) ListTile(dense: true, leading: Icon(part.visible ? Icons.visibility : Icons.visibility_off), title: Text(part.name), subtitle: Text(part.boneId), onTap: () => p.togglePart(part.id)),
                if (p.useImageAsBody && p.importedImagePath.isNotEmpty) ...[
                  const Divider(height: 28),
                  const Text('IMAGE → PART MAPPING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Draw a region for each part so it moves on its own bone instead of the whole image moving as one block.', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.5))),
                  const SizedBox(height: 8),
                  for (final part in p.parts)
                    ListTile(
                      dense: true,
                      leading: Icon(part.crop != null ? Icons.check_box : Icons.check_box_outline_blank, color: part.crop != null ? const Color(0xFFFF8A00) : null),
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

class RigPage extends StatelessWidget { const RigPage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'Rig Studio', subtitle: 'Bones, hierarchy and part binding'), Expanded(child: Row(children: [Expanded(child: CardBox(child: ShinraViewport(project: p))), SizedBox(width: 320, child: CardBox(child: ListView(children: [FilledButton.icon(onPressed: p.autoRig, icon: const Icon(Icons.refresh), label: const Text('Rebuild Auto-Rig')), const SizedBox(height: 16), const Text('SKELETON', style: TextStyle(fontWeight: FontWeight.w800)), for (final b in p.bones) ListTile(selected: b.id == p.selectedBoneId, leading: const Icon(Icons.circle, size: 10), title: Text(b.name), subtitle: Text(b.parentId == null ? 'Root' : '↳ ${b.parentId}'), onTap: () => p.selectBone(b.id)), const Divider(), const Text('PART BINDING', style: TextStyle(fontWeight: FontWeight.w800)), for (final part in p.parts) DropdownButtonFormField<String>(value: part.boneId, decoration: InputDecoration(labelText: part.name), items: [for (final b in p.bones) DropdownMenuItem(value: b.id, child: Text(b.name))], onChanged: (v) { if (v != null) p.bindPart(part.id, v); })])))]))]); }

class AnimatePage extends StatelessWidget { const AnimatePage({super.key, required this.p, required this.onPlay}); final ProjectState p; final VoidCallback onPlay; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'Animation Lab', subtitle: 'Keyframe animation on the rig'), CardBox(child: Column(children: [Row(children: [DropdownButton<String>(value: p.selectedAnimationId, items: [for (final a in p.animations) DropdownMenuItem(value: a.id, child: Text(a.name))], onChanged: (v) { if (v != null) { p.selectedAnimationId = v; p.setPlayhead(0); } }), const SizedBox(width: 12), FilledButton.icon(onPressed: onPlay, icon: Icon(p.playing ? Icons.pause : Icons.play_arrow), label: Text(p.playing ? 'Pause' : 'Play')), OutlinedButton(onPressed: p.captureKeyframe, child: const Text('Keyframe')), OutlinedButton(onPressed: p.resetPose, child: const Text('Reset'))]), const SizedBox(height: 8), Slider(value: p.playhead, min: 0, max: p.selectedAnimation.duration, onChanged: p.setPlayhead), Row(children: [for (final b in p.bones.take(6)) Expanded(child: Text('${b.name}\n${p.selectedAnimation.tracks[b.id]?.keys.length ?? 0} keys', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))])])), Expanded(child: Padding(padding: const EdgeInsets.all(16), child: ShinraViewport(project: p))) ]); }

class FacePage extends StatelessWidget { const FacePage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'Expression Studio', subtitle: 'Anime facial acting presets'), Expanded(child: Row(children: [Expanded(child: CardBox(child: ShinraViewport(project: p, showBones: false))), SizedBox(width: 320, child: CardBox(child: ListView(children: [for (final e in ['Neutral', 'Happy', 'Angry', 'Sad', 'Surprised', 'Terrifying', 'Determined', 'Smirk']) Padding(padding: const EdgeInsets.only(bottom: 8), child: ChoiceChip(label: Text(e), selected: p.expression == e, onSelected: (_) => p.setExpression(e)))])))]))]); }
class FxPage extends StatelessWidget { const FxPage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => _ListTool(title: 'FX Studio', subtitle: 'Combat impacts and cinematic effects', items: ['Impact', 'Dust', 'Speed Lines', 'Energy Burst', 'Smoke', 'Spark', 'Camera Shake'], onAdd: p.addFx, entries: p.fx.map((e) => '${e.name}  •  ${e.time.toStringAsFixed(2)}s').toList()); }
class AudioPage extends StatelessWidget { const AudioPage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => _ListTool(title: 'Audio', subtitle: 'Timeline cues for SFX and music', items: ['Impact SFX', 'Footsteps', 'Whoosh', 'Voice Cue', 'Music Start', 'Music Stop'], onAdd: p.addAudio, entries: p.audio.map((e) => '${e.name}  •  ${e.time.toStringAsFixed(2)}s').toList()); }
class _ListTool extends StatelessWidget { const _ListTool({required this.title, required this.subtitle, required this.items, required this.onAdd, required this.entries}); final String title, subtitle; final List<String> items, entries; final void Function(String) onAdd; @override Widget build(BuildContext c) => Column(children: [Top(title: title, subtitle: subtitle), Expanded(child: Row(children: [Expanded(child: CardBox(child: ListView(children: [for (final x in items) ListTile(leading: const Icon(Icons.add_circle_outline), title: Text(x), trailing: FilledButton(onPressed: () => onAdd(x), child: const Text('Add')))]))), SizedBox(width: 300, child: CardBox(child: ListView(children: [const Text('TIMELINE EVENTS', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12), for (final x in entries) ListTile(title: Text(x))])))]))]); }

class CameraPage extends StatelessWidget { const CameraPage({super.key, required this.p}); final ProjectState p; @override Widget build(BuildContext c) => Column(children: [const Top(title: 'Camera', subtitle: 'Cinematic framing and motion'), Expanded(child: Row(children: [Expanded(child: CardBox(child: ShinraViewport(project: p, showBones: false))), SizedBox(width: 320, child: CardBox(child: ListView(children: [_Num('X', p.camera.x, (v) => p.setCamera(x: v)), _Num('Y', p.camera.y, (v) => p.setCamera(y: v)), _Num('Zoom', p.camera.zoom, (v) => p.setCamera(zoom: v)), _Num('Rotation', p.camera.rotation, (v) => p.setCamera(rotation: v)), FilledButton(onPressed: () => p.setCamera(x: 0, y: 0, zoom: 1, rotation: 0), child: const Text('Reset Camera'))])))]))]); }

class AiPage extends StatefulWidget { const AiPage({super.key, required this.p}); final ProjectState p; @override State<AiPage> createState() => _AiPageState(); }
class _AiPageState extends State<AiPage> { final controller = TextEditingController(); List<DirectorAction> actions = []; @override void dispose() { controller.dispose(); super.dispose(); } @override Widget build(BuildContext c) => Column(children: [const Top(title: 'AI Director', subtitle: 'Translate direction into editable timeline actions'), Expanded(child: Padding(padding: const EdgeInsets.all(24), child: CardBox(child: Column(children: [TextField(controller: controller, minLines: 4, maxLines: 6, decoration: const InputDecoration(labelText: 'Direction', hintText: 'Ex: fais courir mon personnage, arrête-le, regarde derrière puis frappe', border: OutlineInputBorder())), const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () { setState(() => actions = AiDirector.parse(controller.text)); widget.p.status = '${actions.length} AI actions planned'; widget.p.notifyListeners(); }, icon: const Icon(Icons.auto_awesome), label: const Text('Plan scene'))), const SizedBox(height: 18), Expanded(child: ListView(children: [for (final a in actions) ListTile(leading: const Icon(Icons.drag_indicator), title: Text(a.label), subtitle: Text('at ${a.time.toStringAsFixed(1)}s'), trailing: const Icon(Icons.edit))]))]))))]); }

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
                  Positioned.fromRect(rect: rect!, child: Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFF8A00), width: 2), color: const Color(0xFFFF8A00).withOpacity(.15)))),
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
            Icon(icon, color: const Color(0xFFFF8A00)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(.5)))])),
          ]),
        ),
      );

  @override
  Widget build(BuildContext c) {
    final p = widget.p;
    return Column(children: [
      const Top(title: 'Library', subtitle: 'Ready-made animations, expressions, FX and audio to reuse on any rig'),
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

class ExportPage extends StatelessWidget {
  const ExportPage({super.key, required this.p});
  final ProjectState p;
  @override
  Widget build(BuildContext c) => Column(children: [
        const Top(title: 'Project', subtitle: 'Save, restore and prepare export'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CardBox(
              child: ListView(children: [
                const Text('SHINRA PROJECT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Bones: ${p.bones.length}   Parts: ${p.parts.length}   Animations: ${p.animations.length}'),
                Text('FX: ${p.fx.length}   Audio cues: ${p.audio.length}'),
                const SizedBox(height: 24),
                FilledButton.icon(onPressed: () => ProjectStore.save(p), icon: const Icon(Icons.save), label: const Text('Save Project')),
                OutlinedButton.icon(onPressed: () => ProjectStore.load(p), icon: const Icon(Icons.folder_open), label: const Text('Load Project')),
                const SizedBox(height: 20),
                const Text('Export pipeline', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('The editor data is ready for a dedicated video encoder/export backend. This build intentionally keeps the project format deterministic instead of pretending to render MP4 locally.'),
              ]),
            ),
          ),
        ),
      ]);
}
