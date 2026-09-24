import 'package:flutter/material.dart';

class RiwayatLaporan extends StatelessWidget {
  const RiwayatLaporan({super.key});

  void tampilkanPesan(
    BuildContext context,
    String pesan,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Laporan'),
      ),

      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Riwayat laporan pengguna akan ditampilkan '
            'pada halaman ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
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
              icon: const Icon(Icons.home_outlined),
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