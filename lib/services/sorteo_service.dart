import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animalitos_lottery/models/sorteo.dart';

class SorteoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener sorteos activos (pendiente = abierto para apuestas)
  Future<List<Sorteo>> getSorteosActivos() async {
    debugPrint('🎯 Obteniendo sorteos activos desde la base de datos');

    final response = await _supabase
        .from('sorteos')
        .select()
        .order('hora_cierre', ascending: true); // Más próximos primero

    debugPrint('📊 Respuesta de sorteos: ${response.length} sorteos encontrados');

    final sorteos = (response as List)
        .map((json) => Sorteo.fromJson(json))
        .toList();

    debugPrint('✅ Sorteos parseados: ${sorteos.length} sorteos');
    for (final sorteo in sorteos) {
      debugPrint('  - Sorteo ${sorteo.id}: ${sorteo.nombreSorteo}, activo=${sorteo.activo}, hora_cierre=${sorteo.horaCierre.hour}:${sorteo.horaCierre.minute.toString().padLeft(2, '0')}');
    }

    return sorteos;
  }

  // Obtener un sorteo por ID
  Future<Sorteo> getSorteoPorId(int id) async {
    final response = await _supabase
        .from('sorteos')
        .select()
        .eq('id', id)
        .single();

    return Sorteo.fromJson(response);
  }

  // Actualizar estado de un sorteo
  Future<void> actualizarEstadoSorteo(int id, String estado) async {
    await _supabase
        .from('sorteos')
        .update({'estado': estado, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // Obtener estadísticas de un sorteo
  Future<Map<String, dynamic>> getEstadisticasSorteo(int sorteoId) async {
    final response = await _supabase
        .rpc('obtener_estadisticas_apuestas', params: {'p_sorteo_id': sorteoId});

    return response ?? {};
  }

  // Crear un nuevo sorteo
  Future<Sorteo> crearSorteo({
    required String nombre,
    required TimeOfDay horaCierre,
    double precioBoleto = 1.0,
    String? descripcion,
  }) async {
    final response = await _supabase
        .from('sorteos')
        .insert({
          'nombre_sorteo': nombre,
          'hora_cierre': '${horaCierre.hour.toString().padLeft(2, '0')}:${horaCierre.minute.toString().padLeft(2, '0')}',
          'precio_boleto': precioBoleto,
          'descripcion': descripcion,
          'estado': 'pendiente',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return Sorteo.fromJson(response);
  }
}
