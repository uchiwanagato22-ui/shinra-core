# SHINRA CORE v27 - Complete Animation Suite

**A full-featured 2D anime animation app** for creating custom characters, animating them with presets, and exporting to TikTok, YouTube, and other platforms.

## ✨ Features

### Character Creator
- **Customizable appearance**: 5,000+ combinations with:
  - 5 skin tones
  - 7 hair colors
  - 8 hair styles (Short/Long/Spike/Queue/Bald/Fringe/Afro/Mohawk)
  - 5 eye shapes (Round/Sharp/Sleepy/Wide/Cat)
  - 6 eye colors
  - 7 outfits (Hoodie/Jacket/Robe/Dress/Tank/Armor/Cape)
  - 6 outfit colors
  - 3 accessories
  - 5 backgrounds

- **Upload & Animate**: Import your own image and animate it on the character rig
- **Draw Canvas**: Built-in drawing tool to create custom artwork

### Animation Engine
- **Pre-built Library**: 40+ animations across 4 categories:
  - **Movement**: Idle, Walk, Run, Jump, Fall, Crouch, Wave, etc.
  - **Combat**: Punch, Kick, Defend, Dodge, Energy Blast, etc.
  - **Facial**: Blink, Smile, Angry, Talk, Laugh, Cry, etc.
  - **FX**: Fire, Lightning, Smoke, Explosions, Healing, etc.

- **Keyframe Timeline**: Full animation editor with:
  - Bone hierarchy and IK support
  - Keyframe capture and editing
  - Smooth interpolation (linear, ease, spline)
  - Undo/Redo
  - Playback preview

- **Scene Studio**: Combine characters, effects, audio, and camera into complete scenes

### Export Formats
- **TikTok** (9:16 vertical, 1080x1920)
- **YouTube** (16:9, 1920x1080)
- **YouTube Shorts** (9:16, 1080x1920)
- **GIF** (with auto-sizing)
- **PNG Sequence** (for external video editing)
- **MP4** (with ffmpeg integration for production)

### AI Director (Experimental)
- Text-to-timeline: Describe a scene and convert it to animation commands
- Smart pose suggestions
- Automated camera framing

## 🚀 Getting Started

### Setup

```bash
# Clone the repo
git clone <repo-url>
cd shinra_core

# Install dependencies
flutter pub get

# Run the app (desktop or mobile)
flutter run
```

### First Animation

1. **Character Creator** → Customize your character's appearance
2. **Library** → Select a pre-built animation (e.g., "Walk Forward")
3. **Animate** → Use the timeline to adjust poses or add keyframes
4. **Export** → Choose your format (TikTok/YouTube/GIF) and render
5. **Share** → Upload directly to social media

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry + UI pages
├── models/
│   └── rig.dart                # Core data structures (Bone, Character, Animation)
├── services/
│   ├── animation_library.dart   # 40+ pre-built animations
│   ├── image_upload_service.dart # Image import, segmentation, editing
│   ├── video_export.dart        # MP4/PNG/GIF export
│   ├── gif_export.dart          # Pure Dart GIF encoding
│   ├── export_handler.dart      # Export dialog UI
│   ├── ai_director.dart         # Text-to-timeline planning
│   ├── audio_cue_service.dart   # SFX playback
│   └── project_store.dart       # Save/load projects
└── widgets/
    ├── viewport.dart           # Animation viewport + renderer
    └── draw_canvas.dart        # Built-in drawing tool
```

## 🎨 Animation Library Reference

### Movement Animations
```dart
movementAnimations = [
  AnimationClip(id: 'idle', name: 'Idle', duration: 1.5, loop: true),
  AnimationClip(id: 'walk_forward', name: 'Walk Forward', duration: 1.2, loop: true),
  AnimationClip(id: 'run_forward', name: 'Run Forward', duration: 0.8, loop: true),
  // ... 10 more
];
```

### Combat Animations
```dart
combatAnimations = [
  AnimationClip(id: 'punch', name: 'Punch', duration: 0.4, loop: false),
  AnimationClip(id: 'kick', name: 'Kick', duration: 0.5, loop: false),
  AnimationClip(id: 'defend', name: 'Defend', duration: 0.3, loop: false),
  // ... 9 more
];
```

### Facial Animations
- **Expressions**: Blink, Smile, Angry, Shocked, Sad, etc.
- **Mouth**: Talking, Laugh, Kiss, etc.
- **Duration**: 0.2–2.0 seconds

### Visual Effects
- **Elements**: Fire, Water, Lightning, Smoke, Explosions
- **Particle System**: Aura, Clone, Teleport
- **Duration**: 0.3–1.5 seconds

## 🎬 Export Workflow

### TikTok (9:16 Vertical)
```dart
await VideoExporter.export(
  boundaryKey: viewportKey,
  project: project,
  format: VideoExporter.ExportFormat.tiktok,
  fps: 30,
);
```

### YouTube (16:9)
```dart
await VideoExporter.export(
  boundaryKey: viewportKey,
  project: project,
  format: VideoExporter.ExportFormat.youtube,
  fps: 30,
);
```

### GIF (All Platforms)
```dart
await VideoExporter.export(
  boundaryKey: viewportKey,
  project: project,
  format: VideoExporter.ExportFormat.gif,
  fps: 12,
);
```

## 🖼️ Image Upload & Animation

### Step 1: Import Image
```dart
final image = await ImageUploadService.loadImage(filePath);
```

### Step 2: Auto-Segment
```dart
final parts = ImageUploadService.segmentImage(image);
// Returns: {face, torso, hands, legs, shoes}
```

### Step 3: Animate on Rig
```dart
// The imported image now follows the character rig
// Animate normally, and the image moves with each bone
```

### Step 4: Export
The image is rendered at full resolution in the output video.

## 🤖 AI Director (Text-to-Timeline)

```dart
// Describe what you want
final prompt = "A character walks forward, then punches twice, then jumps";

// AI Director converts to timeline
final timeline = await AiDirector.planTimeline(prompt);
// Returns: [
//   {clip: 'walk_forward', start: 0, duration: 1.2},
//   {clip: 'punch', start: 1.2, duration: 0.4},
//   {clip: 'punch', start: 1.6, duration: 0.4},
//   {clip: 'jump', start: 2.0, duration: 0.6},
// ]
```

## 🎞️ Timeline Editor Features

- **Keyframe Capture**: Press a button to capture a pose at the current frame
- **Drag & Drop**: Rearrange clips on the timeline
- **Blend Modes**: Cross-fade between animations
- **Loop Control**: Set individual clips to loop or play once
- **Playback Speed**: Slow down or speed up playback
- **Onion Skin**: See previous/next frames for tracing

## 📊 Scene Studio

Compose complete scenes with:
- Multiple characters (layered by depth)
- Background + foreground props
- Dynamic lighting and shadows
- Camera movements and pans
- Particle effects and overlays
- Audio track with cue points

## 🔄 Undo/Redo

Every action is reversible:
- Bone position/rotation/scale changes
- Keyframe edits
- Animation selections
- Character customizations

Uses snapshot-based undo (efficient for large projects).

## 💾 Save & Load

Projects are saved as JSON:
```json
{
  "name": "My Animation",
  "character": { /* customization + rig state */ },
  "animations": [ /* all clips and keyframes */ ],
  "scenes": [ /* scene composition */ ],
  "settings": { /* export preferences */ }
}
```

## 🎯 Roadmap (Planned)

- [ ] GPU-accelerated particle system (for more complex FX)
- [ ] Automatic speech-to-animation (AI lips sync)
- [ ] Mesh deformation (for advanced character deformation)
- [ ] Bone IK solver (for more realistic arm/leg movement)
- [ ] Procedural animation generation (ML-based)
- [ ] Cloud project sync
- [ ] Collaboration tools (multi-user editing)
- [ ] NFT export (for Web3 projects)

## ⚠️ Limitations & Known Issues

- **MP4 Export** requires native platform support or ffmpeg integration (currently exports frame sequence for external encoding)
- **Image Segmentation** is heuristic-based (not ML) — for better results, manually crop your image first
- **Performance**: Animations with 50+ bones may show lag on mobile devices
- **Audio**: Currently supports cue markers only; full audio sync coming soon

## 🛠️ Troubleshooting

### "Frames not captured"
- Ensure the viewport is visible on screen
- Try increasing initial_wait in export settings

### "Out of memory on mobile"
- Reduce export resolution or FPS
- Split long animations into clips and compose in post

### "Image doesn't animate with rig"
- Check that importedImagePath is set correctly
- Ensure the image is in a supported format (PNG/JPG)
- Try adjusting crop regions in Character settings

## 📝 API Reference

### ProjectState (Main Store)
```dart
class ProjectState extends ChangeNotifier {
  // Character
  Color skinColor;
  Color hairColor;
  String hairStyle;
  Color eyeColor;
  String eyeShape;
  Color clothesColor;
  String outfit;
  
  // Animation
  List<AnimationClip> animations;
  AnimationClip selectedAnimation;
  double playhead;
  bool playing;
  
  // Rig
  List<Bone> skeleton;
  Bone selectedBone;
  Map<String, CharacterPart> parts;
  
  // Methods
  void captureKeyframe();
  void setPlayhead(double t);
  void undo();
  void redo();
}
```

### AnimationLibrary
```dart
// Get animations by category
AnimationLibrary.getByCategory(AnimCategory.movement); // -> List<AnimationClip>
AnimationLibrary.getAll(); // -> List<AnimationClip>

// Pre-built complex animations
AnimationLibrary.buildWalkAnimation();
AnimationLibrary.buildPunchAnimation();
AnimationLibrary.buildJumpAnimation();
```

### VideoExporter
```dart
enum ExportFormat { tiktok, youtube, shorts, gif, png }

await VideoExporter.export(
  boundaryKey: key,
  project: state,
  format: ExportFormat.tiktok,
  fps: 30,
  customWidth: 1080, // optional
  customHeight: 1920, // optional
  onProgress: (current, total) => print('$current/$total frames'),
);
```

## 📚 Learning Resources

- **Tutorial Videos**: Coming soon
- **Animation Basics**: See `animation_library.dart` for example keyframes
- **Example Projects**: Included in assets folder

## 🤝 Contributing

Contributions welcome! Areas we need help with:
- More animation presets
- Better ML-based image segmentation
- Particle system optimization
- UI/UX improvements
- Platform-specific integrations (TikTok API, YouTube upload)

## 📄 License

SHINRA CORE is proprietary software. All rights reserved.

---

**Made with ❤️ for anime creators**

For issues, feature requests, or questions, open an issue on GitHub.
