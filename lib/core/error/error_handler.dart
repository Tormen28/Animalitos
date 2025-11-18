import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_exception.dart';

/// Proveedor para el manejador de errores global
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

/// Clase para manejar errores de manera global
class ErrorHandler {
  /// Maneja un error de manera global
  /// [error] El error que se produjo
  /// [stackTrace] El stack trace del error
  /// [context] El contexto de la aplicación (opcional)
  /// [showSnackbar] Si se debe mostrar un snackbar con el error
  Future<void> handleError({
    required dynamic error,
    required StackTrace stackTrace,
    BuildContext? context,
    bool showSnackbar = true,
  }) async {
    // Registrar el error en la consola
    _logError(error, stackTrace);

    // Convertir el error a una AppException
    final exception = _convertToAppException(error, stackTrace);
    
    // Mostrar el error en la interfaz de usuario si es necesario
    if (context != null && showSnackbar) {
      _showErrorSnackbar(context, exception);
    }

    // Aquí podrías agregar más lógica, como enviar el error a un servicio de monitoreo
    // await _sendToCrashlytics(exception, stackTrace);
  }

  /// Convierte un error genérico a una AppException
  AppException _convertToAppException(dynamic error, StackTrace stackTrace) {
    if (error is AppException) {
      return error;
    } else if (error is FormatException) {
      return ValidationException('Error de formato en los datos: ${error.message}');
    } else if (error is TimeoutException) {
      return NetworkException('Tiempo de espera agotado');
    } else if (error is NoSuchMethodError) {
      return AppException('Método no encontrado', code: 'method_not_found', originalError: error);
    } else if (error is TypeError) {
      return AppException('Error de tipo', code: 'type_error', originalError: error);
    } else if (error is ArgumentError) {
      return ValidationException('Argumento inválido: ${error.message ?? error.toString()}');
    } else if (error is StateError) {
      return AppException('Error de estado: ${error.message}', code: 'state_error', originalError: error);
    } else if (error is RangeError) {
      return ValidationException('Error de rango: ${error.message}');
    } else if (error is UnsupportedError) {
      return AppException('Operación no soportada: ${error.message}', code: 'unsupported_operation', originalError: error);
    } else if (error is String) {
      return AppException(error, code: 'unknown_error');
    } else {
      return AppException('Error desconocido: ${error.toString()}', code: 'unknown_error', originalError: error);
    }
  }

  /// Muestra un snackbar con el error
  void _showErrorSnackbar(BuildContext context, AppException exception) {
    // Usar un postFrameCallback para asegurarnos de que el contexto sea válido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'CERRAR',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  /// Registra el error en la consola
  void _logError(dynamic error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('''
===================================================
🚨 ERROR NO MANEJADO 🚨
🔥 Tipo: ${error.runtimeType}
📝 Mensaje: ${error.toString()}
📍 StackTrace: $stackTrace
===================================================
''');
    }
  }

  /// Ejecuta una función y maneja cualquier error que pueda ocurrir
  /// [fn] La función a ejecutar
  /// [context] El contexto de la aplicación (opcional)
  /// [onError] Función de devolución de llamada para manejar el error personalizado
  Future<T> runWithErrorHandling<T>({
    required Future<T> Function() fn,
    BuildContext? context,
    FutureOr<T> Function(AppException)? onError,
  }) async {
    try {
      return await fn();
    } catch (error, stackTrace) {
      final exception = _convertToAppException(error, stackTrace);
      
      // Mostrar el error en la interfaz de usuario si se proporciona un contexto
      if (context != null) {
        _showErrorSnackbar(context, exception);
      }
      
      // Si se proporciona un manejador de errores personalizado, usarlo
      if (onError != null) {
        return await onError(exception);
      }
      
      // Relanzar la excepción si no se proporciona un manejador de errores personalizado
      // y no se puede manejar el error de otra manera
      if (context == null) {
        debugPrint('Error no manejado: $exception');
        rethrow;
      }
      
      // Retornar un valor predeterminado para evitar romper el flujo de la aplicación
      // Nota: Esto es solo para evitar errores de tipo, el valor real debe manejarse adecuadamente
      return Future.value() as T;
    }
  }
}

// Nota: Se eliminó la extensión sobre BuildContext que usaba read() para evitar
// dependencias de Provider desde el contexto. Use ErrorHandler directamente si es necesario.
