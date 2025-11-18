import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:animalitos_lottery/models/apuesta.dart';
import 'package:animalitos_lottery/models/animalito.dart';
import 'package:animalitos_lottery/models/sorteo.dart';

class ApuestaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener historial de apuestas con filtros
  Future<List<Apuesta>> getHistorialApuestas({
    String? estado,
    DateTime? desde,
    DateTime? hasta,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('apuestas')
          .select('''
            *, 
            sorteo:sorteados(
              id, 
              fecha_sorteo, 
              estado, 
              animalito_ganador,
              monto_premio
            ),
            animalito:animalitos(
              id, 
              nombre, 
              numero_str, 
              imagen_url
            )
          ''')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('fecha_juego', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      // TODO: Agregar filtro de estado cuando esté disponible
      // if (estado != null) {
      //   query = query.eq('estado', estado);
      // }

      // TODO: Agregar filtros de fecha cuando estén disponibles en la nueva versión de Supabase
      // if (desde != null) {
      //   query = query.gte('fecha_juego', desde.toIso8601String());
      // }
      // if (hasta != null) {
      //   final hastaMasUnDia = hasta.add(const Duration(days: 1));
      //   query = query.lt('fecha_juego', hastaMasUnDia.toIso8601String());
      // }

      final response = await query;
      
      return (response as List).map((json) {
        return Apuesta.fromJson(
          json,
          sorteo: Sorteo.fromJson(json['sorteo']),
          animalito: Animalito.fromJson(json['animalito']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener historial de apuestas: $e');
      rethrow;
    }
  }


  // Suscribirse a cambios en tiempo real
  // TODO: Actualizar cuando se actualice la API de Realtime
  RealtimeChannel subscribeToBets() {
    return _supabase
        .channel('apuestas')
        // .on(
        //   RealtimeListenTypes.postgresChanges,
        //   ChannelFilter(
        //     event: '*',
        //     schema: 'public',
        //     table: 'apuestas',
        //     filter: 'user_id=eq.${_supabase.auth.currentUser!.id}',
        //   ),
        //   (payload, [ref]) {
        //     print('Cambio en apuestas: $payload');
        //     // Aquí podrías notificar a los listeners
        //   },
        // )
        .subscribe();
  }

  // Obtener estadísticas de apuestas
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final response = await _supabase
          .rpc('obtener_estadisticas_apuestas')
          .single();
      
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error al obtener estadísticas: $e');
      rethrow;
    }
  }
}
