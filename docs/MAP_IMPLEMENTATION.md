
# AquaNav (Bahaar) - Map Page Implementation Document

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [File Structure](#file-structure)
3. [Main Map Screen](#main-map-screen)
4. [Services Layer](#services-layer)
5. [Widgets Layer](#widgets-layer)
6. [Models Layer](#models-layer)
7. [Data Assets](#data-assets)
8. [Initialization Flow](#initialization-flow)
9. [Routing System](#routing-system)
10. [Navigation Session Lifecycle](#navigation-session-lifecycle)
11. [Admin Edit Mode](#admin-edit-mode)

---

## Architecture Overview

The map page follows a **layered architecture** with clean separation of concerns:

```
┌─────────────────────────────────────────────┐
│              IntegratedMap Screen            │  ← Entry point & state orchestration
├─────────────────────────────────────────────┤
│                 Widgets Layer                │  ← UI components (layers, markers, panels)
├─────────────────────────────────────────────┤
│                Services Layer                │  ← Business logic (routing, mask, marinas)
├─────────────────────────────────────────────┤
│                 Models Layer                 │  ← Data classes (route, marina, session)
├─────────────────────────────────────────────┤
│          Constants & Utilities               │  ← Configuration values
├─────────────────────────────────────────────┤
│            Assets (GeoJSON, binary)          │  ← Static data files
└─────────────────────────────────────────────┘
```

**Key technology:** The map uses `flutter_map` (v8.2.2) with `latlong2` for coordinate handling and OpenStreetMap/OpenSeaMap tile providers.

---

## File Structure

### Screen
| File | Purpose |
|------|---------|
| `lib/screens/integrated_map.dart` | Main map page - StatefulWidget that orchestrates all map features |

### Services (`lib/services/map/`)
| File | Purpose |
|------|---------|
| `map_layer_manager.dart` | Centralized state for all map layer visibility and settings |
| `navigation_mask.dart` | Binary grid-based land/water classification for Bahrain's coastline |
| `marine_pathfinding_service.dart` | A* pathfinding algorithm for water-only routes |
| `osrm_routing_service.dart` | HTTP client for OSRM land-based driving/walking/cycling routes |
| `hybrid_route_coordinator.dart` | Orchestrates combined land+marine routing with marina handoffs |
| `navigation_session_manager.dart` | Real-time GPS tracking, off-route detection, waypoint advancement |
| `marina_data_service.dart` | Loads, validates, and queries marina/port data from GeoJSON |
| `mask_storage_service.dart` | Persists admin edits to the navigation mask in local storage |

### Widgets - Map (`lib/widgets/map/`)
| File | Purpose |
|------|---------|
| `enhanced_depth_layer.dart` | Bathymetric/nautical depth visualization with water-only masking |
| `geojson_layers.dart` | Renders GeoJSON overlays (fishing zones, shipping lanes, protected areas) |
| `layer_control_panel.dart` | UI panel for toggling map layers on/off |
| `admin_edit_toolbar.dart` | Toolbar for admin mask editing (brush tools, save/reset) |

### Widgets - Navigation (`lib/widgets/navigation/`)
| File | Purpose |
|------|---------|
| `marina_marker_layer.dart` | Renders marina markers and info cards on the map |
| `route_polyline_layer.dart` | Renders calculated route as colored polylines (blue=marine, grey=land) |
| `destination_picker_panel.dart` | UI for selecting navigation destinations |
| `active_navigation_overlay.dart` | HUD overlay during active navigation (speed, ETA, distance, instructions) |

### Models
| File | Purpose |
|------|---------|
| `lib/models/navigation/route_model.dart` | `NavigationRoute`, `RouteSegment`, `RouteMetrics`, `SegmentType` |
| `lib/models/navigation/marina_model.dart` | `Marina`, `MarinaType`, `MarinaAccessType` |
| `lib/models/navigation/navigation_session_model.dart` | `NavigationSession`, `NavigationState`, `NavigationMetrics` |
| `lib/models/navigation/waypoint_model.dart` | `Waypoint`, `WaypointType`, `RouteSegmentType` |

### Constants
| File | Purpose |
|------|---------|
| `lib/utilities/map_constants.dart` | Tile URLs (OSM, OpenSeaMap), zoom levels, default center (Bahrain) |

---

## Main Map Screen

**File:** `lib/screens/integrated_map.dart`

The `IntegratedMap` widget is the single entry point for the entire map feature. It is a `StatefulWidget` that:

### State Variables
- **Controllers:** `MapController` (flutter_map), `Location` (GPS), `NavigationMask`, `MarinaDataService`, `MapLayerManager`
- **Routing services:** `OsrmRoutingService`, `MarinePathfindingService`, `HybridRouteCoordinator`, `NavigationSessionManager`
- **UI state:** map readiness, location permissions, mask initialization, depth legend visibility, admin edit mode painted cells
- **Navigation state:** selected marina, current route, origin/destination points, port selection mode
- **Predefined ports:** 3 hardcoded Bahrain ports (Mina Salman, Manama Marina, Muharraq Harbor)

### Map Layer Stack (in `_buildMap()`)
The map renders layers in this order (bottom to top):

1. **Base map** - OpenStreetMap tiles
2. **Enhanced depth layer** - Bathymetric colors or nautical chart (via `EnhancedDepthLayer`)
3. **GeoJSON layers** - Fishing zones, shipping lanes, protected areas (via `GeoJsonMapLayers`)
4. **Navigation mask overlay** - Purple boundary cells showing water edges
5. **Painted cells overlay** - Admin edit visualization (blue=water, brown=land, grey=eraser)
6. **Marina markers** - Clickable marina icons (via `MarinaMarkerLayer`)
7. **Route polyline** - Calculated route visualization (via `RoutePolylineLayer`)
8. **Breadcrumb trail** - Purple line showing path traveled during navigation
9. **Origin/destination markers** - Green circle (origin) and red pin (destination)
10. **Port markers** - Anchor icons for predefined ports
11. **Sea destination marker** - Blue pin for marine navigation target
12. **User location marker** - Blue (on water) or orange (on land) GPS position

### Key Methods

| Method | What it does |
|--------|-------------|
| `_initLocation()` | Requests GPS permissions, gets initial location |
| `_initNavigationMask()` | Loads binary mask data for land/water detection |
| `_loadGeoJson()` | Loads `gulf_test_features.geojson` for zone overlays |
| `_initMarinas()` | Loads marina data from `marinas.geojson`, validates against mask |
| `_initRoutingServices()` | Initializes OSRM, A* pathfinding, hybrid coordinator, session manager |
| `_handleMapTap()` | Handles tap: admin paint, or set sea destination in port selection mode |
| `_calculateRoute()` | Calculates route from current GPS to a destination via `HybridRouteCoordinator` |
| `_calculatePortToSeaRoute()` | Calculates land-to-port (OSRM) + port-to-sea (A*) combined route |
| `_startNavigation()` | Begins real-time GPS tracking along calculated route |
| `_endNavigation()` | Stops navigation session and clears route |
| `_enterAdminEditMode()` | Enables admin mask painting mode |
| `_handleAdminPaint()` | Paints water/land cells on the navigation mask |

### UI Overlay Structure (in `build()`)
The screen uses a `Stack` layout:
- Full-screen `FlutterMap` wrapped in `GestureDetector` (for admin painting)
- Navigation status indicator (top right) - green "Navigation Ready" or grey "Loading"
- Layer control panel (top left) - toggleable panel for layer settings
- Admin edit toolbar (top left, replaces layer panel in admin mode)
- Layer control toggle button (top left, when panel is hidden)
- Depth legend toggle + legend widget
- Marina info card (bottom, when marina selected)
- Route stats card (bottom, when route calculated)
- Active navigation overlay (full-width, during navigation)
- Navigation FAB button (boat icon to start port selection)
- Port selection instructions panel
- Route calculation loading spinner (fullscreen overlay)
- Zoom controls (bottom right) - zoom in/out + my location

---

## Services Layer

### 1. MapLayerManager (`map_layer_manager.dart`)

A `ChangeNotifier` that centrally manages the visibility and settings of all map layers. Every toggle in the layer control panel modifies this object, and `ListenableBuilder` widgets in the map rebuild only the affected layers.

**Managed state:**
- `showBaseMap` - OSM tile layer on/off
- `showDepthLayer` + `depthLayerOpacity` + `depthVisualizationType` - depth visualization settings (bathymetric / nautical / combined)
- `showGeoJsonLayers` + individual toggles for fishing spots, shipping lanes, protected zones, fishing zones, restricted areas
- `showMaskOverlay` - navigation mask boundary visualization
- `isAdminEditMode` + `brushType` (water/land/eraser) + `brushRadius` (1-5 cells) - admin editing state

### 2. NavigationMask (`navigation_mask.dart`)

The core land/water detection system. It loads a **pre-generated binary grid** (`bahrain_navigation_mask.bin`) where each byte represents one cell: `1` = water (navigable), `0` = land (blocked).

**How it works:**
- Loads a flat `Uint8List` binary file and a JSON metadata file containing bounding box coordinates (`minLon`, `maxLon`, `minLat`, `maxLat`) and grid dimensions (`width`, `height`, `resolution_degrees`)
- Converts geographic coordinates (lon/lat) to grid indices using: `col = (lon - minLon) / resolution`, `row = (maxLat - lat) / resolution`
- Checks the byte at `index = row * width + col` to determine navigability

**Key capabilities:**
- `isNavigable(lon, lat)` / `isPointNavigable(point)` - single point water check
- `findNearestWater(lon, lat)` - expanding circle search to find closest water cell
- `validateRoute(points)` - validates an entire route, returns count of land/water points
- `paintBrush(lon, lat, radius, value)` - admin tool to paint cells as water or land
- `_expandMaskToInclude(lon, lat)` - dynamically grows the grid if painting outside bounds
- `saveChanges()` / `resetToOriginal()` - persist or revert admin edits via `MaskStorageService`
- `getBoundaryWaterCells()` - returns water cells adjacent to land (for efficient outline rendering)

### 3. MarinePathfindingService (`marine_pathfinding_service.dart`)

Implements **A* pathfinding** on the navigation mask grid to find water-only routes.

**Algorithm details:**
- Converts origin/destination `LatLng` to grid cells, snapping to nearest water if needed
- Uses 8-directional movement (N, S, E, W, NE, NW, SE, SW)
- Diagonal moves cost `sqrt(2)`, cardinal moves cost `1.0`
- Heuristic: Euclidean distance between grid cells
- **Hard blocks** restricted area polygons (uses ray-casting point-in-polygon test)
- Has timeout and max iteration limits to prevent infinite loops
- Reconstructs path and converts grid cells back to `LatLng` coordinates
- Returns a `RouteSegment` with type `SegmentType.marine`

### 4. OsrmRoutingService (`osrm_routing_service.dart`)

HTTP client that queries an **OSRM (Open Source Routing Machine)** server for land-based routes (driving, walking, cycling).

**Features:**
- Retry logic with exponential backoff (up to `maxRetries`)
- Configurable timeout
- Parses OSRM GeoJSON response into `RouteSegment` objects
- `getRoute()` - single best route
- `getAlternativeRoutes()` - up to 3 alternatives
- `getRouteEstimate()` - quick distance/duration without full geometry
- `isServiceAvailable()` - health check

### 5. HybridRouteCoordinator (`hybrid_route_coordinator.dart`)

The **orchestrator** that determines the correct routing strategy based on whether origin and destination are on land or water:

| Origin | Destination | Strategy |
|--------|-------------|----------|
| Land | Land | OSRM land-only route |
| Water | Water | A* marine-only route |
| Land | Water | OSRM to nearest marina, then A* from marina to sea destination |
| Water | Land | A* to nearest marina, then OSRM from marina to destination |

**Key method: `calculateRoute()`**
1. Checks if origin/destination are on water using `NavigationMask`
2. Selects appropriate strategy
3. For hybrid routes, uses `MarinaDataService.findNearestMarina()` as the transition point
4. Assembles `NavigationRoute` from segments with waypoints (start, marina entry/exit, end)
5. Validates route against restricted areas

**Also provides:** `calculateLandToSeaRoute()` - enforced land-origin → marina → sea-destination pattern using `MarinaDataService.findBestShorePoint()` for optimal marina selection.

### 6. NavigationSessionManager (`navigation_session_manager.dart`)

Manages **real-time GPS-tracked navigation sessions**. Extends `ChangeNotifier` so the UI rebuilds on every location update.

**Lifecycle:**
1. `startNavigation(route)` - configures high-accuracy GPS, creates `NavigationSession`, subscribes to location stream
2. Each GPS update triggers `_handleLocationUpdate()`:
   - Updates breadcrumb trail (capped at `maxBreadcrumbs`)
   - Calculates metrics (distance traveled, elapsed time, max speed)
   - Checks waypoint proximity - advances to next waypoint when within threshold
   - Checks off-route detection - measures perpendicular distance to current segment
3. If off-route: automatically recalculates route via `HybridRouteCoordinator` (up to `maxRecalculations`)
4. `cancelNavigation()` or `_completeNavigation()` cleans up GPS subscription

**States:** `active`, `paused`, `cancelled`, `completed`, `error`

### 7. MarinaDataService (`marina_data_service.dart`)

Loads marina/port data from `marinas.geojson`, validates each marina against the navigation mask (only keeps those on water), and provides query methods.

**Key methods:**
- `findNearestMarina(point)` - closest marina within max distance
- `findBestShorePoint(landOrigin, seaDestination)` - finds optimal marina for land-to-sea routing using weighted scoring: `landDistance * 1.5 + marineDistance`
- `findMarinasInRadius()`, `getMarinasByType()`, `getPublicMarinas()`, `getMarinasNearby()`

### 8. MaskStorageService (`mask_storage_service.dart`)

Handles **local persistence** of admin mask edits using the device's documents directory.

**Files managed:**
- `user_navigation_mask.bin` - modified mask binary data
- `user_navigation_mask_metadata.json` - grid dimensions and bounding box after any expansions
- `user_navigation_mask_backup.bin` - backup before each save

On app startup, `NavigationMask.initialize()` checks for a user-modified mask first; if found, it uses that instead of the bundled asset.

---

## Widgets Layer

### EnhancedDepthLayer (`enhanced_depth_layer.dart`)

Renders depth visualization with three modes:
- **Bathymetric** - EMODnet Bathymetry tiles (colored depth: light blue=shallow, dark blue=deep)
- **Nautical** - OpenSeaMap tiles (navigation symbols, buoys, depth contours)
- **Combined** - Both layers stacked (bathymetric at 60% opacity + nautical on top)

**Water masking:** Each tile is clipped using `_WaterOnlyClipper`, a `CustomClipper<Path>` that samples a 32x32 grid across the tile, checks each sample point against the `NavigationMask`, and only renders cells that are on water. This prevents depth tiles from showing over land.

Also includes a `DepthLegend` widget showing depth color scale from 0-10m (very shallow) to 3000m+ (abyssal).

### GeoJsonLayerBuilder & GeoJsonMapLayers (`geojson_layers.dart`)

Parses GeoJSON feature collections and converts them to flutter_map objects:
- **Fishing spots** (`type: fishing_spot`) -> `Marker` icons (blue location pins)
- **Shipping lanes** (`type: shipping_lane`, `patrol_route`) -> `Polyline` (red/orange lines)
- **Protected zones** (`type: protected_zone`, `reef`) -> `Polygon` (red/brown fill)
- **Fishing zones** (`type: fishing_zone`) -> `Polygon` (green fill)
- **Restricted areas** (`type: restricted_area`) -> `Polygon` (red fill, thick border)

The `GeoJsonMapLayers` widget stacks these as: polygons (bottom) -> polylines (middle) -> markers (top).

### LayerControlPanel (`layer_control_panel.dart`)

A floating panel with toggles for every layer. Reads from and writes to `MapLayerManager`. Includes depth visualization type selector and an "Enter Admin Edit Mode" button.

### AdminEditToolbar (`admin_edit_toolbar.dart`)

Visible only in admin edit mode. Provides:
- Brush type selection (water/land/eraser)
- Brush radius slider (1-5 cells)
- Zoom in/out buttons (since map gestures are disabled during painting)
- Save mask / Reset mask / Exit edit mode buttons

---

## Models Layer

### NavigationRoute (`route_model.dart`)

The central data class representing a calculated route:
- `segments: List<RouteSegment>` - ordered list of land/marine sections
- `geometry: List<LatLng>` - flattened list of all points (for polyline rendering)
- `waypoints: List<Waypoint>` - navigation instructions (start, marina transitions, end)
- `validation: RouteValidation` - how many points are on water vs land
- `metrics: RouteMetrics` - breakdown of land vs marine distance/duration
- `isHybrid` - true if route contains both land and marine segments

### RouteSegment

A single section of a route:
- `type: SegmentType` - `land` or `marine`
- `geometry: List<LatLng>` - points for this segment
- `distance` / `duration` - meters and seconds
- `transportMode` - "car", "walk", "boat"
- `entryMarina` / `exitMarina` - marina used for land/water transition

### Marina (`marina_model.dart`)

Represents a marina, harbor, slipway, boat ramp, or port:
- Parsed from GeoJSON features or OpenStreetMap node data
- Types: `marina`, `harbor`, `slipway`, `boatRamp`, `port`
- Access types: `public`, `private`, `customers`, `permissive`
- Optional fields: `depth`, `facilities`, `osmId`

### NavigationSession (`navigation_session_model.dart`)

Active navigation state:
- Current GPS location, bearing, speed
- Current segment and waypoint indices
- Breadcrumb trail (list of past positions)
- Metrics: distance traveled, elapsed time, max speed, recalculation count

---

## Data Assets

| File | Format | Purpose |
|------|--------|---------|
| `assets/navigation/bahrain_navigation_mask.bin` | Binary (Uint8List) | Pre-computed land/water grid for Bahrain coastline |
| `assets/navigation/mask_metadata.json` | JSON | Bounding box, grid dimensions, resolution for the mask |
| `assets/data/marinas.geojson` | GeoJSON | Marina and port locations with properties (type, access, facilities) |
| `assets/data/gulf_test_features.geojson` | GeoJSON | Fishing zones, shipping lanes, protected areas, restricted areas |

### Mask Processing Scripts (`lib/widgets/map/mask/`)

Python scripts used **offline** to generate the binary mask from geographic data:
- `Coastline_processor.py` - Processes coastline shapefiles
- `territorial_water_processor.py` - Processes territorial water boundaries
- `mask_visualizer.py` - Visualization tool for debugging masks
- `validate_territorial_waters.py` - Validates mask accuracy

These scripts produce `.tif`, `.bin`, `.npz`, and `.geojson` files in the same directory. The `.bin` file is then placed in `assets/navigation/` for the Flutter app.

---

## Initialization Flow

When `IntegratedMap` is mounted, `initState()` kicks off 5 parallel initialization tasks:

```
initState()
├── _initLocation()          → GPS permissions + first location fix
├── _initNavigationMask()    → Load binary mask + metadata
├── _loadGeoJson()           → Parse gulf_test_features.geojson
├── _initMarinas()           → [waits for mask] → Load marinas.geojson → validate against mask
└── _initRoutingServices()   → [waits for mask + marinas + geojson]
    ├── Create OsrmRoutingService
    ├── Create MarinePathfindingService (needs mask)
    ├── Create HybridRouteCoordinator (needs all services)
    └── Create NavigationSessionManager (needs coordinator)
```

Dependencies are enforced with polling loops: `_initMarinas()` waits for `_maskInitialized`, and `_initRoutingServices()` waits for mask + marinas + GeoJSON to all be ready.

---

## Routing System

### Route Calculation Flow

```
User taps marina → "Navigate" → _calculateRoute(marina.location)
                                    │
                                    ▼
                        HybridRouteCoordinator.calculateRoute()
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              Land→Land        Land→Water       Water→Water
              (OSRM only)     (OSRM+A*)        (A* only)
                    │               │               │
                    ▼               ▼               ▼
              RouteSegment    [land seg +       RouteSegment
              (type: land)    marine seg]       (type: marine)
                    │               │               │
                    └───────┬───────┘               │
                            ▼                       │
                    _buildRouteFromSegments() ◄─────┘
                            │
                            ▼
                    NavigationRoute
                    (segments, geometry, waypoints, metrics)
```

### Port-to-Sea Route Flow

```
User opens port selection → taps port → taps sea point
                                            │
                                            ▼
                              _calculatePortToSeaRoute()
                              ├── OSRM: current location → selected port (land)
                              └── A*:   selected port → sea destination (marine)
                                            │
                                            ▼
                                    Combined NavigationRoute
```

---

## Navigation Session Lifecycle

```
┌─────────┐   startNavigation()   ┌────────┐
│  IDLE   │ ────────────────────> │ ACTIVE │ <──── resumeNavigation()
└─────────┘                       └────┬───┘
                                       │
                    ┌──────────────┬────┴─────────────┐
                    │              │                   │
              pauseNavigation()   │          destination reached
                    │              │                   │
                    ▼              ▼                   ▼
              ┌──────────┐  ┌───────────┐      ┌───────────┐
              │  PAUSED  │  │   ERROR   │      │ COMPLETED │
              └──────────┘  └───────────┘      └───────────┘

              cancelNavigation() → CANCELLED (from any state)
```

**During ACTIVE state, each GPS update:**
1. Adds position to breadcrumb trail
2. Calculates distance traveled and elapsed time
3. Checks if within proximity threshold of next waypoint → advances
4. Measures perpendicular distance to route segment → if > threshold, triggers recalculation

---

## Admin Edit Mode

Allows administrators to manually correct the land/water navigation mask by painting cells directly on the map.

### How it works:
1. User enters admin mode via layer control panel
2. Map gestures (pan/zoom) are **disabled**; touch events are captured for painting
3. User selects brush type (water=blue, land=brown, eraser=grey) and radius (1-5 cells)
4. Tapping or dragging calls `NavigationMask.paintBrush()` which modifies the in-memory `Uint8List`
5. Painted cells are visualized as colored squares on the map via `PolygonLayer`
6. If painting outside current mask bounds, `_expandMaskToInclude()` grows the grid dynamically
7. "Save" persists to local storage via `MaskStorageService` (with backup)
8. "Reset" reverts to original bundled asset mask
9. On next app launch, the saved user mask is loaded automatically
