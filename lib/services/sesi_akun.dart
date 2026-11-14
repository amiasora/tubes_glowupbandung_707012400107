import '../db/database_helper.dart';

enum PeranAkun {
  warga('Warga'),
  admin('Admin'),
  petugas('Petugas');

  const PeranAkun(this.label);
  final String label;
}

class AkunAktif {
  const AkunAktif._({
    required this.id,
    required this.nama,
    required this.peran,
  });

  final int id;
  final String nama;
  final PeranAkun peran;
}

class SesiAkun {
  SesiAkun._();

  // Kredensial contoh terbuka untuk praktikum dalam satu browser.
  static const kataSandiDemo = 'GlowUpDemo8!';
  static const daftarDemo = <String, ({PeranAkun peran, int id, String label})>{
    'warga@glowup.test': (
      peran: PeranAkun.warga,
      id: 1,
      label: 'Warga · Annisa',
    ),
    'warga2@glowup.test': (
      peran: PeranAkun.warga,
      id: 2,
      label: 'Warga · Akun uji',
    ),
    'admin@glowup.test': (peran: PeranAkun.admin, id: 1, label: 'Admin'),
    'petugas@glowup.test': (
      peran: PeranAkun.petugas,
      id: 1,
      label: 'Petugas A',
    ),
    'petugas2@glowup.test': (
      peran: PeranAkun.petugas,
      id: 2,
      label: 'Petugas B',
    ),
  };

  static AkunAktif? _aktif;
  static AkunAktif? get aktif => _aktif;

  static Future<AkunAktif?> periksaKredensial({
    required String email,
    required String kataSandi,
  }) async {
    final akun = daftarDemo[email.trim().toLowerCase()];
    if (akun == null || kataSandi != kataSandiDemo) return null;

    final nama = await DatabaseHelper.instance.ambilNamaAkunDemo(
      peran: akun.peran.name,
      idAkun: akun.id,
    );
    if (nama == null) return null;
    return AkunAktif._(id: akun.id, nama: nama, peran: akun.peran);
  }

  static void aktifkan(AkunAktif akun) => _aktif = akun;

  static void keluar() => _aktif = null;
}