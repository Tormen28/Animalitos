import 'package:flutter/material.dart';
import 'package:animalitos_lottery/models/animalito.dart';
import 'package:animalitos_lottery/utils/constants.dart';

class AnimalitoGrid extends StatelessWidget {
  final List<Animalito> animalitos;
  final Function(Animalito) onAnimalitoSelected;
  final bool showSelection;
  final Animalito? selectedAnimalito;

  const AnimalitoGrid({
    super.key,
    required this.animalitos,
    required this.onAnimalitoSelected,
    this.showSelection = true,
    this.selectedAnimalito,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.9,
      ),
      itemCount: animalitos.length,
      itemBuilder: (context, index) {
        final animalito = animalitos[index];
        final isSelected = showSelection && selectedAnimalito?.id == animalito.id;
        
        return _AnimalitoCard(
          animalito: animalito,
          isSelected: isSelected,
          onTap: () => onAnimalitoSelected(animalito),
        );
      },
    );
  }
}

class _AnimalitoCard extends StatelessWidget {
  final Animalito animalito;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimalitoCard({
    super.key,
    required this.animalito,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 12.0 : 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: isSelected
              ? BorderSide(
                  color: AppConstants.accentColor, // Dorado para selección
                  width: 3.0,
                )
              : BorderSide.none,
        ),
        color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : AppConstants.surfaceColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: isSelected ? LinearGradient(
              colors: [
                AppConstants.primaryColor.withOpacity(0.2),
                AppConstants.secondaryColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono del animalito con mejor diseño
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppConstants.accentColor.withOpacity(0.2) : AppConstants.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: isSelected ? AppConstants.accentColor : AppConstants.primaryColor,
                    width: 2.0,
                  ),
                ),
                child: Icon(
                  Icons.pets,
                  size: 32.0,
                  color: isSelected ? AppConstants.accentColor : AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                animalito.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: isSelected ? AppConstants.accentColor : AppConstants.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppConstants.accentColor.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '#${animalito.numeroStr}',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.accentColor,
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
