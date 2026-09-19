import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/frame_animation.dart';
import '../models/rig.dart';
import '../services/project_store.dart';

/// Dedicated raster exposure editor. It intentionally does not convert a
/// drawing into bones: a frame is a drawing. The same scene can later mix
/// these exposures with the rig/mesh/camera renderer.
class FrameByFramePage extends StatefulWidget {
  const FrameByFramePage({super.key, required this.project});
  final ProjectState project;
  @override State<FrameByFramePage> createState() => _FrameByFramePageState();
}

class _FrameByFramePageState extends State<FrameByFramePage> {
  Color color = Colors.white;
  double width = 6;
  bool eraser = false;
  final GlobalKey _paintKey = GlobalKey();

  FrameAnimationTrack get t => widget.project.frameAnimation;
  ExposureFrame get f => t.ensureFrame(widget.project.frameCursor);

  @override
  void initState() { super.initState(); t.ensureFrame(0); }

  // Points are stored as 0-1 fractions of the drawing area, not raw pixels —
  // otherwise a stroke drawn on a phone-sized editor window lands in the
  // wrong place (or off-canvas entirely) when played back in the main
  // viewport, which is almost never the same pixel size as this editor.
  Offset _normalized(Offset local) {
    final box = _paintKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(800, 800);
    return Offset((local.dx / size.width).clamp(0, 1), (local.dy / size.height).clamp(0, 1));
  }
  void _strokeStart(DragStartDetails d) {
    setState(() {
      f.strokes.add(DrawingStroke(argb: color.toARGB32(), width: width, erase: eraser));
      final n = _normalized(d.localPosition);
      f.strokes.last.points.add(DrawingPoint(n.dx, n.dy));
    });
  }
  void _strokeUpdate(DragUpdateDetails d) {
    if (f.strokes.isEmpty) return;
    final n = _normalized(d.localPosition);
    setState(() => f.strokes.last.points.add(DrawingPoint(n.dx, n.dy)));
  }
  void _strokeEnd(DragEndDetails _) => _save();

  Future<void> _save() => ProjectStore.save(widget.project);
  void _newFrame() { setState(() { t.insert(widget.project.frameCursor + 1); widget.project.frameCursor++; }); _save(); }
  void _duplicate() { setState(() { t.duplicate(widget.project.frameCursor); widget.project.frameCursor++; }); _save(); }
  void _delete() { setState(() { t.remove(widget.project.frameCursor); widget.project.frameCursor = widget.project.frameCursor.clamp(0, t.length - 1).toInt(); }); _save(); }
  void _clear() { setState(() => t.clearFrame(widget.project.frameCursor)); _save(); }

  @override
  Widget build(BuildContext context) {
    final current = widget.project.currentFrame;
    return Scaffold(
      appBar: AppBar(title: const Text('Frame by Frame'), actions: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [
          const Text('Aperçu = dessin', style: TextStyle(fontSize: 12)),
          Switch(value: widget.project.frameEditorEnabled, onChanged: (v) => setState(() => widget.project.setFrameEditorEnabled(v))),
        ])),
        IconButton(onPressed: () => setState(() => t.onionSkin = !t.onionSkin), icon: Icon(t.onionSkin ? Icons.lightbulb : Icons.lightbulb_outline), tooltip: 'Onion skin'),
        IconButton(onPressed: _clear, icon: const Icon(Icons.delete_sweep_outlined), tooltip: 'Effacer la frame'),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 4), child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          IconButton(onPressed: () { widget.project.frameStep(-1); setState(() {}); }, icon: const Icon(Icons.chevron_left)),
          Text('Frame ${current + 1} / ${t.length}  •  ${t.fps} FPS', style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(onPressed: () { widget.project.frameStep(1); setState(() {}); }, icon: const Icon(Icons.chevron_right)),
          const SizedBox(width: 12),
          FilledButton.icon(onPressed: _newFrame, icon: const Icon(Icons.add), label: const Text('Frame')), 
          OutlinedButton.icon(onPressed: _duplicate, icon: const Icon(Icons.content_copy), label: const Text('Dupliquer')),
          OutlinedButton.icon(onPressed: t.length <= 1 ? null : _delete, icon: const Icon(Icons.remove_circle_outline), label: const Text('Supprimer')),
          DropdownButton<int>(value: t.fps, items: const [12,15,24,30,60].map((x) => DropdownMenuItem(value:x, child:Text('$x FPS'))).toList(), onChanged:(v){if(v!=null)setState(()=>t.fps=v);}),
          ChoiceChip(label: const Text('Crayon'), selected: !eraser, onSelected: (_) => setState(() => eraser=false)),
          ChoiceChip(label: const Text('Gomme'), selected: eraser, onSelected: (_) => setState(() => eraser=true)),
        ])),
        Expanded(child: Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Card(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: GestureDetector(
            onPanStart: _strokeStart, onPanUpdate: _strokeUpdate, onPanEnd: _strokeEnd,
            child: CustomPaint(key: _paintKey, painter: _ExposurePainter(t, current), size: Size.infinite),
          ))))),
          SizedBox(width: 230, child: Padding(padding: const EdgeInsets.only(right:12), child: Column(children: [
            const Text('EXPOSITIONS', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height:8),
            Expanded(child: ListView.builder(itemCount:t.length, itemBuilder:(c,i){ final selected=i==current; return GestureDetector(onTap:(){widget.project.setFrameCursor(i);setState((){});}, child: Container(height:58, margin:const EdgeInsets.only(bottom:6), padding:const EdgeInsets.all(8), decoration:BoxDecoration(border:Border.all(color:selected?Colors.red:Colors.white12), borderRadius:BorderRadius.circular(8)), child:Row(children:[SizedBox(width:30,child:Text('${i+1}')), Expanded(child:Text(t.frames[i].strokes.isEmpty?'Blank':'Drawing')), if(t.frames[i].held) const Icon(Icons.pause_circle_outline,size:16)]))); })),
          ]))),
        ])),
      ]),
    );
  }
}

class _ExposurePainter extends CustomPainter {
  _ExposurePainter(this.track, this.index);
  final FrameAnimationTrack track; final int index;
  @override void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color=const Color(0xFF11131A));
    if (track.onionSkin) {
      for (var d=track.onionBefore; d>=1; d--) _drawFrame(canvas,size,index-d,0.10+(track.onionBefore-d)*0.03);
      for (var d=1; d<=track.onionAfter; d++) _drawFrame(canvas,size,index+d,0.10+(track.onionAfter-d)*0.03);
    }
    _drawFrame(canvas,size,index,1);
  }
  void _drawFrame(Canvas canvas, Size size, int i, double alpha) {
    if(i<0||i>=track.length)return;
    final f=track.frames[i];
    canvas.saveLayer(Offset.zero & size, Paint());
    for(final s in f.strokes){
      if(s.points.isEmpty)continue;
      final paint=Paint()..color=Color(s.argb).withValues(alpha:(Color(s.argb).a)*alpha)..strokeWidth=s.width..strokeCap=StrokeCap.round..style=PaintingStyle.stroke..blendMode=s.erase?BlendMode.clear:BlendMode.srcOver;
      Offset px(DrawingPoint p) => Offset(p.x * size.width, p.y * size.height);
      for(var j=1;j<s.points.length;j++){ canvas.drawLine(px(s.points[j-1]),px(s.points[j]),paint); }
      if(s.points.length==1)canvas.drawCircle(px(s.points.first),s.width/2,paint..style=PaintingStyle.fill);
    }
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _ExposurePainter old)=>true;
}
