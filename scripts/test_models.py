import tensorflow as tf, numpy as np, os
from PIL import Image

clf = tf.keras.models.load_model('assets/models/fish_classifier_5class(1).keras')
det = tf.keras.models.load_model('assets/models/fish_detector(4).keras')

print('CLF input:', clf.input_shape, '| output:', clf.output_shape)
print('DET input:', det.input_shape, '| output:', det.output_shape)
print('DET last activation:', det.layers[-1].get_config().get('activation'))
print()

labels = ['Gilt Head Bream','Horse Mackerel','Red Mullet','Sea Bass','Shrimp']

clf_size = clf.input_shape[1]
det_size = det.input_shape[1]

for norm in ['raw', 'div255', 'mobilenet']:
    print(f'--- norm={norm} ---')
    for fname in sorted(os.listdir('assets/images')):
        path = f'assets/images/{fname}'
        try:
            def prep(size):
                img = Image.open(path).convert('RGB').resize((size, size))
                arr = np.array(img, dtype=np.float32)
                if norm == 'div255': arr = arr / 255.0
                elif norm == 'mobilenet': arr = (arr / 127.5) - 1.0
                return np.expand_dims(arr, 0)

            clf_out = clf.predict(prep(clf_size), verbose=0)[0]
            det_out = det.predict(prep(det_size), verbose=0)[0]
            pred = labels[np.argmax(clf_out)]
            conf = round(float(np.max(clf_out))*100, 1)
            det_vals = [round(float(x)*100,1) for x in det_out]
            print(f'  {fname}: clf={pred}({conf}%) det={det_vals}')
        except Exception as e:
            pass
    print()
