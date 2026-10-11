import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/form_laporan_model.dart';
import 'model/riwayat_laporan_model.dart';
import 'navigation/app_routes.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RiwayatLaporanModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => FormLaporanModel(),
        ),
      ],
      child: const AplikasiGlowUpBandung(),
    ),
  );
}

class AplikasiGlowUpBandung extends StatelessWidget {
  const AplikasiGlowUpBandung({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glow Up Bandung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.kerangka,
      routes: AppRoutes.daftarRoute(),
      onGenerateRoute: AppRoutes.bentukRoute,
      onUnknownRoute: AppRoutes.routeTidakDikenal,
    );
  }
}