import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener estadísticas generales de apuestas
  Future<Map<String, dynamic>> getBettingStats(String userId) async {
    try {
      debugPrint('📊 Obteniendo estadísticas para usuario $userId');

      // Obtener el total de apuestas
      final totalBetsResponse = await _supabase
          .from('apuestas')
          .select('id')
          .eq('user_id', userId);

      final totalBets = totalBetsResponse.length;
      debugPrint('🎯 Total de apuestas: $totalBets');

      // Obtener apuestas con información completa de sorteos para determinar estado real
      final allBetsWithState = await _supabase
          .from('apuestas')
          .select('estado, sorteos(estado, animalito_ganador_id), apuestas_detalle(animalito_id)')
          .eq('user_id', userId);

      int wonBets = 0;
      int lostBets = 0;

      for (final bet in allBetsWithState) {
        final betEstado = bet['estado'];
        final sorteoEstado = bet['sorteos']?['estado'];
        final animalitoGanadorId = bet['sorteos']?['animalito_ganador_id'];

        // Si el sorteo está finalizado, determinar estado real basado en si ganó
        if (sorteoEstado == 'finalizado' && animalitoGanadorId != null) {
          final detalles = bet['apuestas_detalle'] as List? ?? [];
          bool gano = false;

          for (final detalle in detalles) {
            if (detalle['animalito_id'] == animalitoGanadorId) {
              gano = true;
              break;
            }
          }

          if (gano) {
            wonBets++;
          } else {
            lostBets++;
          }
        } else {
          // Sorteo no finalizado, usar estado actual
          if (betEstado == 'ganadora') {
            wonBets++;
          } else if (betEstado == 'perdedora') {
            lostBets++;
          }
        }
      }

      debugPrint('✅ Apuestas ganadas (reales): $wonBets');
      debugPrint('❌ Apuestas perdidas (reales): $lostBets');

      // Calcular apuestas pendientes - verificar sorteos finalizados
      final allBetsResponse = await _supabase
          .from('apuestas')
          .select('estado, sorteos(estado)')
          .eq('user_id', userId);

      int realPendingBets = 0;
      int finalizadasSinActualizar = 0;

      for (final bet in allBetsResponse) {
        final betEstado = bet['estado'];
        final sorteoEstado = bet['sorteos']?['estado'];

        if (betEstado == 'pendiente') {
          // Si el sorteo está finalizado, la apuesta debería estar resuelta
          if (sorteoEstado == 'finalizado') {
            finalizadasSinActualizar++;
          } else {
            // Sorteo no finalizado = realmente pendiente
            realPendingBets++;
          }
        }
      }

      final pendingBets = realPendingBets;
      debugPrint('⏳ Apuestas realmente pendientes: $pendingBets');
      debugPrint('🔄 Apuestas finalizadas sin actualizar estado: $finalizadasSinActualizar');

      // Calcular porcentajes
      final wonPercentage = totalBets > 0 ? (wonBets / totalBets) * 100 : 0;
      final lostPercentage = totalBets > 0 ? (lostBets / totalBets) * 100 : 0;
      final pendingPercentage = totalBets > 0 ? (pendingBets / totalBets) * 100 : 0;

      // Calcular ganancias totales basadas en sorteos finalizados
      double totalWon = 0.0;

      for (final bet in allBetsWithState) {
        final sorteoEstado = bet['sorteos']?['estado'];
        final animalitoGanadorId = bet['sorteos']?['animalito_ganador_id'];

        // Solo calcular ganancias para sorteos finalizados
        if (sorteoEstado == 'finalizado' && animalitoGanadorId != null) {
          final detalles = bet['apuestas_detalle'] as List? ?? [];
          bool gano = false;
          double montoApostado = 0.0;

          for (final detalle in detalles) {
            if (detalle['animalito_id'] == animalitoGanadorId) {
              gano = true;
              montoApostado = (detalle['monto'] as num?)?.toDouble() ?? 0.0;
              break;
            }
          }

          if (gano) {
            // Calcular ganancia proporcional
            final sorteoId = bet['sorteo_id'];
            final totalApostadoGanador = await _calcularTotalApostadoAnimalito(sorteoId, animalitoGanadorId);
            final totalApostadoSorteo = await _calcularTotalApostadoSorteo(sorteoId);

            if (totalApostadoGanador > 0) {
              final proporcionGanador = montoApostado / totalApostadoGanador;
              final gananciaCalculada = (totalApostadoSorteo * 0.9) * proporcionGanador;
              totalWon += gananciaCalculada;
            }
          }
        }
      }

      debugPrint('💰 Ganancias totales calculadas: $totalWon');

      // Obtener apuestas por día (últimos 7 días)
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final monthlyBetsResponse = await _supabase
          .from('apuestas')
          .select('created_at, monto_apostado, estado, monto_ganado')
          .eq('user_id', userId)
          .gte('created_at', sevenDaysAgo.toIso8601String());

      debugPrint('📅 Apuestas mensuales obtenidas: ${monthlyBetsResponse.length}');

      // Procesar datos diarios (últimos 7 días)
      final dailyData = <String, Map<String, dynamic>>{};

      for (var i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyData[dayKey] = {
          'total': 0,
          'won': 0,
          'lost': 0,
          'pending': 0,
          'amount': 0.0,
          'winnings': 0.0,
        };
      }

      for (final bet in monthlyBetsResponse) {
        final createdAt = DateTime.parse(bet['created_at']);
        final dayKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

        if (dailyData.containsKey(dayKey)) {
          final data = dailyData[dayKey]!;
          data['total'] = (data['total'] as int) + 1;

          if (bet['estado'] == 'ganadora') {
            data['won'] = (data['won'] as int) + 1;
            data['winnings'] = (data['winnings'] as double) + (double.tryParse(bet['monto_ganado'].toString()) ?? 0);
          } else if (bet['estado'] == 'perdedora') {
            data['lost'] = (data['lost'] as int) + 1;
          } else {
            data['pending'] = (data['pending'] as int) + 1;
          }

          data['amount'] = (data['amount'] as double) + (double.tryParse(bet['monto_apostado'].toString()) ?? 0);
        }
      }

      // Preparar datos para gráficos diarios
      final monthlyChartData = dailyData.entries.map((entry) {
        final dateParts = entry.key.split('-');
        final day = dateParts[2];
        final month = dateParts[1];
        return {
          'month': '$day/$month', // Día/Mes
          'won': entry.value['won'],
          'lost': entry.value['lost'],
          'pending': entry.value['pending'],
          'amount': entry.value['amount'],
          'winnings': entry.value['winnings'],
        };
      }).toList();

      debugPrint('📈 Datos diarios procesados: ${monthlyChartData.length} días');

      // Obtener apuestas por animalito - consulta directa en lugar de RPC
      final animalBetsResponse = await _supabase
          .from('apuestas_detalle')
          .select('''
            animalito_id,
            animalitos!inner(
              nombre,
              numero_str
            ),
            monto,
            apuestas!inner(user_id)
          ''')
          .eq('apuestas.user_id', userId); // Relación con apuestas

      debugPrint('🐾 Apuestas por animalito obtenidas: ${animalBetsResponse.length}');

      // Procesar datos de animalitos
      final animalStats = <String, Map<String, dynamic>>{};

      for (final detalle in animalBetsResponse) {
        final animalito = detalle['animalitos'];
        final animalNombre = animalito['nombre'] as String;
        final monto = (detalle['monto'] as num?)?.toDouble() ?? 0.0;

        if (animalStats.containsKey(animalNombre)) {
          animalStats[animalNombre]!['count'] = (animalStats[animalNombre]!['count'] as int) + 1;
          animalStats[animalNombre]!['total_amount'] = (animalStats[animalNombre]!['total_amount'] as double) + monto;
        } else {
          animalStats[animalNombre] = {
            'animal_nombre': animalNombre,
            'count': 1,
            'total_amount': monto,
          };
        }
      }

      final animalBets = animalStats.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      debugPrint('✅ Estadísticas completas obtenidas');

      return {
        'totalBets': totalBets,
        'wonBets': wonBets,
        'lostBets': lostBets,
        'pendingBets': pendingBets,
        'wonPercentage': wonPercentage,
        'lostPercentage': lostPercentage,
        'pendingPercentage': pendingPercentage,
        'totalWon': totalWon,
        'monthlyData': monthlyChartData,
        'animalBets': animalBets,
      };
    } catch (e) {
      debugPrint('❌ Error al obtener estadísticas: $e');
      rethrow;
    }
  }

  // Generar datos para el gráfico de líneas de apuestas mensuales
  List<FlSpot> getMonthlyBetsSpots(List<dynamic> monthlyData) {
    return monthlyData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final data = entry.value as Map<String, dynamic>;
      return FlSpot(index, (data['total'] as int?)?.toDouble() ?? 0.0);
    }).toList();
  }

  // Generar datos para el gráfico de barras de apuestas por estado
  List<BarChartGroupData> getMonthlyBarsData(List<dynamic> monthlyData) {
    return monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['won'] as int?)?.toDouble() ?? 0.0,
            color: Colors.green,
            width: 8,
          ),
          BarChartRodData(
            toY: (data['lost'] as int?)?.toDouble() ?? 0.0,
            color: Colors.red,
            width: 8,
          ),
          BarChartRodData(
            toY: (data['pending'] as int?)?.toDouble() ?? 0.0,
            color: Colors.blue,
            width: 8,
          ),
        ],
        showingTooltipIndicators: [0, 1, 2],
      );
    }).toList();
  }

  // Generar datos para el gráfico de pastel de apuestas por animalito
  List<PieChartSectionData> getAnimalPieData(List<dynamic> animalBets) {
    final total = animalBets.fold<int>(0, (sum, item) => sum + ((item['count'] as int?) ?? 0));

    return animalBets.map<Map<String, dynamic>>((item) {
      final count = (item['count'] as int?) ?? 0;
      final percentage = total > 0 ? count / total * 100 : 0;
      return {
        'value': percentage,
        'title': '${item['animal_nombre']} (${percentage.toStringAsFixed(1)}%)',
        'color': getColorForAnimal(item['animal_nombre'] as String? ?? ''),
        'radius': 80.0,
      };
    }).map<PieChartSectionData>((item) => PieChartSectionData(
      color: item['color'],
      value: item['value'],
      title: item['title'],
      radius: item['radius'],
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    )).toList();
  }

  // Obtener color para cada animalito (puedes personalizar esto)
  Color getColorForAnimal(String animalName) {
    // Mapa de colores para animales comunes
    final colorMap = <String, Color>{
      'Tigre': Colors.orange,
      'León': Colors.amber,
      'Águila': Colors.brown,
      'Serpiente': Colors.green,
      'Delfín': Colors.blue,
      'Elefante': Colors.grey,
      'Mono': Colors.brown[300]!,
      'Loro': Colors.green[300]!,
      'Toro': Colors.red[300]!,
      'Caballo': Colors.brown[500]!,
      // Agrega más animales según sea necesario
    };

    // Si el animal está en el mapa, devuelve su color, de lo contrario genera uno basado en el hash
    return colorMap[animalName] ?? generateColorFromString(animalName);
  }

  // Generar un color consistente a partir de un string
  Color generateColorFromString(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final hue = (hash.abs() % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
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
