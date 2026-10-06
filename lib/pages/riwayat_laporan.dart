import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/riwayat_laporan_model.dart';

class RiwayatLaporan extends StatelessWidget {
  const RiwayatLaporan({super.key});

  void tampilkanPesan(
    BuildContext context,
    String pesan,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
      ),

      body: Consumer<RiwayatLaporanModel>(
        builder: (
          context,
          riwayat,
          child,
        ) {
          if (riwayat.daftarLaporan.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat laporan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Laporan yang telah dikonfirmasi '
                      'akan muncul pada halaman ini.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount:
                riwayat.daftarLaporan.length,
            separatorBuilder: (
              context,
              index,
            ) {
              return const SizedBox(height: 12);
            },
            itemBuilder: (
              context,
              index,
            ) {
              final laporan =
                  riwayat.daftarLaporan[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${index + 1}',
                    ),
                  ),
                  title: Text(
                    laporan['judul'] ??
                        'Laporan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          laporan['lokasi'] ??
                              'Lokasi tidak tersedia',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: '
                          '${laporan['status'] ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Hapus dari riwayat',
                    onPressed: () {
                      context
                          .read<
                              RiwayatLaporanModel>()
                          .hapusLaporan(laporan);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          tampilkanPesan(
            context,
            'Fitur pembuatan laporan baru dipilih.',
          );
        },
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Beranda',
              onPressed: () {
                tampilkanPesan(
                  context,
                  'Aksi Beranda dipilih.',
                );
              },
              icon:
                  const Icon(Icons.home_outlined),
            ),

            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {
                tampilkanPesan(
                  context,
                  'Aksi Notifikasi dipilih.',
                );
              },
              icon: const Icon(
                Icons.notifications_none,
              ),
            ),

            const SizedBox(width: 48),

            IconButton(
              tooltip: 'Pengaturan',
              onPressed: () {
                tampilkanPesan(
                  context,
                  'Aksi Pengaturan dipilih.',
                );
              },
              icon: const Icon(
                Icons.settings_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}