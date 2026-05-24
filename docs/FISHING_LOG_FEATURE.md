# Fishing Log Feature — Full Technical Explanation

## Overview

The Fishing Log is an offline-first trip tracking system that lets authenticated fishermen record fishing trips and individual catches with GPS coordinates, weight, species, and notes. Data is stored locally in SQLite and automatically synced to Firebase Firestore when the device is online.

---

## Architecture

```
FishingLogScreen  ←→  TripService (singleton)
                            ├── DatabaseService (SQLite, offline)
                            └── FirebaseFirestore (online sync)

Trip (model)
  └── List<CatchEntry> (model)

CatchEditSheet / CatchForm  →  LocationPickerScreen
```

### Key Files

| File | Role |
|------|------|
| `lib/screens/fishing log/fishing_log_screen.dart` | Main screen — trip list, active banner, actions |
| `lib/screens/fishing log/trip_detail_screen.dart` | Trip detail — catch list, catches map, add/edit/delete catches |
| `lib/services/fishing log/trip_service.dart` | Singleton service — all trip/catch CRUD + Firestore sync |
| `lib/models/fishing/trip_model.dart` | `Trip` and `CatchEntry` data models |
| `lib/widgets/fishing_log/catch_form.dart` | Bottom sheet form for logging a new catch |
| `lib/widgets/fishing_log/trip_card.dart` | Card widget for each trip in the list |

---

## Data Models

### Trip
```
id            — UUID (unique per trip)
userId        — Firebase Auth UID (scopes data per user)
title         — optional custom name
startTime     — when trip started
endTime       — when trip ended (null = still active)
pausedSeconds — total break time excluded from duration
startLat/Lon  — GPS position at trip start
catches       — List<CatchEntry>
notes         — optional free text
synced        — whether written to Firestore yet
```

**Derived values:**
- `isActive` → `endTime == null`
- `duration` → `(endTime - startTime) - pausedSeconds` (net fishing time)
- `totalWeightKg` → sum of all catch weights

### CatchEntry
```
id          — UUID
tripId      — parent trip ID
timestamp   — exact time of the catch
species     — fish name (Arabic or English)
weightKg    — optional weight
latitude    — GPS lat of catch location
longitude   — GPS lon of catch location
notes       — optional notes
imagePath   — reserved (not yet used in UI)
synced      — whether written to Firestore
```

---

## TripService (Singleton)

`TripService.instance` is the single source of truth for all trip state.

### Initialization
Called when the screen opens (or user logs in):
1. Checks if an open trip exists in SQLite for this `userId` → restores it as `_activeTrip`
2. If multiple open trips exist (crash recovery), closes all but the most recent
3. If the user has zero local trips and is online → seeds from Firestore (new device / reinstall)

### Trip Lifecycle
```
startTrip()   → creates Trip in SQLite, sets _activeTrip
  ↓
logCatch()    → inserts CatchEntry in SQLite, appends to _activeTrip.catches
  ↓             if online: immediately syncs catch to Firestore
endTrip()     → sets endTime in SQLite, clears _activeTrip
              → if online: syncs trip + all offline catches to Firestore
```

### Resume Flow
If the user ended a trip today, a **Resume** button appears. `resumeTrip()`:
1. Reads the gap between `endTime` and now → adds it to `pausedSeconds`
2. Clears `endTime` in SQLite → trip becomes active again
3. Duration calculation continues excluding that gap

### Offline Sync
- Every write goes to SQLite first (always succeeds)
- Each row has a `synced` flag (0 = pending, 1 = synced)
- On `endTrip()` and `syncPendingToFirestore()`: unsynced rows are pushed to Firestore under `users/{uid}/trips` and `users/{uid}/catches`

---

## FishingLogScreen — UI Flow

### States
| Condition | UI shown |
|-----------|----------|
| Guest user | Lock screen → prompts login |
| Loading | Spinner |
| No trips | Empty state with anchor icon |
| Has trips | Trip list |
| Active trip exists | Green live-duration banner + "Log Catch" + "End Trip" buttons |
| No active trip | "Start Trip" button (+ "Resume" if a trip ended today) |

### Active Banner
Shows a pulsing green dot, real-time duration (updates every second via `Timer.periodic`), and catch count. Has quick edit-title and delete-trip icon buttons.

### Search
Trips are filterable by title or date. Date search supports multiple formats: `d/M/yyyy`, `d MMM yyyy`, `MMMM yyyy`, `yyyy-MM-dd` — all case-insensitive.

### Actions
- **Start Trip** → calls `TripService.startTrip()`, then resolves GPS in background to store `startLat/Lon`
- **Log Catch** → opens `CatchEditSheet` bottom sheet → on submit calls `TripService.logCatch()`
- **End Trip** → confirmation dialog → calls `TripService.endTrip()`, stops the live timer
- **Delete Trip** → confirmation dialog → calls `TripService.deleteTrip()` (also deletes from Firestore if online)
- **Edit Title** → inline dialog → calls `TripService.updateTripTitle()`, syncs to Firestore

---

## Catch Form (CatchEditSheet)

A modal bottom sheet used for both adding new catches and editing existing ones.

### Fields
| Field | Required | Detail |
|-------|----------|--------|
| Species | Yes | Quick-pick chips (Hamour, Safi, Sobaity, Chanad, Zubaidi, Shrimp, Crab, Other) + free-text fallback |
| Weight (kg) | No | Numeric input, decimal allowed |
| Notes | No | Multi-line free text |
| Location | No | GPS auto-fetch or manual map pin |

### Species Quick-Pick
Pre-defined chips for the 7 most common Gulf fish species, fully localized (Arabic/English). Tapping a chip fills the species field instantly. Tapping "Other" clears the field and focuses the text input.

### Location Options
1. **Use Current Location** — calls the device GPS, validates that the point is on water (using `NavigationMask`). Shows an error if GPS fails or the point is on land.
2. **Pin on Map** — opens `LocationPickerScreen`, returns a `LatLng` chosen by the user.

The `NavigationMask` is a binary grid loaded from assets (1 = water, 0 = land). This prevents logging a catch from a land location.

---

## Trip Detail Screen

Opened by tapping a trip card. Shows:

### Header Stats
- Trip date, start time, end time (or "Ongoing")
- Number of catches
- Total weight (only shown if > 0 kg)

### Catch Map
If any catches have a GPS location, a `flutter_map` view (200 px tall) renders orange circle markers. Tapping a marker shows a bottom sheet with species, weight, time, coordinates, and notes.

### Catch Cards
Each catch displayed as a card with:
- Species name + numbered badge (#1, #2, …)
- Weight badge (if set)
- Time badge
- Notes (if set)
- GPS coordinates (if set)
- Edit and Delete buttons

### Add Catch to a Completed Trip
Even after a trip ends, the user can add retrospective catches. For a completed trip, a **time picker** appears first, clamped between `startTime` and `endTime`, so the catch timestamp is historically accurate.

---

## Localization

All user-facing strings are in `FishingLogLocalizations` (ARB files). Numbers are rendered through `arabicN()` — converts Western digits to Eastern Arabic numerals when the locale is `ar`. Species chips switch between Arabic and English names based on locale.

---

---

# Presentation Content — 1 Slide (1 Minute)

**Slide title:** Fishing Log — Smart Trip & Catch Tracking

---

**What to say (script, ~60 seconds):**

> "The Fishing Log feature lets fishermen record their trips directly from their phone while they're out at sea.
>
> When you start a trip, the app captures your GPS location automatically. As you fish, you tap 'Log Catch' — a quick form pops up where you pick the species from pre-set chips for common Gulf fish like Hamour or Zubaidi, enter the weight, and the app auto-fills your current GPS position. If you moved since you cast the line, you can also pin the exact catch spot on a map.
>
> Everything is stored locally first using SQLite, so it works without internet. When you're back in range, the data syncs automatically to Firebase Firestore under your account.
>
> After you end a trip, you can tap into it to see a full summary — a live map showing where each fish was caught, total weight, duration, and each catch listed in order. You can still add or edit catches after the trip is over.
>
> The whole system is offline-first, GPS-aware, bilingual in Arabic and English, and tied to the user's account — so a fisherman can reinstall the app and get all their history back automatically."

---

---

# Q&A — Common Examiner Questions

**Q1: Why did you use SQLite instead of storing everything in Firestore directly?**

> SQLite is offline-first. Fishermen are often at sea where mobile data is unavailable. Every write goes to SQLite immediately so the app never fails due to no internet. Firestore sync happens opportunistically — when the device is online. This gives reliability AND cloud backup.

---

**Q2: How does the sync work — what if the user logs catches offline and then goes online?**

> Every row in SQLite has a `synced` flag (0 = pending, 1 = done). When a catch is logged offline, it goes to SQLite with `synced = 0`. When the trip ends and the device is online, `TripService.endTrip()` pushes the trip and all its unsynced catches to Firestore. There is also a `syncPendingToFirestore()` method that can be called at login to catch anything still pending.

---

**Q3: What happens if the app crashes mid-trip?**

> On the next app launch, `TripService.initialize()` queries SQLite for any open trips (`endTime = null`) for the current user. It restores the most recent one as the active trip. If somehow multiple open trips exist (e.g., multiple crashes), it auto-closes all but the latest one. The user can continue the trip as if nothing happened.

---

**Q4: How does location work — can someone log a catch from the wrong place?**

> We use the `NavigationMask`, which is a binary grid asset where 1 = water and 0 = land. When GPS coordinates are fetched, we check `mask.isPointNavigable(point)`. If the user is on land, an error message is shown and the location is not accepted. They can still manually pin a location on the map but it's their choice at that point.

---

**Q5: How does the duration calculation work, specifically the pause/resume?**

> The `Trip` model stores `pausedSeconds`. When a user resumes a trip, the gap between `endTime` and `DateTime.now()` is computed in seconds and added to `pausedSeconds`. Duration is then `(endTime - startTime) - pausedSeconds`. This means break time is excluded from the reported fishing duration, giving an accurate active fishing time.

---

**Q6: Is the data private per user?**

> Yes. Every trip and catch row in SQLite includes a `userId` column. All queries filter by the currently authenticated Firebase UID. In Firestore, data is stored under `users/{uid}/trips` and `users/{uid}/catches` — so each user's data is completely isolated. Guest users see a locked screen and cannot access the feature at all.

---

**Q7: What is the "Resume Trip" button for?**

> If a fisherman ends a trip but realizes they forgot to log something, or they went back out the same day, the app detects that a trip ended today and shows a Resume button. Resuming re-opens the trip and adds the break gap to `pausedSeconds`, so the final duration doesn't count the time they were off the water.

---

**Q8: How does the catch map work?**

> In the Trip Detail screen, any catches that have GPS coordinates are rendered as orange circle markers on a `flutter_map` tile map (OpenStreetMap). The map auto-centers on the average of all catch positions. Tapping a marker shows a bottom sheet with the catch details. Catches without a location don't appear on the map.

---

**Q9: Why is there a quick-pick chip system for species instead of just a text field?**

> Speed and accuracy. Fishermen log catches in the moment, often with wet hands on a moving boat. Tapping a chip takes one touch instead of typing. The chips cover the 7 most common Gulf fish species. For anything unusual, there is an "Other" chip that exposes a free-text field. The chips are also localized — they show Arabic names in Arabic mode and English names in English mode.

---

**Q10: How is the app multilingual (Arabic/English)?**

> All UI strings are in ARB localization files loaded through `FishingLogLocalizations`. Numbers are converted through an `arabicN()` utility that switches between Western (1, 2, 3) and Eastern Arabic (١, ٢, ٣) numerals based on the active locale. The layout also respects RTL/LTR direction automatically via Flutter's `Directionality` system.
