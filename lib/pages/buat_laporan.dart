import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/buat_laporan_cubit.dart';
import '../models/titik_laporan.dart';
import '../widgets/kerangka_warga.dart';
import 'pilih_lokasi_laporan.dart';

class BuatLaporan extends StatelessWidget {
  const BuatLaporan({super.key, this.idWarga = 1});

  // Akun warga praktikum. Sesi login akan menggantikan nilai ini pada tahap berikut.
  final int idWarga;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BuatLaporanCubit(idWarga: idWarga)..muatReferensi(),
      child: const _FormBuatLaporan(),
    );
  }
}

class _FormBuatLaporan extends StatefulWidget {
  const _FormBuatLaporan();

  @override
  State<_FormBuatLaporan> createState() => _FormBuatLaporanState();
}

class _FormBuatLaporanState extends State<_FormBuatLaporan> {
  final _form = GlobalKey<FormState>();
  final _deskripsi = TextEditingController();
  final _deskripsiLokasi = TextEditingController();
  bool _pernahMenyimpan = false;
  bool _mencobaKirim = false;

  @override
  void dispose() {
    _deskripsi.dispose();
    _deskripsiLokasi.dispose();
    super.dispose();
  }

  Future<void> _pilihLokasi() async {
    final cubit = context.read<BuatLaporanCubit>();
    final titik = await Navigator.push<TitikLaporan>(
      context,
      MaterialPageRoute(
        builder: (_) => PilihLokasiLaporan(lokasiAwal: cubit.state.lokasi),
      ),
    );
    if (!mounted || titik == null) return;
    cubit.tetapkanLokasi(titik);
  }

  Future<void> _kirim() async {
    setState(() => _mencobaKirim = true);
    final valid = _form.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();
    final cubit = context.read<BuatLaporanCubit>();
    if (!valid) return;
    await cubit.kirim();
  }

  void _formBaru() {
    setState(() => _mencobaKirim = false);
    _deskripsi.clear();
    _deskripsiLokasi.clear();
    _form.currentState?.reset();
    final cubit = context.read<BuatLaporanCubit>();
    cubit.mulaiFormBaru();
    cubit.muatReferensi();
  }

  String? _validasiPanjang(String? nilai, int minimum, int maksimum) {
    final panjang = (nilai ?? '').trim().runes.length;
    if (panjang < minimum || panjang > maksimum) {
      return 'Isi $minimum–$maksimum karakter.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BuatLaporanCubit, BuatLaporanState>(
      listener: (context, state) {
        if (state.hasilSimpan != null) _pernahMenyimpan = true;
      },
      builder: (context, state) {
        final cubit = context.read<BuatLaporanCubit>();
        final hasil = state.hasilSimpan;
        final terkunci = state.sibuk || hasil != null;
        return PopScope<Object?>(
          canPop: !state.sibuk && !_pernahMenyimpan,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !state.sibuk && _pernahMenyimpan) {
              Navigator.pop(context, true);
            }
          },
          child: KerangkaWarga(
            menuAktif: MenuWarga.buatLaporan,
            navigasiAktif: !state.sibuk,
            child: hasil != null
                ? _tampilanBerhasil(state)
                : Form(
                    key: _form,
                    child: KontenWarga(
                      maxLebar: 990,
                      children: [
                        JudulHalamanWarga(
                          judul: 'Buat Laporan',
                          deskripsi: state.namaWarga.isEmpty
                              ? 'Memuat identitas pelapor…'
                              : 'Pelapor · ${state.namaWarga}',
                        ),
                        if (state.memuatReferensi)
                          const LinearProgressIndicator(),
                        if (!state.referensiSiap && !state.memuatReferensi)
                          OutlinedButton.icon(
                            onPressed: state.sibuk ? null : cubit.muatReferensi,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Muat ulang data pilihan'),
                          ),
                        _seksi('Kondisi sampah', Icons.description_outlined, [
                          TextFormField(
                            controller: _deskripsi,
                            enabled: !terkunci,
                            minLines: 4,
                            maxLines: 8,
                            decoration: InputDecoration(
                              labelText: 'Deskripsi laporan',
                              hintText:
                                  'Jelaskan kondisi dan dampak sampah yang ditemukan.',
                              helperText: 'Wajib diisi, 10–2.000 karakter.',
                              counterText:
                                  '${state.deskripsiLaporan.trim().runes.length}/2000',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (nilai) =>
                                _validasiPanjang(nilai, 10, 2000),
                            onChanged: cubit.ubahDeskripsi,
                          ),
                        ]),

                        const SizedBox(height: 14),
                        _seksi('Bukti foto', Icons.photo_library_outlined, [
                          const Text(
                            'Unggah 3 foto JPG/PNG, maksimal 2 MB per foto.',
                          ),
                          const Text(
                            'Foto 1 · Ambil dari jarak lebih jauh agar lokasi dan patokan terlihat.',
                          ),
                          const Text(
                            'Foto 2 · Ambil dari samping untuk memperlihatkan bentuk dan sebaran sampah.',
                          ),
                          const Text(
                            'Foto 3 · Ambil detail sampah dari jarak aman.',
                          ),
                          if (state.foto.isNotEmpty)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(state.foto.length, (
                                indeks,
                              ) {
                                final foto = state.foto[indeks];
                                return SizedBox(
                                  width: 180,
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.memory(
                                          Uint8List.fromList(foto.dataFoto),
                                          width: 180,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          cacheWidth: 360,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => const SizedBox(
                                                height: 120,
                                                child: Center(
                                                  child: Text(
                                                    'Pratinjau tidak tersedia',
                                                  ),
                                                ),
                                              ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            'Foto ${indeks + 1} · ${foto.namaBerkas}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${(foto.ukuranByte / 1000).toStringAsFixed(1)} KB',
                                        ),
                                        TextButton.icon(
                                          onPressed: terkunci
                                              ? null
                                              : () => cubit.hapusFoto(indeks),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Hapus foto'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: terkunci || state.foto.length >= 3
                                  ? null
                                  : cubit.tambahFoto,
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: Text(
                                state.memprosesFoto
                                    ? 'Memeriksa foto…'
                                    : 'Tambah foto (${state.foto.length}/3)',
                              ),
                            ),
                          ),
                          if (state.memprosesFoto)
                            const LinearProgressIndicator(),
                          if (state.pesanError case final pesan?
                              when pesan.startsWith('Foto ') ||
                                  pesan.startsWith('Pilih maksimal'))
                            Text(
                              pesan,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          if (_mencobaKirim && state.foto.length != 3)
                            Text(
                              'Lengkapi ketiga foto JPG/PNG.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ]),

                        const SizedBox(height: 14),
                        KisiGlow(
                          kolomMaksimal: 2,
                          lebarMinimum: 315,
                          children: [
                            _seksi(
                              'Kategori laporan',
                              Icons.category_outlined,
                              [
                                DropdownButtonFormField<int>(
                                  key: ValueKey(state.idKategori),
                                  initialValue: state.idKategori,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Pilih satu kategori',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: state.daftarKategori
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item.idKategori,
                                          child: Text(item.namaKategori),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: terkunci || !state.referensiSiap
                                      ? null
                                      : cubit.pilihKategori,
                                  validator: (nilai) =>
                                      nilai == null ? 'Pilih kategori.' : null,
                                ),
                                TextButton.icon(
                                  onPressed: terkunci
                                      ? null
                                      : cubit.muatReferensi,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Muat ulang kategori'),
                                ),
                              ],
                            ),

                            _seksi('Jenis sampah', Icons.recycling, [
                              const Text(
                                'Pilih sedikitnya satu jenis; boleh lebih dari satu.',
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: state.daftarJenisSampah
                                    .map(
                                      (item) => FilterChip(
                                        label: Text(item.namaJenis),
                                        selected: state.jenisDipilih.contains(
                                          item.idJenis,
                                        ),
                                        onSelected: terkunci
                                            ? null
                                            : (dipilih) =>
                                                  cubit.ubahJenisSampah(
                                                    item.idJenis,
                                                    dipilih,
                                                  ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              if (_mencobaKirim && state.jenisDipilih.isEmpty)
                                Text(
                                  'Pilih sedikitnya satu jenis sampah.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _seksi('Titik kejadian', Icons.location_on_outlined, [
                          if (state.lokasi case final lokasi?)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Titik lokasi sudah dikonfirmasi.',
                                    ),
                                    Text(
                                      lokasi.alamatPeta ??
                                          'Kecamatan ${lokasi.kecamatan}',
                                    ),
                                    SelectableText(
                                      'Latitude: ${lokasi.latitude.toStringAsFixed(6)}\n'
                                      'Longitude: ${lokasi.longitude.toStringAsFixed(6)}',
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Text(
                              'Belum ada titik yang dikonfirmasi.',
                              style: _mencobaKirim
                                  ? TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    )
                                  : null,
                            ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: terkunci ? null : _pilihLokasi,
                                icon: const Icon(Icons.map_outlined),
                                label: Text(
                                  state.lokasi == null
                                      ? 'Mencari Titik Lokasi'
                                      : 'Ubah Titik Lokasi',
                                ),
                              ),
                              if (state.lokasi != null)
                                TextButton(
                                  onPressed: terkunci
                                      ? null
                                      : cubit.hapusLokasi,
                                  child: const Text('Hapus pilihan titik'),
                                ),
                            ],
                          ),
                        ]),

                        const SizedBox(height: 14),
                        _seksi('Patokan lokasi', Icons.signpost_outlined, [
                          TextFormField(
                            controller: _deskripsiLokasi,
                            enabled: !terkunci,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Deskripsi lokasi',
                              hintText:
                                  'Nama jalan, patokan, atau ciri lokasi sampah.',
                              helperText:
                                  'Opsional, 5–500 karakter jika diisi.',
                              counterText:
                                  '${state.deskripsiLokasi.trim().runes.length}/500',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (nilai) => (nilai ?? '').trim().isEmpty
                                ? null
                                : _validasiPanjang(nilai, 5, 500),
                            onChanged: cubit.ubahDeskripsiLokasi,
                          ),
                        ]),

                        if (state.pesanError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              state.pesanError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (_mencobaKirim &&
                            !state.bolehKirim &&
                            state.pesanError == null &&
                            state.pesanValidasi != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(state.pesanValidasi!),
                          ),
                        const SizedBox(height: 14),
                        PanelGlow(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: state.referensiSiap && !state.sibuk
                                    ? _kirim
                                    : null,
                                icon: state.menyimpan
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send_outlined),
                                label: Text(
                                  state.menyimpan
                                      ? 'Menyimpan…'
                                      : 'Kirim Laporan',
                                ),
                              ),
                              TextButton(
                                onPressed: state.sibuk
                                    ? null
                                    : () => Navigator.maybePop(context),
                                child: const Text('Batal'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _seksi(String judul, IconData icon, List<Widget> isi) => PanelGlow(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _JudulSeksi(judul: judul, icon: icon),
        ...isi,
      ],
    ),
  );

  Widget _tampilanBerhasil(BuatLaporanState state) {
    final laporan = state.hasilSimpan!;
    return KontenWarga(
      maxLebar: 760,
      children: [
        const JudulHalamanWarga(judul: 'Laporan Tersimpan'),
        _seksi('Laporan berhasil dikirim', Icons.task_alt, [
          SelectableText(
            '${laporan.kodeLaporan} · ${waktuWibWarga(laporan.dibuatAtUtc)}',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: LabelGlow(laporan.statusPenanganan.nilaiDatabase),
          ),
          const Text(
            'Laporan menunggu peninjauan admin. Bukti pengiriman tersedia di Notifikasi.',
          ),
        ]),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => Navigator.pushNamed<Object?>(
                context,
                '/detail-laporan',
                arguments: <String, int>{
                  'idLaporan': laporan.idLaporan!,
                  'idWarga': state.idWarga,
                },
              ),
              child: const Text('Lihat Detail Laporan'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kembali'),
            ),
            TextButton(
              onPressed: _formBaru,
              child: const Text('Buat Laporan Baru'),
            ),
          ],
        ),
      ],
    );
  }
}

class _JudulSeksi extends StatelessWidget {
  const _JudulSeksi({required this.judul, required this.icon});
  final String judul;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      spacing: 10,
      children: [
        Icon(icon, color: tema.colorScheme.primary),
        Expanded(child: Text(judul, style: tema.textTheme.titleMedium)),
      ],
    );
  }
}