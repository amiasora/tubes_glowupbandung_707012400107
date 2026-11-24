import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'cubit/form_laporan_cubit.dart';
import 'cubit/riwayat_laporan_cubit.dart';
import 'cubit/theme_cubit.dart';
import 'helpers/hive_helper.dart';
import 'helpers/pengaturan_helper.dart';
import 'navigation/app_routes.dart';
import 'pages/pengaturan.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Hive.initFlutter();
  await HiveHelper.instance.init();

  debugPrint('Hive siap: ${HiveHelper.instance.box.name}');

  final pengaturan = PengaturanHelper.instance;
  final modeGelap = await pengaturan.muatTemaGelap();

  debugPrint('Tema tersimpan: ${modeGelap ? "gelap" : "terang"}');

  runApp(
    AplikasiGlowUpBandung(
      temaAwal: modeGelap ? ThemeMode.dark : ThemeMode.light,
      pengaturan: pengaturan,
    ),
  );
}

class AplikasiGlowUpBandung extends StatelessWidget {
  const AplikasiGlowUpBandung({
    super.key,
    this.temaAwal = ThemeMode.light,
    this.pengaturan,
  });

  final ThemeMode temaAwal;
  final PengaturanHelper? pengaturan;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RiwayatLaporanCubit>(create: (_) => RiwayatLaporanCubit()),
        BlocProvider<FormLaporanCubit>(create: (_) => FormLaporanCubit()),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(temaAwal: temaAwal, pengaturan: pengaturan),
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
            initialRoute: kIsWeb ? null : AppRoutes.kerangka,
            routes: {
              ...AppRoutes.daftarRoute(),
              AppRoutes.pengaturan: (_) => const Pengaturan(),
            },
            onGenerateRoute: AppRoutes.bentukRoute,
            onUnknownRoute: AppRoutes.routeTidakDikenal,
          );
        },
      ),
    );
  }
}
