import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/riwayat_laporan_model.dart';
import 'navigation/app_routes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => RiwayatLaporanModel(),
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