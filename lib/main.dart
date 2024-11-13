import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScheduleScreen(),
    );
  }
}

// Les modèles de données pour les options
class Professor {
  final int id;
  final String name;

  Professor({required this.id, required this.name});

  factory Professor.fromJson(Map<String, dynamic> json) {
    return Professor(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Classe {
  final int id;
  final String name;

  Classe({required this.id, required this.name});

  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Room {
  final int id;
  final String name;

  Room({required this.id, required this.name});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi"];
  final List<String> sessions = ["8:00 - 10:00", "10:00 - 12:00", "13:00 - 15:00", "15:00 - 17:00"];
  Map<String, String> scheduleInfo = {};

  // Listes pour stocker les options de l'API JSON
  List<Professor> professors = [];
  List<Classe> classes = [];
  List<Room> rooms = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Fonction pour récupérer les données de l'API JSON
  Future<void> fetchData() async {
    final profsResponse = await http.get(Uri.parse("http://10.0.2.2:3000/professors"));
    final classesResponse = await http.get(Uri.parse("http://10.0.2.2:3000/classes"));
    final roomsResponse = await http.get(Uri.parse("http://10.0.2.2:3000/rooms"));

    if (profsResponse.statusCode == 200 &&
        classesResponse.statusCode == 200 &&
        roomsResponse.statusCode == 200) {
      setState(() {
        professors = (json.decode(profsResponse.body) as List)
            .map((data) => Professor.fromJson(data))
            .toList();
        classes = (json.decode(classesResponse.body) as List)
            .map((data) => Classe.fromJson(data))
            .toList();
        rooms = (json.decode(roomsResponse.body) as List)
            .map((data) => Room.fromJson(data))
            .toList();
      });
    } else {
      throw Exception("Erreur lors de la récupération des données");
    }
  }

  // Fonction pour envoyer les détails au serveur
  Future<void> sendDetails(String day, String session, String? professor, String? className, String? roomName) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/details'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "day": day,
        "session": session,
        "professor": professor,
        "class": className,
        "room": roomName,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save details');
    }
  }

  // Fonction pour ouvrir la boîte de dialogue
  void openDialog(BuildContext context, String day, String session) {
    String? selectedProf;
    String? selectedClass;
    String? selectedRoom;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Détails de la séance"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Professeur"),
                items: professors
                    .map((prof) => DropdownMenuItem(
                          child: Text(prof.name),
                          value: prof.name,
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedProf = value;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Classe"),
                items: classes
                    .map((classe) => DropdownMenuItem(
                          child: Text(classe.name),
                          value: classe.name,
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedClass = value;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Salle"),
                items: rooms
                    .map((room) => DropdownMenuItem(
                          child: Text(room.name),
                          value: room.name,
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedRoom = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  scheduleInfo["$day-$session"] = "Prof: $selectedProf, Classe: $selectedClass, Salle: $selectedRoom";
                });
                // Envoyer les détails au serveur
                await sendDetails(day, session, selectedProf, selectedClass, selectedRoom);
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion du Temps Universitaire"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            border: TableBorder.all(color: Colors.black, width: 1),
            columnWidths: {
              0: FixedColumnWidth(100),
              for (int i = 1; i <= sessions.length; i++) i: FlexColumnWidth(),
            },
            children: [
              // Header row for sessions
              TableRow(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.blue[100],
                    child: Center(
                      child: Text(
                        "Jour/Heure",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  for (String session in sessions)
                    Container(
                      padding: EdgeInsets.all(12),
                      color: Colors.blue[100],
                      child: Center(
                        child: Text(
                          session,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              // Rows for each day
              for (int i = 0; i < days.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? Colors.grey[100] : Colors.grey[300],
                  ),
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      child: Center(child: Text(days[i])),
                    ),
                    for (String session in sessions)
                      GestureDetector(
                        onDoubleTap: () => openDialog(context, days[i], session),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              scheduleInfo["${days[i]}-$session"] ?? "Vide",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
