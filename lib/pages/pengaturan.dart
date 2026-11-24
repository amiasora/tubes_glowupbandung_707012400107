import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/theme_cubit.dart';
import '../services/sesi_akun.dart';
import 'catatan_admin.dart';

class Pengaturan extends StatefulWidget {
  const Pengaturan({super.key});

  @override
  State<Pengaturan> createState() => _PengaturanState();
}

class _PengaturanState extends State<Pengaturan> {
  bool _menyimpanTema = false;

  Future<void> _ubahTema(bool aktif) async {
    if (_menyimpanTema) return;

    setState(() => _menyimpanTema = true);

    try {
      await context.read<ThemeCubit>().ubahModeGelap(aktif);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Pilihan tema berhasil disimpan.')),
        );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Tema belum berhasil disimpan. Silakan coba kembali.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _menyimpanTema = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final akun = SesiAkun.aktif;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, modeTema) {
              final modeGelap = modeTema == ThemeMode.dark;

              return SwitchListTile(
                key: const ValueKey('sakelar-mode-gelap'),
                secondary: Icon(
                  modeGelap
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                value: modeGelap,
                onChanged: _menyimpanTema ? null : _ubahTema,
                title: const Text('Mode gelap'),
                subtitle: Text(
                  _menyimpanTema
                      ? 'Menyimpan pilihan tema...'
                      : 'Pilihan tema tersimpan pada perangkat ini.',
                ),
              );
            },
          ),
          const Divider(),
          if (akun != null && akun.peran == PeranAkun.admin) ...[
            ListTile(
              key: const ValueKey('buka-catatan-admin'),
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('Catatan kerja admin'),
              subtitle: const Text(
                'Simpan dan baca catatan kerja pada perangkat ini.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _menyimpanTema
                  ? null
                  : () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => HalamanCatatanAdmin(idAdmin: akun.id),
                        ),
                      );
                    },
            ),
            const Divider(),
          ],
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('Bahasa'),
            subtitle: Text('Bahasa Indonesia'),
          ),
          const ListTile(
            leading: Icon(Icons.location_city),
            title: Text('Wilayah layanan'),
            subtitle: Text(
              'Kota Bandung, Kabupaten Bandung, '
              'dan Kabupaten Bandung Barat.',
            ),
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
              Navigator.pushNamed(context, '/route-salah');
            },
          ),
        ],
      ),
    );
  }
}
