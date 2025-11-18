import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sorteo.dart';

class SorteoCard extends StatelessWidget {
  final Sorteo sorteo;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showTimeRemaining;

  const SorteoCard({
    super.key,
    required this.sorteo,
    this.isSelected = false,
    this.onTap,
    this.showTimeRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Indicador de estado
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: sorteo.estaAbierto ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              
              // Información del sorteo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del sorteo
                    Text(
                      sorteo.nombreSorteo,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? colorScheme.primary 
                            : textTheme.titleMedium?.color,
                      ),
                    ),
                    
                    // Hora de cierre
                    Text(
                      'Cierra a las ${sorteo.horaCierreFormateada}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: textTheme.bodySmall?.color?.withAlpha((textTheme.bodySmall!.color!.alpha * 0.8).round()),
                      ),
                    ),
                    
                    // Tiempo restante
                    if (showTimeRemaining && sorteo.estaAbierto) ...[
                      const SizedBox(height: 4),
                      Text(
                        sorteo.tiempoRestanteFormateado,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ] else if (showTimeRemaining) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cerrado',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Indicador de selección
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24,
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar una lista de sorteos
class SorteosList extends StatelessWidget {
  final List<Sorteo> sorteos;
  final int? selectedSorteoId;
  final Function(Sorteo) onSorteoSelected;
  final bool showTimeRemaining;

  const SorteosList({
    super.key,
    required this.sorteos,
    this.selectedSorteoId,
    required this.onSorteoSelected,
    this.showTimeRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    if (sorteos.isEmpty) {
      return Center(
        child: Text(
          'No hay sorteos disponibles',
          style: GoogleFonts.poppins(
            color: Theme.of(context).hintColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorteos.length,
      itemBuilder: (context, index) {
        final sorteo = sorteos[index];
        return SorteoCard(
          sorteo: sorteo,
          isSelected: selectedSorteoId == sorteo.id,
          onTap: () => onSorteoSelected(sorteo),
          showTimeRemaining: showTimeRemaining,
        );
      },
    );
  }
}
