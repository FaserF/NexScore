import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ConfettiController extends ChangeNotifier {
  final Duration duration;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  ConfettiController({this.duration = const Duration(seconds: 4)});

  void play() {
    if (_isPlaying) return;
    _isPlaying = true;
    notifyListeners();
  }

  void stop() {
    if (!_isPlaying) return;
    _isPlaying = false;
    notifyListeners();
  }
}

enum BlastDirectionality {
  directional,
  explosive,
}

class ConfettiWidget extends StatefulWidget {
  final ConfettiController confettiController;
  final BlastDirectionality blastDirectionality;
  final bool shouldLoop;
  final int numberOfParticles;
  final double maxBlastForce;
  final double minBlastForce;
  final double emissionFrequency;
  final double gravity;
  final List<Color>? colors;
  final Path Function(Size)? createParticlePath;

  const ConfettiWidget({
    super.key,
    required this.confettiController,
    this.blastDirectionality = BlastDirectionality.directional,
    this.shouldLoop = false,
    this.numberOfParticles = 10,
    this.maxBlastForce = 15,
    this.minBlastForce = 5,
    this.emissionFrequency = 0.02,
    this.gravity = 0.1,
    this.colors,
    this.createParticlePath,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double angle;
  double angularVelocity;
  double rotationX;
  double rotationXVelocity;
  Color color;
  double opacity;
  Path? customPath;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.angle,
    required this.angularVelocity,
    required this.rotationX,
    required this.rotationXVelocity,
    required this.color,
    required this.opacity,
    this.customPath,
  });

  void update(double gravity, double drag) {
    x += vx;
    y += vy;
    vy += gravity;
    vx *= drag;
    vy *= drag;
    angle += angularVelocity;
    rotationX += rotationXVelocity;
    opacity -= 0.003;
    if (opacity < 0) opacity = 0;
  }
}

class _ConfettiWidgetState extends State<ConfettiWidget> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();
  double _timeSinceLastEmission = 0;
  DateTime? _playStartTime;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.confettiController.addListener(_onControllerChanged);
    if (widget.confettiController.isPlaying) {
      _start();
    }
  }

  @override
  void dispose() {
    widget.confettiController.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.confettiController.isPlaying) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    _playStartTime = DateTime.now();
    _ticker.start();
    _burst(30); // Immediate initial burst
  }

  void _stop() {
    _ticker.stop();
    setState(() {
      _particles.clear();
    });
  }

  void _burst(int count) {
    if (!mounted) return;
    for (int i = 0; i < count; i++) {
      _particles.add(_createParticle(const Size(400, 800))); // Default size fallback, actual updated on draw
    }
  }

  _ConfettiParticle _createParticle(Size canvasSize) {
    final colors = widget.colors ?? [
      Colors.amber,
      Colors.pink,
      Colors.purple,
      Colors.cyan,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.blue,
    ];
    final color = colors[_random.nextInt(colors.length)];

    final angle = widget.blastDirectionality == BlastDirectionality.explosive
        ? _random.nextDouble() * 2 * pi
        : pi / 2 + (_random.nextDouble() - 0.5) * (pi / 3); // Downwards directional arc

    final force = widget.minBlastForce + _random.nextDouble() * (widget.maxBlastForce - widget.minBlastForce);

    // Initial position centered at emitter top-center
    final double startX = canvasSize.width / 2;
    final double startY = 0;

    final double vx = cos(angle) * force * 0.5;
    final double vy = sin(angle) * force * 0.5;

    final size = 8.0 + _random.nextDouble() * 12.0;

    Path? customPath;
    if (widget.createParticlePath != null) {
      customPath = widget.createParticlePath!(Size(size, size));
    }

    return _ConfettiParticle(
      x: startX,
      y: startY,
      vx: vx,
      vy: vy,
      size: size,
      angle: _random.nextDouble() * 2 * pi,
      angularVelocity: (_random.nextDouble() - 0.5) * 0.2,
      rotationX: _random.nextDouble() * 2 * pi,
      rotationXVelocity: (_random.nextDouble() - 0.5) * 0.3,
      color: color,
      opacity: 1.0,
      customPath: customPath,
    );
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    if (_playStartTime != null && !widget.shouldLoop) {
      final runningDuration = DateTime.now().difference(_playStartTime!);
      if (runningDuration > widget.confettiController.duration) {
        widget.confettiController.stop();
        return;
      }
    }

    // Gradual emission
    _timeSinceLastEmission += 0.016; // Approx seconds per frame at 60fps
    if (_timeSinceLastEmission >= widget.emissionFrequency) {
      _timeSinceLastEmission = 0;
      final newParticlesCount = widget.numberOfParticles;
      for (int i = 0; i < newParticlesCount; i++) {
        _particles.add(_createParticle(context.size ?? const Size(400, 800)));
      }
    }

    // Update existing particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.update(widget.gravity, 0.98); // 0.98 air drag

      // Remove if faded out or fell way off screen
      if (p.opacity <= 0 || (context.size != null && p.y > context.size!.height + 50)) {
        _particles.removeAt(i);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _ConfettiPainter(_particles),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      // Simulate 3D flip/rotation by scaling Y coordinate
      final scaleY = sin(p.rotationX);
      canvas.scale(1.0, scaleY.abs());

      if (p.customPath != null) {
        canvas.drawPath(p.customPath!, paint);
      } else {
        // Fallback to simple rectangle
        final halfSize = p.size / 2;
        canvas.drawRect(Rect.fromLTRB(-halfSize, -halfSize, halfSize, halfSize), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
