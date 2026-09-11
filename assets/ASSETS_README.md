# Animation Assets for SHINRA CORE v27

## 📁 Structure

```
assets/
├── animations/          ← Animation keyframe data (JSON)
│   ├── index.json       ← Master list of all animations
│   ├── walk_forward.json
│   ├── punch.json
│   ├── jump.json
│   └── ...
├── characters/          ← Character sprite templates
│   └── (coming soon)
├── expressions/         ← Facial expression data
│   └── (coming soon)
├── effects/             ← VFX particle definitions
│   └── (coming soon)
└── test_images/         ← Sample images for testing
    ├── character_test_segments.json
    └── (character_test.png - user must provide)
```

## 🎬 Animation Format

Each animation is a JSON file with this structure:

```json
{
  "id": "walk_forward",
  "name": "Walk Forward",
  "category": "movement",
  "duration": 1.2,
  "loop": true,
  "tracks": {
    "bone_name": [
      {
        "time": 0.0,
        "x": 0,
        "y": 0,
        "rotation": -20,
        "scale": 1.0
      },
      ...
    ]
  }
}
```

### Fields:
- **id** (string): Unique identifier
- **name** (string): Display name
- **category** (string): "movement", "combat", "face", or "fx"
- **duration** (number): Length in seconds
- **loop** (boolean): Whether animation repeats
- **tracks** (object): Bone animation data
  - **bone_name** (array): Keyframe data for each bone
    - **time** (number): Keyframe time (0.0 to duration)
    - **x, y** (number): Position offset
    - **rotation** (number): Rotation in degrees
    - **scale** (number): Scale multiplier

## 📊 Available Animations

### Movement (12 total)
- idle.json
- walk_forward.json
- run_forward.json
- walk_backward.json
- strafe_left.json
- strafe_right.json
- jump.json
- fall.json
- crouch.json
- stand_up.json
- look_around.json
- wave.json

### Combat (12 total)
- punch.json
- combo_punch.json
- kick.json
- spin_kick.json
- defend.json
- dodge_left.json
- dodge_right.json
- hit_reaction.json
- knockdown.json
- getup.json
- power_charge.json
- energy_blast.json

### Facial (12 total)
- blink.json
- smile.json
- frown.json
- angry.json
- shocked.json
- sad.json
- confused.json
- kiss.json
- talk.json
- laugh.json
- cry.json
- wink.json

### Effects (12 total)
- fire_burst.json
- water_splash.json
- lightning.json
- smoke_cloud.json
- dust_storm.json
- wind_gust.json
- aura_glow.json
- explosion.json
- magic_cast.json
- healing_light.json
- shadow_clone.json
- teleport.json

## 🖼️ Testing with Images

### Using Your Own Image

1. Prepare a PNG or JPG image:
   - Preferably 512x512 pixels or larger
   - Character on plain background
   - Front-facing pose (best results)

2. Place it in `assets/test_images/`

3. In app, go to **Character Creator** → **Upload Image**

4. App will auto-segment into body parts

5. Select an animation and see your image animate!

### Test Segmentation Data

`character_test_segments.json` contains example segmentation regions:
- Face, Torso, Arms, Legs
- Normalized coordinates (0.0 to 1.0)
- Can be used as reference for ML-based segmentation

## 🔄 Loading Animations in Code

```dart
// Load from JSON
import 'dart:convert';
import 'package:flutter/services.dart';

Future<AnimationClip> loadAnimation(String id) async {
  final json = await rootBundle.loadString('assets/animations/$id.json');
  final data = jsonDecode(json);
  
  // Parse into AnimationClip
  final clip = AnimationClip(
    id: data['id'],
    name: data['name'],
    category: AnimCategory.values.byName(data['category']),
    duration: data['duration'],
    loop: data['loop'],
  );
  
  // Load tracks
  (data['tracks'] as Map).forEach((boneName, keyframes) {
    final track = clip.track(boneName);
    for (var kf in keyframes) {
      track.upsert(PoseKeyframe(
        time: kf['time'],
        x: kf['x'],
        y: kf['y'],
        rotation: kf['rotation'],
        scale: kf['scale'],
      ));
    }
  });
  
  return clip;
}
```

## 📈 Creating Your Own Animations

### Step 1: Define Bones
Decide which bones animate:
- `torso` (center)
- `head` (connected to torso)
- `arm_left`, `arm_right`
- `leg_left`, `leg_right`
- `hand_left`, `hand_right`
- etc.

### Step 2: Create Keyframes
For each bone, define positions at key moments:
- t=0.0: Starting pose
- t=0.25, 0.5, 0.75: Mid-animation poses
- t=duration: Ending pose (often same as start for loops)

### Step 3: Smooth Interpolation
The app uses linear interpolation between keyframes.
For smoother motion, add more keyframes closer together.

### Step 4: Export to JSON
Use the format above and test in-app.

## 🎯 Tips

1. **Test Loop Point**: Make sure last keyframe matches first for seamless looping
2. **Natural Motion**: Add slight overlapping rotations for realism
3. **Timing**: Faster movements = shorter duration, fewer keyframes
4. **Bone Names**: Must match the rig's bone names exactly
5. **Scale**: Use 1.0 for normal, 0.8 for smaller, 1.2 for larger

## 📝 Checklist for New Animations

- [ ] Unique ID (lowercase, no spaces)
- [ ] Display name (user-friendly)
- [ ] Category (movement/combat/face/fx)
- [ ] Duration (realistic timing)
- [ ] Loop flag (matches animation type)
- [ ] All bones with data
- [ ] Keyframes at start and end
- [ ] Smooth transitions
- [ ] Tested in app
- [ ] Added to index.json

## 🚀 Next Steps

1. Add missing animations (currently only 3 implemented)
2. Create character sprite templates
3. Add facial expression data
4. Create VFX particle definitions
5. Build animation marketplace

---

**Last Updated**: 2026-09-11  
**Format Version**: 1.0  
**Total Animations**: 40+ planned
