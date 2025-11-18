import 'package:flutter/material.dart';

class AdminMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const AdminMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.color = Colors.blue,
  });

  static List<AdminMenuItem> getMenuItems() {
    return [
      const AdminMenuItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        route: '/admin',
        color: Colors.blue,
      ),
      const AdminMenuItem(
        title: 'Usuarios',
        icon: Icons.people,
        route: '/admin/users',
        color: Colors.green,
      ),
      const AdminMenuItem(
        title: 'Sorteos',
        icon: Icons.list_alt,
        route: '/admin/draws',
        color: Colors.orange,
      ),
      const AdminMenuItem(
        title: 'Configuración',
        icon: Icons.settings,
        route: '/admin/settings',
        color: Colors.purple,
      ),
    ];
  }
}
