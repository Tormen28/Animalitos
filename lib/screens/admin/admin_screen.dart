import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animalitos_lottery/services/auth_service.dart';
import 'package:animalitos_lottery/services/admin_service.dart';
import 'package:animalitos_lottery/screens/admin/sorteos/sorteos_screen.dart';
import 'package:animalitos_lottery/screens/admin/usuarios/usuarios_screen.dart';
import 'package:animalitos_lottery/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late final AdminService _adminService;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // State variables
  Map<String, dynamic> _estadisticas = {
    'total_usuarios': 0,
    'total_apuestas': 0,
    'monto_total_apostado': 0,
    'estadisticas_financieras': {},
    'apuestas_por_estado': {},
    'animales_mas_apostados': [],
    'ultimas_transacciones': [],
  };
  bool _isLoading = true;
  String _error = '';
  
  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _adminService = AdminService();
    _tabController = TabController(length: 3, vsync: this);
    
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }
  
  // Cargar estadísticas
  Future<void> _loadStats() async {
    if (!mounted) return;

    try {
      debugPrint('📊 Cargando estadísticas del dashboard');
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final stats = await _adminService.getEstadisticas();
      debugPrint('✅ Estadísticas cargadas: ${stats.keys.join(', ')}');

      if (!mounted) return;

      setState(() {
        _estadisticas = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar estadísticas: $e');
      if (!mounted) return;

      setState(() {
        _error = 'Error al cargar estadísticas: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _handleLogout() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _authService.signOut();
        if (!mounted) return;

        // Usar Go Router para navegación consistente
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildEstadisticasCard(String titulo, dynamic valor, IconData icono, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              valor.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalMasApostado() {
    final animales = _estadisticas['animales_mas_apostados'] as List? ?? [];
    
    if (animales.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay datos de animales apostados'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Animales más apostados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...animales.take(5).map((animal) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: ClipOval(
                      child: Image.asset(
                        'imgAn/${animal['numero'] != null ? int.parse(animal['numero'].toString()) + 1 : 1}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image for ${animal['nombre']}: $error');
                          debugPrint('Animal data: $animal');
                          return Center(
                            child: Text(
                              animal['nombre']?[0]?.toUpperCase() ?? 'A',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${animal['nombre']} (${animal['numero']})',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    '${animal['total_apuestas']} apuestas',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUltimasTransaccionesSinEmail() {
    final transacciones = _estadisticas['ultimas_transacciones'] as List? ?? [];

    if (transacciones.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay transacciones recientes'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Últimas transacciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...transacciones.map((transaccion) => ListTile(
              leading: CircleAvatar(
                child: Icon(
                  transaccion['tipo'] == 'deposito'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: Colors.white,
                ),
                backgroundColor: transaccion['tipo'] == 'deposito'
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text('Usuario ${transaccion['user_id']?.substring(0, 8) ?? 'Desconocido'}'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(
                  DateTime.parse(transaccion['fecha']).toLocal(),
                ),
              ),
              trailing: Text(
                '${transaccion['monto'] > 0 ? '+' : ''}${NumberFormat.currency(symbol: 'Bs').format(transaccion['monto'])}',
                style: TextStyle(
                  color: transaccion['monto'] > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Inicio'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.casino), text: 'Sorteos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de Inicio
          _buildHomeTab(),
          // Pestaña de Usuarios
          const UsuariosScreen(),
          // Pestaña de Sorteos
          const SorteosScreen(),
        ],
      ),
    );
  }
  
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 16.0 : 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(),
                      SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 16),
                      _buildAnimalMasApostado(),
                      SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 16),
                      _buildUltimasTransaccionesSinEmail(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildAnimalMasApostado(),
          const SizedBox(height: 24),
          _buildUltimasTransaccionesSinEmail(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final statsFinancieras = _estadisticas['estadisticas_financieras'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estadísticas principales
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatsCard(
              'Jugadores Registrados',
              _estadisticas['total_usuarios'] ?? 0,
              Icons.people,
              Colors.blue,
            ),
            _buildStatsCard(
              'Total Apuestas',
              _estadisticas['total_apuestas'] ?? 0,
              Icons.assignment,
              Colors.green,
            ),
            _buildStatsCard(
              'Monto Total Apostado',
              '${(_estadisticas['monto_total_apostado']?.toStringAsFixed(2) ?? '0')} Bs',
              Icons.attach_money,
              Colors.orange,
            ),
            _buildStatsCard(
              'Ganancia de la Casa',
              '${(statsFinancieras['ganancia_casa']?.toStringAsFixed(2) ?? '0')} Bs',
              Icons.business,
              Colors.purple,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Estadísticas financieras detalladas
        Card(
          elevation: 8,
          color: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Estadísticas Financieras',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFinancialStat(
                  '💰 Total Apostado',
                  statsFinancieras['total_apostado'] ?? 0,
                  Colors.blue,
                ),
                _buildFinancialStat(
                  '🎯 Total Ganado por Usuarios',
                  statsFinancieras['total_ganado_usuarios'] ?? 0,
                  Colors.green,
                ),
                _buildFinancialStat(
                  '❌ Total Perdido por Usuarios',
                  statsFinancieras['total_perdido_usuarios'] ?? 0,
                  Colors.red,
                ),
                _buildFinancialStat(
                  '🏢 Ganancia de la Casa',
                  statsFinancieras['ganancia_casa'] ?? 0,
                  Colors.purple,
                ),
                _buildFinancialStat(
                  '👥 Saldo Total Usuarios',
                  statsFinancieras['saldo_total_usuarios'] ?? 0,
                  Colors.orange,
                ),
                _buildFinancialStat(
                  '⚙️ Transacciones Admin',
                  statsFinancieras['transacciones_admin'] ?? 0,
                  Colors.teal,
                ),
                _buildFinancialStat(
                  '💸 Monto Admin Total',
                  statsFinancieras['monto_admin_total'] ?? 0,
                  Colors.amber,
                ),
                const Divider(color: Colors.grey, height: 32),
                _buildFinancialStat(
                  '⚖️ Balance General',
                  statsFinancieras['balance_general'] ?? 0,
                  (statsFinancieras['balance_general'] ?? 0) >= 0 ? Colors.green : Colors.red,
                  isBalance: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialStat(String label, dynamic value, Color color, {bool isBalance = false}) {
    String formattedValue;
    if (value is num) {
      if (isBalance && value < 0) {
        formattedValue = '-${value.abs().toStringAsFixed(2)} Bs';
      } else {
        formattedValue = '${value.toStringAsFixed(2)} Bs';
      }
    } else {
      formattedValue = value.toString();
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width > 600 ? 8.0 : 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            formattedValue,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, dynamic value, IconData icon, Color color) {
    return Card(
      elevation: 8,
      color: const Color(0xFF2D2D2D), // Fondo oscuro
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              const Color(0xFF1A1A1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20.0 : 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 12 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: MediaQuery.of(context).size.width > 600 ? 32 : 24, color: color),
              ),
              SizedBox(height: MediaQuery.of(context).size.width > 600 ? 12 : 8),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: color == const Color(0xFFFFD700) ? color : Colors.white, // Dorado mantiene su color
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.width > 600 ? 8 : 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFB0B0B0), // Gris claro
                  fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              'Gestionar Usuarios',
              Icons.people,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UsuariosScreen(),
                  ),
                );
              },
            ),
            _buildActionButton(
              'Gestionar Sorteos',
              Icons.list_alt,
              Colors.green,
              () {
                // Navegar a gestión de sorteos
              },
            ),
            _buildActionButton(
              'Cerrar Sorteo',
              Icons.lock_clock,
              Colors.orange,
              () {
                // Lógica para cerrar sorteo
              },
            ),
            _buildActionButton(
              'Ver Reportes',
              Icons.bar_chart,
              Colors.purple,
              () {
                // Navegar a reportes
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }

}
