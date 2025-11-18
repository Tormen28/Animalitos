import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animalitos_lottery/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((authState) {
    return authState.session?.user;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value;
});

// Provider para obtener el saldo del usuario actual
final userSaldoProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;

  try {
    final response = await Supabase.instance.client
        .from('perfiles')
        .select('saldo')
        .eq('id', user.id)
        .single();

    return (response['saldo'] as num?)?.toDouble() ?? 0.0;
  } catch (e) {
    return 0.0;
  }
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  late final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;
  
  @override
  AsyncValue<User?> build() {
    _authService = ref.read(authServiceProvider);
    
    // Inicializar la suscripción si no existe
    _authSubscription?.cancel(); // Cancelar suscripción anterior si existe
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (authState) {
        state = AsyncValue.data(authState.session?.user);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
    
    return state;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    // No es necesario llamar a super.dispose() en Riverpod 3.0+
    // El StateNotifier de Riverpod 3.0+ maneja la limpieza automáticamente
  }

  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = AsyncValue.error('El correo y la contraseña son obligatorios', StackTrace.current);
      return;
    }
    
    try {
      state = const AsyncValue.loading();
      await _authService.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // El estado se actualizará a través del stream
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email, 
    required String password,
    required String nombre,
  }) async {
    if (email.isEmpty || password.isEmpty || nombre.isEmpty) {
      state = AsyncValue.error('Todos los campos son obligatorios', StackTrace.current);
      return;
    }
    
    if (password.length < 6) {
      state = AsyncValue.error('La contraseña debe tener al menos 6 caracteres', StackTrace.current);
      return;
    }
    try {
      state = const AsyncValue.loading();
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        nombre: nombre,
      );
      // El estado se actualizará a través del stream
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      state = const AsyncValue.loading();
      await _authService.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(AuthNotifier.new);
