import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;
  
  // Stream de autenticación
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Obtener el usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  // Obtener el ID del usuario actual
  String? get currentUserId => currentUser?.id;

  // Verificar si el usuario está autenticado
  bool get isAuthenticated => currentUser != null;

  // Verificar si el usuario es administrador
  Future<bool> get isAdmin async {
    if (currentUser == null) return false;
    
    final userData = await _supabase
        .from('perfiles')
        .select('es_admin')
        .eq('id', currentUser!.id)
        .single()
        .catchError((_) => null);
    
    if (userData == null) return false;
    return userData['es_admin'] == true;
  }

  // Garantiza que exista el perfil del usuario autenticado (útil tras confirmar email y abrir la app)
  Future<void> ensureProfileForCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _upsertProfileIfMissing(
      userId: user.id,
      email: user.email ?? '',
    );
  }
  // Crea el perfil si no existe (usa la sesión actual para pasar RLS)
  Future<void> _upsertProfileIfMissing({
    required String userId,
    required String email,
    String? nombre,
    String? apellido,
    String? telefono,
  }) async {
    try {
      final existing = await _supabase
          .from('perfiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('perfiles').insert({
          'id': userId,
          'email': email,
          if (nombre != null) 'nombre': nombre,
          if (apellido != null) 'apellido': apellido,
          if (telefono != null) 'telefono': telefono,
          'es_admin': false,
          'bloqueado': false,
        });
      }
    } catch (e) {
      debugPrint('Error al crear perfil si faltaba: $e');
    }
  }

  // Iniciar sesión con correo y contraseña
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      // Asegurar que el perfil exista al iniciar sesión (ya hay sesión => JWT válido para RLS)
      if (resp.session != null && resp.user != null) {
        await _upsertProfileIfMissing(
          userId: resp.user!.id,
          email: email.trim(),
        );
      }
      return resp;
    } catch (e) {
      debugPrint('Error en inicio de sesión: $e');
      rethrow;
    }
  }

  // Registrar un nuevo usuario
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String nombre,
    String? apellido,
    String? telefono,
  }) async {
    try {
      // 1. Registrar el usuario en Auth
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        // Para Web: redirigir al mismo origen (localhost:puerto) tras confirmar email
        emailRedirectTo: kIsWeb ? Uri.base.origin : 'animalitos://login-callback',
      );

      // 2. Si HAY sesión inmediata (confirmación desactivada), crear el perfil ahora.
      //    Si NO hay sesión (confirmación por email activa), se creará en el primer inicio de sesión.
      if (response.session != null && response.user != null) {
        await _upsertProfileIfMissing(
          userId: response.user!.id,
          email: email.trim(),
          nombre: nombre.trim(),
          apellido: apellido?.trim(),
          telefono: telefono,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error en registro: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? null : 'animalitos://reset-password',
      );
    } catch (e) {
      debugPrint('Error al restablecer contraseña: $e');
      rethrow;
    }
  }

  // Actualizar perfil de usuario
  Future<void> updateProfile({
    required String userId,
    String? nombre,
    String? apellido,
    String? telefono,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (nombre != null) updates['nombre'] = nombre.trim();
      if (apellido != null) updates['apellido'] = apellido.trim();
      if (telefono != null) updates['telefono'] = telefono.trim();
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('perfiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error al actualizar perfil: $e');
      rethrow;
    }
  }

  // Obtener perfil del usuario actual
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    try {
      final profile = await _supabase
          .from('perfiles')
          .select()
          .eq('id', currentUser!.id)
          .single()
          .catchError((_) => null);

      debugPrint('👤 Perfil obtenido: $profile');
      debugPrint('💰 Saldo del usuario: ${profile?['saldo']}');

      return profile;
    } catch (e) {
      debugPrint('Error al obtener perfil: $e');
      return null;
    }
  }

  // Verificar si el usuario está bloqueado
  Future<bool> isUserBlocked() async {
    if (currentUser == null) return false;
    
    try {
      final data = await _supabase
          .from('perfiles')
          .select('bloqueado')
          .eq('id', currentUser!.id)
          .single();
          
      return data['bloqueado'] == true;
    } catch (e) {
      debugPrint('Error al verificar estado de bloqueo: $e');
      return false;
    }
  }
}
