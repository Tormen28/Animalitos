import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Configuración
import 'config/supabase_config.dart';
import 'core/error/error_handler.dart';
import 'core/widgets/loading_screen.dart';

// Servicios
import 'services/auth_service.dart';

// Pantallas
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/apuesta_screen.dart';
import 'screens/history/enhanced_history_screen.dart';
import 'screens/stats/stats_screen.dart';
// Admin
import 'screens/admin/admin_screen.dart';

// Widgets
import 'widgets/main_navigation.dart';

// Utilidades
import 'utils/constants.dart';

Future<void> main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  // Permitir fetch de GoogleFonts en runtime si se usa
  GoogleFonts.config.allowRuntimeFetching = true;

  try {
    // Inicializar Supabase ANTES de construir el árbol de widgets
    await SupabaseConfig.initialize();

    // Garantizar que el perfil exista si ya hay sesión (por ejemplo, tras confirmar email y volver)
    final _authServiceForInit = AuthService();
    await _authServiceForInit.ensureProfileForCurrentUser();

    // También escuchar cambios de autenticación para crear el perfil cuando se inicie sesión
    SupabaseConfig.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        _authServiceForInit.ensureProfileForCurrentUser();
      }
    });

    // Iniciar la app normalmente
    runApp(
      ProviderScope(
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Mostrar pantalla de error si falla la inicialización
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    'Error de inicialización',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudo inicializar la aplicación. Verifica la configuración.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Reiniciar la aplicación
                      main();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// Proveedor para el router
final routerProvider = Provider<GoRouter>((ref) {
  final authService = AuthService();
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = authService.isAuthenticated;
      final path = state.uri.toString();
      final isLoginRoute = path.endsWith('/login') || path.endsWith('/register');
      
      // Si el usuario no está autenticado y no está en una ruta de autenticación, redirigir a login
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      
      // Si el usuario está autenticado y en una ruta de login/registro, redirigir según rol
      if (isLoggedIn && isLoginRoute) {
        final isAdmin = await authService.isAdmin;
        return isAdmin ? '/admin' : '/home';
      }
      
      // Si el usuario está en la raíz, redirigir a home
      if (path == '/') {
        return '/home';
      }
      
      // No redirigir si no es necesario
      return null;
    },
    routes: [
      // Rutas públicas
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Ruta principal con navegación
      GoRoute(
        path: '/home',
        builder: (context, state) => MainNavigation(
          currentIndex: 0,
          child: const HomeScreen(),
        ),
        routes: [
          // Subrutas que necesitan la navegación principal
          GoRoute(
            path: 'bet/:sorteoId',
            builder: (context, state) {
              final sorteoId = int.parse(state.pathParameters['sorteoId']!);
              // TODO: Need to get sorteo object here instead of just ID
              return MainNavigation(
                currentIndex: 0,
                child: Container(), // Placeholder - will need to be updated
              );
            },
          ),
        ],
      ),
      
      // Ruta de perfil con navegación
      GoRoute(
        path: '/profile',
        builder: (context, state) => MainNavigation(
          currentIndex: 3,
          child: const ProfileScreen(),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => MainNavigation(
              currentIndex: 3,
              child: const EditProfileScreen(),
            ),
          ),
        ],
      ),
      
      // Ruta de historial con navegación
      GoRoute(
        path: '/history',
        builder: (context, state) => MainNavigation(
          currentIndex: 2,
          child: const EnhancedHistoryScreen(),
        ),
      ),
      
      // Ruta de estadísticas con navegación
      GoRoute(
        path: '/stats',
        builder: (context, state) => MainNavigation(
          currentIndex: 1,
          child: const StatsScreen(),
        ),
      ),
      
      // Ruta de apuesta con parámetro sorteoId - REMOVED: Only multiple bets now
      
      // Ruta de administración
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: dotenv.get('APP_NAME', fallback: 'Animalitos Lottery'),
      debugShowCheckedModeBanner: dotenv.get('DEBUG', fallback: 'false').toLowerCase() == 'true' ? true : false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          surface: AppConstants.surfaceColor,
          background: AppConstants.backgroundColor,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppConstants.textColor,
          onBackground: AppConstants.textColor,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        // Se usará la tipografía definida en AppConstants más abajo
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            side: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingM,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            borderSide: const BorderSide(color: AppConstants.borderColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            borderSide: const BorderSide(color: AppConstants.borderColor, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            borderSide: const BorderSide(color: AppConstants.secondaryColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            borderSide: const BorderSide(color: AppConstants.errorColor, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            borderSide: const BorderSide(color: AppConstants.errorColor, width: 2.0),
          ),
          labelStyle: AppConstants.bodyMedium.copyWith(
            color: AppConstants.hintColor,
          ),
          hintStyle: AppConstants.bodyMedium.copyWith(
            color: AppConstants.hintColor,
          ),
          errorStyle: AppConstants.caption.copyWith(
            color: AppConstants.errorColor,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: AppConstants.heading1,
          displayMedium: AppConstants.heading2,
          displaySmall: AppConstants.heading3,
          headlineMedium: AppConstants.heading4,
          bodyLarge: AppConstants.bodyLarge,
          bodyMedium: AppConstants.bodyMedium,
          bodySmall: AppConstants.bodySmall,
          labelLarge: AppConstants.button,
          labelMedium: AppConstants.button.copyWith(fontSize: 14),
          labelSmall: AppConstants.caption,
        ),
        iconTheme: const IconThemeData(
          color: AppConstants.textColor,
          size: AppConstants.iconSizeM,
        ),
        dividerTheme: const DividerThemeData(
          color: AppConstants.borderColor,
          thickness: 1.0,
          space: 1.0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppConstants.textColor,
          contentTextStyle: AppConstants.bodyMedium.copyWith(
            color: AppConstants.surfaceColor,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppConstants.surfaceColor,
          selectedItemColor: AppConstants.accentColor,
          unselectedItemColor: AppConstants.hintColor,
          elevation: 4.0,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
      routerConfig: router,
    );
  }
}
