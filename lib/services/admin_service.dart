import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animalitos_lottery/models/index.dart';
import 'package:animalitos_lottery/core/services/base_service.dart';
import 'package:animalitos_lottery/core/config/app_config.dart';
import 'package:animalitos_lottery/core/error/app_exception.dart';

/// Servicio para manejar operaciones de administración
class AdminService extends BaseService {

  // Obtener estadísticas generales
  Future<Map<String, dynamic>> getEstadisticas() async {
    return executeWithErrorHandling(() async {
      AppConfig.log('📊 Iniciando carga de estadísticas', tag: 'AdminService');

      // Obtener total de usuarios (jugadores, excluyendo admins)
      final usuarios = await supabase
          .from('perfiles')
          .select('id')
          .neq('es_admin', true)
          .count(CountOption.exact);

      AppConfig.log('👥 Total de usuarios: ${usuarios.count ?? 0}', tag: 'AdminService');

      // Obtener total de apuestas
      final apuestas = await supabase
          .from('apuestas')
          .select()
          .count(CountOption.exact);

      AppConfig.log('🎯 Total de apuestas: ${apuestas.count ?? 0}', tag: 'AdminService');

      // Obtener monto total apostado - consulta directa ya que la función RPC puede no existir
      final montoTotalResult = await supabase
          .from('apuestas')
          .select('monto_apostado')
          .not('monto_apostado', 'is', null);

      double montoTotal = 0.0;
      for (final apuesta in montoTotalResult) {
        montoTotal += (apuesta['monto_apostado'] as num?)?.toDouble() ?? 0.0;
      }

      AppConfig.log('💵 Monto total apostado: $montoTotal', tag: 'AdminService');

      // Obtener estadísticas financieras - calcular directamente desde la BD
      AppConfig.log('💰 Calculando estadísticas financieras directamente...', tag: 'AdminService');

      // Obtener saldo total de todos los usuarios (excluyendo admins)
      final saldoTotalResult = await supabase
          .from('perfiles')
          .select('saldo')
          .not('saldo', 'is', null)
          .neq('es_admin', true);

      double saldoTotalUsuarios = 0.0;
      for (final perfil in saldoTotalResult) {
        saldoTotalUsuarios += (perfil['saldo'] as num?)?.toDouble() ?? 0.0;
      }

      AppConfig.log('💰 Saldo total de usuarios: $saldoTotalUsuarios', tag: 'AdminService');

      // Obtener transacciones admin
      final transaccionesAdmin = await supabase
          .from('transacciones')
          .select('monto')
          .or('tipo.eq.recarga_admin,tipo.eq.ajuste_admin');

      double montoAdminTotal = 0.0;
      int numTransaccionesAdmin = transaccionesAdmin.length;
      for (final transaccion in transaccionesAdmin) {
        montoAdminTotal += (transaccion['monto'] as num?)?.toDouble() ?? 0.0;
      }

      AppConfig.log('💰 Monto admin total: $montoAdminTotal, transacciones: $numTransaccionesAdmin', tag: 'AdminService');

      // Calcular estadísticas financieras
      final statsFinancieras = {
        'total_apostado': montoTotal,
        'total_ganado_usuarios': 0.0, // Por ahora 0, se calcularía con resultados de sorteos
        'total_perdido_usuarios': montoTotal,
        'ganancia_casa': 0.0, // Por ahora 0, se calcularía con resultados de sorteos
        'saldo_total_usuarios': saldoTotalUsuarios,
        'transacciones_admin': numTransaccionesAdmin,
        'monto_admin_total': montoAdminTotal,
        'balance_general': saldoTotalUsuarios - montoTotal + montoAdminTotal,
      };

      AppConfig.log('💰 Estadísticas financieras calculadas: $statsFinancieras', tag: 'AdminService');

      // Obtener animales más apostados - consulta directa
      final animalesResult = await supabase
          .from('apuestas_detalle')
          .select('''
            animalito_id,
            animalitos!inner(
              nombre,
              numero_str,
              imagen_url
            ),
            monto
          ''');

      // Agrupar por animalito
      final Map<int, Map<String, dynamic>> animalesMap = {};
      for (final detalle in animalesResult) {
        final animalitoId = detalle['animalito_id'] as int;
        final animalito = detalle['animalitos'];
        final monto = (detalle['monto'] as num?)?.toDouble() ?? 0.0;

        if (animalesMap.containsKey(animalitoId)) {
          animalesMap[animalitoId]!['total_apuestas'] += 1;
          animalesMap[animalitoId]!['total_monto'] += monto;
        } else {
          animalesMap[animalitoId] = {
            'id': animalitoId,
            'nombre': animalito['nombre'],
            'numero': animalito['numero_str'],
            'imagen_url': animalito['imagen_url'],
            'total_apuestas': 1,
            'total_monto': monto,
          };
        }
      }

      final animalesMasApostados = animalesMap.values.toList()
        ..sort((a, b) {
          final aVal = (a['total_apuestas'] as num?)?.toInt() ?? 0;
          final bVal = (b['total_apuestas'] as num?)?.toInt() ?? 0;
          return bVal.compareTo(aVal);
        });

      debugPrint('🐾 Animales más apostados: ${animalesMasApostados.length}');

      // Obtener últimas transacciones - consulta simplificada sin join problemático
      final ultimasTransacciones = await supabase
          .from('transacciones')
          .select('''
            id,
            user_id,
            tipo,
            monto,
            descripcion,
            fecha
          ''')
          .order('fecha', ascending: false)
          .limit(5);

      debugPrint('💸 Últimas transacciones: ${ultimasTransacciones.length}');

      // Obtener apuestas por estado
      final apuestasPorEstado = await supabase
          .from('apuestas')
          .select('estado');

      final Map<String, int> estadoCounts = {};
      for (final apuesta in apuestasPorEstado) {
        final estado = apuesta['estado'] as String? ?? 'desconocido';
        estadoCounts[estado] = (estadoCounts[estado] ?? 0) + 1;
      }

      debugPrint('📈 Apuestas por estado: $estadoCounts');

      return {
        'total_usuarios': usuarios.count ?? 0,
        'total_apuestas': apuestas.count ?? 0,
        'monto_total_apostado': montoTotal,
        'estadisticas_financieras': statsFinancieras,
        'apuestas_por_estado': estadoCounts,
        'animales_mas_apostados': animalesMasApostados.take(5).toList(),
        'ultimas_transacciones': ultimasTransacciones,
      };
    }, operationName: 'getEstadisticas');
  }

  /// Obtiene una lista paginada de usuarios con opción de búsqueda
  Future<Map<String, dynamic>> getUsuarios({
    String busqueda = '',
    int pagina = 1,
    int porPagina = 10,
  }) async {
    return executeWithErrorHandling(() async {
      AppConfig.log('👥 Iniciando carga de usuarios: página=$pagina, búsqueda="$busqueda"', tag: 'AdminService');

      // Verificar permisos de admin primero
      await requireAdmin();

      // Consulta directa a perfiles que incluye email (ya que está en la tabla perfiles)
      var query = supabase
          .from('perfiles')
          .select('''
            id,
            nombre,
            apellido,
            telefono,
            saldo,
            es_admin,
            bloqueado,
            created_at,
            updated_at,
            email
          ''')
          .order('created_at', ascending: false);

      // Aplicar filtro de búsqueda si es necesario
      if (busqueda.isNotEmpty) {
        AppConfig.log('🔍 Aplicando filtro de búsqueda: $busqueda', tag: 'AdminService');
        // Para búsqueda simple, obtener todos y filtrar manualmente
        final allUsers = await supabase
            .from('perfiles')
            .select('''
              id,
              nombre,
              apellido,
              telefono,
              saldo,
              es_admin,
              bloqueado,
              created_at,
              updated_at,
              email
            ''')
            .order('created_at', ascending: false);

        // Filtrar por email
        final filteredUsers = allUsers.where((user) {
          final email = (user['email'] as String?)?.toLowerCase() ?? '';
          return email.contains(busqueda.toLowerCase());
        }).toList();

        AppConfig.log('🎯 Usuarios filtrados: ${filteredUsers.length}', tag: 'AdminService');

        // Aplicar paginación
        final startIndex = (pagina - 1) * porPagina;
        final endIndex = startIndex + porPagina;
        final paginatedUsers = filteredUsers.length > startIndex
            ? filteredUsers.sublist(
                startIndex,
                endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
              )
            : [];

        // Crear usuarios con la estructura esperada por la UI
        final usuarios = paginatedUsers.map((user) {
          return {
            ...user,
            'auth': {
              'email': user['email'] ?? 'Sin email',
              'last_sign_in_at': null,
              'created_at': user['created_at'],
            },
          };
        }).toList();

        AppConfig.log('✅ Retornando ${usuarios.length} usuarios filtrados', tag: 'AdminService');

        return {
          'usuarios': usuarios,
          'total': filteredUsers.length,
          'pagina': pagina,
          'porPagina': porPagina,
        };
      }

      // Aplicar paginación
      query = query.range((pagina - 1) * porPagina, (pagina * porPagina) - 1);

      final response = await query;
      AppConfig.log('📄 Usuarios obtenidos de perfiles: ${response.length}', tag: 'AdminService');

      // Obtener el total de usuarios (con filtro si aplica)
      var countQuery = supabase
          .from('perfiles')
          .select();

      if (busqueda.isNotEmpty) {
        countQuery = countQuery.ilike('email', '%$busqueda%');
      }

      final count = await countQuery.count(CountOption.exact);
      AppConfig.log('📊 Total de usuarios: ${count.count ?? 0}', tag: 'AdminService');

      // Crear usuarios con la estructura esperada por la UI
      final usuarios = response.map((user) {
        return {
          ...user,
          'auth': {
            'email': user['email'] ?? 'Sin email',
            'last_sign_in_at': null, // No disponible en esta consulta
            'created_at': user['created_at'],
          },
        };
      }).toList();

      AppConfig.log('✅ Retornando ${usuarios.length} usuarios', tag: 'AdminService');

      return {
        'usuarios': usuarios,
        'total': count.count ?? 0,
        'pagina': pagina,
        'porPagina': porPagina,
      };
    }, operationName: 'getUsuarios');
  }

  /// Bloquea o desbloquea un usuario
  ///
  /// [userId] ID del usuario a bloquear/desbloquear
  /// [bloquear] true para bloquear, false para desbloquear
  Future<void> toggleBloquearUsuario(String userId, bool bloquear) async {
    return executeWithErrorHandling(() async {
      AppConfig.log('🔒 Cambiando estado de bloqueo para usuario $userId: $bloquear', tag: 'AdminService');

      await requireAdmin();
      validateUserId(userId);

      await supabase
          .from('perfiles')
          .update({
            'bloqueado': bloquear,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', userId);

      AppConfig.log('✅ Estado de bloqueo actualizado para usuario $userId', tag: 'AdminService');

      // Cerrar sesión del usuario si se está bloqueando
      if (bloquear) {
        try {
          AppConfig.log('🚪 Intentando cerrar sesión del usuario bloqueado $userId', tag: 'AdminService');
          await supabase.auth.admin.deleteUser(userId);
          AppConfig.log('✅ Sesión cerrada para usuario $userId', tag: 'AdminService');
        } catch (e) {
          AppConfig.logError('No se pudo cerrar sesión del usuario $userId', tag: 'AdminService', error: e);
          // Ignorar errores al cerrar sesión
        }
      }
    }, operationName: 'toggleBloquearUsuario');
  }

  // Métodos para gestión de sorteos
  Future<List<Map<String, dynamic>>> getSorteos() async {
    return executeWithErrorHandling(() async {
      final response = await supabase
          .from('sorteos')
          .select('''
            *,
            animalito_ganador:animalitos!animalito_ganador_id(*)
          ''')
          .order('hora_cierre', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    }, operationName: 'getSorteos');
  }

  Future<Map<String, dynamic>> crearSorteo(DateTime fechaHora) async {
    return executeWithErrorHandling(() async {
      await requireAdmin();

      // Determinar el tipo de sorteo basado en la hora
      final hora = fechaHora.hour;
      String nombreSorteo;
      DateTime horaApertura;

      if (hora >= 6 && hora < 12) {
        nombreSorteo = 'Mañana';
        horaApertura = DateTime(fechaHora.year, fechaHora.month, fechaHora.day, 6, 0);
      } else if (hora >= 12 && hora < 18) {
        nombreSorteo = 'Tarde';
        horaApertura = DateTime(fechaHora.year, fechaHora.month, fechaHora.day, 12, 0);
      } else {
        nombreSorteo = 'Noche';
        horaApertura = DateTime(fechaHora.year, fechaHora.month, fechaHora.day, 18, 0);
      }

      final response = await supabase
          .from('sorteos')
          .insert({
            'nombre_sorteo': nombreSorteo,
            'hora_apertura': horaApertura.toIso8601String(),
            'hora_cierre': fechaHora.toIso8601String(),
            'estado': 'pendiente',
          })
          .select()
          .single();
      return response as Map<String, dynamic>;
    }, operationName: 'crearSorteo');
  }

  Future<void> cerrarApuestas(int sorteoId) async {
    return executeWithErrorHandling(() async {
      await requireAdmin();

      AppConfig.log('🔒 Actualizando estado del sorteo $sorteoId a "cerrado"', tag: 'AdminService');
      final result = await supabase
          .from('sorteos')
          .update({
            'estado': 'cerrado',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', sorteoId)
          .select()
          .single();

      AppConfig.log('✅ Sorteo $sorteoId cerrado exitosamente: $result', tag: 'AdminService');
    }, operationName: 'cerrarApuestas');
  }

  Future<Map<String, dynamic>> seleccionarGanador(int sorteoId, int animalId) async {
    return executeWithErrorHandling(() async {
      await requireAdmin();

      AppConfig.log('🎯 Iniciando selección de ganador para sorteo $sorteoId, animal $animalId', tag: 'AdminService');

      // Verificar que el sorteo existe y está en estado cerrado
      final sorteoActual = await supabase
          .from('sorteos')
          .select('estado, animalito_ganador_id')
          .eq('id', sorteoId)
          .single();

      AppConfig.log('📊 Estado actual del sorteo: ${sorteoActual['estado']}, ganador actual: ${sorteoActual['animalito_ganador_id']}', tag: 'AdminService');

      if (sorteoActual['estado'] != 'cerrado') {
        throw AppException('El sorteo debe estar cerrado antes de seleccionar un ganador', code: 'SORTEO_NOT_CLOSED');
      }

      if (sorteoActual['animalito_ganador_id'] != null) {
        throw AppException('Este sorteo ya tiene un ganador seleccionado', code: 'SORTEO_ALREADY_HAS_WINNER');
      }

      // Actualizar directamente el sorteo con el ganador seleccionado
      AppConfig.log('🎯 Actualizando sorteo $sorteoId con ganador $animalId', tag: 'AdminService');
      final updateResult = await supabase
          .from('sorteos')
          .update({
            'animalito_ganador_id': animalId,
            'estado': 'finalizado',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sorteoId)
          .select()
          .single();

      AppConfig.log('✅ Sorteo actualizado: $updateResult', tag: 'AdminService');

      // Insertar resultado en la tabla resultados para que aparezca en la pantalla principal
      AppConfig.log('📝 Insertando resultado en tabla resultados para sorteo $sorteoId', tag: 'AdminService');
      final fechaSorteo = DateTime.now().toIso8601String().split('T')[0]; // Solo fecha YYYY-MM-DD

      await supabase.from('resultados').insert({
        'sorteo_id': sorteoId,
        'animalito_id': animalId,
        'fecha_sorteo': fechaSorteo,
      });

      AppConfig.log('✅ Resultado insertado en tabla resultados', tag: 'AdminService');

      // Pagar ganancias automáticamente a los ganadores - con manejo de error
      Map<String, dynamic> pagoResult = {};
      try {
        AppConfig.log('💰 Pagando ganancias automáticamente para sorteo $sorteoId', tag: 'AdminService');
        pagoResult = await supabase.rpc('pagar_ganancias_sorteo', params: {
          'p_sorteo_id': sorteoId,
        });
        AppConfig.log('✅ Ganancias pagadas: $pagoResult', tag: 'AdminService');
      } catch (e) {
        AppConfig.logError('Función RPC pagar_ganancias_sorteo no disponible, ganancias no pagadas automáticamente', tag: 'AdminService', error: e);
        pagoResult = {'error': 'Función RPC no disponible', 'message': e.toString()};
      }

      // Calcular estadísticas finales usando la función existente - con manejo de error
      Map<String, dynamic> gananciasResult = {};
      try {
        AppConfig.log('📊 Calculando estadísticas finales para sorteo $sorteoId', tag: 'AdminService');
        gananciasResult = await supabase.rpc('calcular_ganancias', params: {
          'p_sorteo_id': sorteoId,
        });
        AppConfig.log('✅ Estadísticas calculadas: $gananciasResult', tag: 'AdminService');
      } catch (e) {
        AppConfig.logError('Función RPC calcular_ganancias no disponible, estadísticas no calculadas', tag: 'AdminService', error: e);
        gananciasResult = {'error': 'Función RPC no disponible', 'message': e.toString()};
      }

      // Obtener el sorteo actualizado con el ganador
      final sorteo = await supabase
          .from('sorteos')
          .select('''
            *,
            animalito_ganador:animalitos!animalito_ganador_id(*)
          ''')
          .eq('id', sorteoId)
          .single();

      AppConfig.log('🎯 Sorteo finalizado exitosamente: ${sorteo['animalito_ganador']?['nombre'] ?? 'Sin ganador'}', tag: 'AdminService');

      return {
        'sorteo': sorteo,
        'result': gananciasResult,
        'pago_result': pagoResult,
      };
    }, operationName: 'seleccionarGanador');
  }

  // Ajustar saldo de usuario
  Future<void> ajustarSaldo({
    required String userId,
    required double monto,
    required String motivo,
  }) async {
    return executeWithErrorHandling(() async {
      await requireAdmin();
      validateUserId(userId);
      validatePositiveAmount(monto.abs(), fieldName: 'monto absoluto');

      AppConfig.log('💰 Ajustando saldo para usuario $userId: $monto ($motivo)', tag: 'AdminService');

      // Verificar si el usuario existe
      final usuario = await supabase
          .from('perfiles')
          .select('saldo')
          .eq('id', userId)
          .single();

      final saldoActual = (usuario['saldo'] as num?)?.toDouble() ?? 0.0;
      final nuevoSaldo = saldoActual + monto;

      AppConfig.log('💵 Saldo actual: $saldoActual, nuevo saldo: $nuevoSaldo', tag: 'AdminService');

      if (nuevoSaldo < 0) {
        throw InsufficientFundsException('El saldo no puede ser negativo. Saldo actual: $saldoActual, ajuste solicitado: $monto');
      }

      // Actualizar saldo
      await supabase
          .from('perfiles')
          .update({
            'saldo': nuevoSaldo,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', userId);

      // Registrar transacción
      await supabase.from('transacciones').insert({
        'user_id': userId,
        'monto': monto,
        'tipo': monto > 0 ? 'recarga_admin' : 'ajuste_admin',
        'descripcion': motivo,
        'saldo_anterior': saldoActual,
        'saldo_nuevo': nuevoSaldo,
        'fecha': DateTime.now().toIso8601String(),
      });

      AppConfig.log('✅ Saldo ajustado exitosamente para usuario $userId', tag: 'AdminService');
    }, operationName: 'ajustarSaldo');
  }

  // Obtener historial de apuestas de un usuario
  Future<List<Map<String, dynamic>>> getHistorialApuestas(String userId) async {
    return executeWithErrorHandling(() async {
      await requireAdmin();
      validateUserId(userId);

      final response = await supabase
          .from('apuestas')
          .select('''
            *,
            sorteo:sorteo_id(*, animalito_ganador:animalitos!animalito_ganador_id(*)),
            apuestas_detalle(*, animalito:animalitos(*))
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    }, operationName: 'getHistorialApuestas');
  }

  // Obtener saldo total de usuarios para estadísticas
  Future<double> getSaldoTotalUsuarios() async {
    return executeWithErrorHandling(() async {
      final saldoTotalResult = await supabase
          .from('perfiles')
          .select('saldo')
          .not('saldo', 'is', null);

      double saldoTotal = 0.0;
      for (final perfil in saldoTotalResult) {
        saldoTotal += (perfil['saldo'] as num?)?.toDouble() ?? 0.0;
      }

      return saldoTotal;
    }, operationName: 'getSaldoTotalUsuarios');
  }

  // Verificar si el usuario actual es administrador
  Future<bool> esAdministrador() async {
    return executeWithErrorHandling(() async {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final response = await supabase
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .single();

      return response['es_admin'] ?? false;
    }, operationName: 'esAdministrador');
  }

  // Cerrar un sorteo
  Future<Sorteo> cerrarSorteo(int sorteoId, {int? animalitoGanadorId}) async {
    return executeWithErrorHandling(() async {
      await requireAdmin();

      final updates = {
        'estado': 'cerrado',
        'updated_at': DateTime.now().toIso8601String(),
        if (animalitoGanadorId != null) 'animal_ganador_id': animalitoGanadorId,
      };

      final response = await supabase
          .from('sorteos')
          .update(updates)
          .eq('id', sorteoId)
          .select()
          .single();

      // Si se especificó un ganador, actualizar las apuestas
      if (animalitoGanadorId != null) {
        await _actualizarApuestasGanadoras(sorteoId, animalitoGanadorId);
      }

      return Sorteo.fromJson(response);
    }, operationName: 'cerrarSorteo');
  }

  // Actualizar apuestas ganadoras
  Future<void> _actualizarApuestasGanadoras(int sorteoId, int animalitoGanadorId) async {
    // Obtener todas las apuestas detalle del sorteo para el animalito ganador
    final apuestasGanadoras = await supabase
        .from('apuestas_detalle')
        .select('*, apuestas(*)')
        .eq('animalito_id', animalitoGanadorId)
        .eq('apuestas.sorteo_id', sorteoId);

    // Calcular el monto total apostado al animalito ganador
    final montoTotalGanador = apuestasGanadoras.fold<double>(
      0,
      (sum, detalle) => sum + (detalle['monto'] as num).toDouble(),
    );

    // Actualizar cada apuesta ganadora
    for (final detalle in apuestasGanadoras) {
      final montoApostado = (detalle['monto'] as num).toDouble();
      final montoGanado = _calcularGanancia(
        montoApostado,
        montoTotalGanador,
      );

      await supabase.from('apuestas').update({
        'estado': 'ganada',
        'monto_ganado': montoGanado,
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      }).eq('id', detalle['apuesta_id']);

      // Aquí podrías agregar lógica para acreditar el monto ganado al usuario
      // Por ejemplo, actualizar el saldo del usuario
      await _acreditarGanancia(
        detalle['apuestas']['user_id'],
        montoGanado,
        'Ganancia por apuesta múltiple #${detalle['apuesta_id']}',
      );
    }

    // Marcar el resto de apuestas como perdidas
    await supabase
        .from('apuestas')
        .update({
          'estado': 'perdida',
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('sorteo_id', sorteoId)
        .neq('estado', 'ganada'); // No marcar como perdidas las que ya ganaron
  }

  // Acreditar ganancia al usuario
  Future<void> _acreditarGanancia(String userId, double monto, String descripcion) async {
    AppConfig.log('💰 Acreditando ganancia: usuario=$userId, monto=$monto, descripcion="$descripcion"', tag: 'AdminService');

    // Obtener el saldo actual del usuario
    final response = await supabase
        .from('perfiles')
        .select('saldo')
        .eq('id', userId)
        .single();

    final saldoActual = (response['saldo'] as num).toDouble();
    final nuevoSaldo = saldoActual + monto;

    AppConfig.log('💵 Saldo antes: $saldoActual, después: $nuevoSaldo', tag: 'AdminService');

    // Actualizar el saldo
    await supabase
        .from('perfiles')
        .update({'saldo': nuevoSaldo})
        .eq('id', userId);

    // Registrar transacción de ganancia
    await supabase.from('transacciones').insert({
      'user_id': userId,
      'monto': monto,
      'tipo': 'ganancia_sorteo',
      'descripcion': descripcion,
      'saldo_anterior': saldoActual,
      'saldo_nuevo': nuevoSaldo,
      'fecha': DateTime.now().toIso8601String(),
    });

    AppConfig.log('✅ Ganancia acreditada exitosamente al usuario $userId', tag: 'AdminService');
  }

  // Calcular la ganancia basada en el monto apostado y el total del pozo
  double _calcularGanancia(double montoApostado, double montoTotalGanador) {
    // Porcentaje de la casa (10%)
    const porcentajeCasa = 0.1;
    
    // Si nadie apostó al ganador, se pierde el dinero
    if (montoTotalGanador == 0) return 0;
    
    // Calcular el monto total del pozo (todas las apuestas al sorteo)
    // Nota: En una implementación real, deberías obtener este valor de la base de datos
    // Para simplificar, asumimos que es 10 veces el monto total ganador
    final montoTotalPozo = montoTotalGanador * 10;
    
    // Calcular la proporción de la apuesta sobre el total ganador
    final proporcion = montoApostado / montoTotalGanador;
    
    // Calcular la ganancia (90% del pozo distribuido proporcionalmente)
    return (montoTotalPozo * (1 - porcentajeCasa)) * proporcion;
  }

  // Actualizar saldo de un usuario
  Future<void> actualizarSaldoUsuario(
    String userId,
    double monto,
    String motivo,
  ) async {
    return executeWithErrorHandling(() async {
      await requireAdmin();
      validateUserId(userId);
      validatePositiveAmount(monto.abs(), fieldName: 'monto absoluto');

      AppConfig.log('💰 Iniciando actualización de saldo para usuario $userId: monto=$monto, motivo="$motivo"', tag: 'AdminService');

      // Obtener el saldo actual
      final perfilResponse = await supabase
          .from('perfiles')
          .select('saldo')
          .eq('id', userId);

      if (perfilResponse.isEmpty) {
        throw AppException('Usuario no encontrado', code: 'USER_NOT_FOUND');
      }

      final perfil = perfilResponse.first;
      final saldoActual = (perfil['saldo'] as num?)?.toDouble() ?? 0.0;
      final nuevoSaldo = saldoActual + monto;

      AppConfig.log('💵 Saldo actual: $saldoActual, nuevo saldo: $nuevoSaldo', tag: 'AdminService');

      if (nuevoSaldo < 0) {
        throw InsufficientFundsException('El saldo no puede ser negativo. Saldo actual: $saldoActual, ajuste solicitado: $monto');
      }

      // Actualizar el saldo directamente usando update para evitar problemas de RPC
      AppConfig.log('🔄 Actualizando saldo directamente en la tabla...', tag: 'AdminService');

      // Actualizar saldo
      final updateResult = await supabase
          .from('perfiles')
          .update({
            'saldo': nuevoSaldo,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', userId)
          .select()
          .single();

      AppConfig.log('✅ Saldo actualizado en perfiles: $updateResult', tag: 'AdminService');
      AppConfig.log('💰 Nuevo saldo confirmado en BD: ${(updateResult['saldo'] as num?)?.toDouble() ?? 0.0}', tag: 'AdminService');

      // Registrar transacción
      final transactionData = {
        'user_id': userId,
        'monto': monto,
        'tipo': monto >= 0 ? 'recarga_admin' : 'ajuste_admin',
        'descripcion': motivo,
        'saldo_anterior': saldoActual,
        'saldo_nuevo': nuevoSaldo,
        'fecha': DateTime.now().toIso8601String(),
      };

      AppConfig.log('💸 Insertando transacción: $transactionData', tag: 'AdminService');

      try {
        final transactionResult = await supabase
            .from('transacciones')
            .insert(transactionData)
            .select()
            .single();

        AppConfig.log('✅ Transacción registrada exitosamente: $transactionResult', tag: 'AdminService');
      } catch (transactionError) {
        AppConfig.logError('Error al registrar transacción, pero saldo actualizado', tag: 'AdminService', error: transactionError);
        // No lanzamos error aquí porque el saldo ya se actualizó
      }

      AppConfig.log('✅ Saldo actualizado exitosamente para usuario $userId', tag: 'AdminService');
    }, operationName: 'actualizarSaldoUsuario');
  }

}
