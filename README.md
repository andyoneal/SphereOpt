# SphereOpt

**SphereOpt v0.8.0 should be considered a "beta" release. The worst you should is experience is errors or graphical glitches, in which case you can uninstall the mod. Please report any issues you encounter.**

Improves rendering of Dyson Shells by drastically reducing the amount of data sent to the gpu per shell. Impact is larger depending on the number of shells in your Dyson Sphere(s).

In a new game with a large and densely packed sphere containing 5,240 shells, framerate increased from 18fps with [DSPOptimizations](https://dsp.thunderstore.io/package/Selsion/DSPOptimizations/) alone to ~85fps with SphereOpt.

[DSPOptimizations](https://dsp.thunderstore.io/package/Selsion/DSPOptimizations/) is not required, but I don't know why you wouldn't use it if you're interested in this mod.

## Changelog
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
