# Map Feature

## What It Is

The map is the core screen of AquaNav. It is a multi-layer maritime map built on **flutter_map** (OpenStreetMap tiles) with real-time GPS tracking, hybrid land-and-sea routing, environmental overlays, AI fishing spot suggestions, and active navigation with voice guidance. Every other feature in the app either feeds data into the map or reads a position from it.

---

## Architecture Overview

The map is composed of three tiers that work together:

```
┌──────────────────────────────────────────────────┐
│  UI Layer (IntegratedMap + Widgets)               │
│  FlutterMap canvas, toolbars, overlays, dialogs   │
└───────────────────┬──────────────────────────────┘
                    │
┌───────────────────▼──────────────────────────────┐
│  Services Layer                                   │
│  Routing · Pathfinding · Navigation session       │
│  Mask validation · Marina data · Exclusion zones  │
└───────────────────┬──────────────────────────────┘
                    │
┌───────────────────▼──────────────────────────────┐
│  Data Layer                                       │
│  Binary navigation mask · GeoJSON assets          │
│  Firestore (outline edits) · SQLite (trips)       │
└──────────────────────────────────────────────────┘
```

---

## Sub-Feature 1: Tile Layers and Depth Visualization

The base map renders OpenStreetMap tiles via flutter_map's `TileLayer`. On top of that the user can switch between three depth modes managed by `MapLayerManager`:

| Mode | What renders |
|---|---|
| **Bathymetric** | Color gradient: deep blue → light blue → sand. Sourced from GEBCO depth data. |
| **Nautical** | OpenSeaMap overlay — navigation symbols, depth contours, buoys. |
| **Combined** | Both layers simultaneously — color depth + navigation symbols. |

An opacity slider lets the user blend depth over the base map. The layer visibility state lives in `MapLayerManager` (a `ChangeNotifier`) so any widget in the tree can react to changes without passing state manually.

---

## Sub-Feature 2: Navigation Mask (Water/Land Grid)

**File:** [lib/services/map/navigation_mask.dart](lib/services/map/navigation_mask.dart)

The navigation mask is the foundation for all routing. It is a **binary grid** stored as a `Uint8List` where each cell is either `1` (water, navigable) or `0` (land, blocked). The grid covers Bahrain's territorial waters at approximately 111 m per cell.

**How it is built:**
- Source asset: `assets/navigation/bahrain_navigation_mask.bin` (binary) + `mask_metadata.json` (grid dimensions, bounding box, resolution in degrees)
- Loaded at app startup; kept in memory for the session
- Coordinate-to-grid conversion: `coordsToGrid(lon, lat)` → `(row, col)`; inverse: `gridToCoords(row, col)` → `(lon, lat)`

**Key operations:**
- `isNavigable(lon, lat)` → true/false — used by routing to validate every point
- `findNearestWater(lon, lat, maxRadius)` — expanding circle search, used when a start or end point is snapped slightly onto land
- `validateRoute(List<LatLng>)` — walks every point in a route and reports violations
- `paintBrush(lon, lat, radius, value)` — admin editing: paints circular regions as water or land

**User editing:**
Administrators can modify the mask via a brush tool in the app. Changes are saved locally by `MaskStorageService` as `user_navigation_mask.bin`. On next startup the user-modified mask is loaded instead of the asset. A backup is created before every save. Users can also reset to the original asset mask.

---

## Sub-Feature 3: Routing System

Routing is split across three services that the `HybridRouteCoordinator` orchestrates depending on whether the journey is land-only, sea-only, or mixed.

---

### 3a. Marine Pathfinding — A* on the Water Grid

**File:** [lib/services/map/marine_pathfinding_service.dart](lib/services/map/marine_pathfinding_service.dart)

For any segment that crosses open water, the app uses **A\* pathfinding** directly on the navigation mask grid. This guarantees the route never crosses land, always avoids restricted areas, and respects weather conditions.

**Algorithm detail:**

1. Snap start and end coordinates to the nearest navigable water cell.
2. Run A\* with 8-directional movement (cardinal + diagonal):
   - Straight move cost: `1.0`
   - Diagonal move cost: `1.414` (√2)
   - Weather cost multiplier: `1.0×` (calm) to `3.0×` (rough seas, slower travel)
3. Hard-block cells that fall inside:
   - Restricted areas (checked via ray-casting point-in-polygon)
   - Exclusion zones around oil/gas platforms (500 m buffer circles)
4. Heuristic: Haversine great-circle distance to goal (admissible — never overestimates)
5. Timeout protection: maximum iteration count + wall-clock time limit to prevent the UI from hanging on pathologically complex routes
6. Reconstruct path from the `came-from` map → convert grid cells back to `LatLng` coordinates

**Output:** `List<LatLng>` route geometry + estimated duration based on average boat speed.

---

### 3b. Land Routing — OSRM

**File:** [lib/services/map/osrm_routing_service.dart](lib/services/map/osrm_routing_service.dart)

For land segments (e.g., driving to a marina), the app calls the **OSRM** (Open Source Routing Machine) public API over HTTPS. OSRM handles all road-network logic and returns:
- Full route geometry as GeoJSON coordinates
- Turn-by-turn steps with maneuver type and modifier (turn left, keep right, etc.)
- Distance and duration estimates

The service retries up to 3 times with exponential backoff (500 ms × attempt) and has a 10-second timeout. Up to 3 alternative routes are requested.

---

### 3c. Hybrid Routing — Land + Sea

**File:** [lib/services/map/hybrid_route_coordinator.dart](lib/services/map/hybrid_route_coordinator.dart)

The coordinator picks the right strategy based on where origin and destination fall:

| Scenario | Strategy |
|---|---|
| Both on land | Single OSRM call |
| Both on water | Single A* marine pathfinding call |
| Land → Sea | Find best marina, OSRM to marina, A* from marina to destination |
| Sea → Land | Find nearest marina to destination, A* to marina, OSRM from marina |

**Finding the best marina (land-to-sea):**
The coordinator asks `MarinaDataService.findBestShorePoint()`, which minimizes a weighted cost:

```
cost = 1.5 × land_distance + 1.0 × marine_distance
```

The 1.5× weight on land distance reflects slower land travel vs. boat travel. This picks a marina that is close by road and does not force a long detour at sea.

**Waypoint generation:**
OSRM turn steps are converted to `Waypoint` objects with instruction text ("Turn left onto King Faisal Highway"). Transition waypoints are inserted at marina entry and exit points ("Launch boat here", "Return to land"). The waypoint list drives voice guidance and the on-screen instruction card.

**Route validation:**
The final merged geometry is validated against the navigation mask. Any point that falls on land triggers a route warning shown to the user before navigation starts.

---

## Sub-Feature 4: Real-Time Navigation Session

**File:** [lib/services/map/navigation_session_manager.dart](lib/services/map/navigation_session_manager.dart)

Once the user starts navigation, `NavigationSessionManager` takes over and manages the active session.

**Session lifecycle:**

```
Planning → Ready → Active → Completed
                 ↘ Paused ↗
                 ↘ Cancelled
                 ↘ Error (GPS loss / routing failure)
```

**During Active state, every GPS update triggers:**

1. **Waypoint proximity check** — if user is within threshold distance of the next waypoint, advance the waypoint index.
2. **Off-route detection** — if user drifts more than 50 m from the route geometry, flag as off-route and schedule a recalculation (with a 30-second cooldown, max 5 recalculations per session).
3. **Exclusion zone check** — `ExclusionZoneService.checkViolation()` fires an alert if the vessel enters a 500 m platform buffer.
4. **Breadcrumb trail** — every GPS point is appended to the session's breadcrumb list (used for trip log replay).
5. **Progress update** — distance traveled, remaining, ETA, and completion percentage are recalculated.
6. **Weather refresh** — every 60 seconds, weather is re-fetched. If conditions worsen, the route is recalculated.
7. **Voice announcement** — at 200 m from each waypoint, `NavigationVoiceService` reads the next instruction aloud (en-US, 0.48× speed for clarity).

**GPS configuration:** High accuracy mode, 5 m minimum distance filter (avoids unnecessary updates while stationary).

---

## Sub-Feature 5: GeoJSON Overlays

**File:** [lib/widgets/map/geojson_layers.dart](lib/widgets/map/geojson_layers.dart)

**Data source:** `assets/data/gulf_test_features.geojson`

Four feature types are parsed and rendered as flutter_map `PolygonLayer` entries:

| Type | Fill | Border | Role |
|---|---|---|---|
| Protected zones | Red, 15% opacity | Red, 2 px | Marine protected areas — no fishing |
| Fishing zones | Green, 15% opacity | Green, 2 px | Designated fishing areas |
| Restricted areas | Red, 25% opacity | Red, 3 px bold | Navigation prohibited |
| Reefs | Brown, 15% opacity | Brown, 2 px | Hazards and natural fishing grounds |

These polygons are also passed to the A\* pathfinder as hard-block regions — so the route will never be drawn through a restricted area even if the mask grid would technically allow it.

All four layers can be toggled independently from the layer control panel.

---

## Sub-Feature 6: Exclusion Zones (Oil & Gas Platforms)

**File:** [lib/services/map/exclusion_zone_service.dart](lib/services/map/exclusion_zone_service.dart)

**Data source:** `assets/data/bahrain_exclusion_zones.geojson`

Each platform entry is loaded and given a **500 m mandatory safety buffer** in compliance with UNCLOS Article 60. The buffer is rendered on the map as a circle polygon (16 points).

The service has three proximity states:
- **Inside buffer** → hard warning, route refused
- **Approaching** → advisory alert shown to navigator
- **Clear** → no display

During A\* pathfinding, each exclusion zone is converted to a 16-point circular polygon and passed as a hard-block region. The pathfinder will route around it without any user configuration needed.

---

## Sub-Feature 7: Marina / Port Data

**File:** [lib/services/map/marina_data_service.dart](lib/services/map/marina_data_service.dart)

**Data source:** `assets/data/marinas.geojson`

Marinas are the transition points between land and sea routes. Each entry stores:
- Location, name, type (Marina / Harbor / Slipway / Boat Ramp / Port)
- Access type (Public / Private / Customers Only / Permissive)
- Water depth, available facilities, OSM reference ID

At startup, each marina is validated against the navigation mask — any marina that maps to a land cell is filtered out (data error). Only validated, publicly accessible marinas are offered as routing transition points.

---

## Sub-Feature 8: AI Fishing Spot Overlay (Bahaar)

**File:** [lib/widgets/map/bahaar_overlay_layer.dart](lib/widgets/map/bahaar_overlay_layer.dart)

When the fishing suggestions layer is enabled, the map calls the Bahaar AI backend (`https://bahaar-whjo.onrender.com/spots/nearby`) and renders:
- **MPA circles** — red semi-transparent circles around marine protected areas where fishing is prohibited
- **Spot markers** — color-coded pins at AI-suggested fishing locations, with confidence score and species information
- Tapping a spot opens a bottom sheet with details and a "Get Prediction" button that links to the Prediction screen

---

## Sub-Feature 9: Collaborative Boundary Editing

**File:** [lib/services/map/outline_edit_service.dart](lib/services/map/outline_edit_service.dart)

Administrators can modify the territorial boundary (navigation mask) directly on the map using a brush tool. Every brush stroke is stored as an `OutlineEdit` document in Firestore (`territorial_outline_edits` collection):

```
OutlineEdit {
  point: LatLng     (center of brush stroke)
  radius: double    (brush radius in degrees)
  erase: bool       (true = paint land, false = paint water)
  deleted: bool     (soft-delete for undo)
  timestamp: DateTime
}
```

Because this uses Firestore's real-time listener, all connected admin devices see changes immediately. Individual strokes can be undone by setting `deleted: true`. A full reset restores the original asset mask.

---

## Sub-Feature 10: Feature Drawing and Editing

**Files:** [lib/widgets/map/feature_drawing_layer.dart](lib/widgets/map/feature_drawing_layer.dart), [lib/services/map/feature_edit_service.dart](lib/services/map/feature_edit_service.dart)

Users can draw new map features (polygons, polylines, points) directly on the map:
- Tap to place vertices; live preview updates with each tap
- Drag existing vertices to reshape
- Delete selected features
- Changes are persisted and synced

State is managed through `EditableMapFeature` and `FeatureEditState` models which track the current editing mode, selected feature, and pending vertex list.

---

## Full Data Flow: Land-to-Sea Navigation

```
User taps destination on water
          │
IntegratedMap._onMapTap()
          │
HybridRouteCoordinator.calculate(origin=land, dest=sea)
    ├── MarinaDataService.findBestShorePoint()
    │       cost = 1.5 × landDist + 1.0 × marineDist
    │       → best marina selected
    │
    ├── OsrmRoutingService.getRoute(origin → marina)
    │       HTTP GET to OSRM API
    │       → land segment geometry + OSRM turn steps
    │
    └── MarinePathfindingService.findRoute(marina → dest)
            A* on navigation mask grid
            Hard blocks: restricted areas + exclusion zones
            Weather cost multipliers applied
            → marine segment geometry
          │
HybridRouteCoordinator._generateWaypoints()
    OSRM steps → Waypoint objects
    Marina entry/exit → transition waypoints
          │
NavigationMask.validateRoute()  ← check no land crossings
          │
Route displayed on map (polyline + waypoint markers)
          │
User taps "Start Navigation"
          │
NavigationSessionManager.startNavigation(route)
    GPS stream: high accuracy, 5 m filter
          │
    Every GPS update:
        ├── Advance waypoint if within proximity
        ├── Off-route? → recalculate (30s cooldown, max 5×)
        ├── Exclusion zone? → alert
        ├── Append breadcrumb
        ├── Refresh progress / ETA
        ├── Every 60s: refresh weather
        └── 200 m before waypoint → TTS announcement
          │
User reaches destination
    NavigationState.completed
    Trip saved to SQLite (breadcrumbs, catches, duration)
```

---

## Key Files

| File | Role |
|---|---|
| [lib/screens/map/integrated_map.dart](lib/screens/map/integrated_map.dart) | Main screen, lifecycle, layer orchestration |
| [lib/services/map/map_layer_manager.dart](lib/services/map/map_layer_manager.dart) | Layer visibility / opacity state |
| [lib/services/map/navigation_mask.dart](lib/services/map/navigation_mask.dart) | Binary water/land grid, routing validation |
| [lib/services/map/marine_pathfinding_service.dart](lib/services/map/marine_pathfinding_service.dart) | A* routing on water grid |
| [lib/services/map/osrm_routing_service.dart](lib/services/map/osrm_routing_service.dart) | OSRM land routing API client |
| [lib/services/map/hybrid_route_coordinator.dart](lib/services/map/hybrid_route_coordinator.dart) | Orchestrates land + sea segments |
| [lib/services/map/navigation_session_manager.dart](lib/services/map/navigation_session_manager.dart) | Real-time active navigation session |
| [lib/services/map/exclusion_zone_service.dart](lib/services/map/exclusion_zone_service.dart) | Platform safety buffers |
| [lib/services/map/marina_data_service.dart](lib/services/map/marina_data_service.dart) | Marina loading, filtering, shore-point selection |
| [lib/services/map/outline_edit_service.dart](lib/services/map/outline_edit_service.dart) | Firestore-backed boundary editing |
| [lib/services/map/mask_storage_service.dart](lib/services/map/mask_storage_service.dart) | Offline persistence of user mask edits |
| [lib/widgets/map/geojson_layers.dart](lib/widgets/map/geojson_layers.dart) | GeoJSON overlay rendering |
| [lib/widgets/map/bahaar_overlay_layer.dart](lib/widgets/map/bahaar_overlay_layer.dart) | AI fishing spots + MPA circles |
| [lib/widgets/map/feature_drawing_layer.dart](lib/widgets/map/feature_drawing_layer.dart) | Interactive feature drawing |
| [lib/utilities/cn/geometry_utils.dart](lib/utilities/cn/geometry_utils.dart) | Douglas-Peucker, ray-casting, Haversine |
| [lib/models/navigation/route_model.dart](lib/models/navigation/route_model.dart) | Route, segment, waypoint, metrics |
| [assets/navigation/bahrain_navigation_mask.bin](assets/navigation/bahrain_navigation_mask.bin) | Binary water/land grid |
| [assets/data/gulf_test_features.geojson](assets/data/gulf_test_features.geojson) | Zones, reefs, restricted areas |
| [assets/data/marinas.geojson](assets/data/marinas.geojson) | Marina / port locations |
| [assets/data/bahrain_exclusion_zones.geojson](assets/data/bahrain_exclusion_zones.geojson) | Oil/gas platform locations |

---

---

# One-Minute Slide Presentation

> Read at a calm pace. Three blocks of roughly 20 seconds each.

---

**Opening (20 sec):**
"The map is the central feature of AquaNav. It is a multi-layer maritime map that supports real-time GPS navigation, hybrid land-and-sea routing, and a set of environmental overlays specific to Bahrain's territorial waters — protected zones, fishing zones, reefs, oil platform exclusion zones, and AI-suggested fishing spots. Every other feature in the app either pushes data onto the map or reads a position from it."

**How it works (25 sec):**
"The map is built on flutter_map with OpenStreetMap tiles, but the intelligence sits in the routing system. Navigation follows a three-tier approach: for land segments the app calls the OSRM routing API to get turn-by-turn road directions; for sea segments it runs A-star pathfinding on a binary water/land grid called the navigation mask — a grid where every cell is either water or land at roughly 111-metre resolution. When a journey crosses from land to sea, the app finds the optimal marina to use as the transition point by minimizing a weighted cost of road distance and marine distance, then stitches the two segments together into a single hybrid route. During active navigation, GPS updates arrive every 5 metres, and the session manager handles waypoint progression, off-route detection with automatic recalculation, voice guidance, and exclusion zone alerts."

**Key value (15 sec):**
"What makes this distinct from a standard navigation app is that it understands maritime constraints natively — the pathfinder will never route through a marine protected area or an oil platform safety buffer, even if the water grid would technically allow it, because those zones are injected as hard blocks into the A-star algorithm. And the depth visualization layer gives fishermen bathymetric context directly underneath the navigation chart."

---

---

# Common Examiner Questions

---

**Q1: Why did you build a custom A\* pathfinder instead of using an existing maritime routing API?**

Maritime routing APIs are either expensive, have coverage gaps in the Gulf region, or do not support application-specific constraints like dynamically injected restricted areas, weather-based cost multipliers, and real-time exclusion zone enforcement. By owning the pathfinder we can hard-block any polygon at call time — including zones the user just drew — without waiting for an external service to update. The navigation mask is also stored on-device, so routing works fully offline.

---

**Q2: What is the navigation mask and how was it created?**

The navigation mask is a binary `Uint8List` grid where `1` = water and `0` = land, at approximately 111-metre cell resolution, covering Bahrain's territorial waters. It was generated offline from coastline data and stored as a binary asset file alongside a JSON metadata file describing its bounding box, resolution, and dimensions. The binary format keeps the file small and fast to load into memory. Administrators can also modify it in the app using a brush tool, and those changes are persisted locally and optionally shared via Firestore.

---

**Q3: How does the hybrid routing work — can you walk through the land-to-sea case?**

When the origin is on land and the destination is on water, the coordinator calls `findBestShorePoint()` on the marina service, which scores each marina using `1.5 × land distance + 1.0 × marine distance`. The 1.5 weight reflects that land travel is slower. The lowest-cost marina is selected as the transition point. Then OSRM routes the land leg (origin to marina), the A\* pathfinder routes the marine leg (marina to destination), and the two geometries are merged into a single route with a transition waypoint inserted at the marina marked "Launch boat here." The full geometry is then validated against the mask before being shown to the user.

---

**Q4: How does off-route detection and recalculation work?**

During active navigation the session manager computes the perpendicular distance from the current GPS position to every segment of the route polyline using the `distanceToLineString` utility. If that distance exceeds 50 metres, the session is flagged as off-route and a recalculation is scheduled. A 30-second cooldown prevents the system from spamming recalculations if the user briefly deviates and corrects. The session allows a maximum of 5 recalculations before it stops trying and asks the user to manually restart.

---

**Q5: How are restricted areas enforced in the routing — can the user route around them?**

Restricted areas are enforced at two levels. First, the GeoJSON polygons (protected zones, restricted areas, exclusion zone circles) are passed into the A\* pathfinder as hard-block regions. Before the algorithm expands a neighbor cell, it checks whether that cell's coordinate falls inside any blocked polygon using a ray-casting point-in-polygon test. If it does, the cell is skipped entirely — it cannot be part of any valid path. This means the route automatically goes around these areas. If no valid path exists (e.g., the destination is inside a protected zone), the routing returns null and the user is informed they cannot navigate there.

---

**Q6: Why use OSRM for land routing instead of Google Maps or a similar API?**

OSRM is open-source, has no per-request cost, and runs on public road network data from OpenStreetMap. Google Maps Directions API charges per request and has terms of service restrictions around caching and display. Since the app already uses OpenStreetMap tiles for the base map, using OSRM keeps the data source consistent. OSRM also returns the full route geometry and per-step maneuvers in a well-documented format that maps cleanly to the app's waypoint model.

---

**Q7: What happens if the OSRM API is unavailable (offline)?**

Currently, land routing requires OSRM connectivity. If the request fails after 3 retries, the route calculation returns null and the user sees an error message. Marine routing, however, is fully offline because it only uses the on-device navigation mask grid. A future improvement would be caching recent OSRM responses for repeated routes.

---

**Q8: How does the depth visualization work — where does the bathymetric data come from?**

The bathymetric layer renders depth gradient tiles sourced from **GEBCO** (General Bathymetric Chart of the Oceans), which is a publicly available global ocean depth dataset maintained by the British Oceanographic Data Centre. The nautical symbols layer comes from **OpenSeaMap**, which adds navigation-specific overlays (buoys, depth contours, anchorages) on top of OpenStreetMap. Both are fetched as standard tile layers (z/x/y URL scheme) so they integrate directly into flutter_map's `TileLayer` with no custom rendering needed.

---

**Q9: How is the 500-metre exclusion zone around oil platforms enforced, and where does that number come from?**

The 500-metre mandatory safety zone around offshore installations is defined in **UNCLOS Article 60** (United Nations Convention on the Law of the Sea), which Bahrain is a signatory to. The exclusion zone service loads platform coordinates from a GeoJSON asset, generates a 16-point circular polygon at 500 m radius for each one, and passes those polygons to the A\* pathfinder as hard-block regions. During active navigation, the service also does a live Haversine distance check on every GPS update and triggers an on-screen alert if the vessel enters the buffer.

---

**Q10: How does voice navigation work?**

The `NavigationVoiceService` wraps Flutter TTS (text-to-speech). It listens to the session manager's waypoint progression. When the user comes within 200 metres of the next waypoint, it reads the waypoint's instruction string aloud — for example "In 200 metres, turn left onto King Faisal Highway" or "You are approaching the marina — prepare to launch." Each waypoint is tracked by index so the same instruction is never spoken twice. The speech rate is set to 0.48× (slightly slower than normal) for clarity in outdoor conditions.
