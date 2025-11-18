import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animalitos_lottery/services/apuesta_service.dart';
import 'package:animalitos_lottery/widgets/custom_dropdown.dart';
import 'package:animalitos_lottery/widgets/date_picker_field.dart';

class BetHistoryScreen extends StatefulWidget {
  const BetHistoryScreen({super.key});

  @override
  _BetHistoryScreenState createState() => _BetHistoryScreenState();
}

class _BetHistoryScreenState extends State<BetHistoryScreen> {
  final ApuestaService _apuestaService = ApuestaService();
  final List<dynamic> _apuestas = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtros
  String? _estadoFiltro;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  final _estados = [
    {'value': null, 'label': 'Todos'},
    {'value': 'pendiente', 'label': 'Pendientes'},
    {'value': 'ganada', 'label': 'Ganadas'},
    {'value': 'perdida', 'label': 'Perdidas'},
    {'value': 'cancelada', 'label': 'Canceladas'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarApuestas();
  }

  Future<void> _cargarApuestas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apuestas = await _apuestaService.getHistorialApuestas(
        estado: _estadoFiltro,
        desde: _fechaInicio,
        hasta: _fechaFin,
      );

      setState(() {
        _apuestas.clear();
        _apuestas.addAll(apuestas);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el historial de apuestas';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    _cargarApuestas();
    Navigator.of(context).pop();
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFiltros(),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filtrar por',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CustomDropdown<String?>(
            value: _estadoFiltro,
            items: _estados
                .map((e) => DropdownMenuItem(
                      value: e['value'],
                      child: Text(e['label']!), // Añadido operador de aserción no nulo
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _estadoFiltro = value);
            },
            hint: 'Estado',
          ),
          const SizedBox(height: 16),
          DatePickerField(
            label: 'Fecha desde',
            selectedDate: _fechaInicio,
            onDateSelected: (date) {
              setState(() => _fechaInicio = date);
            },
          ),
          const SizedBox(height: 16),
          DatePickerField(
            label: 'Fecha hasta',
            selectedDate: _fechaFin,
            onDateSelected: (date) {
              setState(() => _fechaFin = date);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _aplicarFiltros,
            child: const Text('Aplicar Filtros'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildApuestaItem(dynamic apuesta) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: 'Bs', decimalDigits: 2);

    Color getStatusColor() {
      switch (apuesta.estado) {
        case 'ganada':
          return Colors.green;
        case 'perdida':
          return Colors.red;
        case 'cancelada':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    String getStatusText() {
      switch (apuesta.estado) {
        case 'ganada':
          return 'Ganada';
        case 'perdida':
          return 'Perdida';
        case 'cancelada':
          return 'Cancelada';
        default:
          return 'Pendiente';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(
          'Sorteo #${apuesta.sorteo.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${apuesta.animalito.nombre} (${apuesta.animalito.numeroStr})'),
            Text('${DateFormat('dd/MM/yyyy').format(apuesta.fechaJuego)} • ${getStatusText()}')
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(apuesta.montoApostado),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (apuesta.montoGanado > 0) ...[
              const SizedBox(height: 2),
              Text(
                '+${currencyFormat.format(apuesta.montoGanado)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getStatusColor().withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            getStatusText()[0].toUpperCase(),
            style: TextStyle(
              color: getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Apuestas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _apuestas.isEmpty
                  ? const Center(child: Text('No hay apuestas para mostrar'))
                  : RefreshIndicator(
                      onRefresh: _cargarApuestas,
                      child: ListView.builder(
                        itemCount: _apuestas.length,
                        itemBuilder: (context, index) => _buildApuestaItem(_apuestas[index]),
                      ),
                    ),
    );
  }
}
