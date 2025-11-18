import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import '../../services/loteria_service.dart';
import '../../models/apuesta.dart';
import '../../models/animalito.dart';
import '../../models/sorteo.dart';
import '../../widgets/app_scaffold.dart';
import 'dart:async';

class EnhancedHistoryScreen extends StatefulWidget {
  const EnhancedHistoryScreen({super.key});

  @override
  _EnhancedHistoryScreenState createState() => _EnhancedHistoryScreenState();
}

class _EnhancedHistoryScreenState extends State<EnhancedHistoryScreen> with SingleTickerProviderStateMixin {
  final List<String> _filters = ['Todas', 'Ganadas', 'Perdidas', 'Pendientes'];
  String _selectedFilter = 'Todas';
  late StreamController<List<Map<String, dynamic>>> _ticketsController;
  late AnimationController _animationController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _ticketsController = StreamController<List<Map<String, dynamic>>>.broadcast();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Cargar tickets inmediatamente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  @override
  void dispose() {
    _ticketsController.close();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      debugPrint('🔄 Iniciando carga de historial de tickets...');
      final loteriaService = LoteriaService();
      final tickets = await loteriaService.getMisApuestasAgrupadas();
      debugPrint('✅ Tickets cargados: ${tickets.length} tickets');
      if (!_ticketsController.isClosed) {
        _ticketsController.add(tickets);
      }
    } catch (e) {
      debugPrint('❌ Error al cargar tickets: $e');
      if (!_ticketsController.isClosed) {
        _ticketsController.addError(e);
      }
    }
  }

  void _showWinAnimation() {
    setState(() => _showConfetti = true);
    _animationController.forward().then((_) {
      setState(() => _showConfetti = false);
      _animationController.reset();
    });
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, BuildContext context) {
    final theme = Theme.of(context);
    final sorteo = ticket['sorteo'] as Sorteo;
    final estado = ticket['estado'] as String;
    final montoTotal = ticket['monto_total'] as double;
    final montoGanadoTotal = ticket['monto_ganado_total'] as double;
    final apuestas = ticket['apuestas'] as List<Map<String, dynamic>>;
    final fechaJuego = ticket['fecha_juego'] as DateTime;
    final animalitoGanador = ticket['animalito_ganador'];

    final isWin = estado == 'ganadora';
    final isLoss = estado == 'perdedora';
    final isPending = estado == 'pendiente';

    return OpenContainer<bool>(
      openBuilder: (context, _) => _buildTicketDetail(ticket),
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      closedElevation: 2,
      closedColor: theme.cardColor,
      closedBuilder: (context, openContainer) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con sorteo, fecha y estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sorteo.nombreSorteo,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(fechaJuego),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(estado, theme).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(estado, theme),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(estado),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(estado, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mostrar animalito ganador si existe y es ganadora
                  if (estado == 'ganadora' && animalitoGanador != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Ganador: ${animalitoGanador['numero_str']} - ${animalitoGanador['nombre']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),

                  // Lista de animalitos apostados (máximo 3 para preview)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
              ...apuestas.take(3).map((apuesta) {
                final animalito = apuesta['animalito'] as Animalito;
                final monto = apuesta['monto'] as double;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        animalito.numeroStr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${monto.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (apuestas.length > 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.hintColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${apuestas.length - 3} más',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
            ],
                  ),

                  const SizedBox(height: 12),

                  // Totales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${apuestas.length} ${apuestas.length == 1 ? 'juego' : 'juegos'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          Text(
                            'Total: ${montoTotal.toStringAsFixed(2)} Bs',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (isWin)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Ganancia',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '+${montoGanadoTotal.toStringAsFixed(2)} Bs',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'ganadora':
        return Colors.green;
      case 'perdedora':
        return Colors.red;
      case 'pendiente':
        return theme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ganadora':
        return 'GANADA';
      case 'perdedora':
        return 'PERDIDA';
      case 'pendiente':
        return 'PENDIENTE';
      default:
        return 'DESCONOCIDO';
    }
  }

  Widget _buildTicketDetail(Map<String, dynamic> ticket) {
    final theme = Theme.of(context);
    final sorteo = ticket['sorteo'] as Sorteo;
    final estado = ticket['estado'] as String;
    final montoTotal = ticket['monto_total'] as double;
    final montoGanadoTotal = ticket['monto_ganado_total'] as double;
    final apuestas = ticket['apuestas'] as List<Map<String, dynamic>>;
    final fechaJuego = ticket['fecha_juego'] as DateTime;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket ${sorteo.nombreSorteo}'),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del ticket
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sorteo.nombreSorteo,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(estado, theme).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(estado, theme),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _getStatusText(estado),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _getStatusColor(estado, theme),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(fechaJuego)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lista de apuestas del ticket
            Text(
              'Apuestas Realizadas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...apuestas.map((apuesta) {
              final animalito = apuesta['animalito'] as Animalito;
              final monto = apuesta['monto'] as double;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          animalito.numeroStr,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              animalito.nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Monto apostado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${monto.toStringAsFixed(2)} Bs',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Resumen del ticket
            Card(
              elevation: 4,
              color: theme.primaryColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Apostado:',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${montoTotal.toStringAsFixed(2)} Bs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (estado == 'ganadora') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ganancia Total:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '+${montoGanadoTotal.toStringAsFixed(2)} Bs',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy - HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Mis Jugadas',
      body: Column(
        children: [
          // Filtros
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: theme.cardColor,
                    selectedColor: theme.primaryColor.withAlpha((theme.primaryColor.alpha * 0.2).round()),
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter 
                          ? theme.primaryColor 
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Lista de apuestas
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTickets,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _ticketsController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar los tickets',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadTickets,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando historial de tickets...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final tickets = snapshot.data!;

                  // Filtrar según el filtro seleccionado
                  final filteredTickets = tickets.where((ticket) {
                    if (_selectedFilter == 'Todas') return true;
                    if (_selectedFilter == 'Ganadas') return ticket['estado'] == 'ganadora';
                    if (_selectedFilter == 'Perdidas') return ticket['estado'] == 'perdedora';
                    if (_selectedFilter == 'Pendientes') return ticket['estado'] == 'pendiente';
                    return true;
                  }).toList();

                  if (filteredTickets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: theme.hintColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay tickets ${_selectedFilter.toLowerCase() == 'todas' ? '' : _selectedFilter.toLowerCase()}',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Los tickets aparecerán aquí después de realizar jugadas',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedFilter != 'Todas')
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextButton(
                                onPressed: () => setState(() => _selectedFilter = 'Todas'),
                                child: const Text('Ver todos'),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = filteredTickets[index];
                      return _buildTicketCard(ticket, context);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApuestaDetailScreen extends StatelessWidget {
  final Apuesta apuesta;

  const _ApuestaDetailScreen({super.key, required this.apuesta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWin = apuesta.estado == 'ganadora';
    final isLoss = apuesta.estado == 'perdedora';
    final isPending = apuesta.estado == 'pendiente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Apuesta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con número y animalito
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _getStatusColor(apuesta.estado, theme),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      apuesta.animalito.numeroStr,
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    apuesta.animalito.nombre,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      apuesta.estado.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(apuesta.estado, theme),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Detalles de la apuesta
            _buildDetailRow('Sorteo', apuesta.sorteo.nombreSorteo, context),
            _buildDetailRow('Fecha', DateFormat('dd/MM/yyyy').format(apuesta.fechaJuego), context),
            
            const Divider(height: 32),
            
            _buildDetailRow(
              'Monto apostado', 
              '${apuesta.montoApostado.toStringAsFixed(2)} Bs', 
              context,
              valueStyle: theme.textTheme.titleLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (isWin)
              _buildDetailRow(
                'Ganancia', 
                '+${apuesta.montoGanado.toStringAsFixed(2)} Bs', 
                context,
                valueStyle: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            if (isWin)
              _buildDetailRow(
                'Total', 
                '${(apuesta.montoApostado + apuesta.montoGanado).toStringAsFixed(2)} Bs', 
                context,
                valueStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            if (isPending)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Esperando resultados...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
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

  Widget _buildDetailRow(String label, String value, BuildContext context, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          Text(
            value,
            style: valueStyle ?? Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  // Deprecated: use _formatDate(DateTime) instead
  String _formatDateOldStr(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(DateTime date) {
    try {
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'ganadora':
        return Colors.green;
      case 'perdedora':
        return Colors.red;
      case 'pendiente':
        return theme.primaryColor;
      default:
        return Colors.grey;
    }
  }
}
