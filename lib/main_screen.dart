import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'config.dart';
import 'counters_screen.dart';
import 'chart_renderer.dart' as renderer;
import 'savedCharts_main_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:android_intent_plus/android_intent.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  IO.Socket? _socket;
  String currentUser = 'Carla';
  late String _currentResponse;
  late String transit;
  late renderer.Chart chart;
  List<int> activeGates = [];
  String responseText = '';
  String currentView = 'chart'; // 'chart', 'left', 'right'
  bool isLoggedIn = false;
  double panOffset = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TransformationController _transformationController;
  late AnimationController _animationController;
  late Animation<Matrix4> _matrixAnimation;
  late AnimationController _panController;
  late Animation<double> _panAnimation;
  int focusedObjectIndex = -1;
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  String updateStatus = '(Not?) checking for updates';

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
    transit = "Loading...";
    _transformationController = TransformationController();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _matrixAnimation = Matrix4Tween().animate(_animationController);
    _matrixAnimation.addListener(() {
      _transformationController.value = _matrixAnimation.value;
    });
    _panController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _panAnimation = Tween<double>(begin: 0, end: 0).animate(_panController);
    _panAnimation.addListener(() {
      setState(() {
        panOffset = _panAnimation.value;
      });
    });
    // Initialize scale animation for breathing effect
    _scaleController = AnimationController(
      duration: const Duration(seconds: 2),  // Duration of one breath cycle
      vsync: this,
    )..repeat(reverse: true);  // Repeat forward and backward for breathing

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Update the UI on each animation frame
    _scaleAnimation.addListener(() {
      setState(() {});
    });

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_focusController);
    _focusAnimation.addListener(() { setState(() {}); });

    _connectWebSocket();
    fetchData();
    fetchChartQuickHTML();
    updateStatus = 'Checking for updates...';
    if (isRelease) {
      _checkForUpdate();
    }
    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _panController.dispose();
    _scaleController.dispose();
    _focusController.dispose();
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

  Future<bool> _checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('Current version: $currentVersion');
      final response = await http.get(Uri.parse('https://api.github.com/repos/Jhaquen/HDfront/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'] as String;
        print('Latest version: $latestVersion');
        if (_isVersionNewer(latestVersion, currentVersion)) {
          final assets = data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.apk'),
            orElse: () => null,
          );
          if (apkAsset != null) {
            final apkUrl = apkAsset['browser_download_url'] as String;
            setState(() {
              updateStatus = 'Update available, downloading...';
            });
            _downloadAndInstallApk(apkUrl, latestVersion);
            return true;
          }
        } else {
          setState(() {
            updateStatus = 'App is up to date';
          });
        }
      } else {
        print('GitHub API failed: ${response.statusCode}');
        setState(() {
          updateStatus = 'Failed to check for updates';
        });
      }
    } catch (e) {
      print('Update check error: $e');
      setState(() {
        updateStatus = 'Error checking for updates';
      });
    }
    return false;
  }

  bool _isVersionNewer(String latest, String current) {
    // Simple version comparison (assumes semantic versioning)
    final latestParts = latest.replaceAll('v', '').split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();
    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  Future<void> _downloadAndInstallApk(String url, String version) async {
    try {
      final dir = await getDownloadsDirectory();
      final filePath = '${dir!.path}/hdapp_$version.apk';
      final file = File(filePath);
      final response = await http.get(Uri.parse(url));
      await file.writeAsBytes(response.bodyBytes);
      // Show dialog to install
      _showInstallDialog(filePath);
    } catch (e) {
      print('Download failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  void _showInstallDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text('A new version has been downloaded. Install now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _installApk(filePath);
              },
              child: const Text('Install'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _installApk(String filePath) async {
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: 'file://$filePath',
        type: 'application/vnd.android.package-archive',
      );
      await intent.launch();
    } catch (e) {
      print('Install failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Install failed: $e')),
      );
    }
  }

  Future<void> _refreshData() async {
    await fetchData();
    await fetchChartQuickHTML();
    if (isRelease) {
      await _checkForUpdate();
    }
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
              transit = 'res: ${json.decode(responseAsc.body)}';
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
    final response = await http.get(Uri.parse('$backendUrl/getChart'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        final formatted = data.map((item) => '${item['gateNumber']}.${item['line']} ${item['planet']}').join('\n');
        setState(() {
          responseText = formatted;
        });
      } else {
        setState(() {
          responseText = 'Invalid data format';
        });
      }
    } else {
      setState(() {
        responseText = 'Error: ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      responseText = 'Error: $e';
    });
  }
}

  Future<http.Response> login(String username, String password) async {
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

    return response;
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
                  final response = await login(username, password);
                  if (response.statusCode == 200) {
                    setState(() {
                      isLoggedIn = true;
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: ${response.body}')),
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
    chart = renderer.Chart(activeGates: activeGates);
    chart.scale = _scaleAnimation.value;  // Apply animated scale
    chart.focusedIndex = focusedObjectIndex;
    chart.focusValue = _focusAnimation.value;

    renderer.CanvasText leftText = renderer.CanvasText(
      text:  '''
                TestBox

                Active Gates: ${activeGates.join(', ')}

                ${backendUrl}

                ${updateStatus}

                Autoupdate working!
                ''',
      position: const Offset(-150, 100),  // Changed from -150 to 50 for visibility
      fontSize: 12,
      color: Colors.black,
      size: screenSize.width * 0.6,
    );

    renderer.CanvasText rightText = renderer.CanvasText(
      text: responseText,
      position: Offset(350, 100),
      fontSize: 12,
      color: Colors.black,
      size: screenSize.width * 0.6,
    );

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
              // Then check objects for focus
              for (int i = 0; i < chart.objects.length; i++) {
                final obj = chart.objects[i];
                if ((canvasPosition - obj.position).distance < obj.size / 2) {
                  setState(() {
                    focusedObjectIndex = i;
                  });
                  _focusController.forward(from: 0.0);
                  break;
                }
              }
            },
            onDoubleTap: () {
              setState(() {
                focusedObjectIndex = -1;
              });
              _focusController.reverse();
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              if (details.velocity.pixelsPerSecond.dx < -300) { // Swipe left
                double target = panOffset - 200;
                _panAnimation = Tween<double>(begin: panOffset, end: target).animate(_panController);
                _panController.forward(from: 0.0);
              } else if (details.velocity.pixelsPerSecond.dx > 300) { // Swipe right
                double target = panOffset + 200;
                _panAnimation = Tween<double>(begin: panOffset, end: target).animate(_panController);
                _panController.forward(from: 0.0);
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: false, // Disable panning
              child: CustomPaint(
                painter: renderer.ChartPainter(chart, screenSize, panOffset, leftText, rightText),
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
                  'Status: $transit',
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
                const SizedBox(height: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: _refreshData,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
