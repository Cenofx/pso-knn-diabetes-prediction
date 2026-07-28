# 🏥 Prediksi Diabetes dengan Algoritma PSO-KNN

Aplikasi **Sistem Pakar Medis (Medical Expert System)** berbasis *Machine Learning* yang dirancang untuk memprediksi probabilitas seseorang mengidap penyakit diabetes berdasarkan 8 metrik data klinis. 

Proyek ini mengadopsi arsitektur **Client-Server (Microservices)** dengan **Flutter** sebagai antarmuka pengguna (Frontend) dan **Python Flask** sebagai pusat kecerdasan buatan (Backend).

## ✨ Fitur Utama
* **Algoritma Cerdas (PSO-KNN)**: Menggunakan algoritma *K-Nearest Neighbors (KNN)* yang dioptimasi secara otomatis menggunakan *Particle Swarm Optimization (PSO)* untuk mencari nilai tetangga (K) paling akurat.
* **UI/UX Modern**: Animasi *Flip Card 3D* interaktif, fitur *Dark Mode / Light Mode*, serta *Hint Text* referensi nilai medis normal.
* **Lintas Platform**: Antarmuka responsif yang dapat berjalan dengan mulus di Windows Desktop, Web, maupun Android.
* **Real-time Processing**: Prediksi diproses secara instan melalui API penghubung antara frontend dan backend.

## 🛠️ Teknologi yang Digunakan
**Backend (Kecerdasan Buatan & API):**
* Python 3.x
* Flask & Flask-CORS (REST API)
* Scikit-Learn (KNN & Machine Learning Tools)
* Pandas & NumPy (Pemrosesan Data)

**Frontend (Antarmuka Pengguna):**
* Flutter SDK (Dart)
* HTTP Package (Konsumsi API)

## 📊 Dataset
Sistem ini dilatih menggunakan **PIMA Indians Diabetes Dataset**. Terdapat 8 parameter klinis yang menjadi fitur prediksi:
1. `Pregnancies` (Jumlah Kehamilan - *Otomatis disembunyikan jika pasien Laki-laki*)
2. `Glucose` (Kadar Glukosa)
3. `BloodPressure` (Tekanan Darah Diastolik)
4. `SkinThickness` (Ketebalan Lipatan Kulit)
5. `Insulin` (Kadar Insulin)
6. `BMI` (Indeks Massa Tubuh)
7. `DiabetesPedigreeFunction` (Riwayat Genetik Diabetes)
8. `Age` (Usia)

---

## 🚀 Cara Menjalankan Proyek Secara Lokal

Karena proyek ini terbagi menjadi dua bagian, Anda **wajib** menyalakan Backend terlebih dahulu sebelum Frontend.

### 1. Menjalankan Backend (Python/Flask)
Buka terminal/command prompt, lalu arahkan ke folder `backend`.
```bash
# 1. Buat Virtual Environment (jika belum ada)
python -m venv venv

# 2. Aktifkan Virtual Environment
# Untuk Windows (Command Prompt):
venv\Scripts\activate
# Untuk Windows (PowerShell):
.\venv\Scripts\Activate.ps1
# Untuk Mac/Linux:
source venv/bin/activate

# 3. Install Dependensi
pip install flask flask-cors pandas numpy scikit-learn

# 4. Jalankan Server AI
python app.py
(Server akan berjalan di http://127.0.0.1:5000)

2. Menjalankan Frontend (Flutter)
Buka terminal baru, arahkan ke folder diabetes_app (folder Flutter).

Bash
# 1. Unduh semua package Flutter yang dibutuhkan
flutter pub get

# 2. Jalankan aplikasi (Pilih platform seperti Chrome atau Windows)
flutter run
📦 Panduan Build (Compile Aplikasi)
Untuk membuat file aplikasi matang yang bisa dijalankan tanpa membuka kode (Backend tetap harus menyala), jalankan perintah ini di dalam folder diabetes_app:

Aplikasi Windows (.exe):

Bash
flutter build windows
(File EXE akan berada di: build\windows\x64\runner\Release\)

Aplikasi Android (.apk):

Bash
flutter build apk
(File APK akan berada di: build\app\outputs\flutter-apk\app-release.apk)

Aplikasi Web:

Bash
flutter build web
(File Web siap hosting akan berada di: build\web\)

🧠 Penjelasan Singkat Algoritma (Untuk Edukasi/Presentasi)
Kelemahan utama dari algoritma klasifikasi standar seperti KNN adalah pengembang harus menebak secara manual nilai K (jumlah tetangga terdekat). Dalam proyek ini, kelemahan tersebut diselesaikan dengan Algoritma Swarm Intelligence (PSO).

Sistem akan menyebarkan 'partikel' yang bergerak secara matematis di dalam ruang pencarian untuk mengevaluasi berbagai kemungkinan nilai K. Partikel-partikel ini akan saling bertukar informasi mengenai tingkat error terendah hingga akhirnya mengerucut (konvergen) untuk menemukan nilai K (Global Best) yang menghasilkan akurasi prediksi tertinggi pada dataset uji. Model KNN akhir kemudian dibangun menggunakan nilai K optimal tersebut.