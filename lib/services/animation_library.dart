import '../models/rig.dart';

/// Pre-built animation library with common movement, combat, facial, and FX animations.
/// All animations are procedurally generated or loaded from free assets like KayKit.
class AnimationLibrary {
  
  /// Movement animations (walk, run, idle, jump, etc.)
  static final movementAnimations = [
    AnimationClip(id: 'idle', name: 'Idle', category: AnimCategory.movement, duration: 1.5, loop: true),
    AnimationClip(id: 'walk_forward', name: 'Walk Forward', category: AnimCategory.movement, duration: 1.2, loop: true),
    AnimationClip(id: 'run_forward', name: 'Run Forward', category: AnimCategory.movement, duration: 0.8, loop: true),
    AnimationClip(id: 'walk_backward', name: 'Walk Backward', category: AnimCategory.movement, duration: 1.2, loop: true),
    AnimationClip(id: 'strafe_left', name: 'Strafe Left', category: AnimCategory.movement, duration: 1.0, loop: true),
    AnimationClip(id: 'strafe_right', name: 'Strafe Right', category: AnimCategory.movement, duration: 1.0, loop: true),
    AnimationClip(id: 'jump', name: 'Jump', category: AnimCategory.movement, duration: 0.6, loop: false),
    AnimationClip(id: 'fall', name: 'Fall', category: AnimCategory.movement, duration: 0.8, loop: false),
    AnimationClip(id: 'crouch', name: 'Crouch', category: AnimCategory.movement, duration: 0.4, loop: false),
    AnimationClip(id: 'stand_up', name: 'Stand Up', category: AnimCategory.movement, duration: 0.3, loop: false),
    AnimationClip(id: 'look_around', name: 'Look Around', category: AnimCategory.movement, duration: 2.0, loop: false),
    AnimationClip(id: 'wave', name: 'Wave', category: AnimCategory.movement, duration: 1.0, loop: false),
  ];

  /// Combat animations (punch, kick, defend, dodge, etc.)
  static final combatAnimations = [
    AnimationClip(id: 'punch', name: 'Punch', category: AnimCategory.combat, duration: 0.4, loop: false),
    AnimationClip(id: 'combo_punch', name: 'Combo Punch', category: AnimCategory.combat, duration: 1.0, loop: false),
    AnimationClip(id: 'kick', name: 'Kick', category: AnimCategory.combat, duration: 0.5, loop: false),
    AnimationClip(id: 'spin_kick', name: 'Spin Kick', category: AnimCategory.combat, duration: 0.7, loop: false),
    AnimationClip(id: 'defend', name: 'Defend', category: AnimCategory.combat, duration: 0.3, loop: false),
    AnimationClip(id: 'dodge_left', name: 'Dodge Left', category: AnimCategory.combat, duration: 0.3, loop: false),
    AnimationClip(id: 'dodge_right', name: 'Dodge Right', category: AnimCategory.combat, duration: 0.3, loop: false),
    AnimationClip(id: 'hit_reaction', name: 'Hit Reaction', category: AnimCategory.combat, duration: 0.3, loop: false),
    AnimationClip(id: 'knockdown', name: 'Knockdown', category: AnimCategory.combat, duration: 1.0, loop: false),
    AnimationClip(id: 'getup', name: 'Get Up', category: AnimCategory.combat, duration: 0.6, loop: false),
    AnimationClip(id: 'power_charge', name: 'Power Charge', category: AnimCategory.combat, duration: 1.2, loop: false),
    AnimationClip(id: 'energy_blast', name: 'Energy Blast', category: AnimCategory.combat, duration: 0.5, loop: false),
  ];

  /// Facial animations (blink, smile, angry, sad, shocked, etc.)
  static final faceAnimations = [
    AnimationClip(id: 'blink', name: 'Blink', category: AnimCategory.face, duration: 0.2, loop: false),
    AnimationClip(id: 'smile', name: 'Smile', category: AnimCategory.face, duration: 0.3, loop: false),
    AnimationClip(id: 'frown', name: 'Frown', category: AnimCategory.face, duration: 0.3, loop: false),
    AnimationClip(id: 'angry', name: 'Angry', category: AnimCategory.face, duration: 0.4, loop: false),
    AnimationClip(id: 'shocked', name: 'Shocked', category: AnimCategory.face, duration: 0.3, loop: false),
    AnimationClip(id: 'sad', name: 'Sad', category: AnimCategory.face, duration: 0.4, loop: false),
    AnimationClip(id: 'confused', name: 'Confused', category: AnimCategory.face, duration: 0.3, loop: false),
    AnimationClip(id: 'kiss', name: 'Kiss Mouth', category: AnimCategory.face, duration: 0.3, loop: false),
    AnimationClip(id: 'talk', name: 'Talking', category: AnimCategory.face, duration: 1.0, loop: true),
    AnimationClip(id: 'laugh', name: 'Laugh', category: AnimCategory.face, duration: 1.0, loop: false),
    AnimationClip(id: 'cry', name: 'Cry', category: AnimCategory.face, duration: 2.0, loop: false),
    AnimationClip(id: 'wink', name: 'Wink', category: AnimCategory.face, duration: 0.2, loop: false),
  ];

  /// Visual effects animations (fire, water, lightning, smoke, etc.)
  static final fxAnimations = [
    AnimationClip(id: 'fire_burst', name: 'Fire Burst', category: AnimCategory.fx, duration: 0.6, loop: false),
    AnimationClip(id: 'water_splash', name: 'Water Splash', category: AnimCategory.fx, duration: 0.4, loop: false),
    AnimationClip(id: 'lightning_strike', name: 'Lightning Strike', category: AnimCategory.fx, duration: 0.3, loop: false),
    AnimationClip(id: 'smoke_cloud', name: 'Smoke Cloud', category: AnimCategory.fx, duration: 1.0, loop: false),
    AnimationClip(id: 'dust_storm', name: 'Dust Storm', category: AnimCategory.fx, duration: 1.2, loop: true),
    AnimationClip(id: 'wind_gust', name: 'Wind Gust', category: AnimCategory.fx, duration: 0.5, loop: false),
    AnimationClip(id: 'aura_glow', name: 'Aura Glow', category: AnimCategory.fx, duration: 2.0, loop: true),
    AnimationClip(id: 'explosion', name: 'Explosion', category: AnimCategory.fx, duration: 0.8, loop: false),
    AnimationClip(id: 'magic_cast', name: 'Magic Cast', category: AnimCategory.fx, duration: 0.7, loop: false),
    AnimationClip(id: 'healing_light', name: 'Healing Light', category: AnimCategory.fx, duration: 1.5, loop: false),
    AnimationClip(id: 'shadow_clone', name: 'Shadow Clone', category: AnimCategory.fx, duration: 0.5, loop: false),
    AnimationClip(id: 'teleport', name: 'Teleport', category: AnimCategory.fx, duration: 0.3, loop: false),
  ];

  /// Get all animations by category.
  static List<AnimationClip> getByCategory(AnimCategory category) {
    switch (category) {
      case AnimCategory.movement:
        return movementAnimations;
      case AnimCategory.combat:
        return combatAnimations;
      case AnimCategory.face:
        return faceAnimations;
      case AnimCategory.fx:
        return fxAnimations;
    }
  }

  /// Get all animations.
  static List<AnimationClip> getAll() {
    return [
      ...movementAnimations,
      ...combatAnimations,
      ...faceAnimations,
      ...fxAnimations,
    ];
  }

  /// Pre-configured keyframes for common animations.
  /// Returns a clip with actual bone movement data.
  static AnimationClip buildWalkAnimation() {
    final clip = AnimationClip(id: 'walk', name: 'Walk', category: AnimCategory.movement, duration: 1.0, loop: true);
    
    // Left leg goes forward
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: -20, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.25, x: 0, y: -10, rotation: 10, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.5, x: 0, y: 0, rotation: 20, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.75, x: 0, y: 5, rotation: 0, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 1.0, x: 0, y: 0, rotation: -20, scale: 1));
    
    // Right leg opposite phase
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: 20, scale: 1));
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.25, x: 0, y: 5, rotation: 0, scale: 1));
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.5, x: 0, y: 0, rotation: -20, scale: 1));
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.75, x: 0, y: -10, rotation: 10, scale: 1));
    clip.track('leg_right').upsert(PoseKeyframe(time: 1.0, x: 0, y: 0, rotation: 20, scale: 1));
    
    // Arms swing opposite to legs
    clip.track('arm_left').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: 20, scale: 1));
    clip.track('arm_left').upsert(PoseKeyframe(time: 0.5, x: 0, y: 0, rotation: -20, scale: 1));
    clip.track('arm_left').upsert(PoseKeyframe(time: 1.0, x: 0, y: 0, rotation: 20, scale: 1));
    
    clip.track('arm_right').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: -20, scale: 1));
    clip.track('arm_right').upsert(PoseKeyframe(time: 0.5, x: 0, y: 0, rotation: 20, scale: 1));
    clip.track('arm_right').upsert(PoseKeyframe(time: 1.0, x: 0, y: 0, rotation: -20, scale: 1));
    
    // Slight torso sway
    clip.track('torso').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: 2, scale: 1));
    clip.track('torso').upsert(PoseKeyframe(time: 0.5, x: 0, y: 0, rotation: -2, scale: 1));
    clip.track('torso').upsert(PoseKeyframe(time: 1.0, x: 0, y: 0, rotation: 2, scale: 1));
    
    return clip;
  }

  /// Build a punch animation.
  static AnimationClip buildPunchAnimation() {
    final clip = AnimationClip(id: 'punch', name: 'Punch', category: AnimCategory.combat, duration: 0.4, loop: false);
    
    // Torso rotates back for chamber
    clip.track('torso').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: -10, scale: 1));
    
    // Right arm extends forward rapidly
    clip.track('arm_right').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: -20, scale: 1));
    clip.track('arm_right').upsert(PoseKeyframe(time: 0.2, x: 30, y: 0, rotation: 0, scale: 1.1)); // Punch extends
    clip.track('arm_right').upsert(PoseKeyframe(time: 0.3, x: 30, y: 0, rotation: 0, scale: 1.1));
    clip.track('arm_right').upsert(PoseKeyframe(time: 0.4, x: 0, y: 0, rotation: -20, scale: 1)); // Recovery
    
    // Torso returns
    clip.track('torso').upsert(PoseKeyframe(time: 0.2, x: 0, y: 0, rotation: 5, scale: 1));
    clip.track('torso').upsert(PoseKeyframe(time: 0.4, x: 0, y: 0, rotation: 0, scale: 1));
    
    // Left leg steps back for balance
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: 0, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.1, x: -5, y: 0, rotation: -10, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.4, x: -5, y: 0, rotation: -10, scale: 1));
    
    return clip;
  }

  /// Build a jump animation.
  static AnimationClip buildJumpAnimation() {
    final clip = AnimationClip(id: 'jump', name: 'Jump', category: AnimCategory.movement, duration: 0.6, loop: false);
    
    // Crouch down
    clip.track('torso').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: 0, scale: 1));
    clip.track('torso').upsert(PoseKeyframe(time: 0.1, x: 0, y: -15, rotation: 0, scale: 0.9));
    
    // Jump up
    clip.track('torso').upsert(PoseKeyframe(time: 0.2, x: 0, y: 40, rotation: 0, scale: 1));
    clip.track('torso').upsert(PoseKeyframe(time: 0.4, x: 0, y: 60, rotation: 0, scale: 1));
    
    // Fall down
    clip.track('torso').upsert(PoseKeyframe(time: 0.5, x: 0, y: 20, rotation: 0, scale: 1));
    clip.track('torso').upsert(PoseKeyframe(time: 0.6, x: 0, y: 0, rotation: 0, scale: 1));
    
    // Legs bend during jump
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: 0, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.1, x: 0, y: 0, rotation: -45, scale: 0.8));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.2, x: 0, y: 0, rotation: -10, scale: 1));
    clip.track('leg_left').upsert(PoseKeyframe(time: 0.6, x: 0, y: 0, rotation: 0, scale: 1));
    
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.0, x: 0, y: 0, rotation: 0, scale: 1));
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.1, x: 0, y: 0, rotation: -45, scale: 0.8));
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.2, x: 0, y: 0, rotation: -10, scale: 1));
    clip.track('leg_right').upsert(PoseKeyframe(time: 0.6, x: 0, y: 0, rotation: 0, scale: 1));
    
    return clip;
  }
}
