import 'package:flutter/material.dart';
import 'counter_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'backend_response_screen.dart';

class CountersScreen extends StatefulWidget {
  const CountersScreen({super.key});

  @override
  State<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends State<CountersScreen> {
  int _counterCarla = 0;
  int _counterSascha = 0;
  final String _backendResponse = 'Fetching data...';
  WebSocketChannel? _channel;

  Future<void> _incrementCounterCarla() async {
    setState(() {
      _counterCarla++;
    });
    await _sendCountersToBackend();
  }

  Future<void> _incrementCounterSascha() async {
    setState(() {
      _counterSascha++;
    });
    await _sendCountersToBackend();
  }

  Future<void> _sendCountersToBackend() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.165:8080/updateCrazyObj'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Carla': _counterCarla, 'Sascha': _counterSascha}),
      );
      if (response.statusCode != 200) {
        print('Failed to update backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending to backend: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    fetchData();
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.0.165:8080/crazy_obj_updated'));
    _channel!.stream.listen(
      (message) {
        if (message == '/crazy_obj_updated') {  // Add the slash
          fetchData();
        }
      },
      onError: (error) => print('WebSocket error: $error'),
      onDone: () => print('WebSocket closed'),
    );
  }

  Future<void> fetchData() async {
    int newCarla = _counterCarla;
    int newSascha = _counterSascha;

    // Fetch counters from /CrazyObj
    try {
      final counterResponse = await http.get(Uri.parse('http://192.168.0.165:8080/CrazyObj'));
      if (counterResponse.statusCode == 200) {
        final jsonResponse = json.decode(counterResponse.body) as Map<String, dynamic>;
        newCarla = jsonResponse['Carla'] ?? newCarla;
        newSascha = jsonResponse['Sascha'] ?? newSascha;
      }
    } catch (e) {
      // Keep current values
    }

    setState(() {
      _counterCarla = newCarla;
      _counterSascha = newSascha;
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counters'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Counters'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              title: const Text('Backend Response'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackendResponseScreen(backendResponse: _backendResponse),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CounterWidget(
              label: 'Carla is this crazy',
              value: _counterCarla,
              onIncrement: _incrementCounterCarla,
            ),
            CounterWidget(
              label: 'Sascha is this crazy',
              value: _counterSascha,
              onIncrement: _incrementCounterSascha,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => fetchData(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
