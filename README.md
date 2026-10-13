# pixel

a procedural world generation playground. the plan is to turn this into a proper world-building tool, one working feature at a time.

## what's in it right now

- seeded 3d terrain made from layered noise
- elevation-based terrain colors
- basic water, sky and directional lighting
- orbit camera with zoom
- seed box so you can revisit a world
- random seed button for quick exploring

## run it

1. install Godot 4.3 or newer: https://godotengine.org/download
2. clone this repo
3. open the folder with `project.godot` in Godot
4. press **F5**

no asset packs or plugins needed.

## controls

- hold right mouse button and move to orbit
- scroll to zoom
- press escape to release the mouse

## roadmap

- [x] first 3d terrain prototype
- [x] seeded generation
- [x] basic lighting and water
- [ ] terrain settings you can tweak live
- [ ] biomes and climate
- [ ] save and load world presets
- [ ] rivers and erosion
- [ ] export heightmaps and meshes
- [ ] visual node graph

## layout

```
pixel/
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── main.gd
│   ├── orbit_camera.gd
│   └── world_generator.gd
└── project.godot
```

early days for now. the goal is real features and small commits, not pretending it's finished already.
