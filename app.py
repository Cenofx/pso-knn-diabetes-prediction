from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import numpy as np
import random
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score

app = Flask(__name__)
CORS(app)

# 1. Load Dataset
print("Loading dataset and training model...")
df = pd.read_csv('diabetes.csv')
X = df.drop('Outcome', axis=1).values
y = df['Outcome'].values

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 2. Fungsi Particle Swarm Optimization (PSO) untuk mencari nilai K terbaik
def pso_optimize_knn(X_train, y_train, X_test, y_test, num_particles=10, iterations=15):
    # Inisialisasi partikel (posisi mewakili nilai 'k' dari 1 hingga 30)
    particles = [{'pos': random.uniform(1, 30), 'vel': random.uniform(-2, 2), 'best_pos': None, 'best_err': float('inf')} for _ in range(num_particles)]
    global_best_pos = None
    global_best_err = float('inf')

    for _ in range(iterations):
        for p in particles:
            k = int(round(p['pos']))
            k = max(1, min(30, k)) # Batasi K antara 1 sampai 30

            knn = KNeighborsClassifier(n_neighbors=k)
            knn.fit(X_train, y_train)
            err = 1.0 - accuracy_score(y_test, knn.predict(X_test))

            if err < p['best_err']:
                p['best_err'] = err
                p['best_pos'] = k

            if err < global_best_err:
                global_best_err = err
                global_best_pos = k

            # Update Velocity & Position
            r1, r2 = random.random(), random.random()
            p['vel'] = 0.5 * p['vel'] + 0.8 * r1 * (p['best_pos'] - p['pos']) + 0.9 * r2 * (global_best_pos - p['pos'])
            p['pos'] += p['vel']

    return int(global_best_pos), (1 - global_best_err)

# Jalankan optimasi PSO
best_k, best_acc = pso_optimize_knn(X_train, y_train, X_test, y_test)
print(f"Hasil PSO: K terbaik adalah {best_k} dengan Akurasi {best_acc*100:.2f}%")

# Latih model final dengan K hasil optimasi PSO
final_knn = KNeighborsClassifier(n_neighbors=best_k)
final_knn.fit(X_train, y_train)

# 3. Buat API Endpoint
@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.json
        # Ambil input 8 fitur dari Flutter
        features = [
            float(data['Pregnancies']), float(data['Glucose']),
            float(data['BloodPressure']), float(data['SkinThickness']),
            float(data['Insulin']), float(data['BMI']),
            float(data['DiabetesPedigreeFunction']), float(data['Age'])
        ]
        
        # Lakukan prediksi
        prediction = final_knn.predict([features])
        result = "Positif Diabetes" if prediction[0] == 1 else "Negatif Diabetes"
        
        return jsonify({'status': 'success', 'prediction': result, 'best_k_used': best_k})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    # Jalankan server di port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)