import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'states/draw_animation_state.dart';

/// Widget que muestra una animación de sorteo con un resultado final.
///
/// Este widget muestra una animación de carga seguida de un resultado.
/// Permite reiniciar la animación mediante un botón.
class DrawAnimation extends StatefulWidget {
  /// Lista de animalitos que pueden salir en el sorteo
  final List<String> animalitos;
  
  /// Duración total de la animación
  final Duration animationDuration;
  
  /// Función que se llama cuando la animación se completa con el resultado
  final Function(String) onAnimationComplete;

  /// Crea un nuevo [DrawAnimation].
  ///
  /// El parámetro [animalitos] es obligatorio y debe contener al menos un elemento.
  /// [animationDuration] define la duración total de la animación (por defecto 5 segundos).
  /// [onAnimationComplete] es una función de devolución de llamada que se ejecuta cuando
  /// la animación termina, proporcionando el resultado del sorteo.
  const DrawAnimation({
    super.key,
    required this.animalitos,
    this.animationDuration = const Duration(seconds: 5),
    required this.onAnimationComplete,
  });

  @override
  DrawAnimationState createState() => DrawAnimationState();

  /// Inicia manualmente la animación del sorteo.
  /// Útil cuando se necesita activar la animación desde fuera del widget.
  /// Inicia manualmente la animación del sorteo.
  /// Útil cuando se necesita activar la animación desde fuera del widget.
  static void startAnimation(DrawAnimationState state) {
    state.startAnimation();
  }
}
