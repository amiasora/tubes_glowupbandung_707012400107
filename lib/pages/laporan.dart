import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';

class Laporan extends StatelessWidget {
  const Laporan({super.key});

  static const Map<String, List<Map<String, String>>> data = {
    'Menunggu': [
      {
        'judul': 'Tumpukan sampah di Jalan Braga',
        'lokasi': 'Jalan Braga',
        'status': 'Menunggu',
        'deskripsi': 'Sampah menumpuk di sisi jalan.',
      },
      {
        'judul': 'Sampah rumah tangga',
        'lokasi': 'Kecamatan Coblong',
        'status': 'Menunggu',
        'deskripsi': 'Penjemputan sampah belum dilakukan.',
      },
      {
        'judul': 'TPS membutuhkan pengangkutan',
        'lokasi': 'Kecamatan Sukajadi',
        'status': 'Menunggu',
        'deskripsi': 'Kapasitas TPS hampir penuh.',
      },
    ],
    'Diproses': [
      {
        'judul': 'Pengaduan sampah pasar',
        'lokasi': 'Pasar Kosambi',
        'status': 'Diproses',
        'deskripsi': 'Laporan sedang ditangani petugas.',
      },
      {
        'judul': 'Penumpukan sampah lingkungan',
        'lokasi': 'Kecamatan Antapani',
        'status': 'Diproses',
        'deskripsi': 'Petugas sedang menuju lokasi.',
      },
      {
        'judul': 'Pengangkutan terlambat',
        'lokasi': 'Kecamatan Buahbatu',
        'status': 'Diproses',
        'deskripsi': 'Penjadwalan ulang pengangkutan.',
      },
    ],
    'Selesai': [
      {
        'judul': 'Pembersihan area publik',
        'lokasi': 'Alun-Alun Bandung',
        'status': 'Selesai',
        'deskripsi': 'Laporan telah diselesaikan.',
      },
      {
        'judul': 'Pengangkutan sampah warga',
        'lokasi': 'Kecamatan Lengkong',
        'status': 'Selesai',
        'deskripsi': 'Sampah telah diangkut petugas.',
      },
      {
        'judul': 'Penanganan TPS penuh',
        'lokasi': 'Kecamatan Cibeunying',
        'status': 'Selesai',
        'deskripsi': 'Kapasitas TPS telah ditangani.',
      },
    ],
  };

  Future<void> bukaDetail(
    BuildContext context,
    Map<String, String> item,
  ) async {
    final hasil = await Navigator.pushNamed(
      context,
      AppRoutes.detailLaporan,
      arguments: item,
    );

    if (!context.mounted || hasil == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil.toString()),
      ),
    );
  }

  Widget daftarLaporan(
    BuildContext context,
    List<Map<String, String>> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.delete_outline),
            ),
            title: Text(
              item['judul']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item['lokasi']}\n${item['deskripsi']}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => bukaDetail(
              context,
              item,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              tabs: [
                Tab(text: 'Menunggu'),
                Tab(text: 'Diproses'),
                Tab(text: 'Selesai'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              children: [
                daftarLaporan(
                  context,
                  data['Menunggu']!,
                ),
                daftarLaporan(
                  context,
                  data['Diproses']!,
                ),
                daftarLaporan(
                  context,
                  data['Selesai']!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}