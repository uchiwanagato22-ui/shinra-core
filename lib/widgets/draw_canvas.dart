import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class Stroke {
  Stroke(this.color, this.width);
  final Color color;
  final double width;
  final List<Offset> points = [];
}

/// Simple freehand drawing surface so a character can be created directly in
/// the app instead of always requiring an uploaded photo. The result is
/// rasterized to a PNG on disk and can be fed into the exact same
/// image-as-body / part-mapping pipeline as an uploaded image.
class DrawCanvasPage extends StatefulWidget {
  const DrawCanvasPage({super.key});
  @override
  State<DrawCanvasPage> createState() => _DrawCanvasPageState();
}

class _DrawCanvasPageState extends State<DrawCanvasPage> {
  final boundaryKey = GlobalKey();
  final List<Stroke> strokes = [];
  Color color = Colors.white;
  double width = 4;
  bool saving = false;

  static const palette = [Colors.white, Colors.black, Color(0xFFE9B18E), Color(0xFF151722), Color(0xFF7C2431), Color(0xFF2F4A7C), Color(0xFFC9A227), Color(0xFF3E8E4F)];

  void _start(DragStartDetails d) => setState(() => strokes.add(Stroke(color, width)..points.add(d.localPosition)));
  void _update(DragUpdateDetails d) => setState(() => strokes.last.points.add(d.localPosition));
  void _undo() { if (strokes.isNotEmpty) setState(() => strokes.removeLast()); }
  void _clear() => setState(() => strokes.clear());

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/shinra_drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      if (mounted) Navigator.pop(context, file.path);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw your character'),
        actions: [
          IconButton(onPressed: strokes.isEmpty ? null : _undo, icon: const Icon(Icons.undo)),
          IconButton(onPressed: strokes.isEmpty ? null : _clear, icon: const Icon(Icons.delete_outline)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
              label: const Text('Use drawing'),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            for (final c in palette)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => color = c),
                  child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: c == color ? Colors.orange : Colors.white24, width: c == color ? 3 : 1))),
                ),
              ),
            const SizedBox(width: 16),
            const Icon(Icons.brush, size: 18),
            SizedBox(width: 140, child: Slider(value: width, min: 1, max: 20, onChanged: (v) => setState(() => width = v))),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF1A1E29), borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onPanStart: _start,
                    onPanUpdate: _update,
                    child: CustomPaint(painter: _StrokePainter(strokes), size: Size.infinite),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes);
  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1A1E29));
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], paint);
      }
      if (s.points.length == 1) canvas.drawCircle(s.points.first, s.width / 2, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
