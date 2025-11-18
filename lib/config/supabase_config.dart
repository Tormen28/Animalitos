import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static late final String supabaseUrl;
  static late final String supabaseAnonKey;
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Inicializa la configuración de Supabase con variables de entorno
  static Future<void> initialize() async {
    try {
      // Cargar variables de entorno (Web usa assets/.env)
      try {
        await dotenv.load(fileName: 'assets/.env');
      } catch (_) {
        // Fallback para entornos no web o si el asset no existe
        await dotenv.load(fileName: '.env');
      }
      
      // Obtener valores de las variables de entorno
      supabaseUrl = dotenv.maybeGet('SUPABASE_URL') ?? '';
      supabaseAnonKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';
      
      // Validar que las variables de entorno estén presentes
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Faltan las credenciales de Supabase en assets/.env (.env).');
      }

      // Inicializar Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        // authFlowType: AuthFlowType.pkce,  // Comentado temporalmente - no disponible en esta versión
        debug: dotenv.get('DEBUG', fallback: 'false').toLowerCase() == 'true',
      );

      _initialized = true;
      
      if (kDebugMode) {
        print('✅ Supabase inicializado correctamente');
      }
    } catch (e, stackTrace) {
      _initialized = false;
      if (kDebugMode) {
        print('❌ Error al inicializar Supabase: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static User? get currentUser => auth.currentUser;
}
