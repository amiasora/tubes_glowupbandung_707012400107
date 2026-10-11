import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/form_laporan_model.dart';
import '../model/riwayat_laporan_model.dart';

class PratinjauLaporan extends StatelessWidget {
  const PratinjauLaporan({super.key});

  Future<void> _kirimLaporan(BuildContext context) async {
    final form = context.read<FormLaporanModel>();
    final riwayat = context.read<RiwayatLaporanModel>();

    try {
      final berhasil = await form.kirimLaporan(riwayat);

      if (!context.mounted || !berhasil) {
        return;
      }

      Navigator.pop(context, true);
    } on StateError catch (galat) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(galat.message),
          ),
        );
    }
  }

  Widget _rincian(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nilai.trim().isEmpty
                ? 'Belum diisi'
                : nilai.trim(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<FormLaporanModel>();

    return PopScope(
      canPop: !form.sedangMengirim,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pratinjau Laporan'),
          leading: IconButton(
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back),
            onPressed: form.sedangMengirim
                ? null
                : () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Periksa kembali informasi berikut sebelum '
                    'mengirim laporan.',
                  ),
                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _rincian(
                            'Judul laporan',
                            form.judul,
                          ),
                          _rincian(
                            'Lokasi kejadian',
                            form.lokasi,
                          ),
                          _rincian(
                            'Deskripsi permasalahan',
                            form.deskripsi,
                          ),
                          Row(
                            children: [
                              Icon(
                                form.setuju
                                    ? Icons.check_circle_outline
                                    : Icons.info_outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  form.setuju
                                      ? 'Persetujuan sudah diberikan.'
                                      : 'Persetujuan belum diberikan.',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed:
                        form.formLengkap && !form.sedangMengirim
                            ? () => _kirimLaporan(context)
                            : null,
                    child: form.sedangMengirim
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Sedang mengirim...'),
                            ],
                          )
                        : const Text('Kirim Laporan'),
                  ),

                  TextButton(
                    onPressed: form.sedangMengirim
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      'Kembali untuk Mengubah',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}