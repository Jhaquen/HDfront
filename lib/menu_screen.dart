import 'package:flutter/material.dart';
import 'counters_screen.dart';
import 'backend_response_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HDapp Menu'),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CountersScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Backend Response'),
              onTap: () {
                // For now, navigate to a placeholder; in a real app, you'd pass data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackendResponseScreen(backendResponse: 'Sample HTML'),
                  ),
                );
              },
            ),/*
            ListTile(
              title: const Text('Chat'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              }
            // )*/
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CountersScreen(),
                  ),
                );
              },
              child: const Text('View Counters'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Placeholder; in a real app, fetch or pass actual data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackendResponseScreen(backendResponse: 'Sample HTML'),
                  ),
                );
              },
              child: const Text('View Backend Response'),
            ),
          ],
        ),
      ),
    );
  }
}
