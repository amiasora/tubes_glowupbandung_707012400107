import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class Profil extends StatelessWidget {
  const Profil({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            child: Icon(
              Icons.person,
              size: 48,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Pengguna Glow Up Bandung',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Masyarakat Kota Bandung',
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.riwayatLaporan,
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Lihat Riwayat Laporan'),
            ),
          ),
        ],
      ),
    );
  }
}