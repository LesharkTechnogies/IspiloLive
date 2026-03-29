// Run this script with: dart run tooling/create_padded_icon.dart
// It loads assets/images/Ispilo.png and outputs assets/images/Ispilo_padded.png

import 'dart:io';
import 'package:image/image.dart';

void main(List<String> args) async {
  final srcPath = 'assets/images/Ispilo.png';
  final outPath = 'assets/images/Ispilo_padded.png';

  if (!File(srcPath).existsSync()) {
    stderr.writeln('Source file not found: $srcPath');
    exit(2);
  }

  final srcBytes = File(srcPath).readAsBytesSync();
  final img = decodeImage(srcBytes);
  if (img == null) {
    stderr.writeln('Could not decode image');
    exit(2);
  }

  // Create 1024x1024 white background and center the resized image at 80% size
  final size = 1024;
  final bg = Image(size, size);
  fill(bg, getColor(255, 255, 255));

  final targetSize = (size * 0.8).toInt();
  final resized = copyResize(img, width: targetSize, height: targetSize);

  final dx = ((size - resized.width) / 2).round();
  final dy = ((size - resized.height) / 2).round();

  // composite the resized image onto the white background
  copyInto(bg, resized, dstX: dx, dstY: dy, blend: false);

  // Save
  final outFile = File(outPath);
  outFile.createSync(recursive: true);
  outFile.writeAsBytesSync(encodePng(bg), flush: true);
}
