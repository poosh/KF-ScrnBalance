# CacheSizeMegs

`CacheSizeMegs` is a `KillingFloor.ini` setting that performance guides like to "tune". In Killing
Floor 1 it has **no practical effect**. Leave it at the default of `32`.

## Where it is set

```ini
[Engine.GameEngine]
CacheSizeMegs=32
```

The same key also appears under `[Editor.EditorEngine]` and `[UnrealEd.UnrealEdEngine]`. Those two
apply only to the SDK editor (KFEd). The default of `32` comes from `System\Default.ini`, which ships
with the game.

The value is read once, when the game starts. A change needs a restart.

## What it controls

The size, in megabytes, of the engine's general-purpose memory cache. That cache is one block of
memory reserved at startup. When it fills up, the least recently used entries are dropped and
rebuilt the next time they are needed. So an undersized cache costs a little CPU time, and an
oversized one only wastes memory. The cache is also emptied on every map change.

The setting dates back to the original Unreal Engine, where this cache held texture and lighting
data for the software renderer. That is where the advice to raise it comes from. In UE2.5, the
engine KF1 is built on, the cache holds only three kinds of data, all of them small:

1. **Which lights affect each visible actor.** Refreshed as actors move around. Used for
   client-side rendering only.
2. **Uncompressed copies of BSP lightmaps.** Used only when compressed lightmaps are *off*. With the
   stock settings, the game draws each map's pre-built compressed lightmaps directly, and this part
   of the cache is never touched. Stock means the default `D3D9Drv.D3D9RenderDevice` renderer with
   `UseCompressedLightmaps=True`. The cache comes into play only in these cases:
   - `UseCompressedLightmaps=False`;
   - `DecompressTextures=True`;
   - a graphics card without DXT texture compression;
   - the editor, while lights are being edited.

   In the game itself, dynamic lights never repaint BSP lightmaps.
3. **The input-bound properties of each class.** A handful of entries.

Even in a busy scene, all of this adds up to a few megabytes at most, well under the default 32.

## What it does not affect

- **Texture, mesh and video memory.** The renderers manage those separately. Raising
  `CacheSizeMegs` does not give textures or meshes more room.
- **Dedicated servers.** A server renders nothing, so the cache stays unused there. The setting only
  reserves memory.
- **Gameplay.** Nothing in UnrealScript reads it.

## Recommendation

Keep the default `32`. Raising it only makes the game reserve more memory at startup, and KF1 is a
32-bit game with little memory to spare. Lowering it gains nothing worth having.
