import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'chart.dart';
import 'charts_screen.dart';
import '../config.dart';
import 'package:http/http.dart' as http;

class ChartViewerScreen extends StatefulWidget {
  final ChartData chart;

  const ChartViewerScreen({super.key, required this.chart});

  @override
  State<ChartViewerScreen> createState() => _ChartViewerScreenState();
}

class _ChartViewerScreenState extends State<ChartViewerScreen> with TickerProviderStateMixin {
  late Chart chart;
  List<int> activeGates = [];
  String responseText = '';
  String currentView = 'chart'; // 'chart', 'left', 'right'
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
    chart = Chart(activeGates: activeGates);
    _transformationController = TransformationController();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _matrixAnimation = Matrix4Tween().animate(_animationController);
    _matrixAnimation.addListener(() {
      _transformationController.value = _matrixAnimation.value;
    });
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/'));
      setState(() {
        responseText = 'Status: ${response.statusCode}\nBody: ${response.body}';
      });
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is List) {
            setState(() {
              activeGates = List<int>.from(data);
              chart = Chart(activeGates: activeGates); // Recreate chart with new activeGates
            });
          }
        } catch (e) {
          // Ignore if not JSON list
        }
      }
    } catch (e) {
      setState(() {
        responseText = 'Error: $e';
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chart.name),
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
            onDoubleTap: () {
              // Reset to chart view
              setState(() {
                currentView = 'chart';
                responseText = '';
              });
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
                  'Chart: ${widget.chart.name} - Lat: ${widget.chart.lat}, Long: ${widget.chart.long}, Date: ${widget.chart.date.toLocal().toString().split(' ')[0]}, Time: ${widget.chart.time.format(context)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
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
