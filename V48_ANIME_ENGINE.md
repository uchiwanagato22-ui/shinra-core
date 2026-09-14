# SHINRA CORE V48 — Anime Engine Upgrade

This version moves the project from a rigid bone-only prototype toward a real 2D/2.5D animation architecture.

## Engine changes
- Non-destructive animation layers: base locomotion + optional upper-body/facial/secondary clips.
- Optional weighted deformable mesh model (`DeformMesh`, `MeshVertex`, `MeshInfluence`) ready for image/drawn-character deformation.
- Optional two-bone IK targets for arms/legs.
- Secondary motion pass for breathing, head follow-through, hands and attack recoil.
- Imported/drawn characters use the same rig model as procedural characters.
- 2.5D city background depth planes with camera parallax.
- Playback uses elapsed time at ~60 Hz instead of adding a fixed 1/30 second per timer tick.
- Fixed viewport squash-factor compile issue.
- Fixed animation sync angle interpolation to radians and corrected bone-track mapping.

## Important
The uploaded archive did not contain the user's PC asset folders, so the engine is wired to the declared asset paths but the actual local art/audio library cannot be validated inside this archive.

Flutter SDK was not available in the build container, so this release was statically checked rather than compiled here. Run `flutter pub get` then `flutter analyze` / `flutter build windows --release` on the Windows machine.
