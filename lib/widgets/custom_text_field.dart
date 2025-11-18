import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animalitos_lottery/utils/constants.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final TextCapitalization textCapitalization;
  final String? initialValue;
  final bool readOnly;
  final bool showCursor;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool filled;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.textCapitalization = TextCapitalization.none,
    this.initialValue,
    this.readOnly = false,
    this.showCursor = true,
    this.textAlign = TextAlign.start,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppConstants.spacingM,
      vertical: AppConstants.spacingM,
    ),
    this.fillColor = AppConstants.surfaceColor,
    this.filled = true,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      borderSide: BorderSide(
        color: theme.dividerColor.withOpacity(0.5),
        width: 1.0,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppConstants.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          initialValue: initialValue,
          readOnly: readOnly,
          showCursor: showCursor,
          textAlign: textAlign,
          style: GoogleFonts.poppins(
            color: enabled ? AppConstants.textColor : AppConstants.hintColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: AppConstants.hintColor,
              fontSize: 16,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            isDense: true,
            contentPadding: contentPadding,
            fillColor: fillColor,
            filled: filled,
            border: border ?? defaultBorder,
            enabledBorder: enabledBorder ?? defaultBorder,
            focusedBorder: focusedBorder ?? defaultBorder.copyWith(
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: errorBorder ?? defaultBorder.copyWith(
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: focusedErrorBorder ?? defaultBorder.copyWith(
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2.0,
              ),
            ),
            errorText: errorText,
            errorStyle: GoogleFonts.poppins(
              color: theme.colorScheme.error,
              fontSize: 12,
            ),
            counterText: showCounter ? null : '',
          ),
        ),
      ],
    );
  }
}
