import 'package:flutter/material.dart';

import '../pages/beranda.dart';
import '../pages/dashboard_operasional.dart';
import '../pages/login.dart';
import '../services/sesi_akun.dart';

class KerangkaNavigasi extends StatelessWidget {
  const KerangkaNavigasi({super.key});

  @override
  Widget build(BuildContext context) {
    final akun = SesiAkun.aktif;
    if (akun == null) return const HalamanLogin();

    return switch (akun.peran) {
      PeranAkun.warga => Beranda(idWarga: akun.id),
      PeranAkun.admin => DashboardAdmin(akun: akun),
      PeranAkun.petugas => DashboardPetugas(akun: akun),
    };
  }
}