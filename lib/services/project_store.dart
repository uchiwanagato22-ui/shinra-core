import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rig.dart';

class ProjectStore {
  static const key = 'shinra_project_v1';
  static Future<void> save(ProjectState p) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {'image': p.importedImagePath, 'expression': p.expression, 'camera': [p.camera.x, p.camera.y, p.camera.zoom, p.camera.rotation], 'parts': [for (final x in p.parts) {'id': x.id, 'bone': x.boneId, 'visible': x.visible}], 'bones': [for (final b in p.bones) {'id': b.id, 'x': b.x, 'y': b.y, 'r': b.rotation, 's': b.scale}]};
    await prefs.setString(key, jsonEncode(data));
    p.status = 'Project saved'; p.notifyListeners();
  }
  static Future<void> load(ProjectState p) async {
    final prefs = await SharedPreferences.getInstance(); final raw = prefs.getString(key); if (raw == null) { p.status = 'No saved project'; p.notifyListeners(); return; }
    final d = jsonDecode(raw) as Map<String, dynamic>; p.importedImagePath = (d['image'] as String?) ?? ''; p.expression = (d['expression'] as String?) ?? 'Neutral';
    final cam = (d['camera'] as List?)?.cast<num>(); if (cam != null && cam.length == 4) { p.camera.x = cam[0].toDouble(); p.camera.y = cam[1].toDouble(); p.camera.zoom = cam[2].toDouble(); p.camera.rotation = cam[3].toDouble(); }
    for (final item in (d['bones'] as List? ?? const [])) { final m = Map<String, dynamic>.from(item); final b = p.bones.where((x) => x.id == m['id']).firstOrNull; if (b != null) { b.x = (m['x'] as num).toDouble(); b.y = (m['y'] as num).toDouble(); b.rotation = (m['r'] as num).toDouble(); b.scale = (m['s'] as num).toDouble(); } }
    for (final item in (d['parts'] as List? ?? const [])) { final m = Map<String, dynamic>.from(item); final part = p.parts.where((x) => x.id == m['id']).firstOrNull; if (part != null) { part.boneId = m['bone'] as String; part.visible = m['visible'] as bool; } }
    p.status = 'Project loaded'; p.notifyListeners();
  }
}

extension FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
