import 'dart:math';
import 'package:flutter/material.dart';

class Chart {
  List<ChartObject> objects = [];
  List<Connection> connections = [];
  double scale = 0.8;
  List<int> activeGates;
  int? focusedIndex;
  double focusValue = 0.0;

  // Map object names to their gates
  final Map<String, List<Map<String, dynamic>>> gateMap = {
    'obj1': [
      {'number': 1, 'position': Offset(25, 0)},
      {'number': 2, 'position': Offset(17.68, 17.68)},
      {'number': 3, 'position': Offset(0, 25)},
      {'number': 4, 'position': Offset(-17.68, 17.68)},
      {'number': 5, 'position': Offset(-25, 0)},
      {'number': 6, 'position': Offset(-17.68, -17.68)},
      {'number': 7, 'position': Offset(0, -25)},
      {'number': 8, 'position': Offset(17.68, -17.68)},
    ],
    'obj2': [
      {'number': 9, 'position': Offset(25, 0)},
      {'number': 10, 'position': Offset(17.68, 17.68)},
      {'number': 11, 'position': Offset(0, 25)},
      {'number': 12, 'position': Offset(-17.68, 17.68)},
      {'number': 13, 'position': Offset(-25, 0)},
      {'number': 14, 'position': Offset(-17.68, -17.68)},
      {'number': 15, 'position': Offset(0, -25)},
      {'number': 16, 'position': Offset(17.68, -17.68)},
    ],
    'obj3': [
      {'number': 17, 'position': Offset(25, 0)},
      {'number': 18, 'position': Offset(17.68, 17.68)},
      {'number': 19, 'position': Offset(0, 25)},
      {'number': 20, 'position': Offset(-17.68, 17.68)},
      {'number': 21, 'position': Offset(-25, 0)},
      {'number': 22, 'position': Offset(-17.68, -17.68)},
      {'number': 23, 'position': Offset(0, -25)},
      {'number': 24, 'position': Offset(17.68, -17.68)},
    ],
    'obj4': [
      {'number': 25, 'position': Offset(25, 0)},
      {'number': 26, 'position': Offset(17.68, 17.68)},
      {'number': 27, 'position': Offset(0, 25)},
      {'number': 28, 'position': Offset(-17.68, 17.68)},
      {'number': 29, 'position': Offset(-25, 0)},
      {'number': 30, 'position': Offset(-17.68, -17.68)},
      {'number': 31, 'position': Offset(0, -25)},
      {'number': 32, 'position': Offset(17.68, -17.68)},
    ],
    'obj5': [
      {'number': 33, 'position': Offset(25, 0)},
      {'number': 34, 'position': Offset(17.68, 17.68)},
      {'number': 35, 'position': Offset(0, 25)},
      {'number': 36, 'position': Offset(-17.68, 17.68)},
      {'number': 37, 'position': Offset(-25, 0)},
      {'number': 38, 'position': Offset(-17.68, -17.68)},
      {'number': 39, 'position': Offset(0, -25)},
      {'number': 40, 'position': Offset(17.68, -17.68)},
    ],
    'obj6': [
      {'number': 41, 'position': Offset(25, 0)},
      {'number': 42, 'position': Offset(17.68, 17.68)},
      {'number': 43, 'position': Offset(0, 25)},
      {'number': 44, 'position': Offset(-17.68, 17.68)},
      {'number': 45, 'position': Offset(-25, 0)},
      {'number': 46, 'position': Offset(-17.68, -17.68)},
      {'number': 47, 'position': Offset(0, -25)},
      {'number': 48, 'position': Offset(17.68, -17.68)},
    ],
    'obj7': [
      {'number': 49, 'position': Offset(25, 0)},
      {'number': 50, 'position': Offset(17.68, 17.68)},
      {'number': 51, 'position': Offset(0, 25)},
      {'number': 52, 'position': Offset(-17.68, 17.68)},
      {'number': 53, 'position': Offset(-25, 0)},
      {'number': 54, 'position': Offset(-17.68, -17.68)},
      {'number': 55, 'position': Offset(0, -25)},
      {'number': 56, 'position': Offset(17.68, -17.68)},
    ],
    'obj8': [
      {'number': 57, 'position': Offset(25, 0)},
      {'number': 58, 'position': Offset(17.68, 17.68)},
      {'number': 59, 'position': Offset(0, 25)},
      {'number': 60, 'position': Offset(-17.68, 17.68)},
      {'number': 61, 'position': Offset(-25, 0)},
      {'number': 62, 'position': Offset(-17.68, -17.68)},
      {'number': 63, 'position': Offset(0, -25)},
      {'number': 64, 'position': Offset(17.68, -17.68)},
    ],
  };

  Chart({this.activeGates = const []}) {
    // Create objects with names and gates
    objects = [
      Triangle(position: Offset.zero, rotation: 0, color: Colors.blue, name: 'obj1', gates: _createGates('obj1')),
      Triangle(position: Offset.zero, rotation: pi, color: Colors.red, name: 'obj2', gates: _createGates('obj2')),
      Square(position: Offset.zero, rotation: 0, color: Colors.green, name: 'obj3', gates: _createGates('obj3')),
      Square(position: Offset.zero, rotation: pi / 4, color: Colors.yellow, name: 'obj4', gates: _createGates('obj4')),
      Square(position: Offset.zero, rotation: 0, color: Colors.purple, name: 'obj5', gates: _createGates('obj5')),
      Triangle(position: Offset.zero, rotation: pi / 2, color: Colors.grey, name: 'obj6', gates: _createGates('obj6')),
      Triangle(position: Offset.zero, rotation: -pi / 2, color: Colors.pink, name: 'obj7', gates: _createGates('obj7')),
      Square(position: Offset.zero, rotation: 0, color: Colors.orange, name: 'obj8', gates: _createGates('obj8')),
    ];

    connections.add(Connection(objects[0], objects[0].gates[0], objects[1], objects[1].gates[0]));
    connections.add(Connection(objects[0], objects[0].gates[1], objects[1], objects[1].gates[1]));
    connections.add(Connection(objects[0], objects[0].gates[2], objects[1], objects[1].gates[2]));
    connections.add(Connection(objects[1], objects[1].gates[0], objects[2], objects[2].gates[0]));
    connections.add(Connection(objects[1], objects[1].gates[1], objects[2], objects[2].gates[1]));
    connections.add(Connection(objects[1], objects[1].gates[2], objects[2], objects[2].gates[2]));
    connections.add(Connection(objects[2], objects[2].gates[0], objects[3], objects[3].gates[0]));
    connections.add(Connection(objects[2], objects[2].gates[1], objects[3], objects[3].gates[1]));
    connections.add(Connection(objects[2], objects[2].gates[2], objects[3], objects[3].gates[2]));
    connections.add(Connection(objects[2], objects[2].gates[3], objects[5], objects[5].gates[3]));
    connections.add(Connection(objects[2], objects[2].gates[4], objects[5], objects[5].gates[4]));
    connections.add(Connection(objects[2], objects[2].gates[5], objects[6], objects[6].gates[5]));
    connections.add(Connection(objects[2], objects[2].gates[6], objects[6], objects[6].gates[6]));
    connections.add(Connection(objects[3], objects[3].gates[0], objects[4], objects[4].gates[0]));
    connections.add(Connection(objects[3], objects[3].gates[1], objects[4], objects[4].gates[1]));
    connections.add(Connection(objects[3], objects[3].gates[2], objects[4], objects[4].gates[2]));
    connections.add(Connection(objects[4], objects[4].gates[0], objects[7], objects[7].gates[0]));
    connections.add(Connection(objects[4], objects[4].gates[1], objects[7], objects[7].gates[1]));
    connections.add(Connection(objects[4], objects[4].gates[2], objects[7], objects[7].gates[2]));
    connections.add(Connection(objects[4], objects[4].gates[3], objects[7], objects[7].gates[3]));
    connections.add(Connection(objects[4], objects[4].gates[4], objects[5], objects[5].gates[4]));
    connections.add(Connection(objects[4], objects[4].gates[5], objects[5], objects[5].gates[5]));
    connections.add(Connection(objects[4], objects[4].gates[6], objects[6], objects[6].gates[6]));
    connections.add(Connection(objects[4], objects[4].gates[7], objects[6], objects[6].gates[7]));
    connections.add(Connection(objects[4], objects[4].gates[0], objects[5], objects[5].gates[0]));
    connections.add(Connection(objects[4], objects[4].gates[0], objects[6], objects[6].gates[0]));
    connections.add(Connection(objects[5], objects[5].gates[0], objects[7], objects[7].gates[0]));
    connections.add(Connection(objects[5], objects[5].gates[1], objects[7], objects[7].gates[1]));
    connections.add(Connection(objects[6], objects[6].gates[0], objects[7], objects[7].gates[0]));
    connections.add(Connection(objects[6], objects[6].gates[1], objects[7], objects[7].gates[1]));
  }

  List<Gate> _createGates(String name) {
    final gateData = gateMap[name] ?? [];
    return gateData.map((data) => Gate(data['number'], data['position'])).toList();
  }

  void draw(Canvas canvas, Size screenSize) {
    double startY = screenSize.height * 0.2;
    double spacing = (screenSize.height * 0.8) / 6; // 5 vertical + 1 below
    double sizeIncreaseOnTap = 4;

    for (int i = 0; i < 5; i++) {
      double additionalScale = (focusedIndex == i) ? focusValue * sizeIncreaseOnTap : focusValue * 0.2;
      objects[i].position = Offset(screenSize.width / 2, startY + i * spacing);
      objects[i].size = 50 * (scale + additionalScale);
    }
    // Position triangles beside purple square (index 4)
    double purpleY = objects[4].position.dy;
    double additionalScale5 = (focusedIndex == 5) ? focusValue * sizeIncreaseOnTap : focusValue * 0.2;
    objects[5].position = Offset(screenSize.width / 2 - 120, purpleY); // Left
    objects[5].size = 50 * (scale + additionalScale5);
    objects[5].draw(canvas, activeGates, scale + additionalScale5);

    double additionalScale6 = (focusedIndex == 6) ? focusValue * sizeIncreaseOnTap : focusValue * 0.2;
    objects[6].position = Offset(screenSize.width / 2 + 120, purpleY); // Right
    objects[6].size = 50 * (scale + additionalScale6);
    objects[6].draw(canvas, activeGates, scale + additionalScale6);

    // Position square below
    double additionalScale7 = (focusedIndex == 7) ? focusValue * sizeIncreaseOnTap : focusValue * 0.2;
    objects[7].position = Offset(screenSize.width / 2, startY + 5 * spacing);
    objects[7].size = 50 * (scale + additionalScale7);
    objects[7].draw(canvas, activeGates, scale + additionalScale7);

    // Draw lines between connected objects
    for (final conn in connections) {
      conn.draw(canvas);
    }

    for (int i = 0; i < 5; i++) {
      double effectiveScale = objects[i].size / 50.0;
      objects[i].draw(canvas, activeGates, effectiveScale);
    }


  }
}

abstract class ChartObject {
  Offset position;
  double size;
  double rotation;
  Color color;
  String name;
  List<Gate> gates;
  List<ChartObject> connectedTo;

  ChartObject({
    required this.position,
    this.size = 50,
    this.rotation = 0,
    this.color = Colors.blue,
    this.name = '',
    this.gates = const [],
    List<ChartObject>? connectedTo,
  }) : connectedTo = connectedTo ?? [];

  void draw(Canvas canvas, List<int> activeGates, double scale);
}

class Triangle extends ChartObject {
  Triangle({
    required super.position,
    super.size,
    super.rotation,
    super.color,
    super.name,
    super.gates,
  });

  Offset _rotateOffset(Offset offset, double rotation) {
    final cosR = cos(rotation);
    final sinR = sin(rotation);
    return Offset(
      offset.dx * cosR - offset.dy * sinR,
      offset.dx * sinR + offset.dy * cosR,
    );
  }

  @override
  void draw(Canvas canvas, List<int> activeGates, double scale) {
    final fillPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(-size * 0.866, size / 2)
      ..lineTo(size * 0.866, size / 2)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    canvas.restore();

    // Draw gates
    for (final gate in gates) {
      final isActive = activeGates.contains(gate.number);
      gate.draw(canvas, position + _rotateOffset(gate.relativePosition, rotation), isActive, scale);
    }
  }
}

class Square extends ChartObject {
  Square({
    required super.position,
    super.size,
    super.rotation,
    super.color,
    super.name,
    super.gates,
  });

  Offset _rotateOffset(Offset offset, double rotation) {
    final cosR = cos(rotation);
    final sinR = sin(rotation);
    return Offset(
      offset.dx * cosR - offset.dy * sinR,
      offset.dx * sinR + offset.dy * cosR,
    );
  }

  @override
  void draw(Canvas canvas, List<int> activeGates, double scale) {
    final fillPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, strokePaint);

    canvas.restore();

    // Draw gates
    for (final gate in gates) {
      final isActive = activeGates.contains(gate.number);
      gate.draw(canvas, position + _rotateOffset(gate.relativePosition, rotation), isActive, scale);
    }
  }
}

class Connection {
  ChartObject fromObj;
  Gate fromGate;
  ChartObject toObj;
  Gate toGate;

  Connection(this.fromObj, this.fromGate, this.toObj, this.toGate);

  void draw(Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // Calculate absolute positions of gates
    Offset fromPos = fromObj.position + _rotateOffset(fromGate.relativePosition, fromObj.rotation);
    Offset toPos = toObj.position + _rotateOffset(toGate.relativePosition, toObj.rotation);

    canvas.drawLine(fromPos, toPos, linePaint);
  }

  Offset _rotateOffset(Offset offset, double rotation) {
    final cosR = cos(rotation);
    final sinR = sin(rotation);
    return Offset(
      offset.dx * cosR - offset.dy * sinR,
      offset.dx * sinR + offset.dy * cosR,
    );
  }
}

class Gate {
  int number;
  Offset relativePosition;

  Gate(this.number, this.relativePosition);

  void draw(Canvas canvas, Offset position, bool isActive, double scale) {
    final fillColor = isActive ? Colors.red : Colors.white;
    final strokeColor = isActive ? Colors.red.withOpacity(0.7) : Colors.black.withOpacity(0.7);
    canvas.drawCircle(position, 4 * scale, Paint()..color = fillColor);
    canvas.drawCircle(position, 4 * scale, Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1);
    final textPainter = TextPainter(
      text: TextSpan(text: number.toString(), style: TextStyle(color: Colors.black, fontSize: 10 * scale)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position - Offset(textPainter.width / 2, textPainter.height / 2 + 10 * scale));
  }
}

abstract class CanvasObject {
  Offset position;
  double size;
  double rotation;
  Color color;

  CanvasObject({
    required this.position,
    this.size = 50,
    this.rotation = 0,
    this.color = Colors.blue
  });

  void draw(Canvas canvas);
}

class CanvasText extends CanvasObject {
  String text;
  double fontSize;
  TextAlign textAlign;

  CanvasText({
    required this.text,
    required super.position,
    super.size,
    super.rotation,
    super.color,
    this.fontSize = 12,
    this.textAlign = TextAlign.left,
  });

  @override
  void draw(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    textPainter.layout(maxWidth: size);

    // Add background rectangle for visibility
    final backgroundRect = Rect.fromLTWH(-5, -5, size + 10, textPainter.height + 10);
    canvas.drawRect(backgroundRect, Paint()..color = const Color.fromARGB(255, 152, 172, 76).withOpacity(0.8));

    textPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }
}

class ChartPainter extends CustomPainter {
  final Chart chart;
  final Size screenSize;
  final double panOffset;
  final CanvasText leftText;
  final CanvasText rightText;

  ChartPainter(this.chart, this.screenSize, this.panOffset, this.leftText, this.rightText);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset, 0);
    chart.draw(canvas, screenSize);
    leftText.draw(canvas);
    rightText.draw(canvas);
    canvas.restore();

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
