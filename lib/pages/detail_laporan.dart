import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/riwayat_laporan_model.dart';

class DetailLaporan extends StatefulWidget {
  final Map<String, String> data;

  const DetailLaporan({
    super.key,
    required this.data,
  });

  @override
  State<DetailLaporan> createState() =>
      _DetailLaporanState();
}

class _DetailLaporanState extends State<DetailLaporan> {
  bool _sedangMemproses = false;

  Future<void> konfirmasiLaporan() async {
    if (_sedangMemproses) {
      return;
    }

    setState(() {
      _sedangMemproses = true;
    });

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) {
      return;
    }

    context
        .read<RiwayatLaporanModel>()
        .tambahLaporan(widget.data);

    setState(() {
      _sedangMemproses = false;
    });

    if (!mounted) {
      return;
    }

    final judul =
        widget.data['judul'] ?? 'Laporan';

    Navigator.pop(
      context,
      'Laporan "$judul" berhasil diperbarui '
      'dan disimpan ke riwayat.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final sudahTersimpan =
        context.select<RiwayatLaporanModel, bool>(
      (model) => model.sudahTersimpan(widget.data),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.data['judul'] ?? 'Laporan',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
            ),
            title: const Text('Lokasi'),
            subtitle: Text(
              widget.data['lokasi'] ?? '-',
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.info_outline,
            ),
            title: const Text('Status'),
            subtitle: Text(
              widget.data['status'] ?? '-',
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.description_outlined,
            ),
            title: const Text('Keterangan'),
            subtitle: Text(
              widget.data['deskripsi'] ?? '-',
            ),
          ),

          const SizedBox(height: 24),

          if (sudahTersimpan)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color:
                      Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Laporan sudah tersimpan',
                ),
                subtitle: const Text(
                  'Laporan ini sudah tercatat '
                  'pada Riwayat Laporan.',
                ),
              ),
            ),

          if (sudahTersimpan)
            const SizedBox(height: 16),

          FilledButton.icon(
            onPressed:
                _sedangMemproses || sudahTersimpan
                    ? null
                    : konfirmasiLaporan,
            icon: _sedangMemproses
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    sudahTersimpan
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                  ),
            label: Text(
              _sedangMemproses
                  ? 'Memproses...'
                  : sudahTersimpan
                      ? 'Sudah Dikonfirmasi'
                      : 'Konfirmasi Laporan',
            ),
          ),
        ],
      ),
    );
  }
}