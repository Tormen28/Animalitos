import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../error/app_exception.dart';
import '../config/app_config.dart';

/// Servicio base que proporciona funcionalidades comunes a todos los servicios
abstract class BaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseClient get supabase => _supabase;

  /// Obtiene el usuario actualmente autenticado
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated => currentUserId != null;

  /// Ejecuta una operación de base de datos con manejo de errores consistente
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      debugPrint('🔄 Ejecutando operación${operationName != null ? ': $operationName' : ''}');
      final result = await operation();
      debugPrint('✅ Operación completada exitosamente${operationName != null ? ': $operationName' : ''}');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Error en operación${operationName != null ? ': $operationName' : ''}: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Convertir errores comunes de Supabase a nuestras excepciones personalizadas
      if (e is PostgrestException) {
        if (e.code == 'PGRST116') {
          throw DatabaseException('No se encontraron resultados para la consulta');
        } else if (e.code == '23505') {
          throw ValidationException('Ya existe un registro con estos datos');
        } else if (e.code == '23503') {
          throw ValidationException('Referencia a datos inexistentes');
        } else {
          throw DatabaseException('Error en la base de datos: ${e.message}');
        }
      } else if (e is AuthException) {
        throw AuthException('Error de autenticación: ${e.message}');
      } else if (e is NetworkException) {
        throw NetworkException('Error de conexión: ${e.message}');
      } else {
        throw AppException('Error inesperado: ${e.toString()}');
      }
    }
  }

  /// Verifica permisos de administrador
  Future<bool> _isAdmin() async {
    if (!isAuthenticated) return false;

    try {
      final response = await _supabase
          .from('perfiles')
          .select('es_admin')
          .eq('id', currentUserId!)
          .single();

      return response['es_admin'] == true;
    } catch (e) {
      debugPrint('Error verificando permisos de admin: $e');
      return false;
    }
  }

  /// Requiere permisos de administrador, lanza excepción si no los tiene
  Future<void> requireAdmin() async {
    final isAdmin = await _isAdmin();
    if (!isAdmin) {
      throw AuthException('Se requieren permisos de administrador');
    }
  }

  /// Valida que un ID de usuario sea válido
  void validateUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      throw ValidationException('ID de usuario requerido');
    }

    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    if (!uuidRegex.hasMatch(userId)) {
      throw ValidationException('ID de usuario inválido');
    }
  }

  /// Valida que un monto sea positivo
  void validatePositiveAmount(double amount, {String fieldName = 'monto'}) {
    if (amount <= 0) {
      throw ValidationException('El $fieldName debe ser mayor a cero');
    }
  }

  /// Valida que una lista no esté vacía
  void validateNotEmpty<T>(List<T> list, {String fieldName = 'lista'}) {
    if (list.isEmpty) {
      throw ValidationException('La $fieldName no puede estar vacía');
    }
  }
}