import 'package:animalitos_lottery/models/animalito.dart';
import 'package:animalitos_lottery/models/sorteo.dart';

class Resultado {
  final int? id;
  final Sorteo sorteo;
  final Animalito animalitoGanador;
  final DateTime fechaSorteo;

  Resultado({
    this.id,
    required this.sorteo,
    required this.animalitoGanador,
    DateTime? fechaSorteo,
  }) : fechaSorteo = fechaSorteo ?? DateTime.now();

  factory Resultado.fromJson(Map<String, dynamic> json, {Sorteo? sorteo, Animalito? animalito}) {
    return Resultado(
      id: json['id'] as int?,
      sorteo: sorteo ?? Sorteo.fromJson(json['sorteo'] as Map<String, dynamic>),
      animalitoGanador: animalito ?? Animalito.fromJson(json['animalito_ganador'] as Map<String, dynamic>),
      fechaSorteo: DateTime.parse(json['fecha_sorteo'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sorteo_id': sorteo.id,
      'animalito_id_ganador': animalitoGanador.id,
      'fecha_sorteo': '${fechaSorteo.year}-${fechaSorteo.month.toString().padLeft(2, '0')}-${fechaSorteo.day.toString().padLeft(2, '0')}',
    };
  }

  @override
  String toString() {
    return 'Resultado($id: ${sorteo.nombreSorteo} - ${animalitoGanador.nombre} - $fechaSorteo)';
  }
}
