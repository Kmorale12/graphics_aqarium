import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:math';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  late Database database;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat();
    _controller.addListener(_updateFishPositions);
    _initializeDatabase();
    _loadSettings();
  }

  Future<void> _initializeDatabase() async {
    database = await openDatabase(
      p.join(await getDatabasesPath(), 'aquarium_settings.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color INTEGER)",
        );
      },
      version: 1,
    );
  }

  Future<void> _loadSettings() async {
    final List<Map<String, dynamic>> maps = await database.query('settings');
    if (maps.isNotEmpty) {
      setState(() {
        fishList = List.generate(maps[0]['fishCount'], (i) => Fish(color: Color(maps[0]['color']), speed: maps[0]['speed']));
        selectedSpeed = maps[0]['speed'];
        selectedColor = Color(maps[0]['color']);
      });
      // Print the loaded settings to the console for debugging
      print('Settings loaded: fishCount=${fishList.length}, speed=$selectedSpeed, color=${selectedColor.value}');
    }
  }

  Future<void> _saveSettings() async {
    await database.insert(
      'settings',
      {
        'id': 1,
        'fishCount': fishList.length,
        'speed': selectedSpeed,
        'color': selectedColor.value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Show a Snackbar to confirm that settings were saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );
    // Print the saved settings to the console for debugging
    print('Settings saved: fishCount=${fishList.length}, speed=$selectedSpeed, color=${selectedColor.value}');
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  void _updateFishPositions() {
    setState(() {
      for (var fish in fishList) {
        fish.updatePosition();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Virtual Aquarium')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            color: Colors.lightBlueAccent,
            child: Stack(
              children: fishList.map((fish) => fish.buildFish()).toList(),
            ),
          ),
          Row(
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              ElevatedButton(onPressed: _saveSettings, child: Text('Save Settings')),
            ],
          ),
          Slider(
            value: selectedSpeed,
            min: 0.5,
            max: 5.0,
            onChanged: (value) {
              setState(() {
                selectedSpeed = value;
              });
            },
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: [
              DropdownMenuItem(child: Text('Blue'), value: Colors.blue),
              DropdownMenuItem(child: Text('Red'), value: Colors.red),
              DropdownMenuItem(child: Text('Green'), value: Colors.green),
            ],
            onChanged: (value) {
              setState(() {
                selectedColor = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}

class Fish {
  final Color color;
  final double speed;
  Offset position;
  Offset direction;

  Fish({required this.color, required this.speed})
      : position = Offset(Random().nextDouble() * 280, Random().nextDouble() * 280),
        direction = Offset(Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1).normalize();

  void updatePosition() {
    position += direction * speed;
    if (position.dx <= 0 || position.dx >= 280) {
      direction = Offset(-direction.dx, direction.dy);
    }
    if (position.dy <= 0 || position.dy >= 280) {
      direction = Offset(direction.dx, -direction.dy);
    }
  }

  Widget buildFish() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

extension on Offset {
  Offset normalize() {
    final length = sqrt(dx * dx + dy * dy);
    return Offset(dx / length, dy / length);
  }
}