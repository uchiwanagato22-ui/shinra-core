import 'dart:math' as math;

/// A real raster/frame-by-frame track. Unlike pose keyframes, every exposure
/// can contain its own drawing and can be edited independently.
class DrawingPoint {
  const DrawingPoint(this.x, this.y);
  final double x;
  final double y;
  List<double> toJson() => [x, y];
  static DrawingPoint fromJson(List raw) => DrawingPoint((raw[0] as num).toDouble(), (raw[1] as num).toDouble());
}

class DrawingStroke {
  DrawingStroke({required this.argb, required this.width, this.erase = false, List<DrawingPoint>? points}) : points = points ?? [];
  int argb;
  bool erase;
  double width;
  final List<DrawingPoint> points;
  Map<String, dynamic> toJson() => {'argb': argb, 'width': width, 'erase': erase, 'points': points.map((p) => p.toJson()).toList()};
  static DrawingStroke fromJson(Map raw) => DrawingStroke(
    argb: (raw['argb'] as num?)?.toInt() ?? 0xFFFFFFFF,
    width: (raw['width'] as num?)?.toDouble() ?? 4,
    erase: raw['erase'] as bool? ?? false,
    points: [for (final p in (raw['points'] as List? ?? const [])) DrawingPoint.fromJson(p as List)],
  );
}

class ExposureFrame {
  ExposureFrame({required this.index});
  final int index;
  bool held = false;
  final List<DrawingStroke> strokes = [];
  String label = '';
  double opacity = 1;
  Map<String, dynamic> toJson() => {
    'index': index, 'held': held, 'label': label, 'opacity': opacity,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };
  static ExposureFrame fromJson(Map raw) {
    final f = ExposureFrame(index: (raw['index'] as num?)?.toInt() ?? 0)
      ..held = raw['held'] as bool? ?? false
      ..label = raw['label'] as String? ?? ''
      ..opacity = (raw['opacity'] as num?)?.toDouble() ?? 1;
    f.strokes.addAll([for (final s in (raw['strokes'] as List? ?? const [])) DrawingStroke.fromJson(s as Map)]);
    return f;
  }
}

class FrameAnimationTrack {
  FrameAnimationTrack({this.fps = 24, this.name = 'Frame Animation'});
  String name;
  int fps;
  int onionBefore = 2;
  int onionAfter = 2;
  bool onionSkin = true;
  bool loop = false;
  final List<ExposureFrame> frames = [];

  int get length => frames.length;
  double get duration => frames.isEmpty ? 0 : frames.length / fps;

  ExposureFrame ensureFrame(int index) {
    while (frames.length <= index) frames.add(ExposureFrame(index: frames.length));
    return frames[index];
  }

  void insert(int index) {
    index = index.clamp(0, frames.length);
    frames.insert(index, ExposureFrame(index: index));
    _renumber();
  }

  void duplicate(int index) {
    if (index < 0 || index >= frames.length) return;
    final src = frames[index];
    final dst = ExposureFrame(index: index + 1)
      ..held = src.held ..label = src.label ..opacity = src.opacity;
    dst.strokes.addAll(src.strokes.map((s) => DrawingStroke(argb: s.argb, width: s.width, erase: s.erase, points: s.points.map((p) => DrawingPoint(p.x, p.y)).toList())));
    frames.insert(index + 1, dst);
    _renumber();
  }

  void remove(int index) {
    if (frames.length <= 1 || index < 0 || index >= frames.length) return;
    frames.removeAt(index);
    _renumber();
  }

  void clearFrame(int index) {
    if (index < 0 || index >= frames.length) return;
    frames[index].strokes.clear();
  }

  void _renumber() {
    // ExposureFrame.index is immutable; structural edits preserve list order,
    // while the list position is the authoritative frame number.
  }

  ExposureFrame? visibleFrame(int index) {
    if (index < 0 || frames.isEmpty) return null;
    var i = math.min(index, frames.length - 1);
    while (i > 0 && frames[i].held && frames[i].strokes.isEmpty) i--;
    return frames[i];
  }

  Map<String, dynamic> toJson() => {
    'name': name, 'fps': fps, 'onionBefore': onionBefore, 'onionAfter': onionAfter,
    'onionSkin': onionSkin, 'loop': loop, 'frames': frames.map((f) => f.toJson()).toList(),
  };
  static FrameAnimationTrack fromJson(Map raw) {
    final t = FrameAnimationTrack(fps: (raw['fps'] as num?)?.toInt() ?? 24, name: raw['name'] as String? ?? 'Frame Animation')
      ..onionBefore = (raw['onionBefore'] as num?)?.toInt() ?? 2
      ..onionAfter = (raw['onionAfter'] as num?)?.toInt() ?? 2
      ..onionSkin = raw['onionSkin'] as bool? ?? true
      ..loop = raw['loop'] as bool? ?? false;
    t.frames.addAll([for (final f in (raw['frames'] as List? ?? const [])) ExposureFrame.fromJson(f as Map)]);
    return t;
  }
}
