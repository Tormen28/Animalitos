import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../widgets/confetti_celebration.dart';

/// Estado para el widget [ConfettiCelebration].
///
/// Maneja la lógica de la animación de confeti.
class ConfettiCelebrationState extends State<ConfettiCelebration> {
  late ConfettiController _controller;
  bool _isPlaying = false;

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
        _controller.play();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reproduce la animación de confeti.
  void play() {
    _controller.play();
  }

  /// Detiene la animación de confeti.
  void stop() {
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Widget hijo que se mostrará debajo del confeti
        widget.child,
        
        // Capa de confeti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            shouldLoop: true,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }
}
