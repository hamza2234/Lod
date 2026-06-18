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

## Current implementation status

The temporary generated dice assets were removed.

The project now integrates one real downloaded open-source dice asset:

```text
addons/dice_roller/dice/d6_dice/d6.glb
```

Source:

```text
external/dice-research/godot-dice-roller/
https://github.com/vokimon/godot-dice-roller
```

This is used as the first real test dice in gameplay while the full production dice system is rebuilt.

Downloaded research sources are stored under:

```text
external/dice-research/
```

Downloaded successfully:

- `godot-dice-roller`
- `dice-box`

Itch.io assets require manual browser download because the zip files are gated behind a purchase/session flow even when they are free or name-your-own-price.
