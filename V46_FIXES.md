# SHINRA CORE V46 — fixes

- Fixed `viewport.dart`: `_squashFactor` -> shared `squashFactor`.
- Unified secondary animation sync with the live rig: radians, easing, all animated bones.
- Fixed invalid nested `AppearanceType` declaration and missing `Uint8List` import.
- Fixed pipeline validator's invalid `BoneTrack.isEmpty/length/iteration` usage.
- Restored `AnimationManager.instance.loadAnimation()` compatibility and library-ID fallback.
- Animation JSON loader now remaps bone aliases, converts degrees to radians, and reads easing.
- Imported animations preserve easing.
- Scene actor parts now preserve transform/lock data.
- Project save/load now preserves scene actors, custom animation metadata/tracks, actor rigs/appearance, and part transforms.
- MP4 export captures frame dimensions before disposing the Flutter image.
- Playback uses elapsed time instead of assuming every timer tick is exactly 33ms, reducing drift/jitter.

## Important
The uploaded V45 archive did not contain the declared asset folders/files, so this package cannot add or verify real character/SFX/animation assets that were not present in the archive. The engine is prepared to load them when they are present.

The Android error in the previous Codemagic log was a Dart compile error. This V46 removes the reported `_squashFactor` compile failure and fixes the other static inconsistencies found during inspection. A real Flutter release build still needs to be run on your machine/Codemagic to certify the final APK.
