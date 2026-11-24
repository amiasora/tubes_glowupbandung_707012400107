import 'package:flutter/material.dart';

import '../helpers/hive_helper.dart';
import '../models/catatan_admin.dart';
import '../services/sesi_akun.dart';

class HalamanCatatanAdmin extends StatefulWidget {
  const HalamanCatatanAdmin({super.key, required this.idAdmin});

  final int idAdmin;

  @override
  State<HalamanCatatanAdmin> createState() => _HalamanCatatanAdminState();
}

class _HalamanCatatanAdminState extends State<HalamanCatatanAdmin> {
  final HiveHelper _hive = HiveHelper.instance;

  List<CatatanAdmin> _catatan = const [];
  bool _sibuk = true;
  String? _pesanError;

  bool get _bolehAkses {
    final akun = SesiAkun.aktif;

    return akun != null &&
        akun.peran == PeranAkun.admin &&
        akun.id == widget.idAdmin;
  }

  @override
  void initState() {
    super.initState();
    _muatCatatan();
  }

  Future<void> _muatCatatan() async {
    if (!_bolehAkses) return;

    setState(() {
      _sibuk = true;
      _pesanError = null;
    });

    try {
      await _hive.init();

      if (!mounted || !_bolehAkses) return;

      final daftar = _hive.bacaCatatanAdmin(widget.idAdmin);

      setState(() => _catatan = daftar);
    } catch (error) {
      debugPrint('Gagal membaca catatan admin: $error');

      if (mounted) {
        setState(() {
          _pesanError = 'Catatan belum dapat dimuat.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _sibuk = false);
      }
    }
  }

  Future<void> _jalankanOperasi(
    Future<void> Function() operasi,
    String pesanBerhasil,
  ) async {
    if (_sibuk || !_bolehAkses) return;

    setState(() {
      _sibuk = true;
      _pesanError = null;
    });

    try {
      await _hive.init();

      if (!mounted || !_bolehAkses) return;

      await operasi();

      if (!mounted || !_bolehAkses) return;

      final daftar = _hive.bacaCatatanAdmin(widget.idAdmin);

      setState(() => _catatan = daftar);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pesanBerhasil)));
    } catch (error) {
      debugPrint('Operasi catatan admin gagal: $error');

      if (mounted) {
        setState(() {
          _pesanError = 'Operasi belum berhasil. Silakan coba kembali.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _sibuk = false);
      }
    }
  }

  Future<void> _tambahCatatan() async {
    if (_sibuk || !_bolehAkses) return;

    final formKey = GlobalKey<FormState>();

    var judul = '';
    var isi = '';
    var kodeLaporan = '';

    final baru = await showDialog<CatatanAdmin>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah catatan kerja'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autofocus: true,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Judul'),
                    validator: (nilai) => (nilai?.trim().isEmpty ?? true)
                        ? 'Judul wajib diisi.'
                        : null,
                    onSaved: (nilai) => judul = nilai!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: const InputDecoration(labelText: 'Isi catatan'),
                    validator: (nilai) => (nilai?.trim().isEmpty ?? true)
                        ? 'Isi catatan wajib diisi.'
                        : null,
                    onSaved: (nilai) => isi = nilai!.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Kode laporan (opsional)',
                      helperText: 'Referensi catatan, misalnya GUB-000001.',
                    ),
                    onSaved: (nilai) {
                      kodeLaporan = (nilai ?? '').trim();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final form = formKey.currentState!;

              if (!form.validate()) return;

              form.save();

              final waktu = DateTime.now().toUtc();

              Navigator.pop(
                dialogContext,
                CatatanAdmin(
                  idCatatan: waktu.microsecondsSinceEpoch.toString(),
                  idAdmin: widget.idAdmin,
                  judul: judul,
                  isi: isi,
                  kodeLaporan: kodeLaporan,
                  dibuatAtUtc: waktu,
                  diubahAtUtc: waktu,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (!mounted || baru == null) return;

    await _jalankanOperasi(
      () => _hive.simpanCatatan(baru),
      'Catatan berhasil disimpan.',
    );
  }

  Future<void> _hapusCatatan(CatatanAdmin catatan) async {
    if (_sibuk || !_bolehAkses) return;

    final hapus = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('Catatan "${catatan.judul}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!mounted || hapus != true) return;

    await _jalankanOperasi(
      () => _hive.hapusCatatan(
        idAdmin: widget.idAdmin,
        idCatatan: catatan.idCatatan,
      ),
      'Catatan berhasil dihapus.',
    );
  }

  String _formatWib(DateTime waktu) {
    final wib = waktu.toUtc().add(const Duration(hours: 7));

    String dua(int angka) {
      return angka.toString().padLeft(2, '0');
    }

    return '${dua(wib.day)}/${dua(wib.month)}/${wib.year} '
        '${dua(wib.hour)}:${dua(wib.minute)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    if (!_bolehAkses) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catatan kerja admin')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Masuk sebagai admin untuk membuka catatan kerja.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan kerja admin'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang catatan',
            onPressed: _sibuk ? null : _muatCatatan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _sibuk && _catatan.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  '${_catatan.length} catatan tersimpan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Catatan kerja pribadi admin pada perangkat ini.'),
                const SizedBox(height: 16),
                if (_sibuk) const LinearProgressIndicator(),
                if (_pesanError != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_pesanError!),
                    ),
                  ),
                if (_catatan.isEmpty && _pesanError == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada catatan. Tekan Tambah catatan '
                        'untuk memulai.',
                      ),
                    ),
                  ),
                for (final catatan in _catatan)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  catatan.judul,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Hapus catatan',
                                onPressed: _sibuk
                                    ? null
                                    : () {
                                        _hapusCatatan(catatan);
                                      },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          if (catatan.kodeLaporan.isNotEmpty)
                            Text('Referensi: ${catatan.kodeLaporan}'),
                          const SizedBox(height: 8),
                          Text(catatan.isi),
                          const SizedBox(height: 12),
                          Text(
                            'Dibuat: '
                            '${_formatWib(catatan.dibuatAtUtc)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sibuk ? null : _tambahCatatan,
        icon: const Icon(Icons.add),
        label: const Text('Tambah catatan'),
      ),
    );
  }
}
