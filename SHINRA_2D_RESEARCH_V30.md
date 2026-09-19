# Shinra Core — 2D character research notes

This document records design decisions adopted after reviewing current 2D
animation systems and open-source research.

## 1. A 2D character must be an asset, not a procedural preview

Shinra's imported character must remain the source of the visible artwork.
The procedural character generator is only a fallback/template.

## 2. Layer decomposition

Professional cutout workflows separate the artwork into independently
transformable layers. Synfig documents bitmap cutout animation as separate
PNG parts linked to bones. OpenToonz Plastic similarly creates a deformable
mesh from an exposed drawing and links that mesh to the original drawing
layer.

Shinra therefore supports a layered-character manifest:
`shinra-2d-layers`.

It stores:
- transparent image layer
- z/depth order
- pivot
- parent layer
- bone binding
- optional mask

This lets an external decomposition model, a manual editor, or Shinra's own
heuristic segmentation all feed the same animation engine.

## 3. Mesh deformation

A rigid bone rotation alone is not enough for anime motion. OpenToonz Plastic
uses a triangular deformable mesh and skeleton; Synfig also documents raster
skeleton deformation.

Shinra's Auto-Rig now writes a lightweight skinning mesh for every generated
cutout. The current renderer can fall back to rigid transforms; mesh rendering
can consume the same metadata later without changing the character format.

## 4. Single-owner pixel assignment

Overlapping rectangular masks cause duplicated pixels and bad compositing.
V30 assigns each foreground pixel to one anatomical region using the nearest
eligible segment plus specificity priorities.

This is deliberately deterministic and editable rather than pretending to be
a learned pose model.

## 5. AI decomposition adapter

Modern research/projects demonstrate that single-image anime decomposition
can be paired with auto-rigging. Shinra should treat this as an adapter
boundary, not as a mandatory cloud service:

`source image -> segmentation/decomposition provider -> layered character -> Shinra rig`

That means the core engine stays usable offline and can later accept a local
model, an external model, or manual layer correction.

## 6. Important limitation

A single flat image cannot reveal pixels that were never present behind an
occluding arm, hair strand, or body part. A production-quality pipeline needs
an explicit hidden-region reconstruction/inpainting stage before aggressive
articulation.

The format therefore keeps the original source and separated layers instead
of destructively replacing the artwork.

## Sources reviewed

- OpenToonz Plastic: deformable mesh + skeleton workflow.
- Synfig cutout/bone documentation: bitmap layers, pivots, skeletons and raster
  deformation.
- Stretchy Studio / See-Through research: anime layer decomposition,
  auto-rigging and mesh deformation.
- SAM2Matting: interactive image/video matting with masks, points, boxes and
  text prompts.

Shinra does not copy these tools. Their documented architectural ideas are
used as references for interoperability and engine design.
