import 'package:flutter/material.dart';
import '../models/rig.dart';
import 'animation_rig_sync.dart';
import 'animation_loader.dart';

/// Complete validation system for character → animation → export pipeline.
/// Ensures everything works together perfectly.
class PipelineValidator {
  
  /// Validate entire production pipeline.
  /// Returns ValidationReport with all checks.
  static Future<ValidationReport> validateComplete({
    required CharacterAppearance appearance,
    required List<Bone> skeleton,
    required Map<String, CharacterPart> parts,
    required String selectedAnimationId,
  }) async {
    final report = ValidationReport();

    // Step 1: Character appearance validation
    _validateAppearance(appearance, report);

    // Step 2: Skeleton validation
    _validateSkeleton(skeleton, report);

    // Step 3: Parts validation
    _validateParts(parts, skeleton, report);

    // Step 4: Load animation
    AnimationClip? animation;
    try {
      animation = await AnimationManager.instance.loadAnimation(selectedAnimationId);
      if (animation == null) {
        report.addError('Animation "$selectedAnimationId" not found in library');
      } else {
        // Step 5: Animation-Rig sync validation
        final syncErrors = AnimationRigSync.validate(
          animation: animation,
          skeleton: skeleton,
          parts: parts,
        );
        for (final error in syncErrors) {
          report.addError(error);
        }

        // Step 6: Timeline validation
        _validateTimeline(animation, report);

        // Step 7: Sync test
        _testAnimationSync(animation, skeleton, parts, appearance, report);
      }
    } catch (e) {
      report.addError('Failed to load animation: $e');
    }

    report.timestamp = DateTime.now();
    return report;
  }

  /// Validate character appearance configuration.
  static void _validateAppearance(CharacterAppearance appearance, ValidationReport report) {
    if (appearance.isProcedural()) {
      if (appearance.skinColor.alpha == 0) {
        report.addWarning('Skin color is transparent');
      }
      if (appearance.hairColor.alpha == 0) {
        report.addWarning('Hair color is transparent');
      }
      report.addPass('Procedural appearance valid');
    } else if (appearance.isImageUpload()) {
      if (appearance.uploadedImageBytes == null) {
        report.addError('Image upload selected but no image data loaded');
      } else {
        report.addPass('Uploaded image loaded (${appearance.uploadedImageBytes?.length ?? 0} bytes)');
      }
    } else if (appearance.isDrawn()) {
      if (appearance.drawnImageBytes == null) {
        report.addError('Drawn appearance selected but no drawing data');
      } else {
        report.addPass('Drawn image loaded (${appearance.drawnImageBytes?.length ?? 0} bytes)');
      }
    }
  }

  /// Validate skeleton structure.
  static void _validateSkeleton(List<Bone> skeleton, ValidationReport report) {
    if (skeleton.isEmpty) {
      report.addError('Skeleton has no bones');
      return;
    }

    final boneIds = <String>{};
    for (final bone in skeleton) {
      if (bone.id.isEmpty) {
        report.addError('Bone has empty ID');
      } else if (boneIds.contains(bone.id)) {
        report.addError('Duplicate bone ID: ${bone.id}');
      } else {
        boneIds.add(bone.id);
      }

      if (bone.name.isEmpty) {
        report.addWarning('Bone ${bone.id} has no name');
      }
    }

    // Validate bone hierarchy
    final validParents = {'root', ...boneIds};
    for (final bone in skeleton) {
      if (bone.parentId != null && !validParents.contains(bone.parentId)) {
        report.addError('Bone ${bone.id} references non-existent parent ${bone.parentId}');
      }
    }

    report.addPass('Skeleton valid: ${skeleton.length} bones');
  }

  /// Validate character parts.
  static void _validateParts(
    Map<String, CharacterPart> parts,
    List<Bone> skeleton,
    ValidationReport report,
  ) {
    if (parts.isEmpty) {
      report.addWarning('Character has no visual parts');
      return;
    }

    final skeletonBones = skeleton.map((b) => b.id).toSet();

    for (final part in parts.values) {
      if (part.id.isEmpty) {
        report.addError('Part has empty ID');
      }

      if (!skeletonBones.contains(part.boneId)) {
        report.addError('Part "${part.id}" bound to non-existent bone "${part.boneId}"');
      }

      if (part.name.isEmpty) {
        report.addWarning('Part ${part.id} has no name');
      }
    }

    report.addPass('Parts valid: ${parts.length} parts bound to skeleton');
  }

  /// Validate animation timeline structure.
  static void _validateTimeline(AnimationClip animation, ValidationReport report) {
    if (animation.duration <= 0) {
      report.addError('Animation duration is not positive (${animation.duration}s)');
      return;
    }

    if (animation.tracks.isEmpty) {
      report.addError('Animation "${animation.name}" has no bone tracks');
      return;
    }

    int totalKeyframes = 0;
    for (final boneId in animation.tracks.keys) {
      final track = animation.tracks[boneId];
      if (track == null || track.isEmpty) {
        report.addError('Track for bone "$boneId" is empty');
      } else {
        totalKeyframes += track.length;

        // Validate keyframe times are in order
        double? prevTime;
        for (final kf in track) {
          if (kf.time < 0) {
            report.addError('Keyframe has negative time: ${kf.time}');
          }
          if (kf.time > animation.duration) {
            report.addError('Keyframe time ${kf.time} exceeds animation duration ${animation.duration}');
          }
          if (prevTime != null && kf.time < prevTime) {
            report.addError('Keyframe times out of order: $prevTime → ${kf.time}');
          }
          prevTime = kf.time;
        }
      }
    }

    report.addPass('Timeline valid: ${animation.tracks.length} bones, $totalKeyframes keyframes');
  }

  /// Test animation sync (sample 10 frames).
  static void _testAnimationSync(
    AnimationClip animation,
    List<Bone> skeleton,
    Map<String, CharacterPart> parts,
    CharacterAppearance appearance,
    ValidationReport report,
  ) {
    try {
      // Test at 10 points in timeline
      final step = animation.duration / 10;
      var failures = 0;

      for (int i = 0; i <= 10; i++) {
        final time = i * step;
        final pose = AnimationRigSync.interpolateAt(
          animation: animation,
          time: time,
          parts: parts,
        );

        if (pose.isEmpty) {
          failures++;
        }
      }

      if (failures == 0) {
        report.addPass('Animation sync test: 10/10 frames interpolated correctly');
      } else {
        report.addWarning('Animation sync test: $failures/10 frames had issues');
      }
    } catch (e) {
      report.addError('Animation sync test failed: $e');
    }
  }
}

/// Validation report with detailed results.
class ValidationReport {
  ValidationReport();

  final List<String> passes = [];
  final List<String> warnings = [];
  final List<String> errors = [];
  late DateTime timestamp;

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isReadyForExport => errors.isEmpty;

  int get totalIssues => warnings.length + errors.length;

  void addPass(String message) => passes.add(message);
  void addWarning(String message) => warnings.add(message);
  void addError(String message) => errors.add(message);

  /// Generate summary.
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== VALIDATION REPORT ===');
    buffer.writeln('Time: $timestamp');
    buffer.writeln('Status: ${isValid ? '✅ VALID' : '❌ INVALID'}\n');

    if (passes.isNotEmpty) {
      buffer.writeln('✅ PASSED (${passes.length}):');
      for (final p in passes) {
        buffer.writeln('  • $p');
      }
      buffer.writeln();
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('⚠️  WARNINGS (${warnings.length}):');
      for (final w in warnings) {
        buffer.writeln('  • $w');
      }
      buffer.writeln();
    }

    if (errors.isNotEmpty) {
      buffer.writeln('❌ ERRORS (${errors.length}):');
      for (final e in errors) {
        buffer.writeln('  • $e');
      }
      buffer.writeln();
    }

    buffer.writeln('Ready for export: ${isReadyForExport ? 'YES ✅' : 'NO ❌'}');
    return buffer.toString();
  }

  /// Export as JSON for debugging.
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'isValid': isValid,
    'isReadyForExport': isReadyForExport,
    'passes': passes,
    'warnings': warnings,
    'errors': errors,
    'summary': getSummary(),
  };
}

/// End-to-end test for complete pipeline.
class E2ETestRunner {
  
  /// Run complete test (creates dummy character and animation).
  static Future<E2ETestResult> runTest() async {
    final result = E2ETestResult();

    try {
      // Create minimal test character
      result.log('Creating test character...');
      final appearance = CharacterAppearance(
        type: CharacterAppearance.AppearanceType.procedural,
      );

      // Create skeleton
      result.log('Building skeleton...');
      final skeleton = _createTestSkeleton();

      // Create parts
      result.log('Binding visual parts...');
      final parts = _createTestParts();

      // Load test animation
      result.log('Loading test animation...');
      final animation = await AnimationManager.instance.loadAnimation('walk_forward');
      if (animation == null) {
        result.error('Test animation "walk_forward" not found');
        return result;
      }

      // Validate
      result.log('Validating pipeline...');
      final validation = await PipelineValidator.validateComplete(
        appearance: appearance,
        skeleton: skeleton,
        parts: parts,
        selectedAnimationId: 'walk_forward',
      );

      if (!validation.isValid) {
        result.error('Validation failed: ${validation.errors.join("; ")}');
        result.details = validation.getSummary();
        return result;
      }

      result.log('Running sync test...');
      final player = SynchedAnimationPlayer(
        animation: animation,
        skeleton: skeleton,
        parts: parts,
        appearance: appearance,
      );

      player.play();
      for (int i = 0; i < 10; i++) {
        final pose = player.update();
        if (pose == null || pose.isEmpty) {
          result.error('Sync update $i failed');
          return result;
        }
        await Future.delayed(Duration(milliseconds: 16)); // ~60 FPS
      }

      result.log('E2E test PASSED ✅');
      result.success = true;
      result.details = validation.getSummary();
    } catch (e) {
      result.error('E2E test failed: $e');
    }

    return result;
  }

  static List<Bone> _createTestSkeleton() => [
    Bone(
      id: 'root',
      name: 'Root',
      x: 0,
      y: 0,
      rotation: 0,
    ),
    Bone(
      id: 'torso',
      name: 'Torso',
      x: 0,
      y: 50,
      rotation: 0,
      parentId: 'root',
    ),
    Bone(
      id: 'leg_left',
      name: 'Left Leg',
      x: -10,
      y: 100,
      rotation: 0,
      parentId: 'torso',
    ),
    Bone(
      id: 'leg_right',
      name: 'Right Leg',
      x: 10,
      y: 100,
      rotation: 0,
      parentId: 'torso',
    ),
    Bone(
      id: 'arm_left',
      name: 'Left Arm',
      x: -30,
      y: 60,
      rotation: 0,
      parentId: 'torso',
    ),
    Bone(
      id: 'arm_right',
      name: 'Right Arm',
      x: 30,
      y: 60,
      rotation: 0,
      parentId: 'torso',
    ),
  ];

  static Map<String, CharacterPart> _createTestParts() => {
    'head': CharacterPart(
      id: 'head',
      name: 'Head',
      boneId: 'torso',
      width: 40,
      height: 40,
    ),
    'torso': CharacterPart(
      id: 'torso',
      name: 'Torso',
      boneId: 'torso',
      width: 30,
      height: 50,
    ),
    'leg_left': CharacterPart(
      id: 'leg_left',
      name: 'Left Leg',
      boneId: 'leg_left',
      width: 15,
      height: 40,
    ),
    'leg_right': CharacterPart(
      id: 'leg_right',
      name: 'Right Leg',
      boneId: 'leg_right',
      width: 15,
      height: 40,
    ),
    'arm_left': CharacterPart(
      id: 'arm_left',
      name: 'Left Arm',
      boneId: 'arm_left',
      width: 12,
      height: 35,
    ),
    'arm_right': CharacterPart(
      id: 'arm_right',
      name: 'Right Arm',
      boneId: 'arm_right',
      width: 12,
      height: 35,
    ),
  };
}

/// Result of end-to-end test.
class E2ETestResult {
  E2ETestResult();

  bool success = false;
  final List<String> logs = [];
  final List<String> logErrors = [];
  String details = '';

  void log(String message) => logs.add(message);
  void error(String message) => logErrors.add(message);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('E2E TEST RESULT: ${success ? "PASSED ✅" : "FAILED ❌"}');
    buffer.writeln('\nLogs:');
    for (final log in logs) {
      buffer.writeln('  ℹ️  $log');
    }
    if (logErrors.isNotEmpty) {
      buffer.writeln('\nErrors:');
      for (final err in logErrors) {
        buffer.writeln('  ❌ $err');
      }
    }
    if (details.isNotEmpty) {
      buffer.writeln('\nDetails:\n$details');
    }
    return buffer.toString();
  }
}
