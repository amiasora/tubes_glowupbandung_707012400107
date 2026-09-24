import 'package:flutter/material.dart';

class DetailLaporan extends StatelessWidget {
  final Map<String, String> data;

  const DetailLaporan({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            data['judul'] ?? 'Laporan',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Lokasi'),
            subtitle: Text(
              data['lokasi'] ?? '-',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Status'),
            subtitle: Text(
              data['status'] ?? '-',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Keterangan'),
            subtitle: Text(
              data['deskripsi'] ?? '-',
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              Navigator.pop(
                context,
                'Laporan "${data['judul']}" berhasil diperbarui.',
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Konfirmasi Laporan'),
          ),
        ],
      ),
    );
  }
}