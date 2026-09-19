# SHINRA 2D Puppet Format (.shn2d)

`.shn2d` is Shinra Core's native 2D character format.

It is intentionally 2D-only. It stores:
- the original character artwork;
- transparent cut-out textures for body parts;
- the bone hierarchy;
- parent/child relationships;
- each part's crop and bone binding.

The important distinction is that the imported artwork is the actor's render source.
The procedural character generator is not used underneath it.

Pipeline:
PNG/JPG/drawing
 -> Auto-Rig
 -> cut-out artwork
 -> .shn2d character asset
 -> 2D bones / IK / keyframes
 -> frame-by-frame overlays
 -> final scene

This is a first native format version. The current Auto-Rig segmentation is deterministic
and heuristic; it does not claim perfect semantic segmentation for arbitrary poses.
