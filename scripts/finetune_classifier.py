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

# Original model was trained at 260×260; we keep the same to reuse its weights
INPUT_SIZE  = 260
BATCH_SIZE  = 16
EPOCHS      = 15
LR          = 1e-4

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

    # Copy extra downloaded images
    suffixes = {".jpg", ".jpeg", ".png"}
    for label in ["Red Mullet", "Shrimp"]:
        src_dir = EXTRA_DIR / label
        if not src_dir.exists():
            continue
        dest_dir = TRAIN_DIR / label
        dest_dir.mkdir(parents=True, exist_ok=True)
        for img in src_dir.glob("*.jpg"):
            shutil.copy(img, dest_dir / img.name)

    # Report
    print("\nDataset summary:")
    total = 0
    for label in LABELS:
        count = len(list((TRAIN_DIR / label).glob("*"))) if (TRAIN_DIR / label).exists() else 0
        print(f"  {label:<20} {count:>4} images")
        total += count
    print(f"  {'TOTAL':<20} {total:>4} images\n")


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
    # Aggressive augmentation to help generalise from diverse images
    train_gen = ImageDataGenerator(
        rescale=1.0 / 255,
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

    print("\n── Validation on reference images ──")
    for expected, path in list(test_images.items()) + [(e, p) for e, p in extra_tests]:
        img = Image.open(path).convert("RGB").resize((INPUT_SIZE, INPUT_SIZE))
        t = np.expand_dims(np.asarray(img, dtype=np.float32) / 255.0, 0)
        interp.set_tensor(inp_idx, t)
        interp.invoke()
        scores = interp.get_tensor(out_idx)[0]
        pred = LABELS[int(np.argmax(scores))]
        conf = float(np.max(scores))
        status = "✓" if pred == expected else "✗"
        print(f"  {status} {expected:<20} → {pred:<20} {conf:.3f}  {pathlib.Path(path).name}")


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
