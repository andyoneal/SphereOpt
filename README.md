# SphereOpt

**SphereOpt v0.9.2 should be considered a "beta" release. The worst you should is experience is errors or graphical glitches, in which case you can uninstall the mod. Please report any issues you encounter.**

Improves rendering of Dyson Shells, Frames, and Nodes by instancing the shell hexagons and issuing one draw call per layer, instead of one per shell. Also implements culling and level of detail for frames/nodes. Impact is larger depending on the size of your Dyson Sphere(s).

In a new game with a large and densely packed sphere containing 5,240 shells, framerate increased from 18fps with [DSPOptimizations](https://dsp.thunderstore.io/package/Selsion/DSPOptimizations/) alone to ~85fps with SphereOpt.

[DSPOptimizations](https://dsp.thunderstore.io/package/Selsion/DSPOptimizations/) is not required, but I don't know why you wouldn't use it if you're interested in this mod.

## Known Limitations
- does not support the "painting grid", but regular colors work.
- some dyson spheres have random gaps but most are fine. it is frustrating.

## Changelog
- v0.9.2
  - supports DSP 0.10.33.26941
- v0.9.1
  - supports colors on shells, frames, and nodes. Does not yet support the "painting grid".
  - fixed some of the gaps in shells. still some left, but a lot less.
  - unfortunately made it slightly slower (85fps->80fps for me), but will be corrected in a later update.
- v0.9.0
  - supports DSP 0.10.29.28154
  - added support for shell textures other than the default, without adding extra draw calls. thanks, Texture2DArray!
- v0.8.3
  - supports DSP 0.10.28.20779
- v0.8.2
  - fixes bright green glow on unbuilt frames/nodes in the dyson sphere editor
  - slight performance increase
- v0.8.1
  - fixes error when using shells on the 10th dyson sphere layer.
- v0.8.0
  - major rework of shell rendering. individual hexagons are now instanced and rendered in one draw call per layer.
  - added basic LOD and frustum culling for both frames and nodes. fps now greatly increases when the sphere is not in view.
  - misc optimizations on shells/frames/nodes
  - all together, increases fps from 55 to 85 on my benchmark giant dense sphere.
- v0.7.1
  - fix bug with clipping shells at edges
- v0.7.0
  - various optimizations
  - fixed unfinished shell rendering
  - fixed lighting on dyson frames
