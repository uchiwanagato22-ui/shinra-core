# SHINRA CORE — Final

Flutter-based 2D anime animation editor foundation.

## Included
- Character parts + image import
- Bone hierarchy and binding
- Procedural rig viewport
- Pose editing
- Keyframes/tracks/interpolation
- Animation presets
- Timeline playback
- Expressions
- FX/audio timeline events
- Camera controls
- AI Director command planning
- Undo/redo
- Local project save/load

## Run
```bash
flutter pub get
flutter analyze
flutter run
```

Target Android first. `image_picker` is used for gallery import.

## Important
This is the final editor foundation, not a claim that every professional production feature (automatic image segmentation, mesh skinning, GPU particle simulation, and native MP4 encoding) is already implemented. Those are separate engine subsystems and should be added without faking them in the UI.
