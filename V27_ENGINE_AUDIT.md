# Shinra Core V27 — Engine Audit / Upgrade Notes

This build adds a real raster exposure track instead of treating every animation frame as a pose keyframe.

## Implemented in V27 patch
- Dedicated `FrameAnimationTrack` model.
- One editable drawing/exposure per frame.
- 12/15/24/30/60 FPS choices.
- Frame insert / duplicate / delete / clear.
- Previous/next frame stepping.
- Onion-skin display for previous and next exposures.
- Vector strokes stored per exposure so edits remain non-destructive until raster export.
- Eraser strokes using `BlendMode.clear`.
- Project persistence for the frame track through `ProjectStore`.
- Frame-by-frame editor entry in the main navigation and Animation page.

## Still not falsely claimed as finished
- A full production-grade paint engine (selection/move/transform, stabilizer, fill, lasso, layer stack, pressure curve, brush engine) is not yet complete.
- True mesh deformation rendering for arbitrary imported artwork is not yet a complete GPU warp pipeline.
- A native 3D scene renderer/editor is not yet implemented in this Flutter build.
- 2D/2.5D/3D unified compositing is therefore still an engine phase, not a completed feature.

## Verification note
The supplied environment does not contain the Flutter SDK executable, so this patch was statically inspected but cannot honestly be reported as a successful Flutter build from this environment.
