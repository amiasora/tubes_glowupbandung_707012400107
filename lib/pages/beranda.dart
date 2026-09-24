import 'package:flutter/material.dart';

class Beranda extends StatelessWidget {
  const Beranda({super.key});

  static const List<Map<String, dynamic>> informasi = [
    {
      'judul': 'Pelaporan Sampah',
      'deskripsi': 'Laporkan tumpukan sampah di lingkungan sekitar.',
      'ikon': Icons.report_problem_outlined,
    },
    {
      'judul': 'Jadwal Pengangkutan',
      'deskripsi': 'Pantau jadwal pengangkutan sampah.',
      'ikon': Icons.local_shipping_outlined,
    },
    {
      'judul': 'Pemantauan TPS',
      'deskripsi': 'Informasi kondisi tempat penampungan sementara.',
      'ikon': Icons.delete_outline,
    },
    {
      'judul': 'Rute Armada',
      'deskripsi': 'Mendukung pemantauan rute petugas lapangan.',
      'ikon': Icons.route_outlined,
    },
    {
      'judul': 'Respons Pengaduan',
      'deskripsi': 'Memantau status penanganan laporan warga.',
      'ikon': Icons.track_changes,
    },
    {
      'judul': 'Data Lingkungan',
      'deskripsi': 'Mendukung pengambilan keputusan berbasis data.',
      'ikon': Icons.analytics_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang di Glow Up Bandung',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'Sistem pengelolaan sampah Kota Bandung '
            'yang lebih terorganisasi dan transparan.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SizedBox(height: 24),

          Text(
            'Fitur Utama',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: informasi.length,
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 150,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = informasi[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item['ikon'] as IconData,
                        size: 30,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        item['judul'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Expanded(
                        child: Text(
                          item['deskripsi'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}