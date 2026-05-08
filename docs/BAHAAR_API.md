# Bahaar Fishing Prediction API

## Overview

A Flask REST API (`api.py`) that provides AI-driven fish-presence predictions for the Bahaar mobile app.

**Base URL:** `https://bahaar-whjo.onrender.com`

**Primary use:**
- Returns probability of catching a species at a given location and time.
- Accepts user reports to continuously improve the prediction model.

---

## How It Works

### Prediction Pipeline

`PredictionEngine` (in `learning_engine.py`) computes four independent factors and combines them:

```
Probability = Static × Seasonal × Weather × Human × 100
```

| Factor   | Source                                     | Description                                      |
|----------|--------------------------------------------|--------------------------------------------------|
| Static   | `static_data.py`                           | Zone/species/spot base affinity scores           |
| Seasonal | `static_data.py` + request date            | Monthly seasonality multiplier per species       |
| Weather  | `weather_service.py` (Open-Meteo API)      | Live conditions (wind, waves, temp) multiplier   |
| Human    | Firestore via `firebase_service.py`        | Dynamic weight updated from real user reports    |

### Learning Loop

`LearningEngine` (in `learning_engine.py`) updates model weights every time a report is submitted via `POST /report`:

- Performs gradient-descent–style adjustments to the Human factor weight.
- Flags new spot candidates when multiple strong reports cluster in the same area.
- Persists updated weights to Firestore via `firebase_service.save_weights`.

### MPA Enforcement

Marine Protected Areas (MPAs) defined in `static_data.py` are enforced at prediction time — any location inside an MPA receives a blocked or very low probability regardless of other factors.

---

## Main Files

| File                     | Purpose                                                                 |
|--------------------------|-------------------------------------------------------------------------|
| `api.py`                 | Flask app, all HTTP endpoints                                           |
| `learning_engine.py`     | `PredictionEngine` + `LearningEngine` core logic; unit tests in `test_learning_engine.py` |
| `firebase_service.py`    | Firestore wrapper with TTL in-process cache (weights, spots, reports)   |
| `weather_service.py`     | Fetches live weather from Open-Meteo; includes safety assessment logic  |
| `static_data.py`         | Zones, MPAs, species metadata, and initial spot list                    |
| `seed_firebase.py`       | One-time script to seed Firestore with initial static data              |
| `requirements.txt`       | Python dependencies                                                     |

---

## API Endpoints

### `POST /predict`

Returns the probability of catching a species at a location.

**Request body (JSON):**
```json
{
  "lat": 26.5,
  "lng": 50.2,
  "species_id": "hamour",
  "date": "2026-05-06"
}
```

**Response:**
```json
{
  "probability": 72.4,
  "factors": {
    "static": 0.85,
    "seasonal": 0.90,
    "weather": 0.78,
    "human": 1.21
  },
  "mpa_blocked": false
}
```

---

### `POST /report`

Submits a catch report and triggers model weight updates.

**Request body (JSON):**
```json
{
  "lat": 26.5,
  "lng": 50.2,
  "species_id": "hamour",
  "caught": true,
  "quantity": 3,
  "date": "2026-05-06",
  "user_id": "firebase_uid"
}
```

**Response:** `200 OK` on success.

---

### `GET /spots/nearby`

Returns confirmed fishing spots near a coordinate.

**Query params:** `lat`, `lng`, `radius_km` (optional, default 10)

---

### `GET /zone/info`

Returns zone metadata for a coordinate.

**Query params:** `lat`, `lng`

---

### `GET /weather`

Returns current weather conditions and a safety assessment for a location.

**Query params:** `lat`, `lng`

---

## Authentication

The Flutter app (`BahaarAIService` in `lib/services/bahaar_ai_service.dart`) attaches a Firebase Auth token to every request:

```
Authorization: Bearer <firebase_id_token>
```

The API validates this token server-side before processing requests.

---

## Caching

- `firebase_service.py` and `weather_service.py` both use simple **in-process TTL caches** to reduce Firestore reads and external API calls.
- Cache is per-process (not distributed) — a server restart clears it.

---

## Mobile Integration

The Flutter side lives in:

- `lib/services/bahaar_ai_service.dart` — `BahaarAIService` wraps all API calls, injects the Auth token, and throws `BahaarOfflineException` (Arabic message) on network failure.
- `lib/screens/prediction_screen.dart` — UI for fish probability prediction.
- `lib/screens/report_screen.dart` — Catch report form (saves to Firestore + calls `/report`).

> **Note:** `lib/services/map/fishing_ai_service.dart` (`FishingAIService`) uses the old URL `https://bahaar-fishing-ai.onrender.com` — do **not** use it for new features.
