import 'package:flutter/material.dart';
import 'counter_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';

class CountersScreen extends StatefulWidget {
  const CountersScreen({super.key});

  @override
  State<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends State<CountersScreen> {
  int _counterCarla = 0;
  int _counterSascha = 0;

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
      print('Sending counters to backend: Carla: $_counterCarla, Sascha: $_counterSascha');
      final response = await http.post(
        Uri.parse('$backendUrl/updateCrazyObj'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Carla': _counterCarla, 'Sascha': _counterSascha}),
      );
      if (response.statusCode == 200) {
        print('Backend update successful: ${response.body}');
      } else {
        print('Failed to update backend: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      print('Error sending to backend: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    checkForUpdates();
  }

  Future<void> fetchData() async {
    int newCarla = _counterCarla;
    int newSascha = _counterSascha;

    // Fetch counters from /CrazyObj
    try {
      final counterResponse = await http.get(Uri.parse('$backendUrl/CrazyObj'));
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

  Future<void> checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/Jhaquen/HDfront/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTag = data['tag_name'];
        if (latestTag != 'v$currentVersion') {
          showUpdateDialog(latestTag);
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void showUpdateDialog(String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text('A new version $tag is available. Download now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          TextButton(onPressed: () {
            launchUrl(Uri.parse('https://github.com/Jhaquen/HDfront/releases/download/$tag/app-release.apk'));
            Navigator.pop(context);
          }, child: const Text('Download')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
