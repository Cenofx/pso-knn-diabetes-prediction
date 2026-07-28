from flask import Flask, request, jsonify # type: ignore
from flask_cors import CORS # type: ignore
import pandas as pd
import numpy as np
import random
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

app = Flask(__name__)
CORS(app)

print("Loading dataset and training baseline models...")
df = pd.read_csv('diabetes.csv')
X = df.drop('Outcome', axis=1).values
y = df['Outcome'].values

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 1. MODEL SEBELUM OPTIMASI (KNN STANDAR K = 5)
default_k = 5
baseline_knn = KNeighborsClassifier(n_neighbors=default_k)
baseline_knn.fit(X_train, y_train)

y_pred_init = baseline_knn.predict(X_test)
init_acc = accuracy_score(y_test, y_pred_init)
init_prec = precision_score(y_test, y_pred_init, zero_division=0)
init_rec = recall_score(y_test, y_pred_init, zero_division=0)
init_f1 = f1_score(y_test, y_pred_init, zero_division=0)

# 2. ALGORITMA PSO UNTUK MENCARI K OPTIMAL
def pso_optimize_knn(X_train, y_train, X_test, y_test, num_particles=10, iterations=15):
    particles = [{'pos': random.uniform(1, 30), 'vel': random.uniform(-2, 2), 'best_pos': None, 'best_err': float('inf')} for _ in range(num_particles)]
    global_best_pos = None
    global_best_err = float('inf')

    for _ in range(iterations):
        for p in particles:
            k = int(round(p['pos']))
            k = max(1, min(30, k))

            knn = KNeighborsClassifier(n_neighbors=k)
            knn.fit(X_train, y_train)
            err = 1.0 - accuracy_score(y_test, knn.predict(X_test))

            if err < p['best_err']:
                p['best_err'] = err
                p['best_pos'] = k

            if err < global_best_err:
                global_best_err = err
                global_best_pos = k

            r1, r2 = random.random(), random.random()
            p['vel'] = 0.5 * p['vel'] + 0.8 * r1 * (p['best_pos'] - p['pos']) + 0.9 * r2 * (global_best_pos - p['pos'])
            p['pos'] += p['vel']

    return int(global_best_pos), (1 - global_best_err)

best_k, best_acc = pso_optimize_knn(X_train, y_train, X_test, y_test)
final_knn = KNeighborsClassifier(n_neighbors=best_k)
final_knn.fit(X_train, y_train)

y_pred_opt = final_knn.predict(X_test)
opt_prec = precision_score(y_test, y_pred_opt, zero_division=0)
opt_rec = recall_score(y_test, y_pred_opt, zero_division=0)
opt_f1 = f1_score(y_test, y_pred_opt, zero_division=0)

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.json
        features = [
            float(data['Pregnancies']), float(data['Glucose']),
            float(data['BloodPressure']), float(data['SkinThickness']),
            float(data['Insulin']), float(data['BMI']),
            float(data['DiabetesPedigreeFunction']), float(data['Age'])
        ]
        
        input_arr = np.array(features).reshape(1, -1)
        
        # Hitung Matriks Jarak Euclidean: d = sqrt(sum((x - y)^2))
        distances = np.linalg.norm(X_train - input_arr, axis=1)

        # A. PERHITUNGAN SEBELUM OPTIMASI (KNN STANDAR K = 5)
        idx_before = np.argsort(distances)[:default_k]
        labels_before = y_train[idx_before]
        pos_before = int(np.sum(labels_before == 1))
        neg_before = int(np.sum(labels_before == 0))
        pred_before_val = baseline_knn.predict(input_arr)[0]
        pred_before = "Positif Diabetes" if pred_before_val == 1 else "Negatif Diabetes"
        conf_before = (max(pos_before, neg_before) / default_k) * 100

        neighbors_before = []
        for i in range(default_k):
            lbl = "Positif" if labels_before[i] == 1 else "Negatif"
            neighbors_before.append(f"  - Rank {i+1}: Jarak = {distances[idx_before[i]]:.2f} -> [{lbl}]")

        # B. PERHITUNGAN SESUDAH OPTIMASI (PSO-KNN K = best_k)
        idx_after = np.argsort(distances)[:best_k]
        labels_after = y_train[idx_after]
        pos_after = int(np.sum(labels_after == 1))
        neg_after = int(np.sum(labels_after == 0))
        pred_after_val = final_knn.predict(input_arr)[0]
        pred_after = "Positif Diabetes" if pred_after_val == 1 else "Negatif Diabetes"
        conf_after = (max(pos_after, neg_after) / best_k) * 100

        neighbors_after = []
        for i in range(min(5, best_k)): # Tampilkan sampel top 5
            lbl = "Positif" if labels_after[i] == 1 else "Negatif"
            neighbors_after.append(f"  - Rank {i+1}: Jarak = {distances[idx_after[i]]:.2f} -> [{lbl}]")

        return jsonify({
            'status': 'success',
            'before': {
                'k_used': default_k,
                'prediction': pred_before,
                'confidence': f"{conf_before:.2f}%",
                'pos_votes': pos_before,
                'neg_votes': neg_before,
                'neighbors': neighbors_before,
                'accuracy': f"{init_acc*100:.2f}%",
                'precision': f"{init_prec*100:.2f}%",
                'recall': f"{init_rec*100:.2f}%",
                'f1_score': f"{init_f1*100:.2f}%"
            },
            'after': {
                'k_used': best_k,
                'prediction': pred_after,
                'confidence': f"{conf_after:.2f}%",
                'pos_votes': pos_after,
                'neg_votes': neg_after,
                'neighbors': neighbors_after,
                'accuracy': f"{best_acc*100:.2f}%",
                'precision': f"{opt_prec*100:.2f}%",
                'recall': f"{opt_rec*100:.2f}%",
                'f1_score': f"{opt_f1*100:.2f}%"
            }
        })
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)