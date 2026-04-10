import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moniteur Capteurs',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Bleu-Noir profond
      ),
      home: const SensorDashboard(),
    );
  }
}

class SensorDashboard extends StatefulWidget {
  const SensorDashboard({super.key});

  @override
  State<SensorDashboard> createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard> {
  // Valeurs des 4 capteurs
  List<int> sensorValues = [0, 0, 0, 0];
  OverlayEntry? _overlayEntry;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // DÉMARRAGE DE LA SURVEILLANCE DU RASPBERRY
    // Vérifie l'état toutes les 2 secondes
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchRaspberryData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Arrêter le timer si on ferme l'app
    super.dispose();
  }

  // --- FONCTION POUR LIRE LES DONNÉES DU RASPBERRY ---
  Future<void> fetchRaspberryData() async {
    final String url = "http://10.188.79.221:5000/etat-capteur";

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 1));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Si le Raspberry détecte du gaz (gaz: true)
        if (data['gaz'] == true) {
          incrementSensor(0); // On incrémente le Capteur 1 automatiquement
        }
      }
    } catch (e) {
      // Erreur de connexion (Raspberry éteint ou mauvaise IP)
      debugPrint("Erreur connexion Raspberry: $e");
    }
  }

  // --- FONCTION POUR LA NOTIFICATION EN HAUT ---
  void _showTopNotification(int index) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Capteur ${index + 1} : +1 ajouté !",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  // --- FONCTION POUR INCRÉMENTER ---
  void incrementSensor(int index) {
    setState(() {
      sensorValues[index]++;
    });
    _showTopNotification(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TABLEAU DE BORD", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 1. Liste des Capteurs (Cartes Modernes)
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sensors, color: Colors.blueAccent, size: 30),
                            const SizedBox(width: 15),
                            Text("Capteur ${index + 1}", style: const TextStyle(fontSize: 18, color: Colors.white70)),
                          ],
                        ),
                        Text(
                          "${sensorValues[index]}",
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 2. Boutons d'action manuelle
            Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => incrementSensor(index),
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("BTN ${index + 1}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}