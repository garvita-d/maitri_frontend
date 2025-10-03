import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// import 'package:rive/rive.dart'; // Uncomment if using Rive

/// Reusable space-themed background with two lightweight variants
/// Optimized for both mobile and web platforms
class SpaceBackground extends StatelessWidget {
  final Widget child;
  final _BackgroundType _type;
  final String? _animationAsset;

  const SpaceBackground._({
    required this.child,
    required _BackgroundType type,
    String? animationAsset,
  })  : _type = type,
        _animationAsset = animationAsset;

  /// Factory: Particle-based animated background with drifting stars
  /// MOBILE IMPLEMENTATION: Efficient CustomPainter with minimal redraws
  /// WEB FALLBACK: Same implementation works well on web, no special handling needed
  /// Performance: ~60fps on most devices, uses single AnimationController
  factory SpaceBackground.particles({required Widget child}) {
    return SpaceBackground._(
      type: _BackgroundType.particles,
      child: child,
    );
  }

  /// Factory: Rive/Lottie animation background with asset fallback
  /// MOBILE IMPLEMENTATION: Prefer Rive for smaller file sizes (5-50KB typical)
  /// WEB FALLBACK: Lottie has better web support, use JSON animations (20-200KB typical)
  ///
  /// Asset size recommendations:
  /// - Rive: 5-50KB, excellent performance, needs .riv files
  /// - Lottie: 20-200KB, good web support, needs .json files
  /// - Keep animations under 10 seconds loop for memory efficiency
  ///
  /// TODO: Add your animation asset to pubspec.yaml assets section
  /// Example: assets/animations/space_background.json (Lottie)
  /// Example: assets/animations/space_background.riv (Rive)
  factory SpaceBackground.rive({
    required Widget child,
    String animationAsset = 'assets/animations/space_background.json',
  }) {
    return SpaceBackground._(
      type: _BackgroundType.animation,
      animationAsset: animationAsset,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background layer
        Positioned.fill(
          child: _type == _BackgroundType.particles
              ? const _ParticleBackground()
              : _AnimationBackground(assetPath: _animationAsset!),
        ),
        // Foreground content
        child,
      ],
    );
  }
}

enum _BackgroundType { particles, animation }

// ============================================================================
// PARTICLE BACKGROUND IMPLEMENTATION
// ============================================================================

/// Particle-based background with animated drifting stars
class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();

  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // Slow drift
    )..repeat();

    // Generate random particles
    _particles = List.generate(
      80, // Particle count - adjust for performance
      (index) => _Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 2 + 1,
        speed: math.Random().nextDouble() * 0.5 + 0.5,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            animation: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Particle data model
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

/// Custom painter for drawing particles and gradient
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animation;

  _ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw gradient background
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0E27), // Deep space blue
          Color(0xFF1A1B3D), // Medium purple-blue
          Color(0xFF2D1B4E), // Purple tint
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );

    // Draw particles (stars)
    final particlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Calculate drifting position
      final xPos = (particle.x + animation * particle.speed * 0.05) % 1.0;
      final yPos = particle.y;

      final offset = Offset(
        xPos * size.width,
        yPos * size.height,
      );

      // Draw star with slight glow effect
      particlePaint.color = Colors.white.withAlpha((180).round());
      canvas.drawCircle(offset, particle.size, particlePaint);

      // Add subtle glow
      particlePaint.color = Colors.white.withAlpha((112).round());
      canvas.drawCircle(offset, particle.size * 1.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

// ============================================================================
// ANIMATION BACKGROUND IMPLEMENTATION (Lottie/Rive)
// ============================================================================

/// Animation-based background with Lottie or Rive
class _AnimationBackground extends StatelessWidget {
  final String assetPath;

  const _AnimationBackground({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    // Determine animation type from file extension
    final isRive = assetPath.endsWith('.riv');
    final isLottie = assetPath.endsWith('.json');

    // WEB FALLBACK: If Rive asset on web, fall back to particles
    // Rive has limited web support compared to Lottie
    if (isRive) {
      // TODO: Uncomment when using Rive package
      // return RiveAnimation.asset(
      //   assetPath,
      //   fit: BoxFit.cover,
      //   onInit: (artboard) {
      //     // Configure animation controller if needed
      //   },
      // );

      // Fallback to particles if Rive not implemented
      return const _ParticleBackground();
    }

    // MOBILE & WEB: Lottie works well on both platforms
    if (isLottie) {
      return Lottie.asset(
        assetPath,
        fit: BoxFit.cover,
        repeat: true,
        // Performance optimization: reduce quality slightly for better FPS
        options: LottieOptions(
          enableMergePaths: true,
        ),
        // Error handling: fall back to particle background
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Lottie animation failed to load: $error');
          return const _ParticleBackground();
        },
      );
    }

    // Default fallback
    return const _ParticleBackground();
  }
}

// ============================================================================
// PERFORMANCE NOTES
// ============================================================================
// 
// Particle Background:
// - 80 particles: ~60fps on modern devices
// - Increase to 150+ for desktop/web with good GPUs
// - Decrease to 40-50 for older mobile devices
// - CustomPainter redraws only when animation value changes
//
// Animation Background:
// - Lottie: Ensure animations are optimized (use LottieFiles optimizer)
// - Rive: Much smaller file sizes, but limited web browser support
// - Both: Avoid complex gradients and effects in animations
// - Consider using static background images on low-end devices
//
// Asset Size Guidelines:
// - Lottie JSON: Target 50-150KB for smooth playback
// - Rive: Target 10-50KB (highly compressed format)
// - Test on actual devices, not just simulators
//
// TODO: Add device-specific background selection based on performance
// TODO: Implement quality settings in user preferences