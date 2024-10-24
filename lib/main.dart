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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blue[50],
      ),
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
  List<Fish> fishList = []; // List of fish in the aquarium, sets up animation too 
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  late Database database;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat();
    _controller.addListener(_updateFishPositions);
    _initializeDatabase().then((_) {
      _loadSettings();
    });
  }

  Future<void> _initializeDatabase() async { // Initialize the database
    final dbPath = p.join(await getDatabasesPath(), 'aquarium_settings.db');
    database = await openDatabase(
      dbPath,
      onCreate: (db, version) {
        return db.execute( // Create a table to store fish settings
          "CREATE TABLE fish(id INTEGER PRIMARY KEY AUTOINCREMENT, color INTEGER, speed REAL)",
        );
      },
      version: 1, 
    );
    print('Database initialized');
  }

  Future<void> _loadSettings() async { // Load the fish settings from the database  
    final List<Map<String, dynamic>> maps = await database.query('fish');
    if (maps.isNotEmpty) {
      setState(() {
        fishList = maps.map((map) => Fish(color: Color(map['color']), speed: map['speed'])).toList();
      });
      // Print the loaded settings to the console for debugging
      print('Settings loaded: fishCount=${fishList.length}'); 
      for (var fish in fishList) { // Print the loaded settings to the console for debugging
        print('Fish color: ${fish.color}, speed: ${fish.speed}');
      }
    } else {
      print('No settings found');
    }
  }

  Future<void> _saveSettings() async {
    await database.delete('fish'); // Clear existing data
    for (var fish in fishList) {
      await database.insert(
        'fish',
        {
          'color': fish.color.value,
          'speed': fish.speed,
        },
      );
    }
    // Show a Snackbar to confirm that settings were saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );
    // Print the saved settings to the console for debugging
    print('Settings saved: fishCount=${fishList.length}');
    for (var fish in fishList) {
      print('Fish color: ${fish.color}, speed: ${fish.speed}');
    }
  }

  void _addFish() {
    if (fishList.length < 10) { // Limit the number of fish to 10
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  void _updateFishPositions() { // Update the position of each fish
    setState(() {
      for (var fish in fishList) {
        fish.updatePosition();
      }
    });
  }

  final List<Color> dropdownColors = [Colors.blue, Colors.red, Colors.green];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration( // Set the background image of the aquarium
              color: Colors.blue[200],
              border: Border.all(color: Colors.blue[800]!, width: 2),
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: AssetImage('assets/aquarium.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: fishList.map((fish) => fish.buildFish()).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addFish,
                child: Text('Add Fish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [ // Add a slider to adjust the speed of the fish and a dropdown to select the color
                Text('Adjust Fish Speed', style: TextStyle(color: Colors.blue[800])),
                Slider(
                  value: selectedSpeed,
                  min: 0.5,
                  max: 5.0,
                  onChanged: (value) {
                    setState(() {
                      selectedSpeed = value;
                    });
                  },
                  activeColor: Colors.blue[800],
                  inactiveColor: Colors.blue[100],
                ),
                Text('Select Fish Color', style: TextStyle(color: Colors.blue[800])),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: dropdownColors.map((Color color) {
                    return DropdownMenuItem<Color>(
                      value: color,
                      child: Text(
                        color == Colors.blue ? 'Blue' : color == Colors.red ? 'Red' : 'Green',
                        style: TextStyle(color: color),
                      ),
                    );
                  }).toList(), // Add the colors to the dropdown
                  onChanged: (value) {
                    setState(() {
                      selectedColor = value!;
                    });
                  },
                  dropdownColor: Colors.blue[50],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Fish { // Define the Fish class
  final Color color;
  final double speed;
  Offset position; // Position of the fish
  Offset direction;

  Fish({required this.color, required this.speed}) // Constructor
      : position = Offset(Random().nextDouble() * 280, Random().nextDouble() * 280),
        direction = Offset(Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1).normalize();

  void updatePosition() { // Update the position of the fish
    position += direction * speed;
    if (position.dx <= 0 || position.dx >= 280) {
      direction = Offset(-direction.dx, direction.dy);
    }
    if (position.dy <= 0 || position.dy >= 280) {
      direction = Offset(direction.dx, -direction.dy);
    }
  }

  Widget buildFish() { // Build the fish widget
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Image.asset('assets/fish.jpg', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Offset { // Define an extension method to normalize the direction vector
  Offset normalize() {
    final length = sqrt(dx * dx + dy * dy);
    return Offset(dx / length, dy / length);
  }
}