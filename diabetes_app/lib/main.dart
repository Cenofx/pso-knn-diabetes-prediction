import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prediksi Diabetes PSO-KNN',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
          ),
        ),
      ),
      home: PredictionScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: (bool value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const PredictionScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen>
    with SingleTickerProviderStateMixin {
  final controllers = List.generate(8, (_) => TextEditingController());

  final labels = [
    'Pregnancies (Kehamilan)',
    'Glucose (Glukosa)',
    'BloodPressure (Tekanan Darah)',
    'SkinThickness (Ketebalan Kulit)',
    'Insulin',
    'BMI',
    'DiabetesPedigreeFunction (Riwayat Genetik)',
    'Age (Umur)',
  ];

  final hints = [
    'Contoh: 1 (Berapa kali kehamilan)',
    'Contoh: 95 (Kadar gula darah normal 70-100)',
    'Contoh: 70 (Tekanan diastolik normal 60-80)',
    'Contoh: 20 (Ketebalan lipatan kulit dalam mm)',
    'Contoh: 45 (Kadar insulin serum 2-Jam)',
    'Contoh: 22.5 (Indeks Massa Tubuh ideal 18.5-24.9)',
    'Contoh: 0.25 (Probabilitas keturunan diabetes 0.1-2.0)',
    'Contoh: 24 (Usia pasien dalam tahun)',
  ];

  String resultMessage = "[SYSTEM] Menunggu input pengguna...";
  bool isLoading = false;
  Color resultColor = Colors.grey;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  String _selectedGender = "";

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _triggerFlip(String gender) {
    setState(() {
      _selectedGender = gender;
      if (gender == "Laki-laki") {
        controllers[0].text = "0";
      } else {
        if (controllers[0].text == "0") controllers[0].text = "";
      }
    });
    _flipController.forward();
  }

  void _triggerFlipBack() {
    _flipController.reverse();
    setState(() {
      resultMessage = "[SYSTEM] Menunggu input pengguna...";
      resultColor = Colors.grey;
    });
  }

  Future<void> predictDiabetes() async {
    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isEmpty &&
          !(_selectedGender == "Laki-laki" && i == 0)) {
        setState(() {
          resultMessage =
              "[WARNING] Gagal memproses! Lengkapi semua data medis.";
          resultColor = Colors.orangeAccent;
        });
        return;
      }
    }

    setState(() {
      isLoading = true;
      resultMessage =
          "[SYSTEM] Mengirim matriks fitur ke backend Python...\n"
          "[SYSTEM] Menghitung perbandingan KNN Standar vs Optimasi PSO...";
      resultColor = const Color(0xFF3B82F6);
    });

    final url = Uri.parse('http://127.0.0.1:5000/predict');

    Map<String, dynamic> requestData = {
      'Pregnancies': controllers[0].text,
      'Glucose': controllers[1].text,
      'BloodPressure': controllers[2].text,
      'SkinThickness': controllers[3].text,
      'Insulin': controllers[4].text,
      'BMI': controllers[5].text,
      'DiabetesPedigreeFunction': controllers[6].text,
      'Age': controllers[7].text,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final before = data['before'];
        final after = data['after'];

        setState(() {
          if (after['prediction'] == "Positif Diabetes") {
            resultColor = Colors.redAccent;
          } else {
            resultColor = const Color(0xFF10B981);
          }

          List<dynamic> nBefore = before['neighbors'] ?? [];
          List<dynamic> nAfter = after['neighbors'] ?? [];

          resultMessage =
              "==========================================================\n"
              "         RINCIAN PERHITUNGAN: SEBELUM dan SESUDAH PSO       \n"
              "==========================================================\n"
              "[1] SEBELUM OPTIMASI (KNN STANDAR K = ${before['k_used']})\n"
              "  • Hasil Prediksi    : ${before['prediction']}\n"
              "  • Tingkat Keyakinan : ${before['confidence']}\n"
              "  • Voting Tetangga   : ${before['pos_votes']} Positif | ${before['neg_votes']} Negatif\n"
              "  • Jarak Euclidean Top Tetangga:\n"
              "${nBefore.join("\n")}\n"
              "  • Performa Model    : Akurasi=${before['accuracy']} | Precision=${before['precision']} | Recall=${before['recall']}\n"
              "----------------------------------------------------------\n"
              "[2] SESUDAH OPTIMASI (PSO-KNN K OPTIMAL = ${after['k_used']})\n"
              "  • Hasil Prediksi    : ${after['prediction']}\n"
              "  • Tingkat Keyakinan : ${after['confidence']}\n"
              "  • Voting Tetangga   : ${after['pos_votes']} Positif | ${after['neg_votes']} Negatif\n"
              "  • Jarak Euclidean Top Tetangga:\n"
              "${nAfter.join("\n")}\n"
              "  • Performa Model    : Akurasi=${after['accuracy']} | Precision=${after['precision']} | Recall=${after['recall']}\n"
              "----------------------------------------------------------\n"
              "[KESIMPULAN PENINGKATAN PERFORMA (DOSEN REVISION)]\n"
              "-> Peningkatan Akurasi: ${before['accuracy']} ===> ${after['accuracy']}\n"
              "==========================================================";
        });
      }
    } catch (e) {
      setState(() {
        resultMessage =
            "[ERROR] Koneksi terputus. Pastikan server Flask backend menyala!";
        resultColor = Colors.redAccent;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDashboardCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildGenderFrontCard() {
    return Column(
      key: const ValueKey('front'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Pilih Jenis Kelamin Anda:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _genderButton(Icons.male, "Laki-laki", Colors.blueAccent),
            _genderButton(Icons.female, "Perempuan", Colors.pinkAccent),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _genderButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => _triggerFlip(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.grey[100],
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormBackCard() {
    return Column(
      key: const ValueKey('back'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Data Pasien: $_selectedGender",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
            TextButton.icon(
              onPressed: isLoading ? null : _triggerFlipBack,
              icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
              label: const Text("Ganti", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        const Divider(color: Color(0xFF334155)),
        const SizedBox(height: 10),
        ...List.generate(8, (index) {
          if (_selectedGender == "Laki-laki" && index == 0) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TextField(
              controller: controllers[index],
              decoration: InputDecoration(
                labelText: labels[index],
                hintText: hints[index],
                hintStyle: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: const Icon(
                  Icons.analytics_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : predictDiabetes,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Data & Mulai Prediksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diabetes Care PSO-KNN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Icon(
                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 20,
              ),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onThemeChanged,
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(
                  0xFF10B981,
                ).withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildDashboardCard(
                  title: '1. Petunjuk Penggunaan',
                  child: const Text(
                    "Aplikasi medis ini menggunakan kecerdasan buatan K-Nearest Neighbors (KNN) yang dioptimasi dengan Particle Swarm Optimization (PSO).\n\n"
                    "Cara Pakai:\n"
                    "• Pilih jenis kelamin Anda (Form akan beradaptasi secara otomatis).\n"
                    "• Masukkan data metrik medis menggunakan angka.\n"
                    "• Klik tombol Prediksi, sistem akan menganalisis data secara instan.",
                    style: TextStyle(height: 1.5, fontSize: 15),
                  ),
                ),

                _buildDashboardCard(
                  title: '2. Masukkan Data Medis Pasien',
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * math.pi;
                        bool isFront = angle < (math.pi / 2);

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(isFront ? angle : angle - math.pi),
                          alignment: Alignment.center,
                          child: isFront
                              ? _buildGenderFrontCard()
                              : _buildFormBackCard(),
                        );
                      },
                    ),
                  ),
                ),

                _buildDashboardCard(
                  title: '3. Konsol Analisis & Hasil',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(0xFF0B1120)
                          : Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      resultMessage,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
