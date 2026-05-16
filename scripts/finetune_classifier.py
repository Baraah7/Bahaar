"""
Fine-tune the fish classifier on extra training images for Red Mullet and Shrimp,
then export a new TFLite model to assets/models/fish_classifier.tflite.

Usage:
    python scripts/finetune_classifier.py
"""

import pathlib
import shutil
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, Model
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# ── paths ────────────────────────────────────────────────────────────────────
KERAS_MODEL     = pathlib.Path("assets/models/fish_classifier_5class(1).keras")
TFLITE_OUT      = pathlib.Path("assets/models/fish_classifier.tflite")
TFLITE_BACKUP   = pathlib.Path("assets/models/fish_classifier_backup.tflite")

# Original reference images per species
ORIGINAL_DIR    = pathlib.Path("assets/images")
# New diverse images for Red Mullet and Shrimp
EXTRA_DIR       = pathlib.Path("assets/data/extra_training")
# Combined dataset built by this script
TRAIN_DIR       = pathlib.Path("assets/data/finetune_dataset")

LABELS = ["Gilt-Head Bream", "Horse Mackerel", "Red Mullet", "Sea Bass", "Shrimp"]

# Original model was trained at 260×260 with raw pixel values (no normalization)
INPUT_SIZE   = 260
BATCH_SIZE   = 16
EPOCHS       = 20
LR           = 1e-4
# Cap per-class images to prevent imbalance dominating training
MAX_PER_CLASS = 55

# ── build dataset directory ──────────────────────────────────────────────────
def build_dataset() -> None:
    """Copy original + extra images into a clean class-folder layout."""
    if TRAIN_DIR.exists():
        shutil.rmtree(TRAIN_DIR)

    # Mapping from asset filenames to class names
    original_map = {
        "Gilt-Head Bream.jpg":  "Gilt-Head Bream",
        "Gilt-Head Bream.png":  "Gilt-Head Bream",
        "Horse mackerel.jpg":   "Horse Mackerel",
        "Red Mullet.jpg":       "Red Mullet",
        "Seabass.jpg":          "Sea Bass",
        "Shrimp.jpeg":          "Shrimp",
        "Shrimp.png":           "Shrimp",
    }

    # Copy original reference images
    for fname, label in original_map.items():
        src = ORIGINAL_DIR / fname
        if not src.exists():
            continue
        dest_dir = TRAIN_DIR / label
        dest_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy(src, dest_dir / fname)

    # Copy test images (species encoded in subdirectory name)
    test_dir = pathlib.Path("assets/data/fish_test/supportedFish")
    folder_to_label = {
        "gilt-headbream": "Gilt-Head Bream",
        "horsemackerel":  "Horse Mackerel",
        "redmullet":      "Red Mullet",
        "seabass":        "Sea Bass",
        "shrimp":         "Shrimp",
    }
    if test_dir.exists():
        for subdir in test_dir.iterdir():
            key = subdir.name.lower().replace("-", "").replace("_", "")
            label = folder_to_label.get(key)
            if label is None:
                continue
            dest_dir = TRAIN_DIR / label
            dest_dir.mkdir(parents=True, exist_ok=True)
            for img in subdir.glob("*"):
                if img.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                    shutil.copy(img, dest_dir / img.name)

    # Copy extra downloaded images (Red Mullet and Shrimp)
    for label in ["Red Mullet", "Shrimp"]:
        src_dir = EXTRA_DIR / label
        if not src_dir.exists():
            continue
        dest_dir = TRAIN_DIR / label
        dest_dir.mkdir(parents=True, exist_ok=True)
        for img in src_dir.glob("*.jpg"):
            shutil.copy(img, dest_dir / img.name)

    # Balance: cap overrepresented classes, augment underrepresented ones
    # by downloading extra images for Gilt-Head Bream, Horse Mackerel, Sea Bass
    _download_extra_for_balance()

    # Cap each class at MAX_PER_CLASS to prevent imbalance
    for label in LABELS:
        class_dir = TRAIN_DIR / label
        if not class_dir.exists():
            continue
        imgs = sorted(class_dir.glob("*"))
        if len(imgs) > MAX_PER_CLASS:
            for img in imgs[MAX_PER_CLASS:]:
                img.unlink()

    # Report
    print("\nDataset summary:")
    total = 0
    for label in LABELS:
        count = len(list((TRAIN_DIR / label).glob("*"))) if (TRAIN_DIR / label).exists() else 0
        print(f"  {label:<20} {count:>4} images")
        total += count
    print(f"  {'TOTAL':<20} {total:>4} images\n")


# ── balance download ─────────────────────────────────────────────────────────
def _download_extra_for_balance() -> None:
    """Download images for classes that still have fewer than MAX_PER_CLASS images."""
    import io, time, requests
    from ddgs import DDGS

    queries = {
        "Gilt-Head Bream": ["gilt head bream fish fresh", "sparus aurata fish market", "orata fish fresh whole"],
        "Horse Mackerel":  ["horse mackerel fish fresh market", "trachurus fish fresh", "saurel fish market"],
        "Sea Bass":        ["sea bass fish fresh market", "branzino fish whole fresh", "loup de mer fish fresh"],
    }
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

    for label, search_queries in queries.items():
        dest_dir = TRAIN_DIR / label
        dest_dir.mkdir(parents=True, exist_ok=True)
        current = len(list(dest_dir.glob("*.jpg")))
        needed = MAX_PER_CLASS - current
        if needed <= 0:
            continue
        print(f"  Downloading {needed} more images for {label}...")
        index = current
        per_query = max(1, needed // len(search_queries) + 1)
        for query in search_queries:
            if index - current >= needed:
                break
            try:
                results = list(DDGS().images(query, max_results=per_query))
            except Exception:
                continue
            for r in results:
                if index - current >= needed:
                    break
                url = r.get("image", "")
                if not url:
                    continue
                try:
                    resp = requests.get(url, headers=headers, timeout=8)
                    from PIL import Image as PILImage
                    img = PILImage.open(io.BytesIO(resp.content))
                    if img.width < 150 or img.height < 150:
                        continue
                    img.convert("RGB").save(dest_dir / f"{index:04d}.jpg", "JPEG", quality=92)
                    index += 1
                except Exception:
                    pass
                time.sleep(0.05)


# ── model ─────────────────────────────────────────────────────────────────────
def build_model() -> Model:
    base = tf.keras.models.load_model(KERAS_MODEL)

    # Freeze EfficientNet backbone, only train the head
    backbone = base.get_layer("efficientnetb0")
    backbone.trainable = False

    # Rebuild head with same architecture
    x = base.get_layer("global_average_pooling2d_1").output
    x = base.get_layer("batch_normalization_1")(x)
    x = base.get_layer("dense_2")(x)
    x = base.get_layer("dropout_1")(x)
    x = base.get_layer("dense_3")(x)
    x = base.get_layer("dropout_2")(x)
    out = base.get_layer("dense_4")(x)

    model = Model(inputs=base.input, outputs=out)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(LR),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


# ── data generators ───────────────────────────────────────────────────────────
def make_generators():
    # No rescale — original model was trained on raw 0-255 pixel values
    train_gen = ImageDataGenerator(
        validation_split=0.15,
        rotation_range=20,
        width_shift_range=0.15,
        height_shift_range=0.15,
        brightness_range=[0.6, 1.4],
        horizontal_flip=True,
        zoom_range=0.15,
        shear_range=0.1,
    )
    train_flow = train_gen.flow_from_directory(
        TRAIN_DIR,
        target_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=BATCH_SIZE,
        class_mode="categorical",
        subset="training",
        classes=LABELS,
        seed=42,
    )
    val_flow = train_gen.flow_from_directory(
        TRAIN_DIR,
        target_size=(INPUT_SIZE, INPUT_SIZE),
        batch_size=BATCH_SIZE,
        class_mode="categorical",
        subset="validation",
        classes=LABELS,
        seed=42,
    )
    return train_flow, val_flow


# ── TFLite export ─────────────────────────────────────────────────────────────
def export_tflite(model: Model) -> None:
    # Back up existing model
    if TFLITE_OUT.exists():
        shutil.copy(TFLITE_OUT, TFLITE_BACKUP)
        print(f"Backed up existing model to {TFLITE_BACKUP}")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    TFLITE_OUT.write_bytes(tflite_model)
    size_kb = len(tflite_model) / 1024
    print(f"Saved new TFLite model to {TFLITE_OUT} ({size_kb:.0f} KB)")


# ── quick validation ──────────────────────────────────────────────────────────
def validate_tflite() -> None:
    """Run the new TFLite model on the 5 test images and print scores."""
    from PIL import Image

    interp = tf.lite.Interpreter(model_path=str(TFLITE_OUT))
    interp.allocate_tensors()
    inp_idx = interp.get_input_details()[0]["index"]
    out_idx = interp.get_output_details()[0]["index"]

    test_images = {
        "Gilt-Head Bream": "assets/images/Gilt-Head Bream.jpg",
        "Horse Mackerel":   "assets/images/Horse mackerel.jpg",
        "Red Mullet":       "assets/images/Red Mullet.jpg",
        "Sea Bass":         "assets/images/Seabass.jpg",
        "Shrimp":           "assets/images/Shrimp.jpeg",
    }
    # Also test the previously failing images
    extra_tests = [
        ("Red Mullet", "assets/data/fish_test/supportedFish/RedMullet/OIP-1643670038.jpg"),
        ("Red Mullet", "assets/data/fish_test/supportedFish/RedMullet/OIP-3982704853.jpg"),
        ("Shrimp",     "assets/data/fish_test/supportedFish/Shrimp/OIP-102484121.jpg"),
        ("Shrimp",     "assets/data/fish_test/supportedFish/Shrimp/OIP-844962183.jpg"),
    ]

    print("\n--- Validation on reference images ---")
    for expected, path in list(test_images.items()) + [(e, p) for e, p in extra_tests]:
        img = Image.open(path).convert("RGB").resize((INPUT_SIZE, INPUT_SIZE))
        t = np.expand_dims(np.asarray(img, dtype=np.float32), 0)  # raw 0-255
        interp.set_tensor(inp_idx, t)
        interp.invoke()
        scores = interp.get_tensor(out_idx)[0]
        pred = LABELS[int(np.argmax(scores))]
        conf = float(np.max(scores))
        status = "OK" if pred == expected else "XX"
        print(f"  {status} {expected:<20} -> {pred:<20} {conf:.3f}  {pathlib.Path(path).name}")


# ── main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    print("=== Fish Classifier Fine-tuning ===\n")

    print("Step 1: Building dataset...")
    build_dataset()

    print("Step 2: Loading model...")
    model = build_model()
    trainable = sum(np.prod(w.shape) for w in model.trainable_weights)
    print(f"  Trainable parameters: {trainable:,} (backbone frozen)\n")

    print("Step 3: Training...")
    train_flow, val_flow = make_generators()

    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=4, restore_best_weights=True, verbose=1
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=2, verbose=1
        ),
    ]

    model.fit(
        train_flow,
        validation_data=val_flow,
        epochs=EPOCHS,
        callbacks=callbacks,
    )

    print("\nStep 4: Exporting TFLite model...")
    export_tflite(model)

    print("\nStep 5: Validating new model...")
    validate_tflite()

    print("\nDone. New model is at:", TFLITE_OUT)
    print("Run the diagnostics script to do a full test:")
    print("  python scripts/fish_recognition_diagnostics.py")


if __name__ == "__main__":
    main()
