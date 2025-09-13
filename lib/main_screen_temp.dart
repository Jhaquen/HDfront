import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'counters_screen.dart';
import 'dart:math';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late String _currentResponse;
  late Chart chart;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentResponse = 'Loading...';
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/'));
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
    final screenSize = MediaQuery.of(context).size;
    chart = Chart([
      Triangle(position: Offset.zero, rotation: 0, color: Colors.blue),
      Triangle(position: Offset.zero, rotation: pi, color: Colors.red), // Flipped
      Square(position: Offset.zero, rotation: 0, color: Colors.green),
      Square(position: Offset.zero, rotation: pi / 2, color: Colors.yellow), // Rotated
      Square(position: Offset.zero, rotation: 0, color: Colors.purple),
      Square(position: Offset.zero, rotation: 0, color: Colors.orange),
    ]);

    return Scaffold(
      key: _scaffoldKey,
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
                  MaterialPageRoute(builder: (context) => const CountersScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            child: CustomPaint(
              painter: CanvasPainter(chart, screenSize),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Status: $_currentResponse',
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, size: 20),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Chart {
  List<ChartObject> objects;

  Chart(this.objects);

  void draw(Canvas canvas, Size screenSize) {
    double startY = screenSize.height * 0.2;
    double spacing = (screenSize.height * 0.6) / objects.length;
    for (int i = 0; i < objects.length; i++) {
      objects[i].position = Offset(screenSize.width / 2, startY + i * spacing);
      objects[i].draw(canvas);
    }
  }
}

abstract class ChartObject {
  Offset position;
  double size;
  double rotation;
  Color color;

  ChartObject({
    required this.position,
    this.size = 50,
    this.rotation = 0,
    this.color = Colors.blue,
  });

  void draw(Canvas canvas);
}

class Triangle extends ChartObject {
  Triangle({
    required super.position,
    super.size,
    super.rotation,
    super.color,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(-size * 0.866, size / 2)
      ..lineTo(size * 0.866, size / 2)
      ..close();
    canvas.drawPath(path, paint);

    canvas.restore();
  }
}

class Square extends ChartObject {
  Square({
    required super.position,
    super.size,
    super.rotation,
    super.color,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
    canvas.drawRect(rect, paint);

    canvas.restore();
  }
}

class CanvasPainter extends CustomPainter {
  final Chart chart;
  final Size screenSize;

  CanvasPainter(this.chart, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    chart.draw(canvas, screenSize);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
