import 'package:flutter_test/flutter_test.dart';
import 'package:shinra_core/models/rig.dart';

void main() {
  test('incoming keyframe easing changes the in-between pose', () {
    final project = ProjectState();
    project.createAnimation('Easing test', 1);
    final clip = project.selectedAnimation;
    final track = clip.track('root')..keys.clear();
    track.upsert(PoseKeyframe(time: 0, x: 0, y: 110, rotation: 0, scale: 1));
    track.upsert(PoseKeyframe(
      time: 1,
      x: 100,
      y: 110,
      rotation: 0,
      scale: 1,
      easing: KeyframeEasing.easeIn,
    ));

    project.setActorAnimation(project.selectedActorId, clip.id);
    project.loadAt(.5);

    // Cubic ease-in is 12.5% at the midpoint, unlike a linear 50% move.
    expect(project.bones.firstWhere((bone) => bone.id == 'root').x, closeTo(12.5, .01));
  });

  test('editing a keyframe curve does not create an accidental keyframe', () {
    final project = ProjectState();
    final track = project.selectedAnimation.track(project.selectedBoneId);
    final before = track.keys.length;

    project.setPlayhead(.123);
    project.setKeyframeEasing(KeyframeEasing.impact);

    expect(track.keys.length, before);
    expect(project.status, 'Add a keyframe first');
  });
}
