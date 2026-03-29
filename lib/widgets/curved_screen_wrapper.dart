import 'package:flutter/material.dart';

/// A wrapper widget that applies a subtle 3D curved/perspective effect 
/// to its child, mimicking a physical device screen in a promotional shot.
class CurvedScreenWrapper extends StatelessWidget {
  final Widget child;
  
  /// Toggle the 3D effect on or off
  final bool isEnabled;
  
  /// Rotation along the X-axis (in radians)
  final double tiltX;
  
  /// Rotation along the Y-axis (in radians)
  final double tiltY;
  
  /// The perspective depth (controls foreshortening)
  final double perspective;
  
  /// The roundness of the device screen corners
  final double borderRadius;
  
  /// Opacity of the drop shadow
  final double shadowIntensity;

  const CurvedScreenWrapper({
    super.key,
    required this.child,
    this.isEnabled = true,
    this.tiltX = 0.05,
    this.tiltY = -0.05,
    this.perspective = 0.001,
    this.borderRadius = 32.0,
    this.shadowIntensity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    // If disabled, just return the child unchanged.
    if (!isEnabled) return child;

    // Apply the 3D transformation
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          // 1. Apply perspective
          ..setEntry(3, 2, perspective)
          // 2. Rotate to tilt the screen
          ..rotateX(tiltX)
          ..rotateY(tiltY),
        
        // Use a container to hold the screen, its clipping, and the shadow
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(shadowIntensity),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(15, 25), // Creates a directional light shadow
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // The actual screen content
                child,
                
                // Optional: A soft glass reflection/gradient overlay to sell the 3D effect
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.0),
                            Colors.black.withOpacity(0.15),
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
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
}
