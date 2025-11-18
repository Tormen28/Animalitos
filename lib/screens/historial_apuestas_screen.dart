import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/apuesta.dart';
import '../services/loteria_service.dart';
import '../widgets/custom_button.dart';

class HistorialApuestasScreen extends StatefulWidget {
  const HistorialApuestasScreen({super.key});

  @override
  _HistorialApuestasScreenState createState() => _HistorialApuestasScreenState();
}

class _HistorialApuestasScreenState extends State<HistorialApuestasScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  bool _isLoading = true;
  String? _errorMessage;
  List<Apuesta> _apuestas = [];
  List<Apuesta> _filteredApuestas = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _filtroEstado = 'Todas';
  final List<String> _estados = ['Todas', 'Pendientes', 'Ganadas', 'Perdidas'];

  @override
  void initState() {
    super.initState();
    _cargarApuestas();
  }

  Future<void> _cargarApuestas() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final loteriaService = Provider.of<LoteriaService>(context, listen: false);
      final apuestas = await loteriaService.getMisApuestas();
      
      if (mounted) {
        setState(() {
          _apuestas = apuestas;
          _aplicarFiltros();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar el historial de apuestas';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _aplicarFiltros() {
    List<Apuesta> filtradas = List.from(_apuestas);

    // Filtrar por fecha seleccionada
    if (_selectedDay != null) {
      filtradas = filtradas.where((apuesta) {
        final fechaApuesta = DateTime(
          apuesta.fechaJuego.year,
          apuesta.fechaJuego.month,
          apuesta.fechaJuego.day,
        );
        final fechaSeleccionada = DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        );
        return fechaApuesta.isAtSameMomentAs(fechaSeleccionada);
      }).toList();
    }

    // Filtrar por estado
    if (_filtroEstado != 'Todas') {
      filtradas = filtradas.where((apuesta) {
        switch (_filtroEstado) {
          case 'Pendientes':
            return apuesta.estado.toLowerCase() == 'pendiente';
          case 'Ganadas':
            return apuesta.estado.toLowerCase() == 'ganada';
          case 'Perdidas':
            return apuesta.estado.toLowerCase() == 'perdida';
          default:
            return true;
        }
      }).toList();
    }

    // Ordenar por fecha más reciente primero
    filtradas.sort((a, b) => b.fechaJuego.compareTo(a.fechaJuego));

    if (mounted) {
      setState(() {
        _filteredApuestas = filtradas;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Apuestas'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),
          
          // Calendario
          Card(
            margin: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = isSameDay(selectedDay, _selectedDay) ? null : selectedDay;
                  _focusedDay = focusedDay;
                  _aplicarFiltros();
                });
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarFormat: CalendarFormat.month,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha((Theme.of(context).colorScheme.primary.alpha * 0.5).round()),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),

          // Resumen
          if (_selectedDay != null || _filtroEstado != 'Todas')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (_selectedDay != null)
                    Chip(
                      label: Text(
                        _dateFormat.format(_selectedDay!),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedDay = null;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  if (_selectedDay != null && _filtroEstado != 'Todas')
                    const SizedBox(width: 8),
                  if (_filtroEstado != 'Todas')
                    Chip(
                      label: Text(
                        _filtroEstado,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _filtroEstado = 'Todas';
                          _aplicarFiltros();
                        });
                      },
                    ),
                  const Spacer(),
                  Text(
                    '${_filteredApuestas.length} apuestas',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de apuestas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredApuestas.isEmpty
                        ? _buildEmptyState()
                        : _buildListaApuestas(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: _estados.map((estado) {
          final isSelected = _filtroEstado == estado;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(estado),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filtroEstado = selected ? estado : 'Todas';
                  _aplicarFiltros();
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary.withAlpha((Theme.of(context).colorScheme.primary.alpha * 0.2).round()),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay apuestas para mostrar',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (_filtroEstado != 'Todas' || _selectedDay != null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Intenta con otros filtros o selecciona otra fecha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: _cargarApuestas,
            text: 'Recargar',
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildListaApuestas() {
    return RefreshIndicator(
      onRefresh: _cargarApuestas,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _filteredApuestas.length,
        itemBuilder: (context, index) {
          final apuesta = _filteredApuestas[index];
          return _buildApuestaItem(apuesta);
        },
      ),
    );
  }

  Widget _buildApuestaItem(Apuesta apuesta) {
    final theme = Theme.of(context);
    final bool esGanada = apuesta.estado.toLowerCase() == 'ganada';
    final bool esPerdida = apuesta.estado.toLowerCase() == 'perdida';
    final bool esPendiente = apuesta.estado.toLowerCase() == 'pendiente';

    Color getEstadoColor() {
      if (esGanada) return Colors.green;
      if (esPerdida) return Colors.red;
      return Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con fecha y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormat.format(apuesta.fechaJuego),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getEstadoColor().withAlpha((getEstadoColor().alpha * 0.1).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: getEstadoColor().withAlpha((getEstadoColor().alpha * 0.3).round())),
                  ),
                  child: Text(
                    apuesta.estado.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: getEstadoColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Detalles de la apuesta
            Row(
              children: [
                // Animalito
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((theme.colorScheme.primary.alpha * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        apuesta.animalito.numeroStr.padLeft(2, '0'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        apuesta.animalito.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Información de la apuesta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apuesta.sorteo.nombreSorteo,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hora: ${DateFormat('hh:mm a').format(apuesta.fechaJuego)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Montos
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${apuesta.montoApostado.toStringAsFixed(2)} Bs',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (esGanada && apuesta.montoGanado > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ganaste: ${apuesta.montoGanado.toStringAsFixed(2)} Bs',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Acciones adicionales
            if (esPendiente) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Acción para ver detalles o cancelar apuesta
                      _mostrarDetallesApuesta(apuesta);
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detalles'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDetallesApuesta(Apuesta apuesta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de la apuesta', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalleItem('Animalito', '${apuesta.animalito.numeroStr} - ${apuesta.animalito.nombre}'),
            const SizedBox(height: 8),
            _buildDetalleItem('Sorteo', apuesta.sorteo.nombreSorteo),
            const SizedBox(height: 8),
            _buildDetalleItem('Fecha', _dateFormat.format(apuesta.fechaJuego)),
            const SizedBox(height: 8),
            _buildDetalleItem('Hora', DateFormat('hh:mm a').format(apuesta.fechaJuego)),
            const SizedBox(height: 8),
            _buildDetalleItem('Monto', '${apuesta.montoApostado.toStringAsFixed(2)} Bs'),
            if (apuesta.estado.toLowerCase() == 'ganada' && apuesta.montoGanado > 0) ...[
              const SizedBox(height: 8),
              _buildDetalleItem(
                'Ganancia', 
                '${apuesta.montoGanado.toStringAsFixed(2)} Bs',
                isGanancia: true,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getEstadoColor(apuesta.estado).withAlpha((_getEstadoColor(apuesta.estado).alpha * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getEstadoColor(apuesta.estado).withAlpha((_getEstadoColor(apuesta.estado).alpha * 0.3).round()),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEstadoIcon(apuesta.estado),
                    size: 16,
                    color: _getEstadoColor(apuesta.estado),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    apuesta.estado.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: _getEstadoColor(apuesta.estado),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String titulo, String valor, {bool isGanancia = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$titulo:',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor,
            style: GoogleFonts.poppins(
              color: isGanancia ? Colors.green : Colors.black87,
              fontWeight: isGanancia ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'ganada':
        return Colors.green;
      case 'perdida':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'ganada':
        return Icons.check_circle;
      case 'perdida':
        return Icons.cancel;
      case 'pendiente':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}
