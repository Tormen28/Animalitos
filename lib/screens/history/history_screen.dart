import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/loteria_service.dart';
import '../../widgets/app_scaffold.dart';
import 'enhanced_history_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Historial de Apuestas',
      body: const EnhancedHistoryScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Recargar el historial
          context.read<LoteriaService>().getMisApuestas();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
