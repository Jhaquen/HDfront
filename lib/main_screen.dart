import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import 'config.dart';
import 'counters_screen.dart';
import 'chart.dart';
import 'charts_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  IO.Socket? _socket;
  String currentUser = 'Carla';
  late String _currentResponse;
  late String ascendent;
  late Chart chart;
  List<int> activeGates = [];
  String responseText = '';
  String currentView = 'chart'; // 'chart', 'left', 'right'
  bool isLoggedIn = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TransformationController _transformationController;
  late AnimationController _animationController;
  late Animation<Matrix4> _matrixAnimation;

  Offset _rotateOffset(Offset offset, double rotation) {
    final cosR = cos(rotation);
    final sinR = sin(rotation);
    return Offset(
      offset.dx * cosR - offset.dy * sinR,
      offset.dx * sinR + offset.dy * cosR,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentResponse = 'Loading...';
    ascendent = "L...";
    _transformationController = TransformationController();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _matrixAnimation = Matrix4Tween().animate(_animationController);
    _matrixAnimation.addListener(() {
      _transformationController.value = _matrixAnimation.value;
    });
    _connectWebSocket();
    fetchData();
    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _socket?.disconnect();
    super.dispose();
  }

  void _connectWebSocket() {
    _socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
    });
    _socket!.onConnect((_) {
      print('Connected to WebSocket as $currentUser');
      // Set username on connect
      _socket!.emit('set_username', currentUser);
    });
    _socket!.onDisconnect((_) => print('Disconnected from WebSocket'));
    _socket!.on('crazy_obj_updated', (data) {
      print('Received update: $data');
      fetchData();
    });
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/'));
      final responseAsc = await http.get(Uri.parse('$backendUrl/getTransit'));
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is List) {
            setState(() {
              activeGates = List<int>.from(data);
              _currentResponse = 'Active gates: ${activeGates.join(', ')}';
              ascendent = 'res: ${json.decode(responseAsc.body)}';
            });
          } else {
            setState(() {
              _currentResponse = response.body;
            });
          }
        } catch (e) {
          setState(() {
            _currentResponse = response.body;
          });
        }
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

  Future<void> fetchChartQuickHTML() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/getChartQuickHTML'));
      setState(() {
        responseText = response.body;
      });
    } catch (e) {
      setState(() {
        responseText = 'Error fetching HTML: $e';
      });
    }
  }

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$backendUrl/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('Login successful: ${response.body}');
      return true;
    } else {
      print('Login failed: ${response.body}');
      return false;
    }
  }

  void _showLoginDialog() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                const username = 'Sascha';
                const password = 'pw1';

                try {
                  final success = await login(username, password);
                  if (success) {
                    setState(() {
                      isLoggedIn = true;
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login error: $e')),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    chart = Chart(activeGates: activeGates);

    if (!isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            ListTile(
              title: const Text('Charts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChartsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (TapUpDetails details) {
              final localPosition = details.localPosition;
              final screenSize = MediaQuery.of(context).size;
              // Inverse transform to get canvas position
              final Matrix4 inverse = Matrix4.inverted(_transformationController.value);
              final canvasPosition = MatrixUtils.transformPoint(inverse, localPosition);
              // First check gates
              for (final obj in chart.objects) {
                for (final gate in obj.gates) {
                  final gateAbsPos = obj.position + _rotateOffset(gate.relativePosition, obj.rotation);
                  if ((canvasPosition - gateAbsPos).distance < 4) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Gate ${gate.number}'),
                          content: Text('Sample text from backend for gate ${gate.number}'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
                }
              }
              // Then check objects for zoom
              for (final obj in chart.objects) {
                if ((canvasPosition - obj.position).distance < obj.size / 2) {
                  // Zoom to fit the object smoothly (faster zoom)
                  final scale = 0.8 * min(screenSize.width / obj.size, screenSize.height / obj.size);
                  final translation = screenSize.center(Offset.zero) - obj.position * scale;
                  final targetMatrix = Matrix4.identity()
                    ..translate(translation.dx, translation.dy)
                    ..scale(scale);
                  _matrixAnimation = Matrix4Tween(begin: _transformationController.value, end: targetMatrix).animate(_animationController);
                  _animationController.forward(from: 0.0);
                  break;
                }
              }
            },
            onDoubleTap: () {
              // Reset to chart view
              setState(() {
                currentView = 'chart';
                responseText = '';
              });
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.velocity.pixelsPerSecond.dx < -300) { // More generous threshold
                // Swipe left: show active gates on left
                setState(() {
                  currentView = 'left';
                  responseText = 'Active Gates: ${activeGates.join(', ')}';
                });
              } else if (details.velocity.pixelsPerSecond.dx > 300) { // More generous threshold
                // Swipe right: fetch HTML and show on right
                currentView = 'right';
                fetchChartQuickHTML();
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: false, // Disable panning
              child: CustomPaint(
                painter: CanvasPainter(chart, screenSize, responseText, currentView),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            top: 10 + topPadding,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.menu, size: 30),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Positioned(
            top: 10 + topPadding,
            left: 60,
            right: 10,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Center(
                child: Text(
                  'Status: $ascendent',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () => setState(() => chart.scale += 0.1),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => setState(() => chart.scale = (chart.scale - 0.1).clamp(0.1, 5.0)),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
