import 'package:flutter/material.dart';

import '../widgets/kerangka_warga.dart';

class RouteTidakDikenal extends StatelessWidget {
  const RouteTidakDikenal({super.key, this.namaRoute});
  final String? namaRoute;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: KeadaanGlow(
            judul: 'Halaman tidak ditemukan',
            pesan: 'Kembali ke dashboard untuk melanjutkan.',
            icon: Icons.search_off,
            aksi: FilledButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Dashboard'),
            ),
          ),
        ),
      ),
    ),
  );
}