import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/form_laporan_cubit.dart';
import 'cubit/riwayat_laporan_cubit.dart';
import 'cubit/theme_cubit.dart';
import 'navigation/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AplikasiGlowUpBandung());
}

class AplikasiGlowUpBandung extends StatelessWidget {
  const AplikasiGlowUpBandung({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RiwayatLaporanCubit>(
          create: (_) => RiwayatLaporanCubit(),
        ),
        BlocProvider<FormLaporanCubit>(
          create: (_) => FormLaporanCubit(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, modeTema) {
          return MaterialApp(
            title: 'Glow Up Bandung',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: modeTema,
            initialRoute: AppRoutes.kerangka,
            routes: AppRoutes.daftarRoute(),
            onGenerateRoute: AppRoutes.bentukRoute,
            onUnknownRoute: AppRoutes.routeTidakDikenal,
          );
        },
      ),
    );
  }
}