"""
Validates the shipped fish_classifier.tflite against the labeled sample
images in assets/data/fish_test/, replicating the exact preprocessing and
decision logic used in lib/services/fish_recognition/fish_classifier_service.dart:
  - resize to 260x260, raw [0,255] RGB (EfficientNetB0)
  - entropy/margin based "not fish" rejection
  - per-class confidence threshold of 0.60
"""
import os
import math
import numpy as np
import tensorflow as tf
from PIL import Image

LABELS = ['Gilt-Head Bream', 'Horse Mackerel', 'Red Mullet', 'Sea Bass', 'Shrimp']
INPUT_SIZE = 260
MAX_FISH_ENTROPY = 0.85
MIN_MARGIN = 0.25
CONFIDENCE_THRESHOLD = 0.60

DIR_TO_LABEL = {
    'Gilt-headBream': 'Gilt-Head Bream',
    'HorseMackerel': 'Horse Mackerel',
    'RedMullet': 'Red Mullet',
    'SeaBass': 'Sea Bass',
    'Shrimp': 'Shrimp',
}

interpreter = tf.lite.Interpreter(model_path='assets/models/fish_classifier.tflite')
interpreter.allocate_tensors()
in_detail = interpreter.get_input_details()[0]
out_detail = interpreter.get_output_details()[0]


def classify(path):
    image = Image.open(path).convert('RGB').resize((INPUT_SIZE, INPUT_SIZE), Image.BICUBIC)
    arr = np.array(image, dtype=np.float32)
    arr = np.expand_dims(arr, 0)

    interpreter.set_tensor(in_detail['index'], arr)
    interpreter.invoke()
    scores = interpreter.get_tensor(out_detail['index'])[0]

    ranked = np.argsort(scores)[::-1]
    best_idx = ranked[0]
    confidence = float(scores[best_idx])
    runner_up = float(scores[ranked[1]]) if len(ranked) > 1 else 0.0
    margin = confidence - runner_up
    predicted = LABELS[best_idx]

    entropy = -sum(s * math.log(s) for s in scores if s > 0)

    looks_like_not_fish = entropy > MAX_FISH_ENTROPY or margin < MIN_MARGIN
    if looks_like_not_fish:
        return 'No fish detected', confidence, entropy, margin

    is_recognized = confidence >= CONFIDENCE_THRESHOLD
    if is_recognized:
        return predicted, confidence, entropy, margin
    return 'Unsupported species', confidence, entropy, margin


def run_folder(folder, expected_label):
    correct = 0
    total = 0
    results = []
    for fname in sorted(os.listdir(folder)):
        path = os.path.join(folder, fname)
        try:
            predicted, conf, entropy, margin = classify(path)
        except Exception as e:
            results.append((fname, f'ERROR: {e}', None, None, None))
            continue
        total += 1
        ok = predicted == expected_label
        correct += int(ok)
        results.append((fname, predicted, conf, entropy, margin, ok))
    return correct, total, results


def main():
    base = 'assets/data/fish_test'
    grand_correct = 0
    grand_total = 0

    print('=== supportedFish (expect exact species match) ===')
    for dirname, label in DIR_TO_LABEL.items():
        folder = os.path.join(base, 'supportedFish', dirname)
        correct, total, results = run_folder(folder, label)
        grand_correct += correct
        grand_total += total
        print(f'\n{label}: {correct}/{total} correct')
        for r in results:
            fname, predicted, conf, entropy, margin = r[0], r[1], r[2], r[3], r[4]
            mark = 'OK' if r[-1] else 'FAIL'
            if conf is not None:
                print(f'  [{mark}] {fname}: predicted={predicted} conf={conf:.3f} entropy={entropy:.3f} margin={margin:.3f}')
            else:
                print(f'  [ERR] {fname}: {predicted}')

    print('\n=== nonFish (expect "No fish detected") ===')
    folder = os.path.join(base, 'nonFish')
    correct, total, results = run_folder(folder, 'No fish detected')
    grand_correct += correct
    grand_total += total
    print(f'No fish detected: {correct}/{total} correct')
    for r in results:
        fname, predicted, conf, entropy, margin = r[0], r[1], r[2], r[3], r[4]
        mark = 'OK' if r[-1] else 'FAIL'
        if conf is not None:
            print(f'  [{mark}] {fname}: predicted={predicted} conf={conf:.3f} entropy={entropy:.3f} margin={margin:.3f}')
        else:
            print(f'  [ERR] {fname}: {predicted}')

    print('\n=== unsupportedFish (expect "Unsupported species") ===')
    folder = os.path.join(base, 'unsupportedFish')
    correct, total, results = run_folder(folder, 'Unsupported species')
    grand_correct += correct
    grand_total += total
    print(f'Unsupported species: {correct}/{total} correct')
    for r in results:
        fname, predicted, conf, entropy, margin = r[0], r[1], r[2], r[3], r[4]
        mark = 'OK' if r[-1] else 'FAIL'
        if conf is not None:
            print(f'  [{mark}] {fname}: predicted={predicted} conf={conf:.3f} entropy={entropy:.3f} margin={margin:.3f}')
        else:
            print(f'  [ERR] {fname}: {predicted}')

    print(f'\n=== TOTAL: {grand_correct}/{grand_total} correct ({100*grand_correct/grand_total:.1f}%) ===')


if __name__ == '__main__':
    main()
