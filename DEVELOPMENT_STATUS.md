# Development Status – South East Railway Simulator V0.1

Last updated: 2026-09-18

## Summary

A complete Godot 4 project foundation exists for a standalone Windows train simulator focused on the real Falmer ↔ Lewes section of the East Coastway.

Core simulation systems (physics, track queries, 4-aspect signalling, controls, HUD, scoring, service selection) are implemented in GDScript and driven by real-world-derived route data.

3D visuals, detailed cab, terrain and audio are still placeholders — the logic is ready for them.

## Feature checklist

### WORKING
- [x] Godot 4 project (`project.godot`) with input map, autoloads, layers
- [x] Route data JSON for Falmer–Lewes (stations, segments, gradients, tunnels, speed limits, signals)
- [x] TrackManager – load route, query speed limit, upcoming limit, gradient, station, tunnel
- [x] TrainPhysics – mass, traction curve, multi-notch power/brake, rolling resistance, gradient effect, door interlock
- [x] TrainController – input, service start, speed monitoring, station stop evaluation, HUD data provider
- [x] SignalManager – 4-aspect (G / DY / Y / R) with occupancy cascade
- [x] GameManager – service list, start/complete, scoring events
- [x] Driver HUD – speed, limit, upcoming, station, power, brake, doors, signal, gradient, score, destination
- [x] Basic Main scene bootstrap that auto-starts Falmer → Lewes for testing
- [x] Clear separation of route data from simulation code

### PARTIALLY WORKING
- [~] Stations – positions and stop scoring exist; multi-platform Lewes layout and door-side logic are simplified
- [~] Timetable – structure present, full clock and early/late calculation still basic
- [~] 3D scene – cameras and HUD exist; no track mesh or terrain yet

### PLACEHOLDER
- [ ] 3D track mesh generated from segments
- [ ] South Downs terrain / heightmap
- [ ] Train exterior + multi-coach model
- [ ] Driving cab interior with animated controls
- [ ] Door animations
- [ ] Head / tail lights visual
- [ ] Destination display
- [ ] Audio (traction, brake, horn, rail, ambient)
- [ ] Proper service selection UI (currently auto-starts)
- [ ] World streaming / LOD scaffolding

### NOT IMPLEMENTED (planned later)
- [ ] AI trains
- [ ] Passengers
- [ ] AWS / TPWS / vigilance
- [ ] Full SPAD consequences beyond scoring
- [ ] Weather systems
- [ ] Day/night cycle
- [ ] Track editor / route tools
- [ ] Expansion to Brighton, Eastbourne, Seaford branch

## How to continue

1. Open the project in Godot 4.3+.
2. Fix any script-path references in `Main.tscn` if the editor complains (the TrainPhysics node should point at `res://scripts/train/TrainPhysics.gd`).
3. Add a simple CSG or ArrayMesh track that follows the segment data so the external camera has a visual reference.
4. Build a minimal heightmap that drops ~73 m over 7 km to match the real descent.
5. Iterate on feel: power notches, brake response, stopping accuracy.

The project is deliberately left in a state that a developer with a normal machine can open and extend immediately.
