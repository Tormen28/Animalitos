import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/animalito.dart';

class AnimalitoCard extends StatelessWidget {
  final Animalito animalito;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showNumber;

  const AnimalitoCard({
    super.key,
    required this.animalito,
    this.isSelected = false,
    this.onTap,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      colorScheme.primary.withAlpha((colorScheme.primary.alpha * 0.1).round()),
                      colorScheme.primary.withAlpha((colorScheme.primary.alpha * 0.05).round()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Número del animalito
              if (showNumber)
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    animalito.numeroStr.padLeft(2, '0'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              
              // Nombre del animalito
              Text(
                animalito.nombre,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? colorScheme.primary 
                      : theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Imagen del animalito
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        animalito.imagenAsset ?? 'imgAn/${animalito.id + 1}.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image for ${animalito.nombre}: $error');
                          debugPrint('Attempted path: ${animalito.imagenAsset ?? 'imgAn/${animalito.id + 1}.png'}');
                          return Center(
                            child: Text(
                              animalito.nombre[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar una cuadrícula de animalitos
class AnimalitosGrid extends StatelessWidget {
  final List<Animalito> animalitos;
  final List<int> selectedIndices;
  final Function(int) onAnimalitoSelected;
  final bool showNumbers;

  const AnimalitosGrid({
    super.key,
    required this.animalitos,
    required this.selectedIndices,
    required this.onAnimalitoSelected,
    this.showNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columnas
        childAspectRatio: 0.8, // Relación ancho/alto
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: animalitos.length,
      itemBuilder: (context, index) {
        final animalito = animalitos[index];
        return AnimalitoCard(
          animalito: animalito,
          isSelected: selectedIndices.contains(index),
          onTap: () => onAnimalitoSelected(index),
          showNumber: showNumbers,
        );
      },
    );
  }
}
