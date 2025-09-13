class Chart {
  List<ChartObject> objects = [
    Triangle(position: Offset.zero, rotation: 0, color: Colors.blue),
    Triangle(position: Offset.zero, rotation: pi, color: Colors.red), // Flipped
    Square(position: Offset.zero, rotation: 0, color: Colors.green),
    Square(position: Offset.zero, rotation: pi / 4, color: Colors.yellow), // Fixed to radians (45°)
    Square(position: Offset.zero, rotation: 0, color: Colors.purple),
    Triangle(position: Offset.zero, rotation: pi / 2, color: Colors.yellow),
    Square(position: Offset.zero, rotation: 0, color: Colors.orange), // Last vertical
    Triangle(position: Offset.zero, rotation: 0, color: Colors.grey), // Extra 1
    Triangle(position: Offset.zero, rotation: 0, color: Colors.pink), // Extra 2
  ];
  double scale = 0.8;

  Chart() {
    objects[0].connectedTo = [objects[1]];
    objects[1].connectedTo = [objects[2]];
  }

  void draw(Canvas canvas, Size screenSize) {
    double startY = screenSize.height * 0.2;
    double spacing = (screenSize.height * 0.8) / 7; // For first 7 objects vertical
    for (int i = 0; i < 7; i++) {
      objects[i].position = Offset(screenSize.width / 2, startY + i * spacing);
      objects[i].size = 50 * scale;
      objects[i].draw(canvas);
    }

    // Position extra triangles at the same height as the purple square (index 4)
    double purpleY = objects[4].position.dy;
    objects[7].position = Offset(screenSize.width / 2 + 100, purpleY); // Offset to the right
    objects[7].size = 50 * scale;
    objects[7].draw(canvas);

    objects[8].position = Offset(screenSize.width / 2 - 100, purpleY); // Offset to the left
    objects[8].size = 50 * scale;
    objects[8].draw(canvas);

    // Draw lines between connected objects
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    for (final obj in objects) {
      for (final connected in obj.connectedTo) {
        // Draw 3 lines from edge instead of center
        Offset start1 = obj.position + Offset(obj.size / 2, 0);
        Offset start2 = obj.position + Offset(-obj.size / 2, 0);
        Offset start3 = obj.position + Offset(0, obj.size / 2);
        Offset end1 = connected.position + Offset(connected.size / 2, 0);
        Offset end2 = connected.position + Offset(-connected.size / 2, 0);
        Offset end3 = connected.position + Offset(0, -connected.size / 2);
        canvas.drawLine(start1, end1, linePaint);
        canvas.drawLine(start2, end2, linePaint);
        canvas.drawLine(start3, end3, linePaint);
      }
    }
  }
}
