// Re-slice assets/library/* spritesheets into clean uniform grid cells.
// Run: dart run tools/slice_library.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

const libraryDir = 'assets/library';

/// Manual overrides when auto-detect picks the wrong grid (cols x rows).
const gridOverrides = <String, (int, int)>{
  'faces': (7, 5),
  'eyes': (7, 5),
  'hair': (7, 5),
  'hair_advanced': (7, 5),
  'expressions': (6, 5),
  'clothes': (7, 4),
  'bodies': (5, 4),
  'beards': (5, 4),
  'accessories': (5, 4),
  'hands_feet': (5, 4),
  'weapons': (5, 4),
  'backgrounds': (4, 3),
  'environments': (4, 3),
  'scenes': (4, 3),
  'vehicles': (4, 3),
  'creatures': (5, 4),
  'objects': (5, 4),
  'fx': (5, 4),
  'poses': (5, 5),
  'transformations': (4, 3),
  'univers': (4, 3),
};

(int cols, int rows)? bestGrid(int w, int h, int targetCells) {
  (int, int)? best;
  var bestScore = double.infinity;
  for (var cols = 1; cols <= targetCells; cols++) {
    if (targetCells % cols != 0) continue;
    final rows = targetCells ~/ cols;
    if (w % cols != 0 || h % rows != 0) continue;
    final cw = w / cols;
    final ch = h / rows;
    final score = (cw - ch).abs() + (cw * ch) / 10000;
    if (score < bestScore) {
      bestScore = score;
      best = (cols, rows);
    }
  }
  return best;
}

void sliceSheet(File sheet, String base, int cols, int rows) {
  final bytes = sheet.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Skip (decode failed): ${sheet.path}');
    return;
  }
  final w = decoded.width;
  final h = decoded.height;
  final cellW = w ~/ cols;
  final cellH = h ~/ rows;
  final dir = sheet.parent;
  final old = dir.listSync().whereType<File>().where((f) => f.path.contains('${base}_cell_'));
  for (final f in old) {
    f.deleteSync();
  }
  var n = 0;
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      n++;
      final crop = img.copyCrop(
        decoded,
        x: col * cellW,
        y: row * cellH,
        width: cellW,
        height: cellH,
      );
      final out = File('${dir.path}${Platform.pathSeparator}${base}_cell_${n.toString().padLeft(2, '0')}.png');
      out.writeAsBytesSync(img.encodePng(crop));
    }
  }
  stdout.writeln('$base: ${cols}x$rows = $n cells (${cellW}x$cellH px each) from ${w}x$h');
}

void main() {
  final dir = Directory(libraryDir);
  if (!dir.existsSync()) {
    stderr.writeln('Missing $libraryDir');
    exit(1);
  }
  final sheets = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.png') && !f.uri.pathSegments.last.contains('_cell_'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final sheet in sheets) {
    final name = sheet.uri.pathSegments.last;
    final base = name.replaceAll('.png', '');
    final existingCells = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('${base}_cell_'))
        .length;
    final target = existingCells > 0 ? existingCells : (gridOverrides[base]?.$1 ?? 1) * (gridOverrides[base]?.$2 ?? 1);

    late int cols;
    late int rows;
    if (gridOverrides.containsKey(base)) {
      cols = gridOverrides[base]!.$1;
      rows = gridOverrides[base]!.$2;
    } else {
      final bytes = sheet.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) continue;
      final grid = bestGrid(decoded.width, decoded.height, target);
      if (grid == null) {
        stderr.writeln('No grid for $base (${decoded.width}x${decoded.height}, target=$target)');
        continue;
      }
      cols = grid.$1;
      rows = grid.$2;
    }
    sliceSheet(sheet, base, cols, rows);
  }
  stdout.writeln('Library re-slice complete.');
}
