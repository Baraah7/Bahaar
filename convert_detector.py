import tensorflow as tf, numpy as np, os
from PIL import Image

det = tf.keras.models.load_model('assets/models/fish_detector(4).keras')
print('DET input:', det.input_shape, '| output:', det.output_shape)

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(det)
tflite_model = converter.convert()
with open('assets/models/fish_detector.tflite', 'wb') as f:
    f.write(tflite_model)
print(f'Saved fish_detector.tflite ({len(tflite_model)/1024/1024:.2f} MB)')

# Test detector on sample images with raw pixels
interp = tf.lite.Interpreter(model_path='assets/models/fish_detector.tflite')
interp.allocate_tensors()
i = interp.get_input_details()
o = interp.get_output_details()
det_size = i[0]['shape'][1]

print('\nDetector scores (raw pixels, sigmoid output = fish probability):')
for fname in sorted(os.listdir('assets/images')):
    path = f'assets/images/{fname}'
    try:
        img = Image.open(path).convert('RGB').resize((det_size, det_size))
        arr = np.expand_dims(np.array(img, dtype=np.float32), 0)
        interp.set_tensor(i[0]['index'], arr)
        interp.invoke()
        score = float(interp.get_tensor(o[0]['index'])[0][0])
        print(f'  {fname}: {round(score*100,1)}%')
    except:
        pass
