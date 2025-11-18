import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;
  final bool showLogo;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showAnimation;
  final String? animationAsset;
  final double? animationSize;

  const LoadingScreen({
    Key? key,
    this.message,
    this.showLogo = true,
    this.backgroundColor,
    this.textColor,
    this.showAnimation = true,
    this.animationAsset,
    this.animationSize = 200.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showAnimation) _buildAnimation(context),
            const SizedBox(height: 24),
            if (showLogo) _buildLogo(context),
            const SizedBox(height: 16),
            _buildMessage(context),
            const SizedBox(height: 32),
            _buildLoadingIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation(BuildContext context) {
    if (animationAsset != null) {
      return Lottie.asset(
        animationAsset!,
        width: animationSize,
        height: animationSize,
        fit: BoxFit.contain,
      );
    }
    
    return Lottie.asset(
      'assets/animations/loading_animation.json', // Asegúrate de tener esta animación en tus assets
      width: animationSize,
      height: animationSize,
      fit: BoxFit.contain,
      package: animationAsset == null ? null : 'your_package_name',
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png', // Asegúrate de tener este logo en tus assets
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Text(
        message!,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textColor ?? Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary,
      ),
      strokeWidth: 2.0,
    );
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;
  final bool showLogo;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showAnimation;
  final String? animationAsset;
  final double? animationSize;

  const FullScreenLoading({
    Key? key,
    this.message = 'Cargando...',
    this.showLogo = true,
    this.backgroundColor,
    this.textColor,
    this.showAnimation = true,
    this.animationAsset,
    this.animationSize = 150.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingScreen(
      message: message,
      showLogo: showLogo,
      backgroundColor: backgroundColor,
      textColor: textColor,
      showAnimation: showAnimation,
      animationAsset: animationAsset,
      animationSize: animationSize,
    );
  }
}

class BlockLoading extends StatelessWidget {
  final String? message;
  final bool showMessage;
  final Color? color;
  final double size;
  final double strokeWidth;

  const BlockLoading({
    Key? key,
    this.message,
    this.showMessage = true,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? theme.colorScheme.primary,
              ),
              strokeWidth: strokeWidth,
            ),
          ),
          if (message != null && showMessage) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color ?? theme.colorScheme.onBackground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ButtonLoading extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const ButtonLoading({
    Key? key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.onPrimary,
        ),
        strokeWidth: strokeWidth,
      ),
    );
  }
}
