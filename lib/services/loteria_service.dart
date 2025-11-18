import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:animalitos_lottery/models/index.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoteriaService {
  final _supabase = Supabase.instance.client;

  // Obtener todos los animalitos
  Future<List<Animalito>> getAnimalitos() async {
    try {
      // En lugar de consultar Supabase, usar la lista estática del modelo
      // que ya tiene las rutas de imágenes correctas
      return Animalito.lottoActivoAnimalitos;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener todos los sorteos
  Future<List<Sorteo>> getSorteos() async {
    try {
      final response = await _supabase
          .from('sorteos')
          .select()
          .order('hora_cierre', ascending: true);

      return (response as List)
          .map((json) => Sorteo.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Realiza múltiples apuestas en un solo sorteo de manera atómica.
  ///
  /// [sorteoId]: El ID del sorteo en el que se realizarán las apuestas.
  /// [apuestas]: Un mapa donde la clave es el ID del animalito y el valor es el monto a apostar.
  ///
  /// Retorna un mapa con el resultado de la operación.
  /// Realiza múltiples apuestas en un solo sorteo de manera atómica.
  ///
  /// [userId]: ID del usuario que realiza la apuesta
  /// [sorteoId]: ID del sorteo en el que se realizarán las apuestas
  /// [apuestas]: Mapa donde la clave es el ID del animalito y el valor es el monto a apostar
  ///
  /// Retorna un mapa con el resultado de la operación.
  Future<Map<String, dynamic>> realizarApuestaMultiple({
    required String userId,
    required int sorteoId,
    required Map<int, double> apuestas,
  }) async {
    try {
      // Usar el userId pasado como parámetro en lugar de obtenerlo de auth
      final usuarioId = userId;
      if (usuarioId == null || usuarioId.isEmpty) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('🎯 Iniciando apuesta múltiple para usuario $usuarioId');
      debugPrint('🎲 Sorteo ID: $sorteoId');
      debugPrint('💰 Apuestas: $apuestas');

      // Validar que hay al menos una apuesta
      if (apuestas.isEmpty) {
        throw Exception('Debes seleccionar al menos un animalito para apostar');
      }

      // Calcular el monto total
      final montoTotal = apuestas.values.fold(0.0, (sum, monto) => sum + monto);
      if (montoTotal <= 0) {
        throw Exception('El monto total debe ser mayor a cero');
      }

      debugPrint('💵 Monto total a apostar: $montoTotal');

      // Verificar montos positivos
      final apuestasInvalidas = apuestas.entries.where((e) => e.value <= 0);
      if (apuestasInvalidas.isNotEmpty) {
        throw Exception('Todos los montos deben ser mayores a cero');
      }

      // Verificar saldo del usuario antes de proceder
      final perfilUsuario = await _supabase
          .from('perfiles')
          .select('saldo')
          .eq('id', usuarioId)
          .single();

      final saldoActual = (perfilUsuario['saldo'] as num?)?.toDouble() ?? 0.0;
      debugPrint('💰 Saldo actual del usuario: $saldoActual');

      if (saldoActual < montoTotal) {
        throw Exception('Saldo insuficiente. Tienes $saldoActual Bs pero necesitas $montoTotal Bs');
      }

      // Preparar los datos de apuestas en el formato correcto para jsonb[]
      final apuestasArray = apuestas.entries
          .map((e) => {'animalito_id': e.key, 'monto': e.value})
          .toList();

      developer.log('Realizando apuesta múltiple: userId=$usuarioId, sorteoId=$sorteoId, apuestas=${apuestasArray.length}, montoTotal=$montoTotal');

      // Verificar que el sorteo esté abierto antes de proceder
      final sorteoData = await _supabase
          .from('sorteos')
          .select('estado, hora_cierre')
          .eq('id', sorteoId)
          .single();

      final estado = sorteoData['estado'] as String?;
      final horaCierreStr = sorteoData['hora_cierre'] as String?;
      final now = DateTime.now();

      // Parsear hora de cierre
      DateTime horaCierre;
      try {
        horaCierre = DateTime.parse(horaCierreStr!);
      } catch (e) {
        throw Exception('Error al parsear hora de cierre del sorteo');
      }

      // Verificar si el sorteo está abierto
      bool sorteoAbierto = false;
      if (estado == 'pendiente' || estado == 'abierto') {
        // Para sorteos pendientes o abiertos, verificar hora
        final cierreHoy = DateTime(
          now.year,
          now.month,
          now.day,
          horaCierre.hour,
          horaCierre.minute,
        );
        sorteoAbierto = now.isBefore(cierreHoy);
      }

      debugPrint('🔍 Verificación de sorteo: estado=$estado, hora_cierre=$horaCierre, ahora=$now, abierto=$sorteoAbierto');

      if (!sorteoAbierto) {
        throw Exception('El sorteo no está abierto para apuestas');
      }

      // Crear la apuesta principal primero
      final apuestaPrincipal = await _supabase
          .from('apuestas')
          .insert({
            'user_id': usuarioId,
            'sorteo_id': sorteoId,
            'monto_apostado': montoTotal,
            'fecha_juego': DateTime.now().toIso8601String().split('T')[0],
            'estado': 'pendiente',
            'monto_ganado': 0.0,
          })
          .select()
          .single();

      final apuestaId = apuestaPrincipal['id'];
      debugPrint('📋 Apuesta principal creada con ID: $apuestaId');

      // Crear los detalles de las apuestas
      final detallesAInsertar = apuestas.entries.map((entry) {
        return {
          'apuesta_id': apuestaId,
          'animalito_id': entry.key,
          'monto': entry.value,
        };
      }).toList();

      await _supabase
          .from('apuestas_detalle')
          .insert(detallesAInsertar);

      debugPrint('📋 Detalles de apuestas creados: ${detallesAInsertar.length}');

      // Actualizar el saldo del usuario
      final nuevoSaldo = saldoActual - montoTotal;
      await _supabase
          .from('perfiles')
          .update({'saldo': nuevoSaldo})
          .eq('id', usuarioId);

      debugPrint('💰 Saldo actualizado: $saldoActual -> $nuevoSaldo');

      // Obtener los detalles completos de la apuesta creada
      final apuestaData = await _supabase
          .from('apuestas')
          .select('''
            *,
            sorteos(*),
            apuestas_detalle:apuestas_detalle(
              *,
              animalitos(*)
            )
          ''')
          .eq('id', apuestaId)
          .single();

      // Obtener el sorteo
      final sorteo = Sorteo.fromJson(apuestaData['sorteos']);

      // Crear lista de apuestas realizadas
      final apuestasRealizadas = (apuestaData['apuestas_detalle'] as List).map((detalle) {
        return {
          'id': detalle['id'],
          'animalito': Animalito.fromJson(detalle['animalitos']),
          'monto': (detalle['monto'] as num).toDouble(),
        };
      }).toList();

      debugPrint('🎉 Apuesta múltiple realizada exitosamente');

      return {
        'success': true,
        'apuesta_id': apuestaId,
        'sorteo': sorteo,
        'apuestas': apuestasRealizadas,
        'monto_total': montoTotal,
        'saldo_anterior': saldoActual,
        'saldo_nuevo': nuevoSaldo,
      };
    } catch (e) {
      debugPrint('❌ Error en realizarApuestaMultiple: $e');
      developer.log('Error en realizarApuestaMultiple: $e');
      rethrow;
    }
  }

  // Obtener apuestas del usuario para un sorteo
  Future<Map<int, double>> getApuestasUsuario(int sorteoId) async {
    try {
      final usuarioId = _supabase.auth.currentUser?.id;
      if (usuarioId == null) {
        debugPrint('❌ Usuario no autenticado para obtener apuestas');
        return {};
      }

      debugPrint('🎯 Consultando apuestas existentes para usuario $usuarioId en sorteo $sorteoId');

      // Cambiar la consulta para evitar el error 406 - usar maybeSingle en lugar de single
      final response = await _supabase
          .from('apuestas')
          .select('''
            id,
            apuestas_detalle(
              animalito_id,
              monto
            )
          ''')
          .eq('user_id', usuarioId)
          .eq('sorteo_id', sorteoId)
          .maybeSingle();

      if (response == null) {
        debugPrint('🎯 No hay apuestas existentes para este usuario en este sorteo');
        return {};
      }

      final detalles = response['apuestas_detalle'] as List? ?? [];
      debugPrint('🎯 Encontradas ${detalles.length} apuestas existentes');

      return Map.fromEntries(
        detalles.map((d) => MapEntry(
              d['animalito_id'] as int,
              (d['monto'] as num).toDouble(),
            )),
      );
    } catch (e) {
      debugPrint('❌ Error al obtener apuestas existentes: $e');
      return {};
    }
  }


  // Obtener el historial de apuestas del usuario actual agrupadas por ticket
  Future<List<Map<String, dynamic>>> getMisApuestasAgrupadas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('📋 Cargando historial de apuestas agrupadas para usuario $userId');

      // Obtener apuestas principales agrupadas por fecha y sorteo
      final response = await _supabase
          .from('apuestas')
          .select('''
            id,
            user_id,
            sorteo_id,
            monto_apostado,
            fecha_juego,
            estado,
            monto_ganado,
            created_at,
            sorteos(
              id,
              nombre_sorteo,
              hora_cierre,
              estado,
              animalito_ganador:animalitos!animalito_ganador_id(
                id,
                nombre,
                numero_str
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      debugPrint('📊 Encontradas ${response.length} apuestas principales');

      if (response.isEmpty) {
        debugPrint('📋 No hay apuestas para este usuario');
        return [];
      }

      // Agrupar apuestas por ticket (mismo sorteo, misma fecha, mismo estado)
      final Map<String, Map<String, dynamic>> ticketsAgrupados = {};

      for (final apuestaData in response) {
        final sorteoId = apuestaData['sorteo_id'];
        final fechaJuego = apuestaData['fecha_juego'];
        final sorteoEstado = apuestaData['sorteos']['estado'];

        // Determinar el estado real basado en el estado del sorteo
        String estadoReal = apuestaData['estado'] ?? 'pendiente';
        if (sorteoEstado == 'finalizado' && estadoReal == 'pendiente') {
          // Si el sorteo está finalizado pero la apuesta sigue pendiente,
          // verificar si el usuario ganó
          final animalitoGanadorId = apuestaData['sorteos']['animalito_ganador']?['id'];

          // Buscar si el usuario apostó al animalito ganador
          final detallesResponse = await _supabase
              .from('apuestas_detalle')
              .select('animalito_id, monto')
              .eq('apuesta_id', apuestaData['id']);

          bool gano = false;
          double montoApostado = 0.0;

          for (final detalle in detallesResponse) {
            if (detalle['animalito_id'] == animalitoGanadorId) {
              gano = true;
              montoApostado = (detalle['monto'] as num).toDouble();
              break;
            }
          }

          if (gano) {
            estadoReal = 'ganadora';
            // Calcular ganancia real basada en el pozo total
            final totalApostadoGanador = await _calcularTotalApostadoAnimalito(sorteoId, animalitoGanadorId);
            final totalApostadoSorteo = await _calcularTotalApostadoSorteo(sorteoId);

            // Evitar división por cero
            final montoGanadoCalculado;
            if (totalApostadoGanador == 0) {
              debugPrint('⚠️ No hay apuestas al animalito ganador, ganancia = 0');
              montoGanadoCalculado = 0.0;
            } else {
              // Ganancia = (monto apostado al ganador / total apostado al ganador) * (total del sorteo * 0.9)
              // El 0.9 es porque la casa se queda con 10%
              final proporcionGanador = montoApostado / totalApostadoGanador;
              montoGanadoCalculado = (totalApostadoSorteo * 0.9) * proporcionGanador;

              debugPrint('💰 Cálculo de ganancia: apostado=$montoApostado, total_ganador=$totalApostadoGanador, total_sorteo=$totalApostadoSorteo, proporcion=$proporcionGanador, ganancia=$montoGanadoCalculado');
            }

            // Actualizar la apuesta en BD si no está actualizada
            await _supabase
                .from('apuestas')
                .update({
                  'estado': 'ganadora',
                  'monto_ganado': montoGanadoCalculado,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', apuestaData['id']);
          } else {
            estadoReal = 'perdedora';
            // Actualizar la apuesta en BD si no está actualizada
            await _supabase
                .from('apuestas')
                .update({
                  'estado': 'perdedora',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', apuestaData['id']);
          }
        }

        // Crear clave única para agrupar
        final ticketKey = '${sorteoId}_${fechaJuego}_${estadoReal}';

        if (!ticketsAgrupados.containsKey(ticketKey)) {
          ticketsAgrupados[ticketKey] = {
            'id': ticketKey,
            'sorteo': Sorteo.fromJson(apuestaData['sorteos']),
            'fecha_juego': DateTime.parse(fechaJuego),
            'estado': estadoReal,
            'monto_total': 0.0,
            'monto_ganado_total': 0.0,
            'apuestas': <Map<String, dynamic>>[],
            'created_at': DateTime.parse(apuestaData['created_at']),
            'animalito_ganador': apuestaData['sorteos']['animalito_ganador'],
          };
        }

        // Obtener detalles de esta apuesta específica
        final apuestaId = apuestaData['id'];
        final detallesResponse = await _supabase
            .from('apuestas_detalle')
            .select('''
              id,
              apuesta_id,
              animalito_id,
              monto,
              animalitos(
                id,
                nombre,
                numero_str,
                imagen_asset
              )
            ''')
            .eq('apuesta_id', apuestaId);

        // Agregar cada detalle al ticket
        for (final detalle in detallesResponse) {
          final animalito = Animalito.fromJson(detalle['animalitos']);
          final monto = (detalle['monto'] as num?)?.toDouble() ?? 0.0;

          ticketsAgrupados[ticketKey]!['apuestas'].add({
            'id': detalle['id'],
            'animalito': animalito,
            'monto': monto,
          });

          ticketsAgrupados[ticketKey]!['monto_total'] += monto;
        }

        // Sumar ganancias si es ganadora
        if (estadoReal == 'ganadora') {
          ticketsAgrupados[ticketKey]!['monto_ganado_total'] +=
              (apuestaData['monto_ganado'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Convertir a lista ordenada por fecha
      final tickets = ticketsAgrupados.values.toList()
        ..sort((a, b) => (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));

      debugPrint('✅ Retornando ${tickets.length} tickets agrupados');
      return tickets;

    } catch (e) {
      debugPrint('❌ Error al obtener historial de apuestas agrupadas: $e');
      rethrow;
    }
  }

  // Mantener el método anterior por compatibilidad
  Future<List<Apuesta>> getMisApuestas() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('📋 Cargando historial de apuestas para usuario $userId');

      // Consulta simplificada y directa - obtener apuestas con JOIN básico
      final response = await _supabase
          .from('apuestas')
          .select('''
            id,
            user_id,
            sorteo_id,
            monto_apostado,
            fecha_juego,
            estado,
            monto_ganado,
            created_at,
            sorteos(
              id,
              nombre_sorteo,
              hora_cierre,
              estado
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      debugPrint('📊 Encontradas ${response.length} apuestas principales');

      if (response.isEmpty) {
        debugPrint('📋 No hay apuestas para este usuario');
        return [];
      }

      // Para cada apuesta, obtener los detalles por separado
      final apuestas = <Apuesta>[];

      for (final apuestaData in response) {
        final apuestaId = apuestaData['id'];

        // Obtener detalles de esta apuesta específica
        final detallesResponse = await _supabase
            .from('apuestas_detalle')
            .select('''
              id,
              apuesta_id,
              animalito_id,
              monto,
              animalitos(
                id,
                nombre,
                numero_str,
                imagen_asset
              )
            ''')
            .eq('apuesta_id', apuestaId);

        debugPrint('📋 Apuesta $apuestaId tiene ${detallesResponse.length} detalles');

        final sorteo = Sorteo.fromJson(apuestaData['sorteos']);

        // Para apuestas múltiples, crear una apuesta por cada detalle
        for (final detalle in detallesResponse) {
          final animalito = Animalito.fromJson(detalle['animalitos']);
          final monto = (detalle['monto'] as num?)?.toDouble() ?? 0.0;

          final apuesta = Apuesta(
            id: detalle['id'],
            userId: userId,
            montoApostado: monto,
            estado: apuestaData['estado'] ?? 'pendiente',
            montoGanado: (apuestaData['monto_ganado'] as num?)?.toDouble() ?? 0.0,
            fechaJuego: DateTime.parse(apuestaData['fecha_juego']),
            sorteo: sorteo,
            animalito: animalito,
          );

          apuestas.add(apuesta);
        }
      }

      debugPrint('✅ Retornando ${apuestas.length} apuestas procesadas');
      return apuestas;

    } catch (e) {
      debugPrint('❌ Error al obtener historial de apuestas: $e');
      rethrow;
    }
  }

  // Realizar múltiples apuestas en una sola transacción
  Future<List<Apuesta>> realizarApuestasMultiples({
    required int sorteoId,
    required Map<int, double> apuestas, // Map<animalitoId, monto>
    String? usuarioId,
  }) async {
    try {
      final userId = usuarioId ?? _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Verificar si el usuario existe
      final usuario = await _supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (usuario == null) {
        throw Exception('Usuario no encontrado');
      }
      
      // Verificar que el sorteo exista y esté abierto
      final sorteoData = await _supabase
          .from('sorteos')
          .select()
          .eq('id', sorteoId)
          .single() as Map<String, dynamic>;
          
      if (sorteoData.isEmpty) {
        throw Exception('Sorteo no encontrado');
      }
      
      final sorteo = Sorteo.fromJson(sorteoData);
      
      if (!sorteo.estaAbierto) {
        throw Exception('El sorteo no está abierto para apuestas');
      }
      
      // Verificar que el usuario tenga saldo suficiente
      final perfil = await _supabase
          .from('perfiles')
          .select('saldo')
          .eq('id', userId)
          .single();
          
      if (perfil == null) {
        throw Exception('Perfil de usuario no encontrado');
      }
      
      final saldoActual = (perfil['saldo'] as num).toDouble();
      final montoTotal = apuestas.values.fold(0.0, (sum, monto) => sum + monto);
      
      if (saldoActual < montoTotal) {
        throw Exception('Saldo insuficiente');
      }

      // Verificar que el sorteo esté abierto
      final sorteoData2 = await _supabase
          .from('sorteos')
          .select()
          .eq('id', sorteoId)
          .single();

      final sorteo2 = Sorteo.fromJson(sorteoData2);
      
      if (!sorteo.estaAbierto) {
        throw Exception('El sorteo ya está cerrado');
      }

      // Iniciar una transacción
      final List<Apuesta> apuestasRealizadas = [];
      
      // Obtener la fecha actual en formato YYYY-MM-DD
      final fechaJuego = DateTime.now().toIso8601String().split('T')[0];
      
      // Crear lista de apuestas para insertar
      final apuestasParaInsertar = apuestas.entries.map((entry) {
        return {
          'user_id': userId,
          'sorteo_id': sorteoId,
          'animalito_id': entry.key,
          'monto_apostado': entry.value,
          'fecha_juego': fechaJuego,
          'estado': 'pendiente',
          'monto_ganado': 0.0,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      // Insertar todas las apuestas en una sola operación
      final response = await _supabase
          .from('apuestas')
          .insert(apuestasParaInsertar)
          .select('''
            *,
            sorteos(*),
            animalitos(*)
          ''');

      // Mapear la respuesta a objetos Apuesta
      for (var apuestaData in response) {
        apuestasRealizadas.add(Apuesta.fromJson(
          apuestaData,
          sorteo: sorteo,
          animalito: Animalito.fromJson(apuestaData['animalitos']),
        ));
      }

      return apuestasRealizadas;
    } catch (e) {
      // Si hay un error, hacer rollback de la transacción
      developer.log('Error al realizar apuestas múltiples: $e');
      rethrow;
    }
  }

  // Suscribirse a cambios en tiempo real de un sorteo
  Stream<Sorteo> suscribirCambiosSorteo(int sorteoId) {
    return _supabase
        .from('sorteos')
        .stream(primaryKey: ['id'])
        .eq('id', sorteoId)
        .map((data) => Sorteo.fromJson(data.first));
  }

  // Obtener el resultado de un sorteo
  Future<Resultado?> getResultadoSorteo(int sorteoId) async {
    try {
      final response = await _supabase
          .from('resultados')
          .select('''
            *,
            sorteos(*),
            animalitos(*)
          ''')
          .eq('sorteo_id', sorteoId)
          .eq('fecha_sorteo', DateTime.now().toIso8601String().split('T')[0])
          .maybeSingle();

      if (response == null) return null;

      return Resultado.fromJson(
        response,
        sorteo: Sorteo.fromJson(response['sorteos']),
        animalito: Animalito.fromJson(response['animalitos']),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Obtener el número total de apuestas para un sorteo
  Future<int> getTotalApuestasSorteo(int sorteoId) async {
    try {
      final response = await _supabase
          .from('apuestas')
          .select('id')
          .eq('sorteo_id', sorteoId)
          .count(CountOption.exact);

      return response.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error al obtener total de apuestas para sorteo $sorteoId: $e');
      return 0;
    }
  }

  // Calcular total apostado a un animalito específico en un sorteo
  Future<double> _calcularTotalApostadoAnimalito(int sorteoId, int animalitoId) async {
    try {
      // Usar una consulta directa con JOIN para obtener el total
      final response = await _supabase
          .from('apuestas_detalle')
          .select('monto, apuestas!inner(sorteo_id)')
          .eq('animalito_id', animalitoId)
          .eq('apuestas.sorteo_id', sorteoId);

      double total = 0.0;
      for (final detalle in response) {
        total += (detalle['monto'] as num?)?.toDouble() ?? 0.0;
      }

      return total;
    } catch (e) {
      debugPrint('❌ Error al calcular total apostado al animalito $animalitoId: $e');
      return 0.0;
    }
  }

  // Calcular total apostado en todo un sorteo
  Future<double> _calcularTotalApostadoSorteo(int sorteoId) async {
    try {
      final response = await _supabase
          .from('apuestas')
          .select('monto_apostado')
          .eq('sorteo_id', sorteoId);

      double total = 0.0;
      for (final apuesta in response) {
        total += (apuesta['monto_apostado'] as num?)?.toDouble() ?? 0.0;
      }

      return total;
    } catch (e) {
      debugPrint('❌ Error al calcular total apostado en sorteo $sorteoId: $e');
      return 0.0;
    }
  }
}
