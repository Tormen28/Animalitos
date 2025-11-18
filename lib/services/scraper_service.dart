import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ScraperService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener resultados de la página web
  // TODO: Implementar scraping cuando se agreguen las dependencias http y html
  Future<Map<String, dynamic>> obtenerResultados(DateTime fecha) async {
    // Retornar datos vacíos por ahora
    return {
      'fecha': DateTime.now().toIso8601String(),
      'resultados': <String, int>{},
    };
  }

  // Map<String, dynamic> _parsearResultados(String html) {
  //   final document = parser.parse(html);
  //   final resultados = <String, int>{};
  //   final elementos = document.querySelectorAll('.sorteo-item');
  //   
  //   for (var elemento in elementos) {
  //     final nombreSorteo = elemento.querySelector('.nombre-sorteo')?.text.trim();
  //     final numeroGanador = int.tryParse(elemento.querySelector('.numero-ganador')?.text.trim() ?? '0') ?? 0;
  //     
  //     if (nombreSorteo != null && numeroGanador > 0) {
  //       resultados[nombreSorteo] = numeroGanador;
  //     }
  //   }
  //   return {
  //     'fecha': DateTime.now().toIso8601String(),
  //     'resultados': resultados,
  //   };
  // }

  // Actualizar base de datos con resultados
  Future<void> actualizarResultados() async {
    try {
      final fechaActual = DateTime.now();
      final resultados = await obtenerResultados(fechaActual);
      
      // Actualizar cada sorteo con su resultado
      for (var entry in resultados['resultados'].entries) {
        final nombreSorteo = entry.key;
        final animalitoGanadorId = entry.value;
        
        // 1. Obtener el ID del sorteo por su nombre
        final sorteoResponse = await _supabase
            .from('sorteos')
            .select('id')
            .eq('nombre_sorteo', nombreSorteo)
            .single();
        final sorteoId = sorteoResponse['id'];
        
        // 2. Actualizar el sorteo con el animalito ganador
        await _supabase
            .from('sorteos')
            .update({
              'estado': 'finalizado',
              'animalito_ganador_id': animalitoGanadorId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', sorteoId);
            
        // 3. Actualizar el estado de las apuestas
        await _actualizarApuestas(sorteoId, animalitoGanadorId);
      }
    } catch (e) {
      debugPrint('Error al actualizar resultados: $e');
      // Aquí podrías implementar un sistema de reintentos o notificaciones
    }
  }
  
  Future<void> _actualizarApuestas(int sorteoId, int animalitoGanadorId) async {
    // 1. Actualizar apuestas ganadoras
    await _supabase.rpc('actualizar_apuestas_ganadoras', params: {
      'p_sorteo_id': sorteoId,
      'p_animalito_ganador_id': animalitoGanadorId,
    });
    
    // 2. Actualizar saldos de los ganadores
    await _supabase.rpc('actualizar_saldos_ganadores', params: {
      'p_sorteo_id': sorteoId,
    });
  }
  
  // Método eliminado por no estar en uso
  // String _formatDate(DateTime date) {
  //   return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  // }
}
