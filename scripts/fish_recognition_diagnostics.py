import argparse
import csv
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import tensorflow as tf
from PIL import Image


LABELS_PATH = Path("assets/models/labels.txt")
DETECTOR_PATH = Path("assets/models/fish_detector.tflite")
CLASSIFIER_PATH = Path("assets/models/fish_classifier.tflite")
SUPPORTED_IMAGES_DIR = Path("assets/images")
DEFAULT_NON_FISH_DIRS = (Path("assets/logo"),)
DEFAULT_SUPPORTED_TEST_DIR = Path("assets/data/fish_test/supportedFish")
DEFAULT_NON_FISH_TEST_DIR = Path("assets/data/fish_test/nonFish")
DEFAULT_UNSUPPORTED_TEST_DIR = Path("assets/data/fish_test/unsupportedFish")

# Maps folder names (case-insensitive, stripped) to canonical label names
FOLDER_TO_LABEL = {
    "gilt-headbream": "Gilt-Head Bream",
    "giltheadbream": "Gilt-Head Bream",
    "horsemackerel": "Horse Mackerel",
    "redmullet": "Red Mullet",
    "seabass": "Sea Bass",
    "shrimp": "Shrimp",
}

INPUT_SIZE = 260
CLASSIFIER_THRESHOLD = 0.35
DETECTOR_AMBIGUOUS_THRESHOLD = 0.40
AMBIGUOUS_ZONE_MIN_CONFIDENCE = 0.65
MINIMUM_TOP_CLASS_MARGIN = 0.10
CLASS_THRESHOLDS = {
    "Gilt-Head Bream": 0.35,
    "Horse Mackerel": 0.35,
    "Red Mullet": 0.35,
    "Sea Bass": 0.35,
    "Shrimp": 0.35,
}


EXPECTED_BY_FILENAME = {
    "gilt": "Gilt-Head Bream",
    "bream": "Gilt-Head Bream",
    "mackerel": "Horse Mackerel",
    "mullet": "Red Mullet",
    "seabass": "Sea Bass",
    "sea bass": "Sea Bass",
    "shrimp": "Shrimp",
}


@dataclass
class Prediction:
    expected: str
    path: str
    detector_score: float
    predicted_label: str
    confidence: float
    margin: float
    decision: str
    issue: str


def load_labels() -> list[str]:
    aliases = {
        "Hourse Mackerel": "Horse Mackerel",
    }
    return [
        aliases.get(line.strip(), line.strip())
        for line in LABELS_PATH.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def load_interpreter(path: Path) -> tf.lite.Interpreter:
    interpreter = tf.lite.Interpreter(model_path=str(path))
    interpreter.allocate_tensors()
    return interpreter


def image_to_tensor(path: Path) -> np.ndarray:
    image = Image.open(path).convert("RGB").resize((INPUT_SIZE, INPUT_SIZE))
    return np.expand_dims(np.asarray(image, dtype=np.float32), axis=0)


def run_interpreter(interpreter: tf.lite.Interpreter, tensor: np.ndarray) -> np.ndarray:
    input_index = interpreter.get_input_details()[0]["index"]
    output_index = interpreter.get_output_details()[0]["index"]
    interpreter.set_tensor(input_index, tensor)
    interpreter.invoke()
    return interpreter.get_tensor(output_index)


def expected_species(path: Path, fallback: str) -> str:
    name = path.stem.lower().replace("-", " ")
    for token, label in EXPECTED_BY_FILENAME.items():
        if token in name:
            return label
    return fallback


def app_decision(detector_score: float, predicted_label: str, confidence: float, margin: float) -> str:
    base_threshold = CLASS_THRESHOLDS.get(predicted_label, CLASSIFIER_THRESHOLD)
    effective_threshold = (
        AMBIGUOUS_ZONE_MIN_CONFIDENCE
        if detector_score >= DETECTOR_AMBIGUOUS_THRESHOLD
        else base_threshold
    )
    if confidence >= effective_threshold and margin >= MINIMUM_TOP_CLASS_MARGIN:
        return "supported"
    return "no_fish"


def diagnose(expected: str, predicted_label: str, confidence: float, decision: str) -> str:
    if expected == "non_fish":
        if decision == "supported":
            return "non-fish accepted as a supported species"
        return ""  # no_fish is the correct rejection
    if expected == "unsupported_fish":
        if decision == "supported":
            return "unsupported fish accepted as supported"
        return ""  # no_fish is the correct rejection
    if decision != "supported":
        return f"supported fish rejected as {decision}"
    if predicted_label != expected:
        return f"wrong species: expected {expected}"
    if confidence < CLASS_THRESHOLDS.get(predicted_label, CLASSIFIER_THRESHOLD):
        return "below configured class threshold"
    return ""


def collect_images(paths: list[Path]) -> list[tuple[str, Path]]:
    images: list[tuple[str, Path]] = []
    suffixes = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    for path in paths:
        if not path.exists():
            continue
        if path.is_file() and path.suffix.lower() in suffixes:
            images.append((path.name, path))
        elif path.is_dir():
            for child in sorted(path.rglob("*")):
                if child.is_file() and child.suffix.lower() in suffixes:
                    images.append((child.name, child))
    return images


def collect_supported_from_subdirs(root: Path) -> list[tuple[str, Path]]:
    """Collect supported fish images where species is encoded in subdirectory name."""
    suffixes = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    cases: list[tuple[str, Path]] = []
    if not root.exists():
        return cases
    for subdir in sorted(root.iterdir()):
        if not subdir.is_dir():
            continue
        label = FOLDER_TO_LABEL.get(subdir.name.lower().replace("-", "").replace("_", "").replace(" ", ""))
        if label is None:
            # Fall back to filename-based inference
            label = None
        for img_path in sorted(subdir.rglob("*")):
            if img_path.is_file() and img_path.suffix.lower() in suffixes:
                expected = label if label else expected_species(img_path, "supported_fish")
                cases.append((expected, img_path))
    return cases


def predict_all(
    non_fish_dirs: list[Path],
    unsupported_dirs: list[Path],
    supported_test_dirs: list[Path],
) -> list[Prediction]:
    labels = load_labels()
    detector = load_interpreter(DETECTOR_PATH)
    classifier = load_interpreter(CLASSIFIER_PATH)
    rows: list[Prediction] = []

    cases: list[tuple[str, Path]] = []
    cases.extend((expected_species(path, "supported_fish"), path) for _, path in collect_images([SUPPORTED_IMAGES_DIR]))
    for d in supported_test_dirs:
        cases.extend(collect_supported_from_subdirs(d))
    cases.extend(("non_fish", path) for _, path in collect_images(non_fish_dirs))
    cases.extend(("unsupported_fish", path) for _, path in collect_images(unsupported_dirs))

    for expected, path in cases:
        try:
            tensor = image_to_tensor(path)
            detector_score = float(run_interpreter(detector, tensor)[0][0])
            scores = run_interpreter(classifier, tensor)[0]
            order = np.argsort(scores)[::-1]
            predicted_label = labels[int(order[0])]
            confidence = float(scores[order[0]])
            margin = float(scores[order[0]] - scores[order[1]]) if len(order) > 1 else confidence
            decision = app_decision(detector_score, predicted_label, confidence, margin)
            issue = diagnose(expected, predicted_label, confidence, decision)
            rows.append(
                Prediction(
                    expected=expected,
                    path=str(path),
                    detector_score=detector_score,
                    predicted_label=predicted_label,
                    confidence=confidence,
                    margin=margin,
                    decision=decision,
                    issue=issue,
                )
            )
        except Exception as exc:
            rows.append(Prediction(expected, str(path), 0.0, "", 0.0, 0.0, "error", str(exc)))
    return rows


def print_table(rows: list[Prediction]) -> None:
    print("expected,path,detector_score,predicted_label,confidence,margin,decision,issue")
    writer = csv.writer(sys.stdout, lineterminator="\n")
    for row in rows:
        writer.writerow(
            [
                row.expected,
                row.path,
                f"{row.detector_score:.4f}",
                row.predicted_label,
                f"{row.confidence:.4f}",
                f"{row.margin:.4f}",
                row.decision,
                row.issue,
            ]
        )


def print_summary(rows: list[Prediction]) -> int:
    failures = [row for row in rows if row.issue]
    print()
    print(f"Checked {len(rows)} images; {len(failures)} need attention.")
    for row in failures:
        print(f"- {row.path}: {row.issue}")
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Diagnose the fish detector + classifier TFLite pipeline."
    )
    parser.add_argument(
        "--non-fish-dir",
        action="append",
        type=Path,
        default=None,
        help="Directory or image containing non-fish examples. Can be repeated.",
    )
    parser.add_argument(
        "--unsupported-dir",
        action="append",
        type=Path,
        default=None,
        help="Directory or image containing fish species outside labels.txt. Can be repeated.",
    )
    parser.add_argument(
        "--supported-test-dir",
        action="append",
        type=Path,
        default=None,
        help="Directory whose subdirectories are named by species (e.g. Gilt-headBream/). Can be repeated.",
    )
    args = parser.parse_args()

    non_fish_dirs = args.non_fish_dir or list(DEFAULT_NON_FISH_DIRS) + [DEFAULT_NON_FISH_TEST_DIR]
    unsupported_dirs = args.unsupported_dir or [DEFAULT_UNSUPPORTED_TEST_DIR]
    supported_test_dirs = args.supported_test_dir or [DEFAULT_SUPPORTED_TEST_DIR]

    rows = predict_all(non_fish_dirs, unsupported_dirs, supported_test_dirs)
    print_table(rows)
    return print_summary(rows)


if __name__ == "__main__":
    raise SystemExit(main())
