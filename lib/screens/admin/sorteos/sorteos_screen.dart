import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animalitos_lottery/services/admin_service.dart';
import 'package:animalitos_lottery/theme/app_theme.dart';
import 'package:animalitos_lottery/models/animalito.dart';

class SorteosScreen extends StatefulWidget {
  const SorteosScreen({Key? key}) : super(key: key);

  @override
  State<SorteosScreen> createState() => _SorteosScreenState();
}

class _SorteosScreenState extends State<SorteosScreen> {
  final AdminService _adminService = AdminService();
  final _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> _sorteos = [];
  bool _cargando = true;
  String _error = '';
  DateTime? _fechaSeleccionada;
  TimeOfDay _horaSeleccionada = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _cargarSorteos();
  }

  Future<void> _cargarSorteos() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final sorteos = await _adminService.getSorteos();
      setState(() {
        _sorteos = sorteos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los sorteos: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFCC0000), // Rojo pasión
              onPrimary: Colors.white,
              surface: Color(0xFF2D2D2D),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      final TimeOfDay? hora = await showTimePicker(
        context: context,
        initialTime: _horaSeleccionada,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFCC0000), // Rojo pasión
                onPrimary: Colors.white,
                surface: Color(0xFF2D2D2D),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (hora != null) {
        setState(() {
          _fechaSeleccionada = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            hora.hour,
            hora.minute,
          );
          _horaSeleccionada = hora;
        });
      }
    }
  }

  Future<void> _crearSorteo() async {
    if (_fechaSeleccionada == null) return;

    try {
      await _adminService.crearSorteo(_fechaSeleccionada!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorteo creado exitosamente')),
        );
        _cargarSorteos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el sorteo: $e')),
        );
      }
    }
  }

  Future<void> _cerrarApuestas(int sorteoId) async {
    try {
      debugPrint('🔒 Cerrando apuestas para sorteo $sorteoId');
      await _adminService.cerrarApuestas(sorteoId);
      debugPrint('✅ Apuestas cerradas exitosamente para sorteo $sorteoId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apuestas cerradas exitosamente')),
        );
        _cargarSorteos();
      }
    } catch (e) {
      debugPrint('❌ Error al cerrar apuestas para sorteo $sorteoId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar las apuestas: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarGanador(int sorteoId) async {
    debugPrint('🎯 Iniciando selección de ganador para sorteo $sorteoId');

    // Obtener lista de animalitos para seleccionar usando el modelo Animalito
    final List<Map<String, dynamic>> animalitos = [];
    for (final animalito in Animalito.lottoActivoAnimalitos) {
      animalitos.add({
        'id': animalito.id,
        'numero': animalito.numeroStr, // Usar numeroStr directamente (00, 01, 02, etc.)
        'nombre': animalito.nombre,
        'imagenAsset': animalito.imagenAsset,
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : screenWidth > 400 ? 2 : 1;
    final imageSize = (screenWidth > 600 ? 180.0 : screenWidth > 400 ? 120.0 : 80.0) * 1.3;

    final animalSeleccionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎯 Seleccionar Animal Ganador'),
        content: SizedBox(
          width: double.maxFinite,
          height: screenWidth > 600 ? 500 : 400,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: animalitos.length,
            itemBuilder: (context, index) {
              final animal = animalitos[index];
              return ElevatedButton(
                onPressed: () => Navigator.pop(context, animal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006400), // Verde esmeralda
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(4), // Padding reducido
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Imagen del animalito - tamaño responsivo
                    Container(
                      width: imageSize,
                      height: imageSize,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700), width: 2), // Borde dorado
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          animal['imagenAsset'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading image for ${animal['nombre']}: $error');
                            return Center(
                              child: Text(
                                animal['nombre'][0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: imageSize * 0.3, // Tamaño proporcional
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Texto responsivo
                    Text(
                      animal['numero'],
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 12 : 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700), // Dorado
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      animal['nombre'],
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 10 : 8,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (animalSeleccionado != null) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Confirmar Ganador'),
          content: Text(
            '¿Estás seguro de que el ganador es:\n\n'
            '${animalSeleccionado['numero']} - ${animalSeleccionado['nombre']}?\n\n'
            'Esta acción calculará automáticamente las ganancias y no se puede deshacer.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000), // Rojo pasión
              ),
              child: const Text('Confirmar Ganador'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        try {
          debugPrint('🎯 Seleccionando ganador: sorteoId=$sorteoId, animalId=${animalSeleccionado['id']}, animal=${animalSeleccionado['numero']} - ${animalSeleccionado['nombre']}');
          await _adminService.seleccionarGanador(sorteoId, animalSeleccionado['id']);
          debugPrint('✅ Ganador seleccionado exitosamente');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 ¡Ganador seleccionado! ${animalSeleccionado['numero']} - ${animalSeleccionado['nombre']}'),
                backgroundColor: Colors.green,
              ),
            );
            _cargarSorteos();
          }
        } catch (e) {
          debugPrint('❌ Error al seleccionar ganador: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error al seleccionar el ganador: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Sorteos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSorteos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Column(
                  children: [
                    // Formulario para crear nuevo sorteo
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                '🎯 Crear Nuevo Sorteo',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006400), // Verde esmeralda
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A), // Fondo oscuro
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF404040)),
                                ),
                                child: ListTile(
                                  title: Text(
                                    _fechaSeleccionada == null
                                        ? '📅 Seleccionar fecha y hora del sorteo'
                                        : '📅 Fecha programada: ${DateFormat('dd/MM/yyyy HH:mm').format(_fechaSeleccionada!)}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFFFFD700), // Dorado
                                  ),
                                  onTap: () => _seleccionarFecha(context),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _fechaSeleccionada == null ? null : _crearSorteo,
                                      icon: const Icon(Icons.add_circle),
                                      label: const Text('Programar Sorteo'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFCC0000), // Rojo pasión
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _fechaSeleccionada = null;
                                      });
                                    },
                                    icon: const Icon(Icons.clear),
                                    tooltip: 'Limpiar selección',
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF404040),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Lista de sorteos
                    Expanded(
                      child: ListView.builder(
                        itemCount: _sorteos.length,
                        itemBuilder: (context, index) {
                          final sorteo = _sorteos[index];
                          final fecha = DateTime.parse(sorteo['hora_cierre']);
                          final estado = sorteo['estado'];
                          final animalGanador = sorteo['animalito_ganador'];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                'Sorteo #${sorteo['id']} - ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estado: ${_obtenerEstado(estado)}'),
                                  if (animalGanador != null)
                                    Text(
                                      'Ganador: ${animalGanador['nombre']} (${animalGanador['numero']})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: _buildAccionesSorteo(sorteo),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAccionesSorteo(Map<String, dynamic> sorteo) {
    final estado = sorteo['estado'];
    final sorteoId = sorteo['id'] as int;

    if (estado == 'pendiente' || estado == 'abierto') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_clock),
            label: const Text('Cerrar Apuestas'),
            onPressed: () => _cerrarApuestas(sorteoId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700), // Dorado
              foregroundColor: const Color(0xFF006400), // Verde esmeralda
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else if (estado == 'cerrado') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.emoji_events),
        label: const Text('Seleccionar Ganador'),
        onPressed: () => _seleccionarGanador(sorteoId),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCC0000), // Rojo pasión
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 4),
          Text(
            'Finalizado',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerEstado(String estado) {
    switch (estado) {
      case 'pendiente':
      case 'abierto':
        return '⏳ Abierto - Abierto para apuestas';
      case 'cerrado':
        return '🔒 Cerrado - Esperando selección de ganador';
      case 'finalizado':
        return '✅ Finalizado - Ganador seleccionado';
      default:
        return estado;
    }
  }
}
