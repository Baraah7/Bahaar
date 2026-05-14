import tensorflow as tf, numpy as np, os
from PIL import Image

det = tf.keras.models.load_model('assets/models/fish_detector(4).keras')
clf = tf.keras.models.load_model('assets/models/fish_classifier_5class(1).keras')
det_size = det.input_shape[1]
clf_size = clf.input_shape[1]
labels = ['Gilt Head Bream','Horse Mackerel','Red Mullet','Sea Bass','Shrimp']

images = [f for f in os.listdir('assets/images') if not f.endswith('.dart')]

print('=== DETECTOR normalization test ===')
for norm_name, norm_fn in [
    ('raw',        lambda a: a),
    ('div255',     lambda a: a / 255.0),
    ('mobilenet',  lambda a: (a / 127.5) - 1.0),
    ('effnet',     lambda a: tf.keras.applications.efficientnet.preprocess_input(a.copy())),
]:
    print(f'\n-- {norm_name} --')
    for fname in sorted(images):
        img = Image.open(f'assets/images/{fname}').convert('RGB').resize((det_size, det_size))
        arr = np.array(img, dtype=np.float32)
        out = det.predict(np.expand_dims(norm_fn(arr), 0), verbose=0)[0][0]
        print(f'  {fname}: {round(float(out)*100,1)}%')

print('\n=== CLASSIFIER normalization test ===')
for norm_name, norm_fn in [
    ('raw',        lambda a: a),
    ('div255',     lambda a: a / 255.0),
    ('mobilenet',  lambda a: (a / 127.5) - 1.0),
    ('effnet',     lambda a: tf.keras.applications.efficientnet.preprocess_input(a.copy())),
]:
    print(f'\n-- {norm_name} --')
    for fname in sorted(images):
        img = Image.open(f'assets/images/{fname}').convert('RGB').resize((clf_size, clf_size))
        arr = np.array(img, dtype=np.float32)
        out = clf.predict(np.expand_dims(norm_fn(arr), 0), verbose=0)[0]
        pred = labels[np.argmax(out)]
        conf = round(float(np.max(out))*100, 1)
        print(f'  {fname}: {pred} ({conf}%)')
