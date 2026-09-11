# CacheSizeMegs

`CacheSizeMegs` is a `KillingFloor.ini` setting that performance guides like to "tune". In Killing
Floor 1 it has **no practical effect**. Leave it at the default of `32`.

This page also covers `UseCompressedLightmaps`, the one renderer setting that decides whether the
cache gets used at all, and how video memory relates to KF1's 32-bit memory limit.

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
   - `UseCompressedLightmaps=False` (see [below](#usecompressedlightmaps));
   - `DecompressTextures=True`;
   - a graphics card without DXT texture compression;
   - the editor, while lights are being edited.

   In the game itself, dynamic lights never repaint BSP lightmaps.
3. **The input-bound properties of each class.** A handful of entries.

Even in a busy scene, all of this adds up to a few megabytes at most, well under the default 32.

## What it does not affect

- **Texture, mesh and video memory.** The renderers manage those separately. Raising
  `CacheSizeMegs` does not give textures or meshes more room. See
  [Video memory and the 32-bit limit](#video-memory-and-the-32-bit-limit).
- **Dedicated servers.** A server renders nothing, so the cache stays unused there. The setting only
  reserves memory.
- **Gameplay.** Nothing in UnrealScript reads it.

## UseCompressedLightmaps

```ini
[D3D9Drv.D3D9RenderDevice]
UseCompressedLightmaps=True
```

BSP lightmaps are the baked lighting on a map's BSP geometry. When a mapper rebuilds a level's
lighting, the editor can save a compressed (DXT1 or DXT3) copy of those lightmaps into the map. It
saves this copy alongside the lighting data the copy was made from. This setting picks which of the
two the game draws:

- **`True`** (the default) draws the compressed copy. It is small, but DXT compression is lossy:
  dark gradients can show visible banding, and shadow edges can look blocky. KF maps are mostly
  dark, which is where banding shows most.
- **`False`** ignores the compressed copy. The game builds the lightmaps itself, from the map's
  lighting data, while the map loads. The lighting is the same, in full 32-bit color, with no
  compression artifacts.

A map saved without a compressed copy always uses uncompressed lightmaps, whatever this setting
says. The game also falls back to uncompressed lightmaps on its own when `DecompressTextures=True`,
or when the graphics card lacks DXT support.

What `False` costs:

- **Memory.** Uncompressed lightmaps take several times more memory: DXT1 compresses 8:1 and DXT3
  4:1. That applies to video memory and, as explained below, also to the game's own system memory.
- **Load time.** The lightmaps are built once, during the texture precaching step of map loading.
  The log reports that step as `Finished precaching textures in N seconds`, so compare that line
  with the setting on and off to see what it costs on your machine. With `UsePrecaching=False`, the
  lightmaps are built instead the first time each part of the map comes into view, which can cause
  brief stutters. Keep `UsePrecaching=True`, which is the default.
- **Nothing during play.** Lighting does not change in-game, so nothing is rebuilt after loading.

With `False`, the lightmaps pass through the memory cache described above while they are being
built. The default `CacheSizeMegs=32` is enough for that.

## Video memory and the 32-bit limit

KF1 is a 32-bit game. `KillingFloor.exe` is marked large-address-aware, so on 64-bit Windows it can
use up to 4 GB of address space. `ucc.exe`, which dedicated servers run, is not, so a server gets
2 GB. On 32-bit Windows the limit is lower. Every program gets 2 GB by default, and
`KillingFloor.exe` gets 3 GB only if Windows boots with the `/3GB` option
(`bcdedit /set increaseuserva 3072`).

- **Video memory is not part of those 4 GB.** Windows manages the graphics card's memory outside
  the game process, so a card with 8 or 16 GB works normally. It is not "capped at 4 GB".
- **Textures also have a copy in system memory.** For the kind of textures KF uses, Direct3D 9
  keeps a copy of each one in the game's own memory, so that it can upload them to the graphics
  card again whenever needed. Those copies *do* count against the 4 GB.

So, in practice, the texture data KF can use is limited by the game's 4 GB address space, not by the
graphics card. That space is shared with everything else the game loads: maps, meshes, sounds and
code. When it runs out, the game crashes, and large custom maps are the most likely to get there.
This is also why `UseCompressedLightmaps=False` has a real cost despite plenty of video memory: its
uncompressed lightmaps take system memory too.

## Recommendation

- **`CacheSizeMegs`:** keep the default `32`. Raising it only makes the game reserve more memory at
  startup, out of the same 4 GB. Lowering it gains nothing worth having.
- **`UseCompressedLightmaps`:** on a modern PC, set it to `False` for cleaner lighting. If large
  custom maps start crashing from lack of memory, set it back to `True`.
