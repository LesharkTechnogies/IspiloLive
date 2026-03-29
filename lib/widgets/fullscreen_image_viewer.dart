import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

/// Simple full-screen image viewer overlay.
/// Use `showDialog` with this widget to display a full-screen image that can be dismissed by tapping or swiping down.
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag; // optional hero tag for smooth transition

  const FullScreenImageViewer(
      {super.key, required this.imageUrl, this.heroTag});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideUpAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideUpAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    // delay the animation slightly so image loads first
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Stack(
              children: [
                // Top-left close button (fade-in)
                Positioned(
                  top: 12,
                  left: 12,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SafeArea(
                      child: ClipOval(
                        child: Material(
                          color: Colors.black45, // semi-transparent background
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.close,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main image (interactive)
                Center(
                  child: Hero(
                    tag: widget.heroTag ?? widget.imageUrl,
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),

                // Action bar at bottom (slide-up)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: SlideTransition(
                    position: _slideUpAnim,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionButton(
                          icon: Icons.file_download,
                          label: 'Download',
                          onTap: () async {
                            final scaffold = ScaffoldMessenger.of(context);
                            final savedPath = await _downloadImageWithWatermark(
                                widget.imageUrl, 'ispilo');
                            if (!mounted) return;
                            if (savedPath != null && savedPath.isNotEmpty) {
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text('Saved to: $savedPath'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () async {
                                      try {
                                        final f = File(savedPath);
                                        if (await f.exists()) {
                                          await f.delete();
                                          scaffold.showSnackBar(const SnackBar(
                                              content: Text('Save undone')));
                                        }
                                      } catch (_) {}
                                    },
                                  ),
                                ),
                              );
                            } else {
                              scaffold.showSnackBar(
                                  const SnackBar(
                                      content: Text('Failed to save image')));
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onTap: () async {
                            final scaffold = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final savedPath = await _downloadImageWithWatermark(
                                widget.imageUrl, 'ispilo');
                            if (!mounted) return;
                            if (savedPath != null && savedPath.isNotEmpty) {
                              // Capture navigator before awaiting share to avoid
                              // using BuildContext across async gaps.
                              final navigatorBefore = navigator;
                              final params = ShareParams(
                                text: 'Shared from Ispilo',
                                files: [XFile(savedPath)],
                              );
                              await SharePlus.instance.share(params);
                              navigatorBefore.pop();
                            } else {
                              scaffold.showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Failed to prepare image for sharing')));
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.person,
                          label: 'Set Avatar',
                          onTap: () async {
                            final scaffold = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final savedPath = await _downloadImageWithWatermark(
                                widget.imageUrl, 'ispilo');
                            if (!mounted) return;
                            if (savedPath != null && savedPath.isNotEmpty) {
                              navigator.pop();
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text('Saved avatar to: $savedPath'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () async {
                                      try {
                                        final f = File(savedPath);
                                        if (await f.exists()) {
                                          await f.delete();
                                          scaffold.showSnackBar(const SnackBar(
                                              content:
                                                  Text('Avatar save undone')));
                                        }
                                      } catch (_) {}
                                    },
                                  ),
                                ),
                              );
                            } else {
                              scaffold.showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Failed to save avatar image')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Decode image bytes into a ui.Image
  Future<ui.Image> _decodeImageFromList(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  // Download image, draw a text watermark and save as PNG. Returns saved file path or null on failure.
  Future<String?> _downloadImageWithWatermark(
      String url, String watermark) async {
    try {
      final uri = Uri.parse(url);
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;

      final bytes = resp.bodyBytes;
      final ui.Image image = await _decodeImageFromList(bytes);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));
      final paint = Paint();
      canvas.drawImage(image, Offset.zero, paint);

      // Watermark styling
    final double fontSize = math.max(14.0, image.width * 0.04);
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      shadows: [
      const Shadow(
        blurRadius: 2, color: Colors.black45, offset: Offset(1, 1))
      ]);
      final tp = TextPainter(
          text: TextSpan(text: watermark, style: textStyle),
          textDirection: TextDirection.ltr);
      tp.layout();

      final double padding = image.width * 0.03;
      final offset = Offset(
          image.width - tp.width - padding, image.height - tp.height - padding);
      tp.paint(canvas, offset);

      final picture = recorder.endRecording();
      final ui.Image finalImage =
          await picture.toImage(image.width, image.height);
      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final pngBytes = byteData.buffer.asUint8List();

      // Save locally under app documents (no external gallery plugin to avoid build issues)

      final dir = await getApplicationDocumentsDirectory();
      final rawName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'image_${DateTime.now().millisecondsSinceEpoch}.png';
      final fileName =
          'ispilo_${DateTime.now().millisecondsSinceEpoch}_$rawName.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
