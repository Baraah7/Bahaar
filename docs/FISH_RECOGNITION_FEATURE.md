# Fish Recognition Feature — Technical Documentation

## Overview

The fish recognition feature lets users photograph a fish (or pick from gallery) and instantly identify its species using an on-device machine-learning model. No internet connection is required for the identification itself. The feature also includes an AI-powered catch prediction screen that forecasts how likely a species is to be caught at a given location and time.

---

## Architecture

```
User takes photo
      │
      ▼
FishRecognitionScreen          (lib/screens/fish recognition/fish_recognition_screen.dart)
      │  picks image via ImagePicker (camera or gallery, max 1024×1024, quality 85)
      ▼
FishClassificationNotifier     (lib/providers/fish recognition/fish_classification_provider.dart)
      │  manages loading / result / error state via Riverpod Notifier
      ▼
FishClassifierService          (lib/services/fishRecognition/fish_classifier_service.dart)
      │
      ├─ _preprocess()   → resize to 260×260, raw [0,255] float tensor
      │
      ├─ TFLite Interpreter runs fish_classifier.tflite (EfficientNetB0)
      │   outputs softmax scores for 5 classes
      │
      ├─ Entropy check  → flat distribution = non-fish → status: noFish
      ├─ Margin check   → top − runner-up < 0.25 → status: noFish
      └─ Confidence check → score ≥ 0.60 → supportedFish, else unsupportedFish
```

---

## Components

### 1. TFLite Model — `fish_classifier.tflite`
- Architecture: EfficientNetB0 (fine-tuned)
- Input: 260 × 260 × 3, raw pixel values `[0, 255]` (no normalization)
- Output: softmax probabilities for 5 classes
- Bundled asset — runs fully on-device, no network call
- Loaded with 2 threads (`InterpreterOptions..threads = 2`)

### 2. Supported Species (5 classes)

| English Name    | Arabic Name | Scientific Name            |
|-----------------|-------------|----------------------------|
| Gilt-Head Bream | دنيس        | *Sparus aurata*            |
| Horse Mackerel  | سكمبري      | *Trachurus trachurus*      |
| Red Mullet      | بربوني      | *Mullus surmuletus*        |
| Sea Bass        | قاروص       | *Dicentrarchus labrax*     |
| Shrimp          | روبيان      | Various species            |

These species were selected for their commercial and cultural significance in the Arabian Gulf / Bahrain fisheries.

### 3. Fish Detector Model — `fish_detector.tflite` (Diagnostic Only)

A second TFLite model exists in `assets/models/fish_detector.tflite`:
- Input: 300 × 300, raw [0, 255]
- Output: a single float — a "fish presence" confidence score
- Architecture: object detection / binary classifier

**Important:** This model is **not called by the live app**. It is only used in the offline diagnostics script (`scripts/fish_recognition_diagnostics.py`) to evaluate the pipeline during development. In the script, the detector score was used to tighten the confidence threshold in an "ambiguous zone" (`detector_score ≥ 0.18` → require classifier confidence ≥ 0.65 instead of 0.35).

In the current production app (`FishClassifierService`), the `detectorScore` field on `FishClassification` is simply set to the classifier's own top confidence — the detector model is never loaded at runtime. The detector's role was replaced by the **entropy + margin filtering** approach, which is more principled and requires no second model.

**Why was it replaced?**
Running two TFLite models per image adds latency and memory. Entropy-based rejection does the same job using only the classifier's existing output, with no extra computation. The diagnostic script still references `fish_detector.tflite` because it was used to tune and verify thresholds during development.

---

### 5. Classification Pipeline (`FishClassifierService`)

**Step 1 — Preprocessing**
```
image file → decode → resize to 260×260 (cubic interpolation) → float tensor [1, 260, 260, 3]
```
Pixel values kept as raw `[0, 255]` to match EfficientNetB0 training preprocessing.

**Step 2 — Inference**
TFLite interpreter runs the model and returns a float array of 5 softmax scores.

**Step 3 — Three-gate filtering**

| Gate | Condition | Result |
|------|-----------|--------|
| Entropy | `entropy > 0.85` | `noFish` — image too ambiguous |
| Margin | `top − 2nd < 0.25` | `noFish` — model is not sure enough |
| Confidence | `top score ≥ 0.60` | `supportedFish` |
| Confidence | `top score < 0.60` | `unsupportedFish` — fish present but unknown species |

**Entropy formula:**
```
H = − Σ (p_i × log(p_i))
```
A real fish produces a peaked distribution → low entropy (measured: 0.14–0.69).  
A non-fish image produces a flat distribution → high entropy (measured: 0.99–1.35).  
Threshold set at 0.85 — squarely in the gap between these ranges.

**Step 4 — Result**
Returns a `FishClassification` object with:
- `className` — species name or "Unsupported species" / "No fish detected"
- `confidence` — top softmax score (0–1)
- `status` — `supportedFish` / `unsupportedFish` / `noFish`
- `arabicName` — localized species name

### 6. State Management (`FishClassificationNotifier` / Riverpod)

```
initialize()     → loads TFLite model from assets
classifyImage()  → sets isLoading, calls service, stores result or error
clearResult()    → resets to empty state
```

State fields: `result`, `isLoading`, `isInitialized`, `error`.

### 7. UI Screen (`FishRecognitionScreen`)

Two modes:
- **Landing view** — upload area (camera + gallery buttons) + 2×2 grid of supported species with photo cards
- **Result view** — selected image preview + result card + fish info card (or unknown/no-fish card)

Result card shows:
- Circular confidence gauge (colored green ≥ 60%, amber below)
- Species name in selected language (Arabic or English)
- "High Confidence" / "Low Confidence" badge
- Tip to retake if confidence is low

Fish info card shows (bilingual):
- Habitat, size, season, diet, flavor
- Popular fishing regions
- Nutritional value
- Fun fact specific to Gulf/Bahrain context

### 8. Model Training & Fine-tuning (`scripts/finetune_classifier.py`)

- Base model: EfficientNetB0 (ImageNet weights)
- Backbone frozen; only head layers trained
- Focus species: Red Mullet and Shrimp (harder to classify)
- Data augmentation applied
- Early stopping to prevent overfitting
- Exported to TFLite format at 260×260

Training images downloaded via `scripts/download_training_images.py` using DuckDuckGo image search, targeting food/market/raw-fish visual contexts per species.

Diagnostics verified with `scripts/fish_recognition_diagnostics.py` — runs both models on test sets, outputs CSV with confidence, margin, entropy, and expected vs predicted labels.

### 9. AI Catch Prediction Screen (`PredictionScreen`)

A separate screen (not on-device ML) that calls a cloud backend:
- User selects: location (GPS or map tap), species, month
- Backend (`BahaarAIService` → Flask/FastAPI on Render) returns:
  - Probability gauge (0–100%)
  - Prediction factors: seasonal trends, environmental conditions, nearby fisher reports, proximity to productive zones
  - MPA (Marine Protected Area) warnings
  - Seasonal fishing advice
- Falls back gracefully offline with bilingual error messages

### 10. Fish Probability Heatmap (`FishProbabilityService`)

Displayed as a togglable map layer (visible at zoom < 12):
- Fetches SST (Sea Surface Temperature) and Chlorophyll-a data from CMEMS (Copernicus Marine)
- Computes per-species probability for each 0.15° grid cell (~16 km) over Bahrain's bounding box (25.5–27°N, 49.5–51°E)
- Uses trapezoidal membership functions tuned per species
- Weighting: SST 55% + Chlorophyll 45%
- Falls back to bundled `fish_probability_fallback.json` when CMEMS is unavailable

---

## Data Flow Summary

```
Camera/Gallery → ImagePicker
    → File → FishClassificationNotifier.classifyImage()
        → FishClassifierService.classifyImage()
            → preprocess (260×260 float tensor)
            → TFLite inference (EfficientNetB0)
            → entropy + margin + confidence gates
            → FishClassification result
    → UI re-renders with result card + fish info
```

---

## Key Technical Numbers

| Parameter | Value |
|-----------|-------|
| Model input | 260 × 260 pixels |
| Pixel range | Raw [0, 255] — no normalization |
| Confidence threshold | 0.60 (all 5 species) |
| Max entropy | 0.85 |
| Min confidence margin | 0.25 |
| Fish entropy range (real data) | 0.14 – 0.69 |
| Non-fish entropy range (real data) | 0.99 – 1.35 |
| Inference threads | 2 |
| Image capture max size | 1024 × 1024 px |
| Map grid resolution | 0.15° ≈ 16 km |

---
---

# 1-Minute Presentation Content (Single Slide)

**Slide Title: Fish Recognition — On-Device AI Species Identification**

---

**[Opening — 10 sec]**
"One of Bahaar's standout features is instant fish recognition. A fisherman takes a photo of their catch — and the app identifies the species right there on the boat, with no internet needed."

**[How It Works — 20 sec]**
"Under the hood, we use a fine-tuned EfficientNetB0 deep learning model bundled directly in the app as a TensorFlow Lite file. When you photograph a fish, the image is resized to 260 by 260 pixels and passed through the model, which outputs confidence scores for five species common to Bahraini waters: Gilt-Head Bream, Horse Mackerel, Red Mullet, Sea Bass, and Shrimp."

**[Smart Filtering — 15 sec]**
"What makes it reliable is a three-gate filtering system. We measure the entropy of the model's output — if the model is uncertain, the distribution is flat and entropy is high, so we reject it. We also check the confidence margin between the top two predictions. Only when both pass do we show a result. This prevents false positives for non-fish images."

**[Output & Value — 15 sec]**
"The app shows a confidence gauge and the species name in both Arabic and English, with a rich info card covering habitat, nutrition, and Gulf-specific context. If the species isn't in our training set, the app says 'unsupported species' rather than guessing. There's also a companion AI prediction screen that forecasts catch probability based on location, season, and satellite environmental data."

---
---

# Common Examiner Questions & Answers

**Q1: Why did you choose EfficientNetB0 specifically?**

EfficientNetB0 is designed for mobile image classification — it balances accuracy and computational cost, making it ideal for on-device TFLite inference. It also fine-tunes well from ImageNet weights with a small dataset when the backbone is frozen and only the head is retrained, which suited our limited Gulf fish training data.

---

**Q2: Why only 5 species? Why not more?**

The 5 species are the most commercially significant in Bahrain's fishing industry. Adding more requires substantially more labeled training data and risks degrading accuracy on existing classes. The system gracefully says "unsupported species" rather than misidentifying, which is the safer behavior for a real fishing application.

---

**Q3: What happens if the user photographs something that isn't a fish — like their hand or the sea?**

This is handled by the entropy-based rejection gate. Non-fish images cause the model's output to be nearly flat across all 5 classes (it doesn't know what it is), resulting in high entropy. We measured real data: fish images produce entropy between 0.14 and 0.69; non-fish images produce 0.99 to 1.35. The threshold is set at 0.85 — squarely in the gap. A second margin check (top score minus runner-up must exceed 0.25) provides a further layer of protection.

---

**Q4: Does this require an internet connection?**

No. The TFLite model is bundled as an asset inside the app. Classification runs entirely on-device. Only the AI catch prediction screen (cloud backend) and the environmental heatmap layer (Copernicus Marine satellite data) require internet. Core fish identification works offline.

---

**Q5: How accurate is the model? How was it validated?**

We fine-tuned EfficientNetB0 on images of the 5 target species with extra focus on Red Mullet and Shrimp, which are harder to distinguish visually. Validation used a dedicated test set split across supported species, unsupported species, and non-fish images. A diagnostics script output per-image CSV reports with confidence, margin, entropy, and expected vs predicted labels. The 0.60 confidence threshold and 0.85 entropy cutoff were tuned empirically from those measurements.

---

**Q6: Why use entropy rather than just a low-confidence threshold to reject non-fish images?**

A low-confidence threshold alone can be fooled: a non-fish image might assign 40% confidence to "Shrimp" simply because that's the closest match, which could pass a 40% threshold even though the model is clearly confused. Entropy captures the whole distribution — a flat distribution means the model has no strong opinion about any class. That is a far more reliable signal that the image isn't a fish. Using entropy and margin together makes rejection robust.

---

**Q7: What is the prediction screen and how is it different from the recognition screen?**

The recognition screen identifies *what you caught* using on-device ML on a photo. The prediction screen forecasts *where and when to fish* — the user picks a location, species, and month, and a cloud backend analyses seasonal patterns, sea surface temperature, chlorophyll levels, and historical catch reports to return a probability score and fishing advice. The two screens are complementary: identify your catch, then plan where to find more.

---

**Q8: Could the model be updated without releasing a new app version?**

Currently the model is a bundled asset, so an update requires a new app release. A future improvement could add over-the-air model delivery (e.g., Firebase ML) with a local fallback to the bundled model. This was a deliberate scope decision — bundling guarantees offline reliability and avoids a network dependency on first use.

---

**Q9: What framework did you use for on-device inference?**

TensorFlow Lite via the `tflite_flutter` Dart package. TFLite is the standard choice for running neural networks on mobile — it supports model quantization, hardware acceleration (GPU delegate, NNAPI), and runs on both Android and iOS. The Flutter plugin wraps the native TFLite runtime.

---

**Q10: There are two TFLite models in the assets folder — a classifier and a detector. Do you use both?**

Only the classifier (`fish_classifier.tflite`) is used in the live app. The detector (`fish_detector.tflite`) is a separate binary model — input 300×300, output a single fish-presence confidence score — that was part of an earlier two-stage pipeline design. In that design, the detector score was used to raise the confidence threshold when the image was in an "ambiguous zone." That approach was replaced by entropy + margin filtering, which achieves the same rejection using only the classifier's own output, with no second model to load or run. The detector remains in assets because the offline diagnostics script (`fish_recognition_diagnostics.py`) still references it to verify threshold behaviour during development.

---

**Q11: How does the bilingual Arabic/English support work?**

Every species has a hardcoded Arabic name in the `FishClassification` class and in the UI's `_fishInfo`/`_fishInfoAr` maps. The app checks the active language via `LanguageProvider` (Riverpod) and renders the appropriate name and full info text. The fish info cards — habitat, diet, fun facts — are maintained as separate fully-translated Arabic and English content maps, not just transliterations.
