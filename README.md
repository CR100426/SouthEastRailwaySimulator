# South East Railway Simulator

**Working title:** South East Railway Simulator  
**Version:** 0.1.0-dev  
**Focus:** Falmer ↔ Lewes (East Coastway)  
**Engine:** Godot 4.3+  
**Platform:** Windows PC (standalone executable target)

## What this is

A real, original, standalone British third-rail train simulator / game.  
It is **not** a Roblox experience, not a website, and not a concept document.

The long-term goal is a connected railway network across East Sussex, West Sussex, Kent, Surrey and South London, starting with a high-quality Falmer–Lewes section and expanding along the real East Coastway and beyond.

## Current status (V0.1)

| System                    | Status              | Notes |
|---------------------------|---------------------|-------|
| Project structure         | WORKING             | Godot 4 project ready to open |
| Route data (Falmer–Lewes) | WORKING             | Real ELR mileages, gradients, stations, signals, speed limits |
| Track system              | WORKING             | Data-driven queries for limit, gradient, stations, tunnels |
| Train physics             | WORKING             | Mass, traction curve, braking, rolling resistance, gradient |
| Cab controls              | WORKING             | Power, brake, reverser, doors, horn, headlights, cameras |
| Signalling (4-aspect)     | WORKING             | GREEN / DY / YELLOW / RED based on occupancy |
| Speed limits + HUD        | WORKING             | Current + upcoming limit with distance |
| Doors                     | WORKING             | Locked while moving, cut traction when open |
| Stations                  | PARTIALLY WORKING   | Positions + stop scoring; layout still simplified |
| Service selection         | WORKING             | Two services: FMR→LWS and LWS→FMR |
| Scoring                   | WORKING             | Stops, speeding, SPADs, doors, on-time |
| 3D terrain / scenery      | PLACEHOLDER         | Needs proper meshes + heightmap (South Downs) |
| Train 3D model + cab      | PLACEHOLDER         | Logic complete; visual model to be added |
| Timetables (full clock)   | PLACEHOLDER         | Basic structure present |
| AI trains                 | NOT IMPLEMENTED     | Planned V0.5 |
| Passengers                | NOT IMPLEMENTED     | Planned V0.5 |
| Weather / lighting        | NOT IMPLEMENTED     | Planned V0.5 |
| AWS / TPWS                | NOT IMPLEMENTED     | Planned later |
| Development tools         | NOT IMPLEMENTED     | Track editor etc. planned |

## How to open and run

1. Install **Godot 4.3 or later** (standard build, not .NET required) from https://godotengine.org
2. Open Godot → Import → select the folder containing `project.godot`
3. Open the project. The main scene is `scenes/main/Main.tscn`
4. Press F5 (or Play) to run.

**Controls (while driving):**
- **W / S** – Power up / down (notches 0–5)
- **Q / A** – Brake up / down (notches 0–5)
- **F / R** – Reverser Forward / Reverse (only when nearly stopped)
- **O / C** – Doors Open / Close
- **H** – Horn
- **L** – Headlights toggle
- **1 / 2** – Cab camera / External camera
- **Esc** – Pause (to be wired)

The game currently auto-starts the **Falmer → Lewes** service for immediate testing.

## Real-world basis (Falmer–Lewes)

- Distance: ≈ 4.38 miles / 7.05 km (ELR BTL: Falmer 3.39 → Lewes 7.77)
- Typical journey: 7 minutes
- Double track, 750 V DC third rail
- Key features modelled in data:
  - Falmer Tunnel (~448 m)
  - Sustained 1-in-88 descent through the South Downs
  - Kingston Tunnel
  - Station speed restrictions
  - 4-aspect signalling skeleton

Someone who knows the real line should recognise the sequence of tunnel → long descent → approach to Lewes once the 3D scenery is in place.

## Architecture principles

- **Route data is separate from code.** New lines are added by dropping new JSON (and later mesh packs) without rewriting the simulator core.
- **Systems are modular.** TrackManager, SignalManager, TrainPhysics, GameManager, etc. can be extended independently.
- **Placeholders are honest.** Every major feature is marked WORKING / PARTIALLY WORKING / PLACEHOLDER / NOT IMPLEMENTED.
- **Performance-first design.** The architecture anticipates world streaming, LOD and large networks even though V0.1 is only 7 km.

## Roadmap (from original brief)

- **V0.1** – Falmer ↔ Lewes (current focus)
- **V0.2** – Brighton ↔ Lewes (add Moulsecoomb, London Road, Brighton)
- **V0.3** – Lewes ↔ Eastbourne
- **V0.4** – Seaford branch
- **V0.5** – AI trains, passengers, advanced signalling, weather, better audio
- **V1.0** – Complete polished East Coastway
- Later – Gatwick, London, Worthing, Hastings, Tonbridge, etc.

## Next concrete development steps (recommended order)

1. Create a simple procedural or CSG track mesh from the segment data so the camera has something to follow.
2. Add a basic heightmap / CSG terrain that roughly matches the 1-in-88 descent and South Downs profile.
3. Replace the empty train node with a simple multi-coach placeholder mesh + cab interior.
4. Improve station platforms (simple box meshes + stopping markers).
5. Wire a proper service-selection menu instead of auto-start.
6. Add original or licensed audio (traction, brake, horn, rail joint, tunnel).
7. Implement AWS/TPWS simplified logic and SPAD consequences.
8. Begin expanding the route data to Moulsecoomb / Brighton once Falmer–Lewes feels solid.

## Legal / asset note

All code and route data in this project are original.  
Do **not** import models, textures, sounds or other assets from Train Sim World, Train Simulator Classic, or any other commercial product.  
Use original work, public-domain sources, or properly licensed assets only.

## Credits

- Route geometry and signalling concepts derived from public sources (ELR mileages, Network Rail / OpenRailwayMap style data, Wikipedia, railway enthusiast references).
- Physics and systems designed for believable rather than engineering-grade accuracy.

---

**This project is intentionally left in a state that can be opened and continued immediately.**  
Quality of the first short section is prioritised over map size.
