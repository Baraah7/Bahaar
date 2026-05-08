## 6.3 Component Implementation — Celestial Navigation Subsystem (DS-1)

The celestial navigation subsystem, internally designated DS-1, provides a GPS-independent position-fixing capability based on real-time star observation through the device camera. It is composed of eleven discrete components spanning native vision processing, astronomical mathematics, a confidence scoring model, dead reckoning, and map integration. Each component is discussed below in the order data flows through the system.

---

### 6.3.1 Vision Engine and Camera Service

The lowest layer of DS-1 is a native C++ vision engine exposed to Dart through the Foreign Function Interface (FFI). The engine is initialised with the camera's focal length and sensor width, from which it computes the horizontal field of view used in all subsequent angular calculations. Four operations are bound at runtime through `lib/navigation/vision_bridge.dart`: engine initialisation, star centroid detection, horizon line detection, and confidence retrieval.

To avoid the overhead of per-frame heap allocation, `VisionBridge` maintains a `_FramePool` of pre-allocated native buffers — one for raw pixel data (RGB-888 layout) and two float arrays for the returned star x/y coordinates. Frames are written into the pool in place and passed to the native functions as pointers, making the transfer effectively zero-copy. The four integer return codes (`kDs1Ok`, `kDs1Rejected`, `kDs1NoGpu`, `kDs1NotInit`, `kDs1BadArg`) allow the Dart layer to distinguish structural failures from hardware unavailability without exception propagation.

`lib/navigation/camera_service.dart` manages the device camera and IMU above the FFI boundary. To balance measurement continuity against battery consumption, the service applies a duty-cycle of one second active followed by one second idle. Gyroscope data from the device sensors is tagged to every frame as an `ImuTag` carrying the three angular-rate components and a microsecond timestamp. The resultant motion-blur metric is the Euclidean magnitude of the three rates; any frame whose drift exceeds 0.5 °/s is marked as motion-blurred and excluded from fix computation downstream. When physical hardware is absent — during laboratory testing or demonstration — a simulation mode substitutes pre-baked synthetic star centroids, allowing the full pipeline to be exercised without a live camera stream.

---

### 6.3.2 Star Identification

Star identification is implemented in `lib/navigation/star_identifier.dart` as a Lost-in-Space triangle-matching algorithm following the Mortari (2004) approach. The algorithm requires no prior attitude estimate, making it suitable for the at-sea context where the device orientation is not reliably known.

On first use the service loads an embedded JSON catalog of 2,500 naked-eye stars drawn from the Hipparcos catalogue, each entry carrying the HIP identifier, common name, right ascension (RA), declination (Dec), and visual magnitude. The 500 brightest entries are then used to pre-build a triplet index: every valid combination of three stars is stored with its three sorted angular separations, enabling O(log n) lookup at match time.

At runtime, `identify()` accepts the three brightest centroids detected by the vision engine as pixel coordinates. Each centroid is converted to an angular offset from the image centre using the calibrated degrees-per-pixel factor:

```
δx_deg = (x − imageWidth / 2) × (fovH / imageWidth)
```

The three pairwise angular separations among the centroids are computed and sorted, then compared against the pre-built catalog index. A candidate triplet is accepted if all three sides agree with the catalog within ±0.3°. Among all accepted candidates the best match is selected by minimum RMS residual:

```
residual = √( Σ (cam_i − cat_i)² / 3 )
```

The inter-star angular separation itself is computed via the spherical Haversine formula applied to the RA/Dec coordinates of each catalog pair:

```
hav = sin²(ΔDec/2) + cos(Dec₁)·cos(Dec₂)·sin²(ΔRA/2)
d   = 2·arcsin(√hav)
```

The function returns `null` rather than throwing on any failure — fewer than three detected stars, uncalibrated FOV, or no catalog match within tolerance — so the pipeline degrades gracefully rather than propagating errors.

---

### 6.3.3 Celestial Calculations

`lib/utilities/cn/celestial_calculator.dart` provides all pure-Dart astronomical calculations needed both for fix computation and for the almanac display in the weather screen. No external API calls are made; all values are derived from well-established algorithms applied to the device's clock.

**Solar events** follow the NOAA method. A Julian Day Number is computed from the Gregorian calendar date with sub-day precision, from which the mean longitude, mean anomaly, and equation of centre are derived. True longitude and apparent longitude correct for the sun's elliptical orbit and the aberration of light. The obliquity of the ecliptic is computed with the standard correction term. Solar declination and the Equation of Time follow directly. Sunrise and sunset are obtained by solving the hour angle equation with a 0.833° horizon depression to account for atmospheric refraction and the finite angular diameter of the solar disc:

```
HA = arccos( cos(90.833°) / (cos(lat)·cos(dec)) − tan(lat)·tan(dec) )
```

**Lunar events** are computed from the synodic month (29.53058867 days) referenced to the known New Moon epoch of Julian Day 2451549.5 (6 January 2000 UTC). The instantaneous phase (0.0–1.0) determines the named phase and the illuminated fraction:

```
illumination = (1 − cos(2π × phase)) / 2 × 100
```

Moonrise and moonset are found by an iterative altitude search at two-minute resolution. Moon altitude at each step uses the Greenwich Sidereal Time to convert phase-derived ecliptic coordinates to a Local Hour Angle, from which altitude follows:

```
alt = arcsin( sin(lat)·sin(dec) + cos(lat)·cos(dec)·cos(LHA) )
```

Default coordinates are set to Manama, Bahrain (26.2154°N, 50.5832°E) but are overridden with the device's live GPS position when available.

---

### 6.3.4 Observation Corrections

Before an observed star altitude can be used for a position line, two systematic errors must be removed. These corrections are consolidated in `lib/navigation/corrections.dart`.

**Atmospheric refraction** is modelled using the Bennett (1982) formula, which is accurate to approximately 0.1 arcminutes for altitudes above 8°:

```
R₀ = 1 / tan(h + 7.31 / (h + 4.4))   [arcminutes]
R  = R₀ × (P / 1010) × (283 / (273 + T))
```

where *h* is the apparent altitude in degrees, *P* the atmospheric pressure in millibars, and *T* the temperature in degrees Celsius. Because refraction grows non-linearly toward the horizon, all observations below 8° are rejected outright; the position error from uncorrected refraction at that elevation exceeds 10 nautical miles.

**Dip of the horizon** is computed from the Bowditch formula:

```
Dip = 1.76 × √(height_metres)   [arcminutes]
```

This correction accounts for the observer's eye height above the sea surface and is subtracted from the sextant reading before the refraction correction is applied. Both functions return 0.0 on out-of-range input rather than throwing, and accept an optional `StringBuffer` for diagnostic logging.

---

### 6.3.5 Confidence Engine

Because sky quality, vessel motion, and sensor health vary continuously at sea, a fix must be accompanied by a reliability estimate rather than accepted unconditionally. `lib/navigation/confidence_engine.dart` implements a four-factor weighted composite score on a 0–100 scale.

| Factor | Weight | Input | Scoring |
|---|---|---|---|
| Sea state | 30 % | IMU pitch standard deviation | Linear penalty; halved if σ > 2° |
| Sky clarity | 25 % | Detected usable stars / expected | Proportional to fill fraction |
| Star altitude | 25 % | Primary star altitude (°) | Linear from 0 at 8° to 100 at 90° |
| IMU health | 20 % | Gyroscope drift rate (°/s) | Linear from 100 at 0 °/s to 0 at 0.5 °/s |

Two hard-rejection conditions bypass the composite: a primary altitude below 8° (refraction error) or a gyroscope drift at or above 0.5 °/s (indicating the device is moving too rapidly for a reliable observation). When neither condition is met, the weighted composite maps to one of three `FixDecision` values:

- **fix** (score ≥ 70): position is accepted and displayed normally.
- **lowConfidenceWarning** (30–69): position is shown with a 5 NM dashed uncertainty radius and an amber indicator.
- **rejected** (score < 30): position is suppressed and a refusal message is displayed to the user.

---

### 6.3.6 Dead Reckoning

When a celestial fix cannot be obtained — cloud cover, daylight, or a rejected confidence score — DS-1 falls back to dead reckoning (DR) in `lib/navigation/dead_reckoning.dart`. Starting from the most recent accepted fix, the vessel's estimated position is propagated forward along the compass heading using the Haversine great-circle equations:

```
sin(lat₂) = sin(lat₁)·cos(d) + cos(lat₁)·sin(d)·cos(bearing)
lon₂      = lon₁ + atan2( sin(bearing)·sin(d)·cos(lat₁),
                           cos(d) − sin(lat₁)·sin(lat₂) )
```

where *d* = distance / 3440.065 is the angular distance in radians (3440.065 being the Earth's radius in nautical miles).

Position uncertainty grows with elapsed time and distance according to a linear model that accounts for compass error, leeway, and tidal drift:

```
uncertainty = lastAccuracy + (0.05 × distNm) + (0.3 × elapsedHours)
```

The 5 % distance term captures cumulative heading error and leeway; the 0.3 NM per hour term represents the unobserved contribution of tidal set and drift. A `DrReliability` enum maps the growing uncertainty to three operational states: **good** (< 1.5 NM), **warning** (1.5–2.0 NM), and **exceeded** (≥ 2.0 NM), the last of which recommends that the vessel heave to and await a new celestial or GPS fix before proceeding.

---

### 6.3.7 Fix State Management

`lib/navigation/celestial_fix_notifier.dart` is a singleton `ChangeNotifier` that carries the latest accepted fix as an immutable `CelestialFix` value object containing the computed `LatLng`, the confidence score, the `FixDecision`, an uncertainty radius in nautical miles, and the UTC observation timestamp. Any widget in the application tree may listen to this notifier without going through Riverpod, enabling the map overlay and the navigation screen to react to new fixes independently. The notifier also holds a boolean spoofing-alert flag, which is set when the celestial position diverges from the GPS position by more than 2 NM — the threshold chosen to detect GPS spoofing rather than normal GPS drift.

---

### 6.3.8 User Interface

The main celestial navigation screen (`lib/screens/celestial navigation/celestial_navigation_screen.dart`) presents the workflow to the user in four logical cards: a status bar showing GPS availability and live star count; a five-step how-to guide localised in both English and Arabic; the sky-scanner launcher; and a results panel displaying the detected star count, identified star names, confidence score, IMU drift rate, and horizon angle after a completed scan.

The full-screen camera view (`sky_scanner_view.dart`) streams `CameraFrameResult` objects from `CameraService` and passes each frame's centroids to `StarIdentifier`. The bottom panel updates in real time with four colour-coded metrics: star count (green when ≥ 3), engine confidence (green ≥ 60 %, amber 30–59 %, white below), IMU drift (green < 0.5 °/s, red at or above), and horizon angle (green when detected). A motion-blur warning overlays the preview when the current frame exceeds the drift threshold. Identified star names are shown as chip widgets below the stats panel. When the user dismisses the view, the collected `SkyScannerResult` is passed back to the parent screen, which feeds it into the confidence engine to produce the final fix decision.

---

### 6.3.9 Map Integration

The celestial fix is rendered on the main flutter\_map canvas through `lib/widgets/map/celestial_fix_overlay.dart`. The position uncertainty is displayed as a 36-point polygon approximation of a circle, with the radius converted from nautical miles to degrees of latitude (1 NM = 1852 m; 1° latitude ≈ 111,319 m) and scaled for longitude at the observer's latitude:

```
radiusLon = radiusDeg / cos(lat_radians)
```

A normal fix uses a dark-teal fill; a low-confidence fix uses an amber fill with a dashed border. A pin marker at the fix position carries a tooltip showing the score, uncertainty, and UTC time. When the spoofing alert is active, a red banner is rendered in the top-left corner of the map viewport with the message "GPS SPOOFING ALERT — Celestial fix diverges > 2 NM", providing the mariner with an immediate visual warning without disrupting the chart view.

---

### 6.3.10 Geometry Utilities

`lib/utilities/cn/geometry_utils.dart` provides the spatial primitives shared across DS-1 and the fishing-activity heatmap. The Douglas–Peucker algorithm simplifies recorded tracks before storage, reducing point count while preserving geometric fidelity above a configurable tolerance. Ray-casting point-in-polygon tests determine whether a computed fix falls within a designated fishing zone or MPA boundary. Haversine distance and centroid calculations are used for spatial aggregation of catch reports. These utilities carry no UI dependencies and are tested in isolation.
