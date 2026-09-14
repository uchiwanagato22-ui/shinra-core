import '../models/rig.dart';
import 'animation_rig_sync.dart';
import 'animation_loader.dart';

/// Lightweight end-to-end validator kept in sync with the live rig model.
class PipelineValidator {
  static Future<ValidationReport> validateComplete({
    required CharacterAppearance appearance,
    required List<Bone> skeleton,
    required Map<String, CharacterPart> parts,
    required String selectedAnimationId,
  }) async {
    final report = ValidationReport()..timestamp = DateTime.now();
    _validateAppearance(appearance, report);
    _validateSkeleton(skeleton, report);
    _validateParts(parts, skeleton, report);
    try {
      final animation = await AnimationManager().getAnimation(selectedAnimationId);
      final errors = AnimationRigSync.validate(animation: animation, skeleton: skeleton, parts: parts);
      for (final e in errors) report.addError(e);
      _validateTimeline(animation, report);
      for (var i=0; i<=10; i++) {
        AnimationRigSync.interpolateAt(animation: animation, time: animation.duration*i/10, parts: parts);
      }
      report.addPass('Animation sync test: 11/11 samples evaluated');
    } catch (e) {
      report.addError('Failed to load/test animation "$selectedAnimationId": $e');
    }
    return report;
  }

  static void _validateAppearance(CharacterAppearance a, ValidationReport r) {
    if (a.isProcedural()) {
      if (a.skinColor.a == 0 || a.hairColor.a == 0) r.addWarning('Procedural appearance contains transparent colors');
      r.addPass('Procedural appearance valid');
    } else if (a.isImageUpload()) {
      if (a.uploadedImagePath == null && a.uploadedImageBytes == null) r.addError('Image-upload appearance has no image');
      else r.addPass('Imported image appearance configured');
    } else if (a.isDrawn()) {
      if (a.drawnImageBytes == null) r.addError('Drawn appearance has no drawing data');
      else r.addPass('Drawn appearance configured');
    } else { r.addPass('Hybrid appearance configured'); }
  }

  static void _validateSkeleton(List<Bone> bones, ValidationReport r) {
    if (bones.isEmpty) { r.addError('Skeleton is empty'); return; }
    final ids=<String>{};
    for (final b in bones) {
      if (!ids.add(b.id)) r.addError('Duplicate bone id: ${b.id}');
      if (b.parentId != null && !bones.any((p)=>p.id==b.parentId)) r.addError('Bone "${b.id}" references missing parent "${b.parentId}"');
    }
    r.addPass('Skeleton valid: ${bones.length} bones');
  }

  static void _validateParts(Map<String, CharacterPart> parts, List<Bone> bones, ValidationReport r) {
    final ids=bones.map((b)=>b.id).toSet();
    for (final p in parts.values) {
      if (!ids.contains(p.boneId)) r.addError('Part "${p.id}" bound to missing bone "${p.boneId}"');
    }
    r.addPass('Parts valid: ${parts.length} parts');
  }

  static void _validateTimeline(AnimationClip a, ValidationReport r) {
    if (a.duration <= 0) r.addError('Animation duration is not positive');
    if (a.tracks.isEmpty) r.addWarning('Animation "${a.name}" has no bone tracks');
    var count=0;
    for (final entry in a.tracks.entries) {
      if (entry.value.keys.isEmpty) { r.addWarning('Track "${entry.key}" is empty'); continue; }
      count += entry.value.keys.length;
      double prev=-1;
      for (final k in entry.value.keys) {
        if (k.time < 0 || k.time > a.duration) r.addError('Keyframe time ${k.time} outside animation duration');
        if (k.time < prev) r.addError('Keyframes out of order on ${entry.key}');
        prev=k.time;
      }
    }
    r.addPass('Timeline valid: ${a.tracks.length} tracks, $count keyframes');
  }
}

class ValidationReport {
  final List<String> passes=[];
  final List<String> warnings=[];
  final List<String> errors=[];
  late DateTime timestamp;
  bool get isValid=>errors.isEmpty;
  bool get hasWarnings=>warnings.isNotEmpty;
  bool get isReadyForExport=>errors.isEmpty;
  int get totalIssues=>warnings.length+errors.length;
  void addPass(String m)=>passes.add(m);
  void addWarning(String m)=>warnings.add(m);
  void addError(String m)=>errors.add(m);
  String getSummary() { final b=StringBuffer()..writeln('=== VALIDATION REPORT ===')..writeln('Time: $timestamp')..writeln('Status: ${isValid ? 'VALID':'INVALID'}')..writeln('Passed: ${passes.length}, Warnings: ${warnings.length}, Errors: ${errors.length}'); return b.toString(); }
  Map<String,dynamic> toJson()=>{'timestamp':timestamp.toIso8601String(),'isValid':isValid,'passes':passes,'warnings':warnings,'errors':errors,'summary':getSummary()};
}

class E2ETestResult {
  bool success=false;
  final List<String> logs=[];
  final List<String> logErrors=[];
  String details='';
  void log(String m)=>logs.add(m);
  void error(String m)=>logErrors.add(m);
  @override String toString()=> 'E2E TEST RESULT: ${success ? 'PASSED':'FAILED'}\n$details';
}

class E2ETestRunner {
  static Future<E2ETestResult> runTest() async {
    final r=E2ETestResult();
    try {
      final skeleton=defaultBones();
      final parts={for(final p in defaultParts()) p.id:p};
      final appearance=CharacterAppearance();
      final report=await PipelineValidator.validateComplete(appearance:appearance,skeleton:skeleton,parts:parts,selectedAnimationId:'walk_forward');
      r.success=report.isValid; r.details=report.getSummary();
      if(!r.success) r.error(report.errors.join('; '));
    } catch(e) { r.error('$e'); }
    return r;
  }
}
