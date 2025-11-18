import 'package:animalitos_lottery/models/animalito.dart';
import 'package:animalitos_lottery/models/sorteo.dart';

class Apuesta {
  final int? id;
  final String userId;
  final Sorteo sorteo;
  final Animalito animalito;
  final double montoApostado;
  final DateTime fechaJuego;
  final String estado; // 'pendiente', 'ganadora', 'perdedora'
  final double montoGanado;

  Apuesta({
    this.id,
    required this.userId,
    required this.sorteo,
    required this.animalito,
    required this.montoApostado,
    DateTime? fechaJuego,
    this.estado = 'pendiente',
    this.montoGanado = 0.0,
  }) : fechaJuego = fechaJuego ?? DateTime.now();

  factory Apuesta.fromJson(Map<String, dynamic> json, {Sorteo? sorteo, Animalito? animalito}) {
    return Apuesta(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      sorteo: sorteo ?? Sorteo.fromJson(json['sorteo'] as Map<String, dynamic>),
      animalito: animalito ?? Animalito.fromJson(json['animalito'] as Map<String, dynamic>),
      montoApostado: (json['monto_apostado'] as num).toDouble(),
      fechaJuego: DateTime.parse(json['fecha_juego'] as String),
      estado: json['estado'] as String,
      montoGanado: (json['monto_ganado'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'sorteo_id': sorteo.id,
      'animalito_id': animalito.id,
      'monto_apostado': montoApostado,
      'fecha_juego': '${fechaJuego.year}-${fechaJuego.month.toString().padLeft(2, '0')}-${fechaJuego.day.toString().padLeft(2, '0')}',
      'estado': estado,
      'monto_ganado': montoGanado,
    };
  }

  Apuesta copyWith({
    int? id,
    String? userId,
    Sorteo? sorteo,
    Animalito? animalito,
    double? montoApostado,
    DateTime? fechaJuego,
    String? estado,
    double? montoGanado,
  }) {
    return Apuesta(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sorteo: sorteo ?? this.sorteo,
      animalito: animalito ?? this.animalito,
      montoApostado: montoApostado ?? this.montoApostado,
      fechaJuego: fechaJuego ?? this.fechaJuego,
      estado: estado ?? this.estado,
      montoGanado: montoGanado ?? this.montoGanado,
    );
  }

  @override
  String toString() {
    return 'Apuesta($id: ${sorteo.nombreSorteo} - ${animalito.nombre} - $montoApostado Bs - $estado)';
  }
}
