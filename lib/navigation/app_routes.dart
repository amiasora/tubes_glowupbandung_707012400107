import 'package:flutter/material.dart';

import '../pages/beranda.dart';
import '../pages/buat_laporan.dart';
import '../pages/dashboard_operasional.dart';
import '../pages/login.dart';
import '../pages/notifikasi_warga.dart';
import '../pages/riwayat_laporan.dart';
import '../pages/route_tidak_dikenal.dart';
import '../services/sesi_akun.dart';
import '../widgets/kerangka_warga.dart';
import 'kerangka_navigasi.dart';

class AppRoutes {
  AppRoutes._();

  static const String kerangka = '/';
  static const String login = '/login';
  static const String beranda = '/beranda';
  static const String laporan = '/laporan';
  static const String profil = '/profil';
  static const String detailLaporan = '/detail-laporan';
  static const String riwayatLaporan = '/riwayat-laporan';
  static const String pengaturan = '/pengaturan';
  static const String tentangAplikasi = '/tentang-aplikasi';
  static const String buatLaporan = '/buat-laporan';
  static const String pratinjauLaporan = '/pratinjau-laporan';
  static const String notifikasi = '/notifikasi';
  static const String daftarLaporanAdmin = '/admin/laporan';

  static Map<String, WidgetBuilder> daftarRoute() => {
    kerangka: (_) => const KerangkaNavigasi(),
    login: (_) => const KerangkaNavigasi(),
    beranda: _untukPeran(PeranAkun.warga, (akun) => Beranda(idWarga: akun.id)),
    laporan: _untukPeran(
      PeranAkun.warga,
      (akun) => RiwayatLaporan(idWarga: akun.id),
    ),
    riwayatLaporan: _untukPeran(
      PeranAkun.warga,
      (akun) => RiwayatLaporan(idWarga: akun.id),
    ),
    buatLaporan: _untukPeran(
      PeranAkun.warga,
      (akun) => BuatLaporan(idWarga: akun.id),
    ),
    notifikasi: _untukPeran(
      PeranAkun.warga,
      (akun) => NotifikasiWarga(idWarga: akun.id),
    ),
    '/admin/jadwal': _untukPeran(
      PeranAkun.admin,
      (akun) => DashboardAdmin(akun: akun, khususJadwal: true),
    ),
    '/petugas/jadwal': _untukPeran(
      PeranAkun.petugas,
      (akun) => DashboardPetugas(akun: akun, rute: '/petugas/jadwal'),
    ),
    '/petugas/notifikasi': _untukPeran(
      PeranAkun.petugas,
      (akun) => DashboardPetugas(akun: akun, rute: '/petugas/notifikasi'),
    ),
  };

  static WidgetBuilder _untukPeran(
    PeranAkun peran,
    Widget Function(AkunAktif akun) buatHalaman,
  ) {
    return (_) {
      final akun = SesiAkun.aktif;
      if (akun == null) return const HalamanLogin();
      if (akun.peran != peran) return _AksesTerbatas(peran: peran);
      return buatHalaman(akun);
    };
  }

  static Route<dynamic>? bentukRoute(RouteSettings settings) {
    if (settings.name == daftarLaporanAdmin ||
        settings.name == '/admin/pemeriksaan') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: _untukPeran(PeranAkun.admin, (akun) {
          final id = settings.arguments;
          return DashboardAdmin(
            akun: akun,
            daftarLengkap: true,
            idLaporanAwal: id is int && id > 0 ? id : null,
          );
        }),
      );
    }
    if (settings.name != detailLaporan) return null;
    return MaterialPageRoute<Object?>(
      settings: settings,
      builder: _untukPeran(PeranAkun.warga, (akun) {
        final argumen = settings.arguments;
        final idLaporan = argumen is Map<String, int>
            ? argumen['idLaporan']
            : null;
        if (idLaporan == null || idLaporan < 1) {
          return const RouteTidakDikenal(
            namaRoute: 'Data detail laporan tidak valid',
          );
        }

        // Pemilik dibaca dari sesi, sehingga argumen rute hanya memilih laporan.
        return DetailLaporanTersimpan(idLaporan: idLaporan, idWarga: akun.id);
      }),
    );
  }

  static Route<dynamic> routeTidakDikenal(RouteSettings settings) =>
      MaterialPageRoute<Object?>(
        settings: settings,
        builder: (_) => SesiAkun.aktif == null
            ? const HalamanLogin()
            : RouteTidakDikenal(namaRoute: settings.name),
      );
}

class _AksesTerbatas extends StatelessWidget {
  const _AksesTerbatas({required this.peran});
  final PeranAkun peran;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: KeadaanGlow(
              judul: 'Akses terbatas',
              pesan: 'Halaman ini tersedia untuk akun ${peran.label}.',
              icon: Icons.lock_outline,
              aksi: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pushNamedAndRemoveUntil<Object?>(
                      AppRoutes.kerangka,
                      (_) => false,
                    ),
                child: const Text('Kembali ke Dashboard'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}