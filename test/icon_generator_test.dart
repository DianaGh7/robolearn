import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate app icon', () async {
    const double s = 1024.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Solid white background
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Paint()..color = const ui.Color(0xFFB8F0E8),
    );

    // Robot face
    _paintRobot(canvas, s);

    final picture = recorder.endRecording();
    final image = await picture.toImage(s.toInt(), s.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final file = File('assets/icon/app_icon.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);

    expect(await file.exists(), true);
  });
}

void _paintRobot(ui.Canvas canvas, double fullSize) {
  final double w = 960;
  final double h = 960;
  final double cx = fullSize / 2;
  final double cy = fullSize / 2;

  canvas.drawCircle(
    ui.Offset(cx, cy),
    w * 0.38,
    ui.Paint()..color = const ui.Color(0xFF4DD0C4),
  );

  final earP = ui.Paint()..color = const ui.Color(0xFF2A9990);
  canvas.drawCircle(ui.Offset(cx - w * .30, cy - h * .22), w * .13, earP);
  canvas.drawCircle(ui.Offset(cx + w * .30, cy - h * .22), w * .13, earP);

  final iEar = ui.Paint()..color = const ui.Color(0xFF4DD0C4);
  canvas.drawCircle(ui.Offset(cx - w * .30, cy - h * .22), w * .07, iEar);
  canvas.drawCircle(ui.Offset(cx + w * .30, cy - h * .22), w * .07, iEar);

  canvas.drawOval(
    ui.Rect.fromCenter(
      center: ui.Offset(cx, cy + h * .02),
      width: w * .56,
      height: h * .52,
    ),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );

  final eyeP = ui.Paint()..color = const ui.Color(0xFF1A3A38);
  canvas.drawCircle(ui.Offset(cx - w * .12, cy - h * .06), w * .08, eyeP);
  canvas.drawCircle(ui.Offset(cx + w * .12, cy - h * .06), w * .08, eyeP);

  final shineP = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  canvas.drawCircle(ui.Offset(cx - w * .09, cy - h * .09), w * .03, shineP);
  canvas.drawCircle(ui.Offset(cx + w * .15, cy - h * .09), w * .03, shineP);

  final smileP = ui.Paint()
    ..color = const ui.Color(0xFF2A7A74)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = w * .025
    ..strokeCap = ui.StrokeCap.round;
  final path = ui.Path()
    ..moveTo(cx - w * .10, cy + h * .08)
    ..quadraticBezierTo(cx, cy + h * .16, cx + w * .10, cy + h * .08);
  canvas.drawPath(path, smileP);

  final cheekP = ui.Paint()
    ..color = const ui.Color(0xFFE8A0BF).withValues(alpha: 0.5);
  canvas.drawCircle(ui.Offset(cx - w * .18, cy + h * .06), w * .06, cheekP);
  canvas.drawCircle(ui.Offset(cx + w * .18, cy + h * .06), w * .06, cheekP);
}
