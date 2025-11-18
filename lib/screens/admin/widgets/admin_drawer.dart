import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../models/admin_menu_item.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;
  final Function(String) onItemSelected;
  final AuthService authService;

  const AdminDrawer({
    super.key,
    required this.currentRoute,
    required this.onItemSelected,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = AdminMenuItem.getMenuItems();
    final currentUser = authService.currentUser;
    
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              currentUser?.email?.split('@').first ?? 'Administrador',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                currentUser?.email?.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return ListTile(
                  leading: Icon(item.icon, color: item.color),
                  title: Text(item.title),
                  selected: currentRoute == item.route,
                  selectedTileColor: Colors.grey[200],
                  onTap: () => onItemSelected(item.route),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
