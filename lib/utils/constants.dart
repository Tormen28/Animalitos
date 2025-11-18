import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // Nombre de la aplicación
  static const String appName = 'Animalitos Criollos';
  
  // Constantes de diseño
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Paleta de colores - Patrón "Patronus Clásico"
  static const Color primaryColor = Color(0xFF006400);    // Verde Oscuro Esmeralda (Fondo/Main)
  static const Color secondaryColor = Color(0xFFCC0000);  // Rojo Pasión/Fuego (Énfasis/CTAs)
  static const Color accentColor = Color(0xFFFFD700);     // Dorado/Amarillo Suerte (Datos/Ganancias)
  static const Color backgroundColor = Color(0xFF1A1A1A); // Fondo oscuro para resaltar elementos
  static const Color surfaceColor = Color(0xFF2D2D2D);   // Superficie oscura
  static const Color errorColor = Color(0xFFE53935);      // Rojo para errores
  static const Color successColor = Color(0xFF43A047);    // Verde para éxito
  static const Color warningColor = Color(0xFFFFB74D);    // Naranja para advertencias
  static const Color textColor = Color(0xFFFFFFFF);       // Texto principal blanco
  static const Color textSecondaryColor = Color(0xFFB0B0B0); // Texto secundario gris claro
  static const Color hintColor = Color(0xFF808080);       // Texto de ayuda gris
  static const Color disabledColor = Color(0xFF404040);    // Elementos deshabilitados
  static const Color borderColor = Color(0xFF404040);      // Bordes oscuros

  // Colores para los estados de los botones
  static const Color buttonPrimary = Color(0xFFCC0000);   // Rojo Pasión para acciones principales
  static const Color buttonSecondary = Color(0xFFFFD700); // Dorado para acciones secundarias
  static const Color buttonDisabled = Color(0xFF404040);  // Botones deshabilitados
  
  // Sombras - Ajustadas para tema oscuro
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x33000000), // Más oscura para tema oscuro
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  
  // Estilos de texto
  static TextStyle get heading1 => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      );
      
  static TextStyle get heading2 => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.5,
      );
      
  static TextStyle get heading3 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      );
      
  static TextStyle get heading4 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      );
      
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      );
      
  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      );
      
  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
        height: 1.5,
      );
      
  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      );
      
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        letterSpacing: 0.4,
      );
  
  // Espaciado
  static const double spacingXXS = 4.0;
  static const double spacingXS = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Tamaños de íconos
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  
  // Duración de animaciones
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationLong = Duration(milliseconds: 500);
}
