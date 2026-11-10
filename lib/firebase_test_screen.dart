import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final TextEditingController _controller = TextEditingController();
  String _status = 'Not tested yet';

  Future<void> _saveTestTrip() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        _status = 'Please enter a trip name.';
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'title': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _controller.clear();

      setState(() {
        _status = 'Saved to Firestore!';
      });
    } catch (error) {
      setState(() {
        _status = 'Error: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Trip name',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveTestTrip,
              child: const Text('Save test trip'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}