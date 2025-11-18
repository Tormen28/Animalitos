import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Sorteo {
  final int id;
  final String nombreSorteo;
  final TimeOfDay horaCierre;
  final bool activo;
  final String? descripcion;
  final double precioBoleto;
  final int? limiteBoletosPorUsuario;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final List<DateTime>? diasExcluidos;

  Sorteo({
    required this.id,
    required this.nombreSorteo,
    required this.horaCierre,
    this.activo = true,
    this.descripcion,
    this.precioBoleto = 1.0,
    this.limiteBoletosPorUsuario,
    this.fechaInicio,
    this.fechaFin,
    this.diasExcluidos,
  });

  factory Sorteo.fromJson(Map<String, dynamic> json) {
    // Manejar diferentes formatos de fecha/hora para hora_cierre
    TimeOfDay horaCierre;
    if (json['hora_cierre'] is String) {
      try {
        // Si viene como timestamp completo, extraer solo la hora
        final dateTimeStr = json['hora_cierre'] as String;
        // Si contiene T, es ISO format, si no, intentar parse directo
        final dateTime = dateTimeStr.contains('T')
            ? DateTime.parse(dateTimeStr)
            : DateTime.parse('${DateTime.now().toIso8601String().split('T')[0]}T$dateTimeStr');
        horaCierre = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      } catch (e) {
        debugPrint('Error parsing hora_cierre: $e, using default');
        // Si el parsing falla, usar default
        horaCierre = const TimeOfDay(hour: 12, minute: 0);
      }
    } else if (json['hora_cierre'] is TimeOfDay) {
      horaCierre = json['hora_cierre'] as TimeOfDay;
    } else {
      // Default a las 12:00 si no hay hora
      horaCierre = const TimeOfDay(hour: 12, minute: 0);
    }

    // Determinar si está activo basado en el estado y la hora actual
    final estado = json['estado'] as String?;
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final cierreHoy = DateTime(
      now.year,
      now.month,
      now.day,
      horaCierre.hour,
      horaCierre.minute,
    );

    bool activo;
    if (estado == 'finalizado') {
      activo = false; // Finalizado nunca está activo
    } else if (estado == 'cerrado') {
      activo = false; // Cerrado no está activo
    } else if (estado == 'abierto') {
      // Abierto: verificar si aún no ha pasado la hora de cierre
      activo = now.isBefore(cierreHoy);
    } else if (estado == 'pendiente' || estado == null) {
      // Pendiente o sin estado: siempre activo (sorteo programado)
      activo = true;
    } else {
      activo = false; // Estado desconocido, asumir inactivo
    }

    debugPrint('🔍 Sorteo ${json['id']}: estado="$estado", activo=$activo, hora_cierre=${horaCierre.hour}:${horaCierre.minute.toString().padLeft(2, '0')}, ahora=${now.hour}:${now.minute.toString().padLeft(2, '0')}, cierre_hoy=${cierreHoy.hour}:${cierreHoy.minute.toString().padLeft(2, '0')}, isBefore=${now.isBefore(cierreHoy)}');

    return Sorteo(
      id: json['id'] as int,
      nombreSorteo: json['nombre_sorteo'] as String,
      horaCierre: horaCierre,
      activo: activo,
      descripcion: json['descripcion'] as String?,
      precioBoleto: 1.0, // Valor por defecto
      limiteBoletosPorUsuario: null, // No existe en BD
      fechaInicio: null, // No existe en BD
      fechaFin: null, // No existe en BD
      diasExcluidos: null, // No existe en BD
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_sorteo': nombreSorteo,
      'hora_cierre':
          '${horaCierre.hour.toString().padLeft(2, '0')}:${horaCierre.minute.toString().padLeft(2, '0')}',
      'activo': activo,
      if (descripcion != null) 'descripcion': descripcion,
      'precio_boleto': precioBoleto,
      if (limiteBoletosPorUsuario != null)
        'limite_boletos': limiteBoletosPorUsuario,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio!.toIso8601String(),
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String(),
      if (diasExcluidos != null)
        'dias_excluidos':
            diasExcluidos!.map((e) => e.toIso8601String()).toList(),
    };
  }

  // Crea una copia del sorteo con algunos campos actualizados
  Sorteo copyWith({
    int? id,
    String? nombreSorteo,
    TimeOfDay? horaCierre,
    bool? activo,
    String? descripcion,
    double? precioBoleto,
    int? limiteBoletosPorUsuario,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    List<DateTime>? diasExcluidos,
  }) {
    return Sorteo(
      id: id ?? this.id,
      nombreSorteo: nombreSorteo ?? this.nombreSorteo,
      horaCierre: horaCierre ?? this.horaCierre,
      activo: activo ?? this.activo,
      descripcion: descripcion ?? this.descripcion,
      precioBoleto: precioBoleto ?? this.precioBoleto,
      limiteBoletosPorUsuario:
          limiteBoletosPorUsuario ?? this.limiteBoletosPorUsuario,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      diasExcluidos: diasExcluidos ?? this.diasExcluidos,
    );
  }

  // Verifica si el sorteo está abierto en este momento
  bool get estaAbierto {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cierreHoy = DateTime(
      now.year,
      now.month,
      now.day,
      horaCierre.hour,
      horaCierre.minute,
    );

    // Verificar si hoy es un día excluido
    if (diasExcluidos != null) {
      final hoy = DateTime(now.year, now.month, now.day);
      if (diasExcluidos!.any((fecha) =>
          fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day)) {
        return false;
      }
    }

    // Verificar si está dentro del rango de fechas
    if (fechaInicio != null && now.isBefore(fechaInicio!)) {
      return false;
    }
    if (fechaFin != null && now.isAfter(fechaFin!)) {
      return false;
    }

    // Verificar si ya pasó la hora de cierre
    final isBeforeCierre = now.isBefore(cierreHoy);
    debugPrint('🔍 Sorteo ${id} estaAbierto: activo=$activo, isBeforeCierre=$isBeforeCierre, hora_cierre=${horaCierre.hour}:${horaCierre.minute.toString().padLeft(2, '0')}, ahora=${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    return isBeforeCierre && activo;
  }

  // Obtiene el tiempo restante para el cierre del sorteo
  Duration get tiempoRestante {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final cierreHoy = hoy.add(Duration(
      hours: horaCierre.hour,
      minutes: horaCierre.minute,
    ));
    return cierreHoy.difference(now);
  }

  // Verifica si el sorteo ya ha finalizado
  bool get haFinalizado => !estaAbierto;

  // Obtiene el tiempo restante formateado como texto
  String get tiempoRestanteFormateado {
    if (haFinalizado) return 'Cerrado';

    final duration = tiempoRestante;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return 'Cierra en $hours h ${minutes.toString().padLeft(2, '0')} m';
    } else if (minutes > 0) {
      return 'Cierra en ${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return 'Cierra en ${seconds}s';
    }
  }

  // Obtiene la hora de cierre formateada
  String get horaCierreFormateada {
    final now = DateTime.now();
    final horaCierreDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      horaCierre.hour,
      horaCierre.minute,
    );
    return DateFormat('h:mm a').format(horaCierreDateTime);
  }

  // Obtiene el nombre del sorteo con la hora de cierre
  String get nombreConHora {
    final now = DateTime.now();
    final horaCierreDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      horaCierre.hour,
      horaCierre.minute,
    );
    final horaFormateada = DateFormat('h:mm a').format(horaCierreDateTime);
    return '$nombreSorteo $horaFormateada';
  }

  // Verifica si el sorteo está programado para hoy
  bool get esHoy {
    final now = DateTime.now();
    return estaAbierto ||
        (now.hour == horaCierre.hour && now.minute < horaCierre.minute);
  }

  // Obtiene el próximo horario de sorteo
  DateTime get proximoSorteo {
    final now = DateTime.now();
    var nextSort = DateTime(
      now.year,
      now.month,
      now.day,
      horaCierre.hour,
      horaCierre.minute,
    );

    // Si ya pasó la hora de hoy, programar para mañana
    if (now.isAfter(nextSort)) {
      nextSort = nextSort.add(const Duration(days: 1));
    }

    // Saltar días excluidos
    if (diasExcluidos != null) {
      while (diasExcluidos!.any((fecha) =>
          fecha.year == nextSort.year &&
          fecha.month == nextSort.month &&
          fecha.day == nextSort.day)) {
        nextSort = nextSort.add(const Duration(days: 1));
      }
    }

    return nextSort;
  }

  // Lista estática de los sorteos del Lotto Activo
  static final List<Sorteo> lottoActivoSorteos = [
    Sorteo(
      id: 1,
      nombreSorteo: 'Mañana',
      horaCierre: const TimeOfDay(hour: 12, minute: 0), // 12:00 PM
      descripcion: 'Sorteo de la mañana',
      precioBoleto: 1.0,
      limiteBoletosPorUsuario: 10,
    ),
    Sorteo(
      id: 2,
      nombreSorteo: 'Tarde',
      horaCierre: const TimeOfDay(hour: 15, minute: 0), // 3:00 PM
      descripcion: 'Sorteo de la tarde',
      precioBoleto: 1.0,
      limiteBoletosPorUsuario: 10,
    ),
    Sorteo(
      id: 3,
      nombreSorteo: 'Noche',
      horaCierre: const TimeOfDay(hour: 19, minute: 0), // 7:00 PM
      descripcion: 'Sorteo de la noche',
      precioBoleto: 1.0,
      limiteBoletosPorUsuario: 10,
    ),
  ];

  // Obtener un sorteo por su ID
  static Sorteo? getById(int id) {
    try {
      return lottoActivoSorteos.firstWhere((sorteo) => sorteo.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener el próximo sorteo disponible
  static Sorteo? getProximoSorteo() {
    final ahora = DateTime.now();
    Sorteo? proximo;
    Duration? diferenciaMasCorta;

    for (final sorteo in lottoActivoSorteos) {
      if (!sorteo.estaAbierto) continue;

      final diferencia = sorteo.tiempoRestante;
      if (diferenciaMasCorta == null ||
          diferencia.inSeconds < diferenciaMasCorta.inSeconds) {
        diferenciaMasCorta = diferencia;
        proximo = sorteo;
      }
    }

    return proximo;
  }

  // Obtener todos los sorteos de hoy
  static List<Sorteo> getSorteosDeHoy() {
    final hoy = DateTime.now();
    return lottoActivoSorteos.where((sorteo) {
      // Verificar si es un día excluido
      if (sorteo.diasExcluidos?.any((fecha) =>
              fecha.year == hoy.year &&
              fecha.month == hoy.month &&
              fecha.day == hoy.day) ??
          false) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.horaCierre.hour.compareTo(b.horaCierre.hour));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sorteo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombreSorteo == other.nombreSorteo;

  @override
  int get hashCode => id.hashCode ^ nombreSorteo.hashCode;

  @override
  String toString() => 'Sorteo($id: $nombreSorteo - $horaCierre)';
}
