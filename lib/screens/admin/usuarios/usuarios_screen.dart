import 'package:flutter/material.dart';
import 'package:animalitos_lottery/services/admin_service.dart';
import 'package:animalitos_lottery/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({Key? key}) : super(key: key);

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final AdminService _adminService = AdminService();
  final _searchController = TextEditingController();
  
  Map<String, dynamic> _usuariosData = {};
  List<dynamic> _usuarios = [];
  int _paginaActual = 1;
  final int _porPagina = 10;
  bool _cargando = true;
  String _error = '';
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _cargando = true;
      _error = '';
    });

    try {
      final data = await _adminService.getUsuarios(
        busqueda: _busqueda,
        pagina: _paginaActual,
        porPagina: _porPagina,
      );
      
      setState(() {
        _usuariosData = data;
        _usuarios = data['usuarios'] ?? [];
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar usuarios: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _toggleBloqueoUsuario(String userId, bool actual) async {
    try {
      // Usar el método correcto de bloqueo/desbloqueo
      await _adminService.toggleBloquearUsuario(userId, !actual); // !actual porque queremos cambiar el estado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!actual ? 'Usuario bloqueado correctamente' : 'Usuario desbloqueado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarUsuarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado del usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDetallesUsuario(Map<String, dynamic> usuario) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👤 Detalles del Usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              _buildInfoSection('Información Básica', [
                _buildInfoRow('ID', usuario['id']?.substring(0, 8) ?? 'N/A'),
                _buildInfoRow('Email', usuario['auth']?['email'] ?? 'Sin email'),
                _buildInfoRow('Nombre', usuario['nombre'] ?? 'No especificado'),
                _buildInfoRow('Apellido', usuario['apellido'] ?? 'No especificado'),
                _buildInfoRow('Teléfono', usuario['telefono'] ?? 'No especificado'),
                _buildInfoRow('Saldo', '${usuario['saldo']?.toStringAsFixed(2) ?? '0.00'} Bs'),
                _buildInfoRow('Estado', usuario['bloqueado'] == true ? '🔒 Bloqueado' : '✅ Activo'),
                _buildInfoRow('Admin', usuario['es_admin'] == true ? '👑 Sí' : '👤 No'),
              ]),

              const SizedBox(height: 16),

              // Fechas importantes
              _buildInfoSection('Fechas Importantes', [
                _buildInfoRow('Creado', usuario['created_at'] != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(usuario['created_at']).toLocal())
                    : 'N/A'),
                _buildInfoRow('Última actualización', usuario['updated_at'] != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(usuario['updated_at']).toLocal())
                    : 'N/A'),
                _buildInfoRow('Último inicio', 'Información no disponible'),
              ]),

              const SizedBox(height: 16),

              // Estadísticas de apuestas
              FutureBuilder<Map<String, dynamic>>(
                future: _cargarEstadisticasUsuario(usuario['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoSection('Estadísticas de Apuestas', [
                      _buildInfoRow('Total Apostado', 'Cargando...'),
                      _buildInfoRow('Apuestas Ganadas', 'Cargando...'),
                      _buildInfoRow('Apuestas Perdidas', 'Cargando...'),
                      _buildInfoRow('Ratio de Ganancia', 'Cargando...'),
                    ]);
                  } else if (snapshot.hasError) {
                    return _buildInfoSection('Estadísticas de Apuestas', [
                      _buildInfoRow('Error', 'No se pudieron cargar las estadísticas'),
                    ]);
                  } else if (snapshot.hasData) {
                    final stats = snapshot.data!;
                    return _buildInfoSection('Estadísticas de Apuestas', [
                      _buildInfoRow('Total Apostado', '${stats['total_apostado']?.toStringAsFixed(2) ?? '0.00'} Bs'),
                      _buildInfoRow('Apuestas Ganadas', '${stats['apuestas_ganadas'] ?? 0}'),
                      _buildInfoRow('Apuestas Perdidas', '${stats['apuestas_perdidas'] ?? 0}'),
                      _buildInfoRow('Ratio de Ganancia', '${stats['ratio_ganancia']?.toStringAsFixed(1) ?? '0.0'}%'),
                    ]);
                  }
                  return _buildInfoSection('Estadísticas de Apuestas', [
                    _buildInfoRow('Sin datos', 'No hay estadísticas disponibles'),
                  ]);
                },
              ),

              const SizedBox(height: 16),

              // Últimas transacciones
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _cargarTransaccionesUsuario(usuario['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoSection('Últimas Transacciones', [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Cargando historial...', style: TextStyle(color: Colors.grey)),
                      ),
                    ]);
                  } else if (snapshot.hasError) {
                    return _buildInfoSection('Últimas Transacciones', [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Error al cargar transacciones', style: TextStyle(color: Colors.red)),
                      ),
                    ]);
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final transacciones = snapshot.data!;
                    return _buildInfoSection('Últimas Transacciones',
                      transacciones.map((transaccion) {
                        final fecha = transaccion['fecha'] != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaccion['fecha']).toLocal())
                            : 'N/A';
                        final tipo = transaccion['tipo'] ?? 'N/A';
                        final monto = transaccion['monto'] != null
                            ? '${double.parse(transaccion['monto'].toString()).toStringAsFixed(2)} Bs'
                            : 'N/A';
                        final descripcion = transaccion['descripcion'] ?? 'Sin descripción';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '$fecha - $tipo',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFD700), // Dorado
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    monto,
                                    style: TextStyle(
                                      color: double.tryParse(transaccion['monto'].toString()) != null &&
                                             double.parse(transaccion['monto'].toString()) >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                descripcion,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return _buildInfoSection('Últimas Transacciones', [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No hay transacciones recientes', style: TextStyle(color: Colors.grey)),
                    ),
                  ]);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006400), // Verde esmeralda
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFFB0B0B0),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _cargarEstadisticasUsuario(String userId) async {
    try {
      debugPrint('📊 Iniciando carga de estadísticas para usuario $userId');

      // Obtener apuestas del usuario
      late final apuestasResponse;
      try {
        apuestasResponse = await Supabase.instance.client
            .from('apuestas')
            .select('estado, monto_apostado')
            .eq('user_id', userId);
        debugPrint('📊 Query successful, response type: ${apuestasResponse.runtimeType}');
      } catch (e) {
        debugPrint('📊 Query failed: $e');
        rethrow;
      }

      final apuestas = List<Map<String, dynamic>>.from(apuestasResponse.where((item) => item != null));
      debugPrint('📊 apuestasResponse type: ${apuestasResponse.runtimeType}');
      debugPrint('📊 apuestasResponse: $apuestasResponse');
      debugPrint('📊 apuestas length: ${apuestas.length}');
      debugPrint('📊 Apuestas obtenidas: ${apuestas.length}');

      double totalApostado = 0.0;
      int apuestasGanadas = 0;
      int apuestasPerdidas = 0;

      for (int i = 0; i < apuestas.length; i++) {
        final apuesta = apuestas[i];
        debugPrint('📊 Procesando apuesta $i: $apuesta');

        try {
          final monto = double.tryParse(apuesta['monto_apostado'].toString()) ?? 0.0;
          debugPrint('📊 Monto parseado: $monto');
          totalApostado += monto;
        } catch (e) {
          debugPrint('❌ Error al parsear monto: $e, valor: ${apuesta['monto_apostado']}');
          rethrow;
        }

        try {
          final estado = apuesta['estado'];
          debugPrint('📊 Estado: $estado (tipo: ${estado.runtimeType})');
          if (estado == 'ganada' || estado == 1) {
            apuestasGanadas++;
          } else if (estado == 'perdida' || estado == 2) {
            apuestasPerdidas++;
          }
        } catch (e) {
          debugPrint('❌ Error al procesar estado: $e, valor: ${apuesta['estado']}');
          rethrow;
        }
      }

      final totalApuestas = apuestasGanadas + apuestasPerdidas;
      final ratioGanancia = totalApuestas > 0 ? (apuestasGanadas / totalApuestas) * 100 : 0.0;

      debugPrint('📊 Estadísticas calculadas: totalApostado=$totalApostado, ganadas=$apuestasGanadas, perdidas=$apuestasPerdidas, ratio=$ratioGanancia');

      return {
        'total_apostado': totalApostado,
        'apuestas_ganadas': apuestasGanadas,
        'apuestas_perdidas': apuestasPerdidas,
        'ratio_ganancia': ratioGanancia,
      };
    } catch (e) {
      debugPrint('❌ Error al cargar estadísticas del usuario $userId: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _cargarTransaccionesUsuario(String userId) async {
    try {
      final transacciones = await Supabase.instance.client
          .from('transacciones')
          .select('tipo, monto, descripcion, fecha')
          .eq('user_id', userId)
          .order('fecha', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(transacciones);
    } catch (e) {
      debugPrint('Error al cargar transacciones del usuario $userId: $e');
      return [];
    }
  }

  Future<void> _mostrarDialogoAjusteSaldo(Map<String, dynamic> usuario) async {
    final montoController = TextEditingController();
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool esRecarga = true;
    bool procesando = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajustar Saldo'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Usuario: ${usuario['auth']?['email'] ?? 'N/A'}'),
                  const SizedBox(height: 16),
                  Text('Saldo actual: ${usuario['saldo']?.toStringAsFixed(2) ?? '0.00'} Bs'),
                  const SizedBox(height: 16),
                  ToggleButtons(
                    isSelected: [esRecarga, !esRecarga],
                    onPressed: (index) {
                      setState(() => esRecarga = index == 0);
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Recargar', style: TextStyle(color: Colors.green)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Retirar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: 'Bs',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un monto';
                      }
                      final monto = double.tryParse(value);
                      if (monto == null || monto <= 0) {
                        return 'El monto debe ser mayor a cero';
                      }
                      if (!esRecarga && monto > (usuario['saldo'] ?? 0)) {
                        return 'Saldo insuficiente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: motivoController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un motivo';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: procesando
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: procesando
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => procesando = true);
                        try {
                          final monto = double.parse(montoController.text);
                          final montoFinal = esRecarga ? monto : -monto;

                          await _adminService.actualizarSaldoUsuario(
                            usuario['id'],
                            montoFinal,
                            motivoController.text,
                          );

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saldo actualizado correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _cargarUsuarios();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => procesando = false);
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: esRecarga ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: procesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(esRecarga ? 'Recargar' : 'Retirar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D), // Fondo oscuro
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF404040)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '🔍 Buscar usuario por correo',
                  hintStyle: const TextStyle(color: Color(0xFF808080)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)), // Dorado
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFFCC0000)), // Rojo pasión
                          onPressed: () {
                            _searchController.clear();
                            _busqueda = '';
                            _paginaActual = 1;
                            _cargarUsuarios();
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) {
                  _busqueda = value;
                  _paginaActual = 1;
                  _cargarUsuarios();
                },
              ),
            ),
          ),
          _cargando
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error.isNotEmpty
                  ? Expanded(
                      child: Center(child: Text(_error)),
                    )
                  : _buildListaUsuarios(),
        ],
      ),
    );
  }

  Widget _buildListaUsuarios() {
    if (_usuarios.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No se encontraron usuarios'),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final usuario = _usuarios[index];
                final email = usuario['auth']?['email'] ?? 'Sin correo';
                final ultimoInicio = 'Información no disponible';
                final bloqueado = usuario['bloqueado'] == true;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saldo: ${usuario['saldo']?.toStringAsFixed(2) ?? '0.00'} Bs',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Último inicio: $ultimoInicio',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withOpacity(0.1), // Dorado sutil
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.attach_money,
                                      color: Color(0xFFFFD700), // Dorado
                                      size: 20,
                                    ),
                                    onPressed: () => _mostrarDialogoAjusteSaldo(usuario),
                                    tooltip: '💰 Ajustar saldo',
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: bloqueado
                                        ? const Color(0xFFCC0000).withOpacity(0.1) // Rojo pasión sutil
                                        : const Color(0xFF006400).withOpacity(0.1), // Verde esmeralda sutil
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      bloqueado ? Icons.lock_open : Icons.lock_outline,
                                      color: bloqueado ? const Color(0xFFCC0000) : const Color(0xFF006400), // Rojo o verde
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleBloqueoUsuario(
                                      usuario['id'],
                                      bloqueado,
                                    ),
                                    tooltip: bloqueado ? '🔓 Desbloquear usuario' : '🔒 Bloquear usuario',
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0066CC).withOpacity(0.1), // Azul sutil
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Color(0xFF0066CC), // Azul
                                      size: 20,
                                    ),
                                    onPressed: () => _mostrarDetallesUsuario(usuario),
                                    tooltip: '👤 Ver detalles completos',
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_usuariosData['total'] > _porPagina)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _paginaActual > 1
                        ? () {
                            setState(() => _paginaActual--);
                            _cargarUsuarios();
                          }
                        : null,
                  ),
                  Text(
                    'Página $_paginaActual de ${(_usuariosData['total'] / _porPagina).ceil()}',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _paginaActual < (_usuariosData['total'] / _porPagina).ceil()
                        ? () {
                            setState(() => _paginaActual++);
                            _cargarUsuarios();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
