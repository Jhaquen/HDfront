import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

class BackendResponseScreen extends StatefulWidget {
  final String backendResponse;

  const BackendResponseScreen({super.key, required this.backendResponse});

  @override
  State<BackendResponseScreen> createState() => _BackendResponseScreenState();
}

class _BackendResponseScreenState extends State<BackendResponseScreen> {
  late String _currentResponse;

  @override
  void initState() {
    super.initState();
    _currentResponse = widget.backendResponse;
    if (_currentResponse == 'Sample HTML' || _currentResponse.isEmpty) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.165:8080/'));
      if (response.statusCode == 200) {
        setState(() {
          _currentResponse = response.body;
        });
      } else {
        setState(() {
          _currentResponse = 'Error fetching HTML: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _currentResponse = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Response'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Html(data: _currentResponse),
        ),
      ),
    );
  }
}
