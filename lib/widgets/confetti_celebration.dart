import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// Widget que muestra una animación de confeti sobre su widget hijo.
///
/// Este widget utiliza el paquete `confetti` para mostrar una animación
/// de confeti que cae desde la parte superior de la pantalla.
class ConfettiCelebration extends StatefulWidget {
  /// El widget que se mostrará debajo de la animación de confeti.
  final Widget child;
  
  /// Si es `true`, la animación de confeti se reproducirá automáticamente.
  final bool isPlaying;
  
  /// La duración de la animación de confeti.
  final Duration duration;
  
  /// Crea un nuevo [ConfettiCelebration].
  ///
  /// El parámetro [child] es obligatorio y representa el contenido que
  /// se mostrará debajo de la animación de confeti.
  const ConfettiCelebration({
    super.key,
    required this.child,
    this.isPlaying = false,
    this.duration = const Duration(seconds: 5),
  });

  @override
  ConfettiCelebrationState createState() => ConfettiCelebrationState();

  /// Método estático para reproducir la animación desde fuera del widget.
  static void play(ConfettiCelebrationState state) => state.play();
  
  /// Método estático para detener la animación desde fuera del widget.
  static void stop(ConfettiCelebrationState state) => state.stop();
}

class ConfettiCelebrationState extends State<ConfettiCelebration> with SingleTickerProviderStateMixin {
  late ConfettiController _controller;
  bool _isPlaying = false;
  
  /// Reproduce la animación de confeti
  void play() {
    if (!_isPlaying) {
      setState(() => _isPlaying = true);
      _controller.play();
    }
  }
  
  /// Detiene la animación de confeti
  void stop() {
    if (_isPlaying) {
      _controller.stop();
      setState(() => _isPlaying = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.duration);
    _isPlaying = widget.isPlaying;
    if (_isPlaying) {
      _controller.play();
    }
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      _isPlaying = widget.isPlaying;
      if (_isPlaying) {
        _play();
      } else {
        _stop();
      }
    }
  }
  
  void _play() {
    _controller.play();
    setState(() {
      _isPlaying = true;
    });
  }
  
  void _stop() {
    _controller.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Confetti que cae desde arriba
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: true,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
            createParticlePath: drawStar,
          ),
        ),
        // Confetti que sube desde abajo
        Align(
          alignment: Alignment.bottomCenter,
          child: Transform.rotate(
            angle: 3.14, // 180 grados en radianes
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: true,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              createParticlePath: drawStar,
            ),
          ),
        ),
      ],
    );
  }

  // Dibuja una estrella para el confeti
  Path drawStar(Size size) {
    // Método para dibujar una estrella
    double degToRad(double deg) => deg * (3.14 / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(
          halfWidth + internalRadius * (step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}
