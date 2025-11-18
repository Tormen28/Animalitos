import 'package:flutter/foundation.dart';

/// Configuración centralizada de la aplicación
class AppConfig {
  // Información de la app
  static const String appName = 'Animalitos Lottery';
  static const String appVersion = '1.0.0';

  // Configuración de Supabase
  static String get supabaseUrl => const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://amjjpsiezxwcpwvbvtrs.supabase.co',
      );

  static String get supabaseAnonKey => const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFtampwc2llendjcHd2YnZ0cnMiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY5ODc4MzQ4MywiZXhwIjoxNzMwMzE5NDgzfQ.example',
      );

  // Configuración de timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuración de lotería
  static const int maxAnimalitosPorSorteo = 38;
  static const double precioBoletoBase = 1.0;
  static const int limiteBoletosPorUsuario = 10;

  // Paths de assets
  static String animalitoAssetPath(int numero) => 'imgAn/${numero + 1}.png';
  static String animalitoAssetPathById(int id) => 'assets/images/animalitos/animalito_${id.toString().padLeft(2, '0')}.png';

  // Configuración de UI
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;

  // Colores principales
  static const int primaryColorValue = 0xFFCC0000; // Rojo pasión
  static const int secondaryColorValue = 0xFF006400; // Verde esmeralda
  static const int accentColorValue = 0xFFFFD700; // Dorado

  // Configuración de debug
  static bool get isDebugMode => kDebugMode;
  static bool get enableLogging => kDebugMode;

  // Validaciones
  static final RegExp uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // Métodos de validación
  static bool isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return uuidRegex.hasMatch(value);
  }

  static bool isValidEmail(String? value) {
    if (value == null || value.isEmpty) return false;
    return emailRegex.hasMatch(value);
  }

  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 10000; // Máximo 10,000 Bs por apuesta
  }

  // Configuración de animaciones
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Configuración de caché
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const int maxCacheSize = 100;

  // Configuración de logging
  static void log(String message, {String? tag}) {
    if (enableLogging) {
      final timestamp = DateTime.now().toIso8601String();
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('[$timestamp]$logTag $message');
    }
  }

  static void logError(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (enableLogging) {
      final timestamp = DateTime.now().toIso8601String();
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('[$timestamp]$logTag ❌ ERROR: $message');
      if (error != null) debugPrint('[$timestamp]$logTag Error details: $error');
      if (stackTrace != null) debugPrint('[$timestamp]$logTag Stack trace: $stackTrace');
    }
  }

  static void logSuccess(String message, {String? tag}) {
    if (enableLogging) {
      final timestamp = DateTime.now().toIso8601String();
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('[$timestamp]$logTag ✅ SUCCESS: $message');
    }
  }
}