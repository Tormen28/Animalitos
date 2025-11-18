import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animalitos_lottery/models/index.dart';
import 'package:animalitos_lottery/services/loteria_service.dart';
import 'package:animalitos_lottery/providers/auth_provider.dart';
import 'package:riverpod/riverpod.dart';

final loteriaServiceProvider = Provider<LoteriaService>((ref) {
  return LoteriaService();
});

// Proveedor para la lista de animalitos
final animalitosProvider = FutureProvider<List<Animalito>>((ref) async {
  final loteriaService = ref.watch(loteriaServiceProvider);
  return await loteriaService.getAnimalitos();
});

// Proveedor para la lista de sorteos
final sorteosProvider = FutureProvider<List<Sorteo>>((ref) async {
  final loteriaService = ref.watch(loteriaServiceProvider);
  return await loteriaService.getSorteos();
});

// Proveedor para las apuestas del usuario
final misApuestasProvider = FutureProvider<List<Apuesta>>((ref) async {
  final loteriaService = ref.watch(loteriaServiceProvider);
  try {
    return await loteriaService.getMisApuestas();
  } catch (e) {
    // Si hay un error de autenticación, devuelve una lista vacía
    return [];
  }
});

// Proveedor para el resultado de un sorteo específico
final resultadoSorteoProvider = FutureProvider.family<Resultado?, int>((ref, sorteoId) async {
  final loteriaService = ref.watch(loteriaServiceProvider);
  return await loteriaService.getResultadoSorteo(sorteoId);
});

// Estado para el proveedor de apuestas
class ApuestaState {
  final bool isLoading;
  final String? error;
  final List<Apuesta> apuestas;

  const ApuestaState({
    this.isLoading = false,
    this.error,
    this.apuestas = const [],
  });

  ApuestaState copyWith({
    bool? isLoading,
    String? error,
    List<Apuesta>? apuestas,
  }) {
    return ApuestaState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      apuestas: apuestas ?? this.apuestas,
    );
  }
}

/// Notifier para manejar el estado de las apuestas
class ApuestaNotifier extends Notifier<ApuestaState> {
  late final LoteriaService _loteriaService;
  StreamSubscription? _subscription;

  @override
  ApuestaState build() {
    _loteriaService = ref.read(loteriaServiceProvider);
    return const ApuestaState();
  }
  
  Future<void> _init() async {
    // Inicializar cualquier suscripción o estado inicial aquí
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
  }

  Future<void> realizarApuestaMultiple({
    required int sorteoId,
    required Map<int, double> apuestas,
    String? usuarioId,
  }) async {
    // Bandera para saber si la operación fue cancelada
    bool isCancelled = false;

    // Si el provider es desechado, marca la bandera como true
    ref.onDispose(() {
      isCancelled = true;
    });

    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = usuarioId ?? ref.read(currentUserProvider)?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _loteriaService.realizarApuestaMultiple(
        userId: userId,
        sorteoId: sorteoId,
        apuestas: apuestas,
      );

      // Verificar si el provider fue desechado antes de actualizar el estado
      if (isCancelled) {
        return; // No intentes actualizar el estado si fue desechado
      }

      // Actualizar el estado con éxito
      state = state.copyWith(
        isLoading: false,
        apuestas: [
          ...state.apuestas,
          // Aquí podrías querer agregar las nuevas apuestas a la lista
        ],
      );

      // Invalidamos los proveedores que necesitan actualizarse
      ref.invalidate(misApuestasProvider);
      ref.invalidate(userSaldoProvider);

    } catch (e, stackTrace) {
      // Verificar si el provider fue desechado antes de actualizar el estado de error
      if (isCancelled) {
        return; // No intentes actualizar el estado si fue desechado
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

final apuestaNotifierProvider = NotifierProvider.autoDispose<ApuestaNotifier, ApuestaState>(ApuestaNotifier.new);

// Proveedor para obtener un animalito por su ID
final animalitoPorIdProvider = Provider.family<AsyncValue<Animalito?>, int>((ref, id) {
  final animalitos = ref.watch(animalitosProvider);
  return animalitos.when(
    data: (animalitos) {
      try {
        return AsyncValue.data(animalitos.firstWhere((a) => a.id == id));
      } catch (e) {
        return AsyncValue.error('Animalito no encontrado', StackTrace.current);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Proveedor para obtener un sorteo por su ID
final sorteoPorIdProvider = Provider.family<AsyncValue<Sorteo?>, int>((ref, id) {
  final sorteos = ref.watch(sorteosProvider);
  return sorteos.when(
    data: (sorteos) {
      try {
        return AsyncValue.data(sorteos.firstWhere((s) => s.id == id));
      } catch (e) {
        return AsyncValue.error('Sorteo no encontrado', StackTrace.current);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Proveedor para obtener las apuestas de un sorteo específico
final apuestasPorSorteoProvider = Provider.family<List<Apuesta>, int>((ref, sorteoId) {
  final apuestas = ref.watch(misApuestasProvider);
  return apuestas.when(
    data: (apuestas) => apuestas.where((a) => a.sorteo.id == sorteoId).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Proveedor para obtener el total apostado en un sorteo
final totalApostadoPorSorteoProvider = Provider.family<double, int>((ref, sorteoId) {
  final apuestas = ref.watch(apuestasPorSorteoProvider(sorteoId));
  return apuestas.fold(0.0, (sum, apuesta) => sum + apuesta.montoApostado);
});

// Proveedor para verificar si un animalito ya fue apostado en un sorteo
final animalitoApostadoEnSorteoProvider = Provider.family<bool, (int, int)>((ref, params) {
  final (sorteoId, animalitoId) = params;
  final apuestas = ref.watch(apuestasPorSorteoProvider(sorteoId));
  return apuestas.any((a) => a.animalito.id == animalitoId);
});
