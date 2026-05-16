# Weather Feature — Technical Documentation

## Overview

The Weather screen gives Bahraini fishermen a safety-first view of marine conditions. It pulls from three external data sources and one local algorithm, each with its own caching and offline strategy.

---

## Data Sources

### 1. WeatherAPI (Current Weather & Forecast)
- **What it provides**: Current temperature, wind speed/direction, humidity, UV index, wave conditions, hourly forecast, 7-day daily forecast.
- **Endpoint**: `api.weatherapi.com/v1/forecast.json`
- **Location**: Uses the device's GPS coordinates when available, falls back to Manama (26.2235, 50.5876).
- **Offline behavior**: **No cache.** If the request fails, the screen shows an error state with a "Try Again" button. Showing an old forecast to a fisherman could be dangerous, so we never display stale weather data.

### 2. WorldTides API (Tide Predictions)
- **What it provides**: High/low tide extremes (time + height in metres) for today.
- **Endpoint**: `worldtides.info/api/v3`
- **Free tier limit**: 10 requests/day — caching is essential.
- **Caching**: Results are stored in `SharedPreferences` keyed by location (rounded to 1 decimal degree, ~11 km grid) and a timestamp. The cache is valid for **24 hours**. If cached data exists and is fresh, no API call is made.
- **Offline behavior**: If the device is offline but a valid cache exists, tides are shown from cache. If the cache is stale and the call fails, the tides section is simply omitted — the rest of the weather data still shows.

### 3. Celestial Calculator (Sunrise, Sunset, Moon Phase)
- **What it provides**: Sunrise time, sunset time, moon phase name and illumination percentage.
- **Implementation**: `CelestialCalculator` — pure local Dart math based on NOAA solar calculation algorithms.
- **Offline behavior**: **Fully offline. No API call at all.** The calculator takes the current `DateTime` and coordinates and returns results instantly, every time.

---

## Architecture

```
Weather (StatefulWidget)
│
├── _loadAll() — runs in parallel with Future.wait([...])
│   ├── WeatherApiService.getWeather()      → WeatherResponseModel
│   └── WorldTidesService.getTides()        → List<TideEntry>
│
└── WeatherList (StatelessWidget)
    ├── WeatherHeader           (current temp, condition, location)
    ├── WeatherHourlyForecast   (next 24 h scroll)
    ├── WeatherDailyForecast    (7-day)
    ├── WeatherWindCard         (speed, direction, gust)
    ├── CompactInfoRow          (UV index, feels-like, humidity, visibility)
    ├── TidesCard               (high/low tide times from WorldTides)
    ├── CelestialAlmanacCard    (sunrise/sunset/moon — from CelestialCalculator)
    └── SafetyBadge             (overall marine safety level: Safe / Caution / Danger)
```

---

## Safety Badge Logic

The `SafetyBadge` widget computes a marine safety level from live weather data:

| Level   | Condition                                                 |
|---------|-----------------------------------------------------------|
| Safe    | Wind < 20 km/h, visibility > 5 km, no extreme UV         |
| Caution | Wind 20–40 km/h, or reduced visibility, or high UV       |
| Danger  | Wind > 40 km/h, or visibility < 2 km, or storm alerts    |

This badge is also used in the navigation A* routing cost multiplier — Danger zones raise the cost of traversing those sea cells.

---

## Caching Strategy Summary

| Source              | Cache          | Duration | Offline fallback              |
|---------------------|----------------|----------|-------------------------------|
| WeatherAPI          | None           | —        | Error state + "Try Again"     |
| WorldTides          | SharedPreferences | 24 h  | Show cached tides             |
| CelestialCalculator | Not needed     | —        | Always works offline          |

---

## 1-Minute Presentation Script

> "The weather screen is built for safety, not just information.
>
> It pulls from three sources. WeatherAPI gives us current conditions and a 7-day marine forecast. WorldTides gives us today's high and low tide times — and because their free plan is limited to 10 requests a day, we cache results in SharedPreferences for 24 hours, so the app works even without a constant connection.
>
> The sunrise, sunset, and moon phase section works completely offline — no API call at all. It uses a local NOAA-based algorithm that runs instant calculations from the device's date and location.
>
> For current weather and forecasts, we made a deliberate choice: we never show stale data. If the call fails, we show an error state with a retry button. Showing a fisherman an outdated storm warning could be genuinely dangerous.
>
> Finally, the safety badge at the bottom summarises all conditions into a single Safe / Caution / Danger level, which we also feed into the navigation system to route boats away from dangerous conditions."

---

## Examiner Q&A

**Q: Why not cache the weather forecast the same way you cache tides?**
> Tides are predictable — they don't change hour by hour. A 24-hour-old tide prediction is still accurate. A 24-hour-old weather forecast, however, could be dangerously wrong during a fast-moving storm. The risk asymmetry is why we cache tides but show an error for stale weather.

**Q: What happens if the user has no internet at all?**
> Celestial data (sunrise, sunset, moon) always works offline. If tides were fetched in the last 24 hours, they show from cache. For current weather, the screen shows an error state with a "Try Again" button — we don't fabricate or show outdated conditions.

**Q: How does WorldTides stay within the 10 requests/day free limit?**
> We round the user's GPS coordinates to one decimal place (~11 km grid) before building the cache key, so nearby location updates reuse the same cache entry. The 24-hour TTL means we make at most one request per grid cell per day.

**Q: Why use local math for celestial data instead of an API?**
> Sunrise and moon phase are deterministic — given a date and location, the answer is always the same. An API would add latency, a potential point of failure, and an API key to manage, for no accuracy benefit. The NOAA algorithm is the same math those APIs use internally.

**Q: How accurate is the NOAA-based celestial calculator?**
> For sunrise/sunset it's accurate to within about 1 minute for Bahrain's latitude. Moon phase is accurate to the day. This is well within the margin that matters for a fisherman planning a trip.

**Q: Does the safety badge affect anything else in the app?**
> Yes. The safety level feeds into the marine A* routing algorithm. A "Danger" weather rating raises the traversal cost multiplier for sea route cells, so the navigation system will prefer calmer corridors or flag the route as high-risk.

**Q: What API does the weather forecast use?**
> WeatherAPI (weatherapi.com). We use the forecast endpoint with 7 days of data and air quality enabled. The key is stored in a `.env` file and loaded via `flutter_dotenv`, so it's never hard-coded in source.
