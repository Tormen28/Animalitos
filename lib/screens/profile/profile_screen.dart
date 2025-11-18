import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/profile_info_item.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar el perfil';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Foto de perfil
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Información del perfil
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información Personal',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              ProfileInfoItem(
                                icon: Icons.person,
                                label: 'Nombre',
                                value: _userProfile?['nombre'] ?? 'No especificado',
                              ),
                              const Divider(),
                              ProfileInfoItem(
                                icon: Icons.email,
                                label: 'Correo',
                                value: _userProfile?['email'] ?? 'No especificado',
                              ),
                              if (_userProfile?['telefono'] != null) ...[
                                const Divider(),
                                ProfileInfoItem(
                                  icon: Icons.phone,
                                  label: 'Teléfono',
                                  value: _userProfile?['telefono'],
                                ),
                              ],
                              const Divider(),
                              ProfileInfoItem(
                                icon: Icons.account_balance_wallet,
                                label: 'Saldo',
                                value: '${(_userProfile?['saldo'] ?? 0).toStringAsFixed(2)} Bs',
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Botón de cerrar sesión
                      CustomButton(
                        onPressed: _signOut,
                        child: const Text('Cerrar Sesión'),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Botón para editar perfil
                      OutlinedButton(
                        onPressed: () => context.push('/profile/edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: AppConstants.primaryColor),
                        ),
                        child: Text(
                          'Editar Perfil',
                          style: GoogleFonts.poppins(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
