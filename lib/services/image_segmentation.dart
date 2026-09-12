import 'dart:io';
import 'package:image/image.dart' as img;

/// Looks at edge density per horizontal row of the uploaded image to find
/// where the head ends and where the legs begin — a real (if simple)
/// computer-vision heuristic instead of a fixed proportion grid. Left/right
/// splits and hand/feet regions still use fixed proportions afterwards
/// (reliably separating those needs real pose estimation, out of scope
/// here) — this only improves the vertical head/torso/legs boundaries,
/// which are usually the most visible edge signal in a portrait.
///
/// Falls back to the same defaults as before if the image gives no clear
/// signal (flat art, solid colors, unusual pose) — never throws, never
/// blocks the manual "Set region" workflow.
class ImageSegmentation {
  static Future<({double headSplit, double legSplit})> findBoundaries(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return (headSplit: .18, legSplit: .52);

      final small = img.copyResize(decoded, width: 80);
      final gray = img.grayscale(small);
      final h = gray.height, w = gray.width;
      if (h < 6 || w < 6) return (headSplit: .18, legSplit: .52);

      final rowEdge = List<double>.filled(h, 0);
      for (var y = 1; y < h - 1; y++) {
        var sum = 0.0;
        for (var x = 1; x < w - 1; x++) {
          final gx = gray.getPixel(x + 1, y).r - gray.getPixel(x - 1, y).r;
          final gy = gray.getPixel(x, y + 1).r - gray.getPixel(x, y - 1).r;
          sum += gx.abs() + gy.abs();
        }
        rowEdge[y] = sum / w;
      }

      final smooth = List<double>.filled(h, 0);
      for (var y = 0; y < h; y++) {
        var s = 0.0;
        var c = 0;
        for (var k = -2; k <= 2; k++) {
          final yy = y + k;
          if (yy >= 0 && yy < h) { s += rowEdge[yy]; c++; }
        }
        smooth[y] = c == 0 ? 0 : s / c;
      }

      double findTrough(int from, int to) {
        if (from >= to) return (from / h);
        var bestY = (from + to) ~/ 2;
        var bestV = double.infinity;
        for (var y = from; y < to; y++) {
          if (smooth[y] < bestV) { bestV = smooth[y]; bestY = y; }
        }
        return bestY / h;
      }

      final headSplit = findTrough((h * .08).round(), (h * .30).round());
      final legSplit = findTrough((h * .42).round(), (h * .68).round());
      return (headSplit: headSplit.clamp(.10, .32), legSplit: legSplit.clamp(.38, .70));
    } catch (_) {
      // Any decode/read failure: same safe defaults, never crash the UI.
      return (headSplit: .18, legSplit: .52);
    }
  }
}
