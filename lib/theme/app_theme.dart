import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const warnaDasar = Color(0xFF14664E);
  static const hijauGelap = Color(0xFF123E34);
  static const hijauSedang = Color(0xFF176551);
  static const aksenTerang = Color(0xFFCCEDAD);

  static ThemeData get lightTheme => _buatTema(Brightness.light);
  static ThemeData get darkTheme => _buatTema(Brightness.dark);

  static ThemeData _buatTema(Brightness brightness) {
    final gelap = brightness == Brightness.dark;
    final skema =
        ColorScheme.fromSeed(
          seedColor: warnaDasar,
          brightness: brightness,
        ).copyWith(
          primary: gelap ? const Color(0xFF9FD6BC) : warnaDasar,
          onPrimary: gelap ? const Color(0xFF12382E) : Colors.white,
          primaryContainer: gelap
              ? const Color(0xFF20483D)
              : const Color(0xFFDCEEE3),
          onPrimaryContainer: gelap
              ? const Color(0xFFDCF7E7)
              : const Color(0xFF154535),
          surface: gelap ? const Color(0xFF182822) : Colors.white,
          onSurface: gelap ? const Color(0xFFE5F0E9) : const Color(0xFF152D25),
          onSurfaceVariant: gelap
              ? const Color(0xFFB0C6B9)
              : const Color(0xFF53685D),
          outlineVariant: gelap
              ? const Color(0xFF3A5045)
              : const Color(0xFFDCE6DE),
          error: gelap ? const Color(0xFFFFB4A9) : const Color(0xFFB13931),
        );
    final dasar = ThemeData(
      useMaterial3: true,
      colorScheme: skema,
      fontFamily: 'Roboto',
    );
    final bentuk = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final batas = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: skema.outlineVariant),
    );
    final teksTombol = const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );
    return dasar.copyWith(
      scaffoldBackgroundColor: gelap
          ? const Color(0xFF101D18)
          : const Color(0xFFF4F7F3),
      focusColor: skema.primary.withValues(alpha: .16),
      hoverColor: skema.primary.withValues(alpha: .08),
      dividerColor: skema.outlineVariant,
      textTheme: dasar.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 36,
          height: 1.12,
          letterSpacing: -.8,
          fontWeight: FontWeight.w800,
          color: skema.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          height: 1.15,
          letterSpacing: -.65,
          fontWeight: FontWeight.w800,
          color: skema.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.2,
          letterSpacing: -.45,
          fontWeight: FontWeight.w800,
          color: skema.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.28,
          letterSpacing: -.25,
          fontWeight: FontWeight.w700,
          color: skema.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: skema.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: skema.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: skema.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: skema.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: skema.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: skema.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: batas,
        enabledBorder: batas,
        focusedBorder: batas.copyWith(
          borderSide: BorderSide(color: skema.primary, width: 2),
        ),
        errorBorder: batas.copyWith(borderSide: BorderSide(color: skema.error)),
        focusedErrorBorder: batas.copyWith(
          borderSide: BorderSide(color: skema.error, width: 2),
        ),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: bentuk,
          minimumSize: const Size(48, 48),
          textStyle: teksTombol,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: bentuk,
          minimumSize: const Size(48, 48),
          textStyle: teksTombol,
          side: BorderSide(color: skema.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: bentuk,
          minimumSize: const Size(48, 48),
          textStyle: teksTombol,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: bentuk,
        ),
      ),
      chipTheme: dasar.chipTheme.copyWith(
        side: BorderSide(color: skema.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: skema.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: skema.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: TextStyle(
          color: skema.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: skema.surface,
        indicatorColor: skema.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (state) => TextStyle(
            fontSize: 11,
            height: 1.25,
            fontWeight: state.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: state.contains(WidgetState.selected)
                ? skema.primary
                : skema.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: bentuk,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: skema.primary,
        linearTrackColor: skema.primaryContainer,
        linearMinHeight: 4,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _TransisiGlow(),
          TargetPlatform.iOS: _TransisiGlow(),
          TargetPlatform.macOS: _TransisiGlow(),
          TargetPlatform.windows: _TransisiGlow(),
          TargetPlatform.linux: _TransisiGlow(),
          TargetPlatform.fuchsia: _TransisiGlow(),
        },
      ),
    );
  }
}

class _TransisiGlow extends PageTransitionsBuilder {
  const _TransisiGlow();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final masuk = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: masuk,
      child: SlideTransition(
        position: masuk.drive(
          Tween(begin: const Offset(0, .012), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}