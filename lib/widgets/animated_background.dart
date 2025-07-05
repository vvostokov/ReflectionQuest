import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  // Этот виджет теперь самодостаточен и не требует параметров
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  void _initializeParticles(Size size) {
    if (_particles.isNotEmpty) return; // Инициализируем только один раз
    for (int i = 0; i < 50; i++) {
      _particles.add(_createParticle(size, initial: true));
    }
  }

  _Particle _createParticle(Size size, {bool initial = false}) {
    return _Particle(
      position: Offset(
        _random.nextDouble() * size.width,
        initial ? _random.nextDouble() * size.height : -5.0,
      ),
      velocity: Offset(
        (_random.nextDouble() - 0.5) * 0.2, // Легкое горизонтальное смещение
        _random.nextDouble() * 0.5 + 0.3,   // Вертикальная скорость
      ),
      radius: _random.nextDouble() * 1.5 + 0.5,
      color: Colors.white.withOpacity(_random.nextDouble() * 0.5 + 0.2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _initializeParticles(constraints.biggest);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: constraints.biggest,
              painter: _SpacePainter(particles: _particles, random: _random),
            );
          },
        );
      },
    );
  }
}

class _SpacePainter extends CustomPainter {
  final List<_Particle> particles;
  final Random random;

  _SpacePainter({required this.particles, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final particlePaint = Paint();

    for (var p in particles) {
      p.position = p.position + p.velocity;

      if (p.position.dy > size.height + 5) {
        p.position = Offset(random.nextDouble() * size.width, -5.0);
      }

      particlePaint.color = p.color;
      canvas.drawCircle(p.position, p.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) => true;
}

class _Particle {
  Offset position;
  Offset velocity;
  double radius;
  Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
  });
}