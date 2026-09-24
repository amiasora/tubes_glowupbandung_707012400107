import 'package:flutter/material.dart';

import '../pages/beranda.dart';
import '../pages/laporan.dart';
import '../pages/detail_laporan.dart';
import '../pages/profil.dart';
import '../pages/riwayat_laporan.dart';
import '../pages/pengaturan.dart';
import '../pages/tentang_aplikasi.dart';
import '../pages/route_tidak_dikenal.dart';
import 'kerangka_navigasi.dart';

class AppRoutes {
  static const String kerangka = '/';
  static const String beranda = '/beranda';
  static const String laporan = '/laporan';
  static const String profil = '/profil';
  static const String detailLaporan = '/detail-laporan';
  static const String riwayatLaporan = '/riwayat-laporan';
  static const String pengaturan = '/pengaturan';
  static const String tentangAplikasi = '/tentang-aplikasi';

  static Map<String, WidgetBuilder> daftarRoute() {
    return {
      kerangka: (_) => const KerangkaNavigasi(),
      beranda: (_) => const Beranda(),
      laporan: (_) => const Laporan(),
      profil: (_) => const Profil(),
      riwayatLaporan: (_) => const RiwayatLaporan(),
      pengaturan: (_) => const Pengaturan(),
      tentangAplikasi: (_) => const TentangAplikasi(),
    };
  }

  static Route<dynamic>? bentukRoute(RouteSettings settings) {
    if (settings.name == detailLaporan) {
      final arguments = settings.arguments;

      if (arguments is Map<String, String>) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DetailLaporan(
            data: arguments,
          ),
        );
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const RouteTidakDikenal(
          namaRoute: 'Data detail laporan tidak valid',
        ),
      );
    }

    return null;
  }

  static Route<dynamic> routeTidakDikenal(
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => RouteTidakDikenal(
        namaRoute: settings.name,
      ),
    );
  }
}