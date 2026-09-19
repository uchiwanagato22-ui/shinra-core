import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'image_segmentation.dart';

/// Converts a single 2D character image into actual transparent puppet pieces.
///
/// Important difference from the old implementation: this does NOT paint
/// rectangular/elliptical pictures over the procedural character.  It builds
/// a foreground mask, assigns foreground pixels to the nearest anatomical
/// segment, crops those pixels, and records the exact source-space anchor that
/// belongs to the corresponding bone.  The viewport can therefore animate the
/// imported artwork itself.
class AutoRigCutoutService {
  static const _partIds = <String>[
    'face', 'hair', 'body', 'clothes',
    'arm_l', 'forearm_l', 'hand_l', 'arm_r', 'forearm_r', 'hand_r',
    'leg_l', 'shin_l', 'shoes_l', 'leg_r', 'shin_r', 'shoes_r',
  ];

  static Future<AutoRigBuildResult> build(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final source = img.decodeImage(bytes);
    if (source == null) throw const FormatException('Image illisible');

    final bounds = await ImageSegmentation.findBoundaries(sourcePath);
    final mask = _foregroundMask(source);
    final outDir = await getApplicationSupportDirectory();
    final dir = Directory('${outDir.path}/shinra/puppets/${DateTime.now().microsecondsSinceEpoch}');
    await dir.create(recursive: true);

    final h = source.height.toDouble(), w = source.width.toDouble();
    final skeleton = _skeleton(bounds.headSplit, bounds.legSplit);

    // Research-derived cutout principle:
    // assign every foreground pixel to ONE layer, rather than extracting
    // overlapping rectangles. This prevents body/clothes/face from duplicating
    // the same pixels and makes the resulting puppet compositable.
    final assignment = _assignPixels(source, mask, skeleton, w, h);

    final result = <String, String>{};
    final crops = <String, List<double>>{};
    final offsets = <String, List<double>>{};
    final anchors = <String, List<double>>{};
    final meshFiles = <String, String>{};

    for (final id in _partIds) {
      final spec = skeleton[id];
      if (spec == null) continue;
      final piece = _extractAssigned(source, assignment, id, spec, w, h);
      if (piece == null) continue;

      final path = '${dir.path}/$id.png';
      await File(path).writeAsBytes(img.encodePng(piece.image));
      result[id] = path;
      crops[id] = [piece.left / w, piece.top / h, piece.width / w, piece.height / h];
      offsets[id] = [
        (piece.anchorX - piece.centerX) * .6,
        (piece.anchorY - piece.centerY) * .6,
      ];
      anchors[id] = [piece.anchorX / w, piece.anchorY / h];

      // A lightweight, renderer-independent skinning mesh is generated for
      // each cutout. The viewport can consume this later for smooth bends;
      // rigid bone rotation remains the fallback.
      final mesh = _buildSkinMesh(piece, spec, w, h);
      final meshPath = '${dir.path}/$id.mesh.json';
      await File(meshPath).writeAsString(jsonEncode(mesh));
      meshFiles[id] = meshPath;
    }

    await File('${dir.path}/rig.json').writeAsString(jsonEncode({
      'sourceWidth': source.width,
      'sourceHeight': source.height,
      'crops': crops,
      'offsets': offsets,
      'anchors': anchors,
      'meshes': meshFiles,
      'maskMode': mask.mode,
      'assignment': 'single-owner-nearest-anatomical-segment-v1',
    }));

    return AutoRigBuildResult(
      cutouts: result,
      crops: crops,
      offsets: offsets,
      rigMetadataPath: '${dir.path}/rig.json',
    );
  }

  static Map<String, String> _assignPixels(
      img.Image source, _Mask mask, Map<String, _Segment> skeleton, double w, double h) {
    final out = <String, String>{};
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (!mask.test(x, y)) continue;
        final nx = x / w, ny = y / h;
        String? bestId;
        var bestScore = double.infinity;
        for (final id in _partIds) {
          final segment = skeleton[id];
          if (segment == null || !segment.contains(nx, ny)) continue;
          final d = segment.distance(nx, ny);
          // Prefer specific facial/hand/foot regions over broad body boxes.
          final score = d - _specificityBonus(id);
          if (score < bestScore) {
            bestScore = score;
            bestId = id;
          }
        }
        if (bestId != null) out['$x,$y'] = bestId;
      }
    }
    return out;
  }

  static double _specificityBonus(String id) {
    if (id == 'face' || id == 'hair') return .16;
    if (id.contains('hand') || id.contains('shoes')) return .12;
    if (id.contains('forearm') || id.contains('shin')) return .06;
    if (id == 'clothes') return -.02;
    if (id == 'body') return -.05;
    return 0;
  }

  static double _segmentDistance(_Segment s, double x, double y) {
    if (s.boxMode) {
      final dx = math.max(math.max(s.left - x, 0), x - s.right);
      final dy = math.max(math.max(s.top - y, 0), y - s.bottom);
      return math.sqrt(dx * dx + dy * dy);
    }
    final dx = s.bx - s.ax, dy = s.by - s.ay;
    final len2 = dx * dx + dy * dy;
    final u = len2 == 0 ? 0.0 : ((x - s.ax) * dx + (y - s.ay) * dy) / len2;
    final q = u.clamp(0.0, 1.0);
    final px = s.ax + q * dx, py = s.ay + q * dy;
    return math.sqrt(math.pow(x - px, 2) + math.pow(y - py, 2));
  }

  static _AssignedPiece? _extractAssigned(
      img.Image source, Map<String, String> assignment, String id, _Segment segment, double w, double h) {
    var left = source.width, top = source.height, right = -1, bottom = -1;
    for (final e in assignment.entries) {
      if (e.value != id) continue;
      final p = e.key.split(',');
      final x = int.parse(p[0]), y = int.parse(p[1]);
      left = math.min(left, x); top = math.min(top, y);
      right = math.max(right, x); bottom = math.max(bottom, y);
    }
    if (right < left || bottom < top) return null;

    const pad = 4;
    left = math.max(0, left - pad); top = math.max(0, top - pad);
    right = math.min(source.width - 1, right + pad);
    bottom = math.min(source.height - 1, bottom + pad);

    final out = img.Image(width: right - left + 1, height: bottom - top + 1, numChannels: 4);
    var any = false;
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        if (assignment['$x,$y'] == id) {
          final p = source.getPixel(x, y);
          out.setPixelRgba(x - left, y - top, p.r, p.g, p.b, p.a);
          if (p.a > 2) any = true;
        } else {
          out.setPixelRgba(x - left, y - top, 0, 0, 0, 0);
        }
      }
    }
    if (!any) return null;
    final anchor = segment.anchor;
    return _AssignedPiece(
      out, left, top, out.width, out.height,
      anchor.x * w, anchor.y * h,
      (left + right) / 2, (top + bottom) / 2,
    );
  }

  static Map<String, dynamic> _buildSkinMesh(
      _AssignedPiece piece, _Segment segment, double sourceW, double sourceH) {
    final cols = 5, rows = 7;
    final vertices = <Map<String, dynamic>>[];
    final indices = <int>[];
    final width = piece.width.toDouble(), height = piece.height.toDouble();

    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= cols; x++) {
        final u = x / cols, v = y / rows;
        final px = piece.left + u * (width - 1);
        final py = piece.top + v * (height - 1);
        final nx = px / sourceW, ny = py / sourceH;
        final d = _segmentDistance(segment, nx, ny);
        final weight = (1.0 - (d / .22)).clamp(0.0, 1.0);
        vertices.add({'x': u, 'y': v, 'u': u, 'v': v, 'boneWeight': weight});
      }
    }
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final a = y * (cols + 1) + x;
        final b = a + 1, c = a + cols + 1, d = c + 1;
        indices.addAll([a, b, c, b, d, c]);
      }
    }
    return {
      'version': 1,
      'type': 'grid-skin',
      'columns': cols,
      'rows': rows,
      'vertices': vertices,
      'indices': indices,
      'sourceCrop': [piece.left, piece.top, piece.width, piece.height],
    };
  }
}

class AutoRigBuildResult {
  const AutoRigBuildResult({required this.cutouts, required this.crops, required this.offsets, required this.rigMetadataPath});
  final Map<String, String> cutouts;
  final Map<String, List<double>> crops;
  final Map<String, List<double>> offsets;
  final String rigMetadataPath;
}

class _Mask {
  _Mask(this.test, this.mode);
  final bool Function(int x, int y) test;
  final String mode;
}

class _Point { const _Point(this.x, this.y); final double x, y; }

class _Segment {
  _Segment.point(this.ax, this.ay, this.radius) : bx = ax, by = ay, left = ax, top = ay, right = ax, bottom = ay, boxMode = false;
  _Segment.line(this.ax, this.ay, this.bx, this.by, this.radius) : left = math.min(ax, bx), top = math.min(ay, by), right = math.max(ax, bx), bottom = math.max(ay, by), boxMode = false;
  _Segment.box(this.left, this.top, this.right, this.bottom) : ax = (left + right) / 2, ay = (top + bottom) / 2, bx = ax, by = bottom, radius = 0, boxMode = true;
  final double ax, ay, bx, by, radius, left, top, right, bottom;
  final bool boxMode;
  _Point get anchor => _Point(ax, ay);
  double distance(double x, double y) {
    if (boxMode) {
      final dx = math.max(math.max(left - x, 0), x - right);
      final dy = math.max(math.max(top - y, 0), y - bottom);
      return math.sqrt(dx * dx + dy * dy);
    }
    final dx = bx - ax, dy = by - ay, len2 = dx * dx + dy * dy;
    final u = len2 == 0 ? 0.0 : ((x - ax) * dx + (y - ay) * dy) / len2;
    final q = u.clamp(0.0, 1.0);
    final px = ax + q * dx, py = ay + q * dy;
    return math.sqrt(math.pow(x - px, 2) + math.pow(y - py, 2));
  }

  bool contains(double x, double y) {
    if (boxMode) return x >= left && x <= right && y >= top && y <= bottom;
    final dx = bx - ax, dy = by - ay, len2 = dx * dx + dy * dy;
    final u = len2 == 0 ? 0.0 : ((x - ax) * dx + (y - ay) * dy) / len2;
    final q = u.clamp(0.0, 1.0);
    final px = ax + q * dx, py = ay + q * dy;
    return math.sqrt(math.pow(x - px, 2) + math.pow(y - py, 2)) <= radius;
  }
}

class _AssignedPiece {
  _AssignedPiece(this.image, this.left, this.top, this.width, this.height, this.anchorX, this.anchorY, this.centerX, this.centerY);
  final img.Image image;
  final int left, top, width, height;
  final double anchorX, anchorY, centerX, centerY;
}
