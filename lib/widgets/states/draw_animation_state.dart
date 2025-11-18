import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../draw_animation.dart';

// Importar el archivo de constantes si existe
// import '../../../constants/app_constants.dart';

/// Estado para el widget [DrawAnimation].
///
/// Maneja la lógica de animación y estado del sorteo.
class DrawAnimationState extends State<DrawAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;
  bool _isAnimating = false;
  bool _showResult = false;
  String? _resultado;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
        }
      });

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  /// Inicia la animación del sorteo.
  Future<void> startAnimation() async {
    if (_isAnimating) return;
    
    if (!mounted) return;
    
    setState(() {
      _isAnimating = true;
      _showResult = false;
      _resultado = null;
    });
    
    final startTime = DateTime.now();

    // Fase 1: Animación rápida
    while (DateTime.now().difference(startTime).inMilliseconds <
           widget.animationDuration.inMilliseconds * 0.7) {
      if (!mounted) return;

      setState(() {
        _currentIndex = ((_currentIndex + 1) % widget.animalitos.length).toInt();
      });

      await _controller.forward(from: 0);

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final delay = (100 - (elapsed ~/ 200)).clamp(10, 100);

      await Future.delayed(Duration(milliseconds: delay));
    }

    // Fase 2: Desaceleración
    while (DateTime.now().difference(startTime).inMilliseconds <
           widget.animationDuration.inMilliseconds * 0.9) {
      setState(() {
        _currentIndex = ((_currentIndex + 1) % widget.animalitos.length).toInt();
      });
      await _controller.forward(from: 0).then((_) => _controller.reset());
      await Future.delayed(Duration(
        milliseconds: 150 - (DateTime.now().difference(startTime).inMilliseconds ~/ 300),
      ));
    }

    // Fase 3: Resultado final
    _resultado = widget.animalitos[_currentIndex];
    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete(_resultado!);
    }

    setState(() {
      _isAnimating = false;
      _showResult = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_showResult) ...[
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withAlpha((0.1 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Lottie.asset(
                'assets/animations/spinner.json',
                width: 100,
                height: 100,
              ),
            ),
          ),
        ] else ...[
          Container(
            width: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¡Salió!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _resultado ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
        if (!_isAnimating)
          ElevatedButton(
            onPressed: startAnimation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              _showResult ? 'Volver a sortear' : 'Iniciar sorteo',
              style: const TextStyle(fontSize: 16),
            ),
          ) else
          const CircularProgressIndicator(),
      ],
    );
  }
}
