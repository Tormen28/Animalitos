import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animalitos_lottery/models/sorteo.dart';
import 'package:animalitos_lottery/models/animalito.dart';
import 'package:animalitos_lottery/screens/apuesta_screen.dart';
import 'package:animalitos_lottery/screens/history/bet_history_screen.dart';
import 'package:animalitos_lottery/services/sorteo_service.dart';
import 'package:animalitos_lottery/services/loteria_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SorteoService _sorteoService = SorteoService();
  List<Sorteo> _sorteos = [];
  List<Map<String, dynamic>> _resultados = [];
  bool _isLoading = true;
  bool _isLoadingResultados = true;
  String? _error;

  // Mapa para almacenar el conteo de apuestas por sorteo
  Map<int, int> _conteoApuestas = {};

  // Paginación para resultados
  int _paginaResultados = 1;
  final int _resultadosPorPagina = 8;
  int _totalResultados = 0;

  @override
  void initState() {
    super.initState();
    _cargarSorteos();
    _cargarResultados();
  }

  Future<void> _cargarSorteos() async {
    try {
      debugPrint('🏠 Cargando sorteos en pantalla principal');
      final sorteos = await _sorteoService.getSorteosActivos();

      // Filtrar solo sorteos que están realmente activos
      final sorteosActivos = sorteos.where((sorteo) => sorteo.activo).toList();

      debugPrint('🏠 Sorteos totales: ${sorteos.length}, sorteos activos: ${sorteosActivos.length}');

      // Cargar el conteo de apuestas para cada sorteo activo
      final Map<int, int> conteoApuestas = {};
      for (final sorteo in sorteosActivos) {
        final loteriaService = LoteriaService();
        final totalApuestas = await loteriaService.getTotalApuestasSorteo(sorteo.id);
        conteoApuestas[sorteo.id] = totalApuestas;
        debugPrint('🎯 Sorteo ${sorteo.id} (${sorteo.nombreSorteo}): $totalApuestas apuestas');
      }

      setState(() {
        _sorteos = sorteosActivos;
        _conteoApuestas = conteoApuestas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar sorteos en home: $e');
      setState(() {
        _error = 'Error al cargar los sorteos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarResultados() async {
    try {
      debugPrint('🏆 Cargando resultados de sorteos - Página $_paginaResultados');
      final supabase = Supabase.instance.client;

      // Obtener el total de resultados primero
      final countResponse = await supabase
          .from('resultados')
          .select()
          .count(CountOption.exact);

      _totalResultados = countResponse.count ?? 0;
      debugPrint('🏆 Total de resultados: $_totalResultados');

      // Calcular offset para paginación
      final offset = (_paginaResultados - 1) * _resultadosPorPagina;

      final response = await supabase
          .from('resultados')
          .select('''
            *,
            sorteos(*),
            animalitos(*)
          ''')
          .order('fecha_sorteo', ascending: false)
          .range(offset, offset + _resultadosPorPagina - 1);

      debugPrint('🏆 Resultados obtenidos para página $_paginaResultados: ${response.length}');

      // Filtrar solo resultados que tienen datos válidos
      final resultadosValidos = response.where((resultado) {
        final sorteo = resultado['sorteos'];
        final animalito = resultado['animalitos'];
        return sorteo != null && animalito != null &&
               sorteo['nombre_sorteo'] != null && animalito['nombre'] != null;
      }).toList();

      debugPrint('🏆 Resultados válidos: ${resultadosValidos.length}');

      setState(() {
        _resultados = List<Map<String, dynamic>>.from(resultadosValidos);
        _isLoadingResultados = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar resultados: $e');
      setState(() {
        _isLoadingResultados = false;
        _resultados = []; // Asegurar que esté vacío en caso de error
      });
    }
  }

  Future<void> _refrescar() async {
    setState(() {
      _isLoading = true;
      _isLoadingResultados = true;
      _paginaResultados = 1; // Resetear a primera página al refrescar
      _conteoApuestas.clear(); // Limpiar conteo anterior
    });
    await Future.wait([
      _cargarSorteos(),
      _cargarResultados(),
    ]);
  }

  void _cambiarPaginaResultados(int pagina) {
    setState(() {
      _paginaResultados = pagina;
      _isLoadingResultados = true;
    });
    _cargarResultados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animalitos Lottery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refrescar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refrescar,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sorteos activos
            if (_sorteos.isNotEmpty) ...[
              const Text(
                '🎯 SORTEOS ACTIVOS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCC0000), // Rojo pasión
                ),
              ),
              const SizedBox(height: 16),
              ..._sorteos.map((sorteo) => _buildSorteoCard(sorteo)),
              const SizedBox(height: 32),
            ],

            // Resultados
            const Text(
              '🏆 ÚLTIMOS RESULTADOS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006400), // Verde esmeralda
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingResultados)
              const Center(child: CircularProgressIndicator())
            else if (_resultados.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No hay resultados disponibles',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Mostrar máximo 8 resultados por página
                  _buildResultadosGrid(_resultados.take(8).toList()),
                  if (_totalResultados > 8)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: _paginaResultados > 1
                                ? () => _cambiarPaginaResultados(_paginaResultados - 1)
                                : null,
                          ),
                          Text(
                            'Página $_paginaResultados de ${(_totalResultados / 8).ceil()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: _paginaResultados < (_totalResultados / 8).ceil()
                                ? () => _cambiarPaginaResultados(_paginaResultados + 1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSorteoCard(Sorteo sorteo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          debugPrint('🎯 Navegando a pantalla de apuestas para sorteo ${sorteo.id} - ${sorteo.nombreSorteo}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApuestaScreen(sorteo: sorteo),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sorteo.nombreConHora,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: sorteo.activo
                          ? const Color(0xFF006400).withOpacity(0.8) // Verde esmeralda
                          : Colors.orange.withOpacity(0.8), // Naranja para cerrado
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: sorteo.activo
                            ? const Color(0xFF006400)
                            : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      sorteo.activo
                          ? '🟢 ABIERTO'
                          : '🟠 CERRADO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              if (sorteo.descripcion != null) ...{
                Text(
                  sorteo.descripcion!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
              },
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    Icons.schedule,
                    'Cierra',
                    sorteo.tiempoRestanteFormateado,
                  ),
                  _buildInfoItem(
                    Icons.emoji_events,
                    'Ganador',
                    'Pendiente',
                  ),
                  _buildInfoItem(
                    Icons.people,
                    'Apuestas',
                    (_conteoApuestas[sorteo.id] ?? 0).toString(),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Indicador visual del tiempo restante
              if (sorteo.activo) ...{
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sorteo.tiempoRestante.inHours < 1
                        ? Colors.red.withOpacity(0.1) // Menos de 1 hora - rojo
                        : sorteo.tiempoRestante.inHours < 2
                            ? Colors.orange.withOpacity(0.1) // Menos de 2 horas - naranja
                            : Colors.green.withOpacity(0.1), // Más tiempo - verde
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sorteo.tiempoRestante.inHours < 1
                          ? Colors.red
                          : sorteo.tiempoRestante.inHours < 2
                              ? Colors.orange
                              : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sorteo.tiempoRestante.inHours < 1
                            ? Icons.timer
                            : sorteo.tiempoRestante.inHours < 2
                                ? Icons.schedule
                                : Icons.access_time,
                        size: 16,
                        color: sorteo.tiempoRestante.inHours < 1
                            ? Colors.red
                            : sorteo.tiempoRestante.inHours < 2
                                ? Colors.orange
                                : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sorteo.tiempoRestanteFormateado,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sorteo.tiempoRestante.inHours < 1
                              ? Colors.red
                              : sorteo.tiempoRestante.inHours < 2
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8.0),
              },
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sorteo.activo ? () {
                    debugPrint('🎯 Botón apostar presionado para sorteo ${sorteo.id} - ${sorteo.nombreSorteo}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApuestaScreen(sorteo: sorteo),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sorteo.estaAbierto
                        ? const Color(0xFFCC0000) // Rojo pasión
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(sorteo.activo ? '🎯 APOSTAR AHORA' : '⏰ SORTEO CERRADO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultadosGrid(List<Map<String, dynamic>> resultados) {
    if (resultados.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : screenWidth > 400 ? 2 : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8, // Relación de aspecto más alta para cards cuadradas
      ),
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        return _buildResultadoCardGrid(resultados[index]);
      },
    );
  }

  Widget _buildResultadoCardGrid(Map<String, dynamic> resultado) {
    final sorteo = resultado['sorteos'] as Map<String, dynamic>? ?? {};
    final animalito = resultado['animalitos'] as Map<String, dynamic>? ?? {};

    // Validar que los datos necesarios estén presentes
    if (sorteo.isEmpty || animalito.isEmpty ||
        sorteo['nombre_sorteo'] == null || animalito['nombre'] == null) {
      debugPrint('⚠️ Resultado inválido, omitiendo: $resultado');
      return const SizedBox.shrink();
    }

    final fechaSorteo = DateTime.parse(resultado['fecha_sorteo'] as String);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth > 600 ? 225.0 : screenWidth > 400 ? 150.0 : 100.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: EdgeInsets.all(screenWidth > 600 ? 12.0 : screenWidth > 400 ? 8.0 : 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF006400), // Verde esmeralda
              Color(0xFF004400),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen del animalito - tamaño responsivo
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 3), // Borde más grueso
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/images/animalitos/animalito_${(animalito['id'] as int? ?? 0).toString().padLeft(2, '0')}.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading image for ${animalito['nombre']}: $error');
                    return Center(
                      child: Text(
                        animalito['numero_str']?.toString() ?? '00',
                        style: TextStyle(
                          fontSize: imageSize * 0.2, // Tamaño proporcional
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Información del sorteo con HORA REAL del sorteo (ej: Tarde 3:00 PM)
            Text(
              '${sorteo['nombre_sorteo'] ?? 'Sorteo'} ${DateFormat('h:mm a').format(DateTime.parse(sorteo['hora_cierre'] ?? fechaSorteo.toIso8601String()))}',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 12 : screenWidth > 400 ? 10 : 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            // Número y nombre del animalito
            Text(
              '${animalito['numero_str'] ?? '00'} - ${animalito['nombre'] ?? 'Animalito'}',
              style: TextStyle(
                fontSize: screenWidth > 600 ? 14 : screenWidth > 400 ? 12 : 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700), // Dorado
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Fecha y badge FINALIZADO en una línea
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(fechaSorteo),
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 10 : screenWidth > 400 ? 9 : 8,
                    color: const Color(0xFFB0B0B0),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 4 : 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1),
                  ),
                  child: Text(
                    'FINALIZADO',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: screenWidth > 600 ? 8 : screenWidth > 400 ? 7 : 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoCard(Map<String, dynamic> resultado) {
    final sorteo = resultado['sorteos'] as Map<String, dynamic>? ?? {};
    final animalito = resultado['animalitos'] as Map<String, dynamic>? ?? {};

    // Validar que los datos necesarios estén presentes
    if (sorteo.isEmpty || animalito.isEmpty ||
        sorteo['nombre_sorteo'] == null || animalito['nombre'] == null) {
      debugPrint('⚠️ Resultado inválido, omitiendo: $resultado');
      return const SizedBox.shrink();
    }

    final fechaSorteo = DateTime.parse(resultado['fecha_sorteo'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF006400), // Verde esmeralda
              Color(0xFF004400),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con fecha y sorteo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sorteo['nombre_sorteo'] ?? 'Sorteo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fechaSorteo),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2), // Dorado sutil
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1),
                  ),
                  child: const Text(
                    'FINALIZADO',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ganador destacado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Row(
                children: [
                  // Imagen del animalito
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/animalitos/animalito_${(animalito['id'] as int? ?? 0).toString().padLeft(2, '0')}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image for ${animalito['nombre']}: $error');
                          return Center(
                            child: Text(
                              animalito['numero_str']?.toString() ?? '00',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información del ganador
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎉 GANADOR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${animalito['numero_str'] ?? '00'} - ${animalito['nombre'] ?? 'Animalito'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (animalito['descripcion'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            animalito['descripcion'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0B0B0),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Estos métodos ya no se usan, pero se mantienen por compatibilidad
  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'en_curso':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'finalizado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String estado) {
    switch (estado.toLowerCase()) {
      case 'en_curso':
        return 'EN CURSO';
      case 'pendiente':
        return 'PENDIENTE';
      case 'finalizado':
        return 'FINALIZADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  String _computeEstado(Sorteo sorteo) {
    if (sorteo.estaAbierto) return 'en_curso';
    if (sorteo.haFinalizado) return 'finalizado';
    return 'pendiente';
  }
}
