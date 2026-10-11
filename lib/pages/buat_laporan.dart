import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/form_laporan_model.dart';
import '../model/riwayat_laporan_model.dart';
import '../navigation/app_routes.dart';

class BuatLaporan extends StatefulWidget {
  const BuatLaporan({super.key});

  @override
  State<BuatLaporan> createState() => _BuatLaporanState();
}

class _BuatLaporanState extends State<BuatLaporan> {
  late final FormLaporanModel _form;
  late final TextEditingController _judul;
  late final TextEditingController _lokasi;
  late final TextEditingController _deskripsi;

  @override
  void initState() {
    super.initState();

    _form = context.read<FormLaporanModel>();

    _judul = TextEditingController(text: _form.judul);
    _lokasi = TextEditingController(text: _form.lokasi);
    _deskripsi = TextEditingController(text: _form.deskripsi);

    _form.addListener(_sinkronkanIsian);
  }

  void _perbaruiController(
    TextEditingController controller,
    String nilai,
  ) {
    if (controller.text == nilai) {
      return;
    }

    controller.value = TextEditingValue(
      text: nilai,
      selection: TextSelection.collapsed(
        offset: nilai.length,
      ),
    );
  }

  void _sinkronkanIsian() {
    _perbaruiController(_judul, _form.judul);
    _perbaruiController(_lokasi, _form.lokasi);
    _perbaruiController(_deskripsi, _form.deskripsi);
  }

  Future<void> _bukaPratinjau() async {
    FocusScope.of(context).unfocus();

    final berhasil = await Navigator.pushNamed(
      context,
      AppRoutes.pratinjauLaporan,
    );

    if (!mounted || berhasil != true) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _form.removeListener(_sinkronkanIsian);

    _judul.dispose();
    _lokasi.dispose();
    _deskripsi.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<FormLaporanModel>();

    final total = context.select<RiwayatLaporanModel, int>(
      (model) => model.totalLaporan,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan'),
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
                Text(
                  'Laporkan Permasalahan Sampah',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lengkapi informasi lokasi dan kondisi sampah, '
                  'lalu periksa laporan sebelum mengirim.',
                ),
                const SizedBox(height: 8),
                Text('Laporan tersimpan: $total'),
                const SizedBox(height: 24),

                TextField(
                  controller: _judul,
                  enabled: !form.sedangMengirim,
                  onChanged: form.ubahJudul,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Judul laporan',
                    hintText:
                        'Contoh: Sampah menumpuk di Jalan Braga',
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _lokasi,
                  enabled: !form.sedangMengirim,
                  onChanged: form.ubahLokasi,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi kejadian',
                    hintText:
                        'Tuliskan jalan atau wilayah di Bandung',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _deskripsi,
                  enabled: !form.sedangMengirim,
                  onChanged: form.ubahDeskripsi,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi permasalahan',
                    alignLabelWithHint: true,
                    hintText:
                        'Jelaskan kondisi sampah dan dampaknya.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity:
                      ListTileControlAffinity.leading,
                  value: form.setuju,
                  onChanged: form.sedangMengirim
                      ? null
                      : (nilai) {
                          form.ubahPersetujuan(
                            nilai ?? false,
                          );
                        },
                  title: const Text(
                    'Saya menyetujui penggunaan informasi laporan '
                    'untuk tindak lanjut kebersihan lingkungan.',
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed:
                      form.formLengkap && !form.sedangMengirim
                          ? _bukaPratinjau
                          : null,
                  icon: const Icon(
                    Icons.preview_outlined,
                  ),
                  label: const Text('Pratinjau Laporan'),
                ),

                TextButton.icon(
                  onPressed: form.sedangMengirim
                      ? null
                      : form.kosongkanForm,
                  icon: const Icon(Icons.clear),
                  label: const Text('Kosongkan Formulir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}