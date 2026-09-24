import 'package:flutter/material.dart';

class Pengaturan extends StatelessWidget {
  const Pengaturan({super.key});

  void ujiRouteTidakDikenal(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/route-salah',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Notifikasi Laporan'),
            subtitle: const Text(
              'Terima informasi mengenai status laporan.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Bahasa'),
            subtitle: Text('Bahasa Indonesia'),
          ),
          const ListTile(
            leading: Icon(Icons.location_city),
            title: Text('Wilayah'),
            subtitle: Text('Kota Bandung'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text('Uji Route Tidak Dikenal'),
            subtitle: const Text(
              'Menguji penanganan route yang tidak terdaftar.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ujiRouteTidakDikenal(context);
            },
          ),
        ],
      ),
    );
  }
}