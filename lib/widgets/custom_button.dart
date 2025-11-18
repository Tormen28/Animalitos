import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animalitos_lottery/utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final double? elevation;
  final bool isDisabled;

  const CustomButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.borderRadius = AppConstants.defaultBorderRadius,
    this.padding,
    this.icon,
    this.elevation,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = backgroundColor ?? AppConstants.buttonPrimary; // Rojo pasión por defecto
    final buttonTextColor = textColor ?? Colors.white;
    final disabledColor = AppConstants.buttonDisabled;

    return SizedBox(
      width: width,
      height: height ?? 56.0, // Más alto para mejor presencia
      child: Container(
        decoration: isOutlined ? null : BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            colors: [
              buttonColor,
              buttonColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isOutlined
            ? OutlinedButton(
                onPressed: isDisabled || isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDisabled ? disabledColor : buttonColor,
                  side: BorderSide(
                    color: isDisabled ? disabledColor : buttonColor,
                    width: 2.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  padding: padding ?? const EdgeInsets.symmetric(vertical: 16.0),
                  elevation: 0,
                ),
                child: _buildChild(buttonTextColor, disabledColor),
              )
            : ElevatedButton(
                onPressed: isDisabled || isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Transparente para mostrar gradiente
                  foregroundColor: buttonTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  padding: padding ?? const EdgeInsets.symmetric(vertical: 16.0),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _buildChild(buttonTextColor, disabledColor),
              ),
      ),
    );
  }

  Widget _buildChild(Color buttonTextColor, Color disabledColor) {
    if (child != null) {
      return child!;
    }
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: GoogleFonts.poppins(
                color: isOutlined
                    ? (isDisabled ? disabledColor : buttonTextColor)
                    : Colors.white,
                fontSize: 18, // Más grande
                fontWeight: FontWeight.w700, // Más bold
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
