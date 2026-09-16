import 'dart:convert';
import 'package:flutter/material.dart' show Color, Rect;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rig.dart';

/// Persists everything the user can actually create in the editor. Earlier
/// versions only saved rest-pose bones, part visibility, camera and the
/// image/expression — captured keyframes, FX, audio cues, appearance colors
/// and image-part crop regions were silently lost on reload.
class ProjectStore {
  static const key = 'shinra_project_v1';

  static Future<void> save(ProjectState p) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'image': p.importedImagePath,
      'useImageAsBody': p.useImageAsBody,
      'expression': p.expression,
      'mouthShape': p.mouthShape,
      'eyeLookX': p.eyeLookX,
      'eyeLookY': p.eyeLookY,
      'browLeft':p.browLeft,'browRight':p.browRight,'eyeOpenLeft':p.eyeOpenLeft,'eyeOpenRight':p.eyeOpenRight,'pupilScale':p.pupilScale,'mouthWidth':p.mouthWidth,'mouthOpen':p.mouthOpen,'mouthCornerLeft':p.mouthCornerLeft,'mouthCornerRight':p.mouthCornerRight,'jawOpen':p.jawOpen,'headTilt':p.headTilt,'facialRigEnabled':p.facialRigEnabled,
      'skin': p.skinColor.toARGB32(),
      'hair': p.hairColor.toARGB32(),
      'eyes': p.eyeColor.toARGB32(),
      'clothes': p.clothesColor.toARGB32(),
      'hairStyle': p.hairStyle,
      'eyeShape': p.eyeShape,
      'outfitStyle': p.outfitStyle,
      'background': p.background,
      'accGlasses': p.accGlasses,
      'accHeadband': p.accHeadband,
      'accScarf': p.accScarf,
      'accHat': p.accHat,
      'accGloves': p.accGloves,
      'accBelt': p.accBelt,
      'selectedAnimationId': p.selectedAnimationId,
      'camera': [p.camera.x, p.camera.y, p.camera.zoom, p.camera.rotation],
      'parts': [for (final x in p.parts) {'id': x.id, 'bone': x.boneId, 'visible': x.visible, 'crop': x.crop == null ? null : [x.crop!.left, x.crop!.top, x.crop!.width, x.crop!.height]}],
      'bones': [for (final b in p.bones) {'id': b.id, 'x': b.x, 'y': b.y, 'r': b.rotation, 's': b.scale}],
      'animations': [
        for (final clip in p.animations)
          {
            'id': clip.id,
            'faceTrack': [for(final k in clip.faceTrack.keys) [k.time,k.browLeft,k.browRight,k.eyeOpenLeft,k.eyeOpenRight,k.pupilX,k.pupilY,k.mouthWidth,k.mouthOpen,k.mouthCornerLeft,k.mouthCornerRight,k.jawOpen,k.headTilt,k.easing.index]],
            'tracks': {
              for (final entry in clip.tracks.entries)
                entry.key: [for (final k in entry.value.keys) [k.time, k.x, k.y, k.rotation, k.scale, k.easing.index]],
            },
          },
      ],
      'fx': [for (final e in p.fx) {'id': e.id, 'name': e.name, 'time': e.time, 'clip': e.clipId}],
      'audio': [for (final e in p.audio) {'id': e.id, 'name': e.name, 'time': e.time, 'clip': e.clipId}],
      'dialogue': [for (final d in p.dialogue) {'id': d.id, 'actor': d.actorId, 'text': d.text, 'time': d.time, 'duration': d.duration, 'clip': d.clipId}],
    };
    await prefs.setString(key, jsonEncode(data));
    p.status = 'Project saved';
    p.refresh();
  }

  static Future<void> load(ProjectState p) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) { p.status = 'No saved project'; p.refresh(); return; }
    final d = jsonDecode(raw) as Map<String, dynamic>;
    p.importedImagePath = (d['image'] as String?) ?? '';
    p.useImageAsBody = (d['useImageAsBody'] as bool?) ?? false;
    p.expression = (d['expression'] as String?) ?? 'Neutral';
    p.mouthShape = (d['mouthShape'] as String?) ?? 'Auto';
    p.eyeLookX = ((d['eyeLookX'] as num?) ?? 0).toDouble().clamp(-1, 1).toDouble();
    p.eyeLookY = ((d['eyeLookY'] as num?) ?? 0).toDouble().clamp(-1, 1).toDouble();
    p.browLeft=((d['browLeft'] as num?)??0).toDouble();p.browRight=((d['browRight'] as num?)??0).toDouble();p.eyeOpenLeft=((d['eyeOpenLeft'] as num?)??1).toDouble();p.eyeOpenRight=((d['eyeOpenRight'] as num?)??1).toDouble();p.pupilScale=((d['pupilScale'] as num?)??1).toDouble();p.mouthWidth=((d['mouthWidth'] as num?)??1).toDouble();p.mouthOpen=((d['mouthOpen'] as num?)??0).toDouble();p.mouthCornerLeft=((d['mouthCornerLeft'] as num?)??0).toDouble();p.mouthCornerRight=((d['mouthCornerRight'] as num?)??0).toDouble();p.jawOpen=((d['jawOpen'] as num?)??0).toDouble();p.headTilt=((d['headTilt'] as num?)??0).toDouble();p.facialRigEnabled=(d['facialRigEnabled'] as bool?)??true;
    if (d['skin'] != null) p.skinColor = Color(d['skin'] as int);
    if (d['hair'] != null) p.hairColor = Color(d['hair'] as int);
    if (d['eyes'] != null) p.eyeColor = Color(d['eyes'] as int);
    if (d['clothes'] != null) p.clothesColor = Color(d['clothes'] as int);
    p.hairStyle = (d['hairStyle'] as String?) ?? hairStyles.first;
    p.eyeShape = (d['eyeShape'] as String?) ?? eyeShapes.first;
    p.outfitStyle = (d['outfitStyle'] as String?) ?? outfitStyles.first;
    p.background = (d['background'] as String?) ?? backgroundStyles.first;
    p.accGlasses = (d['accGlasses'] as bool?) ?? false;
    p.accHeadband = (d['accHeadband'] as bool?) ?? false;
    p.accScarf = (d['accScarf'] as bool?) ?? false;
    p.accHat = (d['accHat'] as bool?) ?? false;
    p.accGloves = (d['accGloves'] as bool?) ?? false;
    p.accBelt = (d['accBelt'] as bool?) ?? false;
    final cam = (d['camera'] as List?)?.cast<num>();
    if (cam != null && cam.length == 4) { p.camera.x = cam[0].toDouble(); p.camera.y = cam[1].toDouble(); p.camera.zoom = cam[2].toDouble(); p.camera.rotation = cam[3].toDouble(); }
    for (final item in (d['bones'] as List? ?? const [])) {
      final m = Map<String, dynamic>.from(item);
      final b = p.bones.where((x) => x.id == m['id']).firstOrNull;
      if (b != null) { b.x = (m['x'] as num).toDouble(); b.y = (m['y'] as num).toDouble(); b.rotation = (m['r'] as num).toDouble(); b.scale = (m['s'] as num).toDouble(); }
    }
    for (final item in (d['parts'] as List? ?? const [])) {
      final m = Map<String, dynamic>.from(item);
      final part = p.parts.where((x) => x.id == m['id']).firstOrNull;
      if (part == null) continue;
      part.boneId = m['bone'] as String;
      part.visible = m['visible'] as bool;
      final crop = (m['crop'] as List?)?.cast<num>();
      part.crop = crop == null ? null : Rect.fromLTWH(crop[0].toDouble(), crop[1].toDouble(), crop[2].toDouble(), crop[3].toDouble());
    }
    for (final item in (d['animations'] as List? ?? const [])) {
      final m = Map<String, dynamic>.from(item);
      final clip = p.animations.where((c) => c.id == m['id']).firstOrNull;
      if (clip == null) continue;
      clip.faceTrack.keys.clear();
      for(final raw in (m['faceTrack'] as List? ?? const [])){final k=(raw as List).cast<num>();if(k.length>=13){final ei=k.length>13?k[13].toInt():KeyframeEasing.smooth.index;final e=ei>=0&&ei<KeyframeEasing.values.length?KeyframeEasing.values[ei]:KeyframeEasing.smooth;clip.faceTrack.keys.add(FacePoseKeyframe(time:k[0].toDouble(),browLeft:k[1].toDouble(),browRight:k[2].toDouble(),eyeOpenLeft:k[3].toDouble(),eyeOpenRight:k[4].toDouble(),pupilX:k[5].toDouble(),pupilY:k[6].toDouble(),mouthWidth:k[7].toDouble(),mouthOpen:k[8].toDouble(),mouthCornerLeft:k[9].toDouble(),mouthCornerRight:k[10].toDouble(),jawOpen:k[11].toDouble(),headTilt:k[12].toDouble(),easing:e));}}
      clip.faceTrack.keys.sort((a,b)=>a.time.compareTo(b.time));
      final tracks = Map<String, dynamic>.from(m['tracks'] as Map? ?? const {});
      for (final entry in tracks.entries) {
        final track = clip.track(entry.key);
        track.keys.clear();
        for (final raw in (entry.value as List)) {
          final k = (raw as List).cast<num>();
          // Older saved projects have five values. New projects append the
          // easing index, while old ones safely retain the classic smooth
          // motion instead of failing to load.
          final easingIndex = k.length > 5 ? k[5].toInt() : KeyframeEasing.smooth.index;
          final easing = easingIndex >= 0 && easingIndex < KeyframeEasing.values.length
              ? KeyframeEasing.values[easingIndex]
              : KeyframeEasing.smooth;
          track.keys.add(PoseKeyframe(time: k[0].toDouble(), x: k[1].toDouble(), y: k[2].toDouble(), rotation: k[3].toDouble(), scale: k[4].toDouble(), easing: easing));
        }
        track.keys.sort((a, b) => a.time.compareTo(b.time));
      }
    }
    p.fx..clear()..addAll([for (final item in (d['fx'] as List? ?? const [])) FxEvent(id: item['id'] as String, name: item['name'] as String, time: (item['time'] as num).toDouble(), clipId: item['clip'] as String)]);
    p.audio..clear()..addAll([for (final item in (d['audio'] as List? ?? const [])) AudioCue(id: item['id'] as String, name: item['name'] as String, time: (item['time'] as num).toDouble(), clipId: item['clip'] as String)]);
    p.dialogue..clear()..addAll([for (final item in (d['dialogue'] as List? ?? const [])) DialogueCue(id: item['id'] as String, actorId: item['actor'] as String, text: item['text'] as String, time: (item['time'] as num).toDouble(), duration: (item['duration'] as num).toDouble(), clipId: item['clip'] as String)]);
    if (d['selectedAnimationId'] != null && p.animations.any((c) => c.id == d['selectedAnimationId'])) p.selectedAnimationId = d['selectedAnimationId'] as String;
    p.status = 'Project loaded';
    p.refresh();
  }
}

extension FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
