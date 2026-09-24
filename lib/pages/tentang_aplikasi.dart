import 'package:flutter/material.dart';

class TentangAplikasi extends StatelessWidget {
  const TentangAplikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
      ),

      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glow Up Bandung',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12),

            Text(
              'Glow Up Bandung merupakan rancangan aplikasi '
              'sistem pengelolaan sampah Kota Bandung. '
              'Aplikasi ini dirancang untuk membantu '
              'masyarakat dan petugas dalam proses pelaporan '
              'serta pemantauan pengelolaan sampah.',
            ),

            SizedBox(height: 20),

            Text(
              'Versi Purwarupa: 1.0.0',
            ),
          ],
        ),
      ),
    );
  }
}