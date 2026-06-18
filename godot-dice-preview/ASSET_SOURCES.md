# Open 3D Asset Sources

These sources were reviewed for dice and cinematic companion assets.

## Dice

- `3d-dice/dice-themes`
  - URL: https://github.com/3d-dice/dice-themes
  - License: MIT for the repository; upstream dice themes mention license-free/CC0 model usage in the Dice Box ecosystem.
  - Note: The checked repository currently stores themes in Babylon-style JSON rather than Godot-ready GLB files, so they were not imported directly.

## Snake

- Quaternius Snake on Poly Pizza
  - URL: https://poly.pizza/m/x9x0viZs8V
  - Format: FBX/GLTF
  - License: Public Domain / CC0
  - Suitable for replacing the procedural snake cinematic effect.

## Lion

- CC0 lion-like statue options exist mostly as STL/3D-print assets, for example:
  - https://www.thingiverse.com/thing:2870430
  - License: CC0
  - Note: STL assets should be converted and optimized in Blender before importing into Godot.

## Current implementation

The game currently uses procedural Godot 3D effects for premium dice results:

- Snake effect for selected skins with `effect = "snake"`.
- Lion/mane effect for selected skins with `effect = "lion"`.
- Eagle/wings effect for selected skins with `effect = "eagle"`.

This keeps the APK self-contained and avoids shipping unverified third-party downloads. When production art is selected, place GLB files under `assets/models/` and replace the procedural factories in `scripts/dice_preview.gd`.
