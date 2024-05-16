import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SearchSymptomsScreen extends StatefulWidget {
  @override
  _SearchSymptomsScreenState createState() => _SearchSymptomsScreenState();
}

class _SearchSymptomsScreenState extends State<SearchSymptomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<int> _selectedSymptoms = [];

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'symptoms.db');
    return await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE user_symptoms (id INTEGER PRIMARY KEY, user_id INTEGER, symptom_id INTEGER)');
        });
  }

  void _searchSymptoms() async {
    final db = await _openDatabase();
    final searchText = _searchController.text.trim();
    final results = await db.query('symptoms',
        where: 'name LIKE ?', whereArgs: ['%$searchText%']);
    setState(() {
      _searchResults = results;
    });
  }

  void _selectSymptom(int id) {
    setState(() {
      _selectedSymptoms.add(id);
    });
    final db = _openDatabase();
    db.then((db) async {
      await db.insert('user_symptoms', {'user_id': 1, 'symptom_id': id});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Symptoms'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search symptoms',
            ),
            onSubmitted: (_) => _searchSymptoms(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (BuildContext context, int index) {
                final result = _searchResults[index];
                return ListTile(
                  title: Text(result['name']),
                  trailing: _selectedSymptoms.contains(result['id'])
                      ? Icon(Icons.check)
                      : null,
                  onTap: () => _selectSymptom(result['id']),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSymptoms.map((id) {
                return Chip(
                  label: Text(
                    _searchResults.firstWhere((result) => result['id'] == id)['name'],
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedSymptoms.remove(id);
                    });
                    final db = _openDatabase();
                    db.then((db) async {
                      await db.delete(
                          'user_symptoms', where: 'symptom_id = ?', whereArgs: [id]);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
