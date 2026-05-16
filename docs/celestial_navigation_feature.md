# Celestial Navigation Feature (DS-1)

## What It Is

DS-1 is an offline, star-based position-fixing system built into AquaNav. It lets the app compute the vessel's location using only the device camera and gyroscope — no GPS, no internet. It is designed for maritime use cases where GPS may be unavailable or untrusted (e.g., signal loss at sea, or GPS spoofing attacks).

---

## How It Works — Step by Step

### 1. Startup: Load Star Catalog + Get GPS Reference

When the screen opens, the app does two things in parallel:

- Fetches the current GPS position as a **reference / fallback** coordinate.
- Loads `assets/data/stars_2500.json` into memory — a catalog of ~2,500 naked-eye stars from the Hipparcos satellite catalog (ESA 1997), each with:
  - Hipparcos catalog ID (`hip`)
  - Common name (`Sirius`, `Vega`, `Polaris`, etc.)
  - J2000 right ascension (`ra`) and declination (`dec`) in degrees
  - Visual magnitude (`mag`) — lower = brighter (Sirius = −1.46)

---

### 2. Camera Frame Capture (`camera_service.dart`)

The camera runs in a **duty cycle**: 1-second burst of frame capture → 1-second cooldown (for thermal and power management). Each captured frame goes through:

**a) YUV420 → RGB-888 Conversion**
Camera hardware delivers frames in YUV420 format. The app converts each pixel manually:
```
r = clamp(Y + 1.402 × V)
g = clamp(Y − 0.34414 × U − 0.71414 × V)
b = clamp(Y + 1.772 × U)
```
where U and V are the chroma planes (quarter resolution, one byte per 4 pixels).

**b) IMU (Gyroscope) Snapshot**
At the moment of each frame, the gyroscope reading (from `sensors_plus`) is captured. If rotation exceeds **0.5 °/s**, the frame is immediately discarded as motion-blurred. This prevents star streaks from corrupting detection.

**c) Native C++ Vision Engine (via FFI)**
The RGB frame is passed zero-copy through a Dart FFI bridge (`vision_bridge.dart`) to a native library:
- **Android:** `libds1_vision.so`
- **iOS:** `ds1_vision.framework`

The engine returns:
- A list of up to 50 star **centroids** (pixel x, y coordinates) detected in the frame
- **Horizon** detection result: angle in degrees + vertical offset in pixels
- An **engine confidence score** (0–100%)

---

### 3. Star Identification — Triangle Matching (`star_identifier.dart`)

This is the core algorithm. It implements a variant of the **Lost-in-Space** star pattern recognition algorithm (based on Mortari 2004).

**Why triangles?**
Three stars form a triangle with three side lengths. The side lengths are angular separations — they are independent of camera orientation, roll, or where on the sky you are pointing. This makes the triangle a rotation-invariant fingerprint that can be matched against the catalog.

**Algorithm:**

1. Reject frames with fewer than 3 detected star centroids.
2. Take the **3 brightest** centroids (sorted by pixel intensity).
3. Convert pixel coordinates to angular offsets from the image center:
   ```
   degPerPx = fovH / imageWidth        (FOV typically 55–60° for a phone)
   dx_deg = (x − width/2) × degPerPx
   dy_deg = (y − height/2) × degPerPx
   ```
4. Compute the 3 inter-star angular separations (the triangle's sides):
   ```
   d = sqrt(dx² + dy²)    (for each of the 3 pairs)
   ```
5. Sort the three side lengths in ascending order (order-independent matching).
6. Search the **pre-built catalog index** (all triplets from the brightest 500 stars) for a matching triangle within ±0.3° tolerance.
7. Calculate residual error (RMS difference between camera and catalog side lengths):
   ```
   residual = sqrt((d1_cam − d1_cat)² + (d2_cam − d2_cat)² + (d3_cam − d3_cat)²) / 3
   ```
8. Return the **best match** (lowest residual) with the identified star names and their catalog RA/Dec, or `null` if no match is found.

Angular separations between catalog stars are computed using the **Haversine formula** (great-circle distance on the celestial sphere).

---

### 4. Confidence Engine (`confidence_engine.dart`)

Even if a star match is found, the fix is only displayed if conditions are reliable enough. The confidence engine scores four environmental factors:

| Factor | Weight | What It Measures |
|---|---|---|
| Sea State | 30% | Pitch standard deviation from a rolling IMU window |
| Sky Clarity | 25% | Detected usable stars vs. expected count |
| Star Altitude | 25% | Primary star's elevation above the horizon |
| IMU Health | 20% | Peak gyroscope drift rate |

**Hard rejection rules (override the score):**
- Star altitude < **8°**: Atmospheric refraction at low angles introduces > 10 NM of error → **always rejected**
- Gyro drift ≥ **0.5 °/s**: Platform too unstable → **always rejected** (requires IMU recalibration)

**Composite score → decision:**
- Score ≥ 70 → **Fix** (reliable, displayed normally)
- 30 ≤ Score < 70 → **Low Confidence Warning** (displayed with a 5 NM dashed uncertainty radius)
- Score < 30 → **Rejected** (fix refused, reason shown to user)

---

### 5. Fix Display on Map (`celestial_fix_overlay.dart`)

Once a fix is accepted, it is posted to `CelestialFixNotifier` (a singleton `ChangeNotifier`) and rendered on the navigation map:

- **Uncertainty circle**: A polygon approximation drawn on the FlutterMap canvas, sized in nautical miles, converted to degrees of latitude. Dark blue for a confirmed fix, orange for a low-confidence warning. Dashed border on warnings.
- **Fix marker**: Shows tooltip with score, uncertainty, and UTC timestamp.
- **GPS Spoofing Alert**: If the celestial fix diverges from the GPS position by more than **2 nautical miles**, a red banner appears at the top of the map: *"GPS SPOOFING ALERT — Celestial fix diverges > 2 NM"*. This is the feature's primary security function.

---

### 6. Astronomical Almanac (Separate from DS-1)

`celestial_calculator.dart` handles a separate concern: computing **sunrise/sunset** times and **moon phase** data for the weather screen. It uses the NOAA solar algorithm and Meeus lunar formulas (all pure Dart, no external astronomy API). This module is **not** involved in position fixing.

---

## Full Data Flow

```
User opens Celestial Navigation Screen
    │
    ├── GPS position fetched (reference only)
    └── Star catalog loaded from assets (2,500 stars)
         │
User taps "Start Sky Scan"
         │
    CameraService — duty cycle 1s on / 1s off
         │
    For each frame:
         ├── YUV420 → RGB-888 conversion
         ├── Gyroscope snapshot
         ├── Reject if drift > 0.5 °/s  ──→ discarded
         └── Pass RGB frame to VisionBridge (FFI → C++)
                  │
             Native vision engine:
                  ├── Detect star centroids (pixel x, y)
                  ├── Detect horizon (angle, offset)
                  └── Return confidence score (0–100%)
                  │
    StarIdentifier.identify(centroids, FOV)
         ├── Convert pixels → angular offsets
         ├── Build triangle from 3 brightest stars
         ├── Search catalog for matching triangle (±0.3°)
         └── Return star names + RA/Dec (or null)
                  │
    Live display updated: star count, confidence, drift, names
                  │
User taps "Done"
         │
    ConfidenceEngine.evaluate(sea state, clarity, altitude, IMU)
         ├── score ≥ 70 → Fix
         ├── 30–69   → Warning + 5 NM circle
         └── < 30    → Rejected
                  │
    CelestialFixNotifier.setFix(position, score, uncertainty)
         │
    IntegratedMap renders:
         ├── Uncertainty circle (NM → metres → lat degrees)
         ├── Fix marker with tooltip
         └── Spoofing alert banner if divergence > 2 NM from GPS
```

---

## Key Files

| File | Role |
|---|---|
| [lib/screens/celestial navigation/celestial_navigation_screen.dart](lib/screens/celestial%20navigation/celestial_navigation_screen.dart) | Main screen, GPS init, lifecycle |
| [lib/screens/celestial navigation/sky_scanner_view.dart](lib/screens/celestial%20navigation/sky_scanner_view.dart) | Camera preview, live stats, result packaging |
| [lib/screens/celestial navigation/camera_service.dart](lib/screens/celestial%20navigation/camera_service.dart) | Frame capture, IMU, duty cycle |
| [lib/screens/celestial navigation/vision_bridge.dart](lib/screens/celestial%20navigation/vision_bridge.dart) | FFI to native C++ engine |
| [lib/screens/celestial navigation/star_identifier.dart](lib/screens/celestial%20navigation/star_identifier.dart) | Lost-in-Space triangle matching |
| [lib/screens/celestial navigation/confidence_engine.dart](lib/screens/celestial%20navigation/confidence_engine.dart) | Fix reliability scoring |
| [lib/screens/celestial navigation/celestial_fix_notifier.dart](lib/screens/celestial%20navigation/celestial_fix_notifier.dart) | State bridge to map |
| [lib/screens/celestial navigation/celestial_fix_overlay.dart](lib/screens/celestial%20navigation/celestial_fix_overlay.dart) | Map rendering (circle + marker + alert) |
| [lib/screens/celestial navigation/celestial_calculator.dart](lib/screens/celestial%20navigation/celestial_calculator.dart) | Solar/lunar almanac (weather screen only) |
| [assets/data/stars_2500.json](assets/data/stars_2500.json) | 2,500-star Hipparcos catalog |

---

---

# One-Minute Slide Presentation

> Read at a calm pace. Each bullet is roughly 10–12 seconds.

---

**Opening (15 sec):**
"One of AquaNav's most distinctive features is its celestial navigation system, which we call DS-1. It can determine the vessel's position using only the phone camera and gyroscope — with no GPS and no internet connection. This is designed for deep-sea scenarios where GPS signals are lost or, more critically, where GPS is being spoofed."

**How it works (30 sec):**
"When the user points the camera at the night sky, the app captures frames, filters out any that are motion-blurred using the gyroscope, and passes each frame to a native C++ vision engine over Dart's FFI interface. The engine detects star centroids in the image. Those centroids are then matched against a 2,500-star catalog using a triangle-pattern algorithm — three stars form a triangle whose side lengths are rotation-invariant angular separations, making them a unique fingerprint that can be looked up in the catalog regardless of which direction you are pointing. Once stars are identified, the app runs a confidence engine that scores sea state, sky clarity, star altitude, and IMU stability before deciding whether to accept or reject the fix."

**Key value (15 sec):**
"The fix is shown on the navigation map with an uncertainty circle sized in nautical miles. And if the celestial fix diverges from GPS by more than two nautical miles, the app immediately raises a spoofing alert — which means this feature doubles as an active GPS integrity monitor. It works entirely offline, with all algorithms running on-device."

---

---

# Common Examiner Questions

---

**Q1: Why use star triangles instead of just identifying one star?**

Identifying a single star requires knowing which direction you are pointing — you need the device's compass and tilt sensor to be perfectly calibrated. A triangle of three stars is rotation-invariant: the three side lengths (angular separations) are the same regardless of roll, azimuth, or field of view. This makes matching reliable even when the camera orientation is unknown.

---

**Q2: How accurate is the position fix?**

The uncertainty is reported honestly rather than assumed. A high-confidence fix (score ≥ 70) carries a 1 NM uncertainty radius. A low-confidence fix shows a 5 NM radius. Stars below 8° altitude are always rejected because atmospheric refraction at that angle introduces errors greater than 10 NM — so the system refuses to display a fix rather than display a wrong one.

---

**Q3: What happens if the sky is overcast or it is daytime?**

If fewer than 3 stars are detected, the triangle algorithm cannot run and no fix is produced. The app remains in scanning mode and continues trying. The user sees live feedback (star count, confidence score) so they know why no fix is available. The app falls back to GPS normally.

---

**Q4: Why is there a native C++ engine? Why not do everything in Dart?**

Star detection in a 1920×1080 image involves processing over 2 million pixels per frame to find faint point sources against a noisy background. This is computationally intensive and needs to run at real-time frame rates. C++ with direct memory access (via FFI zero-copy buffers) is significantly faster than Dart for this kind of pixel-level processing. The triangle matching and confidence scoring happen in Dart because they operate on a small number of centroids (at most 50), not raw pixels.

---

**Q5: What is the Lost-in-Space algorithm?**

It is a class of star pattern recognition algorithms developed originally for spacecraft attitude determination — satellites that "wake up" with no knowledge of which direction they are pointing and must figure it out purely from what stars they can see. The name comes from that problem. The variant implemented here (based on Mortari 2004) pre-indexes all possible triangles from the brightest 500 stars and uses binary search to find matches efficiently rather than doing a brute-force scan of all 20 million possible triplets at runtime.

---

**Q6: What is the GPS spoofing detection and how does it work?**

GPS spoofing is when a malicious transmitter sends fake GPS signals to mislead a vessel. The celestial fix is completely independent of GPS — it uses astronomy and physics, which cannot be spoofed. If the celestial fix disagrees with the GPS position by more than 2 nautical miles, the app shows a red alert banner. This gives the navigator an independent cross-check that is physically impossible to fake with a radio transmitter.

---

**Q7: Does this work on any phone?**

It requires a phone with a rear camera (1080p or better), a gyroscope, and support for loading the native vision library (ARMv8 on Android, arm64 on iOS). For phones without a gyroscope, the motion-blur rejection step is skipped but fix quality degrades. The feature includes a simulation mode for testing on emulators.

---

**Q8: Why is this not a main navigation tab? Is it finished?**

The feature is fully implemented with a complete pipeline from camera to map overlay. It is not surfaced as a primary tab because it only works at night with a clear sky — making it contextually inappropriate as a permanent tab alongside features that work anytime. It is accessible from within the map screen, where a navigator would naturally look for positioning tools.

---

**Q9: How is the star catalog stored and how large is it?**

The catalog (`assets/data/stars_2500.json`) contains 2,500 stars sourced from the Hipparcos satellite catalog published by ESA in 1997, which is in the public domain. Each entry is about 60 bytes (five fields: ID, name, RA, Dec, magnitude), so the full catalog is approximately 150 KB — small enough to bundle with the app and load entirely into memory at startup.

---

**Q10: What is the confidence engine's most important factor and why?**

Sea state, at 30% weight, is the largest single factor. When a vessel is pitching in rough seas, the camera is constantly moving, making it impossible to keep stars stable in the frame for long enough to get a reliable centroid. Even if the gyroscope catches large motions, small residual pitch introduces position errors. Star altitude (25%) is the second most critical: below 8°, the atmosphere bends starlight by an unpredictable amount, introducing errors that no algorithm can correct.
