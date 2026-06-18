# Dice System Research

This folder contains downloaded open-source dice references and notes for rebuilding the dice system from scratch.

## Downloaded successfully

### 1. Godot Dice Roller

Path:

```text
external/dice-research/godot-dice-roller/
```

Source:

```text
https://github.com/vokimon/godot-dice-roller
```

Why it matters:

- Godot-native dice rolling addon.
- Supports 3D dice in Godot.
- Supports configurable dice and different rolling modes.
- Best candidate for replacing the prototype dice implementation.

### 2. Dice Box

Path:

```text
external/dice-research/dice-box/
```

Source:

```text
https://github.com/3d-dice/dice-box
```

Why it matters:

- Mature web dice engine using BabylonJS/AmmoJS.
- Useful for studying production-grade dice architecture, theme loading, physics, and mesh handling.
- Not directly Godot-native.

## Could not download automatically

These sources are visible and free/name-your-own-price, but itch.io requires a purchase/session flow before serving the actual zip files. They must be downloaded manually in a browser, then copied into this repository.

### Voxel Board Games by Kytric

```text
https://kytric.itch.io/board-game-assets
```

Target files:

```text
BoardGames-gltf.zip
BoardGames-GodotDemoScenes.zip
```

License:

```text
CC0
```

### 3D Dice Roller Template with Physics for Godot

```text
https://pawsgineer.itch.io/godot-3d-dice-roller-template
```

Target file:

```text
paws_dice_roller_template.zip
```

License:

```text
MIT for code
```

### Free 3D Dice Models 2 by VOiD1 Gaming

```text
https://void1gaming.itch.io/free-3d-dice-models-2
```

Target files:

```text
Free 3D Dice Models 2.zip
Free 3D Dice Models 2 License.pdf
```

Notes:

- Large download, about 507 MB.
- Contains PBR dice assets and textures.

## Recommended rebuild plan

1. Remove the prototype dice implementation completely from gameplay.
2. Integrate `godot-dice-roller` as a dedicated addon or as a reference implementation.
3. Use a real dice scene structure:

```text
DiceRig.tscn
  RigidBody3D
    VisualRoot
      Imported GLB dice mesh
    CollisionShape3D
    Marker3D face_1
    Marker3D face_2
    Marker3D face_3
    Marker3D face_4
    Marker3D face_5
    Marker3D face_6
    AnimationPlayer
    GPUParticles3D
    AudioStreamPlayer3D
```

4. Detect result using face `Marker3D` dot products against `Vector3.UP`, not UI labels.
5. Use `RigidBody3D` + `PhysicsMaterial`:

```text
bounce = 0.2
friction = 0.8
```

6. Roll with:

```gdscript
apply_impulse(...)
apply_torque_impulse(...)
```

7. For network fairness, get the official result from backend first, then guide the final orientation toward that result after the physical roll starts.
8. Build one high-quality GLB dice asset per skin and one companion cinematic scene per premium effect.
