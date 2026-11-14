import 'package:flutter/material.dart';

class RouteTidakDikenal extends StatelessWidget {
  final String? namaRoute;

  const RouteTidakDikenal({
    super.key,
    this.namaRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Tidak Ditemukan'),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 72,
              ),

              const SizedBox(height: 16),

              const Text(
                'Route Tidak Dikenal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Nama route: ${namaRoute ?? 'Tidak tersedia'}',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}