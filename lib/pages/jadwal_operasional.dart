import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../db/database_helper.dart';
import '../models/foto_laporan.dart';
import '../models/jadwal_pengangkutan.dart';
import '../models/penanganan_laporan.dart';
import '../services/layanan_foto.dart';
import '../services/sesi_akun.dart';
import '../widgets/kerangka_warga.dart';
import 'pilih_lokasi_laporan.dart';

String _hari(DateTime wib) => const [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
][wib.weekday - 1];

String _jam(TimeOfDay jam) =>
    '${jam.hour.toString().padLeft(2, '0')}.${jam.minute.toString().padLeft(2, '0')}';

String _waktuJadwal(JadwalPengangkutan jadwal) {
  final mulai = jadwal.mulaiUtc.toUtc().add(const Duration(hours: 7));
  final selesai = jadwal.selesaiUtc.toUtc().add(const Duration(hours: 7));
  return '${_hari(mulai)}, ${tanggalWarga(mulai)} · '
      '${_jam(TimeOfDay.fromDateTime(mulai))}–${_jam(TimeOfDay.fromDateTime(selesai))} WIB';
}

class JadwalAdmin extends StatefulWidget {
  const JadwalAdmin({
    super.key,
    required this.akun,
    required this.idLaporan,
    required this.kodeLaporan,
    required this.versiLaporan,
  });

  final AkunAktif akun;
  final int idLaporan;
  final String kodeLaporan;
  final int versiLaporan;

  @override
  State<JadwalAdmin> createState() => _JadwalAdminState();
}

class _JadwalAdminState extends State<JadwalAdmin> {
  final _db = DatabaseHelper.instance;
  final _catatan = TextEditingController();
  final _tim = <int>{};
  late Future<
    ({JadwalPengangkutan? jadwal, List<Map<String, Object?>> petugas})
  >
  _data;
  DateTime? _tanggal;
  TimeOfDay? _mulai;
  TimeOfDay? _selesai;
  int? _koordinator;
  String? _galat;
  bool _simpanAktif = false;
  bool _ubah = false;

  @override
  void initState() {
    super.initState();
    _data = _muat();
  }

  Future<({JadwalPengangkutan? jadwal, List<Map<String, Object?>> petugas})>
  _muat() async {
    final jadwal = await _db.ambilJadwalAktifAdmin(
      idAdmin: widget.akun.id,
      idLaporan: widget.idLaporan,
    );
    final petugas = await _db.ambilPetugasAktifJadwal(widget.akun.id);
    return (jadwal: jadwal, petugas: petugas);
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final hariIni = DateTime(wib.year, wib.month, wib.day);
    final terpilih = _tanggal;
    final tanggal = await showDatePicker(
      context: context,
      initialDate: terpilih == null || terpilih.isBefore(hariIni)
          ? hariIni
          : terpilih,
      currentDate: hariIni,
      firstDate: hariIni,
      lastDate: DateTime(hariIni.year + 2, 12, 31),
      helpText: 'Tanggal pengangkutan (WIB)',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted || tanggal == null) return;
    setState(() => _tanggal = tanggal);
  }

  Future<void> _pilihJam(bool mulai) async {
    final jam = await showTimePicker(
      context: context,
      initialTime:
          (mulai ? _mulai : _selesai) ??
          TimeOfDay(hour: mulai ? 9 : 10, minute: 0),
      helpText: mulai ? 'Jam mulai (WIB)' : 'Perkiraan selesai (WIB)',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted || jam == null) return;
    setState(() {
      if (mulai) {
        _mulai = jam;
      } else {
        _selesai = jam;
      }
    });
  }

  Future<void> _simpan(int? idJadwalDiganti) async {
    if (_simpanAktif || !identical(SesiAkun.aktif, widget.akun)) return;
    final tanggal = _tanggal;
    final mulai = _mulai;
    final selesai = _selesai;
    final koordinator = _koordinator;
    if (tanggal == null || mulai == null || selesai == null) {
      setState(
        () => _galat = 'Pilih tanggal, jam mulai, dan perkiraan selesai.',
      );
      return;
    }
    if (koordinator == null) {
      setState(() => _galat = 'Pilih tim dan satu koordinator penyelesaian.');
      return;
    }

    DateTime keUtc(TimeOfDay jam) => DateTime.utc(
      tanggal.year,
      tanggal.month,
      tanggal.day,
      jam.hour,
      jam.minute,
    ).subtract(const Duration(hours: 7));

    setState(() {
      _simpanAktif = true;
      _galat = null;
    });
    try {
      await _db.simpanJadwalPengangkutan(
        idAdmin: widget.akun.id,
        idLaporan: widget.idLaporan,
        versiLaporan: widget.versiLaporan,
        idJadwalDiganti: idJadwalDiganti,
        mulai: keUtc(mulai),
        selesai: keUtc(selesai),
        idTim: _tim,
        idKoordinator: koordinator,
        catatan: _catatan.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on GalatJadwal catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } on Exception {
      if (mounted) {
        setState(() => _galat = 'Jadwal belum bisa disimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _simpanAktif = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_simpanAktif,
    child: KerangkaPeran(
      peran: PeranAkun.admin,
      ruteAktif: '/admin/jadwal',
      menu: const {'/': 'Dashboard', '/admin/laporan': 'Daftar Laporan'},
      navigasiAktif: !_simpanAktif,
      child: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final jadwal = data?.jadwal;
          return KontenWarga(
            maxLebar: 920,
            children: [
              JudulHalamanWarga(
                judul: jadwal == null
                    ? 'Jadwalkan Pengangkutan'
                    : 'Jadwal Pengangkutan',
                deskripsi: widget.kodeLaporan,
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (snapshot.hasError || data == null) ...[
                const Text('Data jadwal belum dapat dimuat.'),
                OutlinedButton(
                  onPressed: () {
                    final data = _muat();
                    setState(() {
                      _data = data;
                    });
                  },
                  child: const Text('Muat ulang'),
                ),
              ] else ...[
                if (jadwal != null)
                  _KartuJadwal(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LabelGlow(jadwal.status),
                      ),
                      Text(_waktuJadwal(jadwal)),
                      if (jadwal.status == 'Terjadwal' && !_ubah)
                        OutlinedButton(
                          onPressed: () => setState(() => _ubah = true),
                          child: const Text('Jadwalkan ulang'),
                        ),
                    ],
                  ),
                if (jadwal == null || _ubah) ..._form(data.petugas, jadwal?.id),
              ],
              TextButton(
                onPressed: _simpanAktif
                    ? null
                    : () => Navigator.maybePop(context),
                child: const Text('Kembali'),
              ),
            ],
          );
        },
      ),
    ),
  );

  List<Widget> _form(List<Map<String, Object?>> petugas, int? idJadwalDiganti) {
    final tanggal = _tanggal;
    final mulai = _mulai;
    final selesai = _selesai;
    return [
      KisiGlow(
        kolomMaksimal: 2,
        lebarMinimum: 325,
        children: [
          _KartuJadwal(
            children: [
              Text(
                'Waktu pengangkutan (WIB)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              OutlinedButton.icon(
                onPressed: _simpanAktif ? null : _pilihTanggal,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  tanggal == null
                      ? 'Pilih tanggal'
                      : '${_hari(tanggal)}, ${tanggalWarga(tanggal)}',
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _simpanAktif ? null : () => _pilihJam(true),
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      mulai == null ? 'Jam mulai' : 'Mulai ${_jam(mulai)} WIB',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _simpanAktif ? null : () => _pilihJam(false),
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      selesai == null
                          ? 'Perkiraan selesai'
                          : 'Selesai ${_jam(selesai)} WIB',
                    ),
                  ),
                ],
              ),
            ],
          ),
          _KartuJadwal(
            children: [
              Text(
                'Tim penugasan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Pilih petugas, lalu tetapkan satu anggota sebagai koordinator.',
              ),
              if (petugas.isEmpty) const Text('Belum ada petugas aktif.'),
              for (final orang in petugas)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(orang['nama'] as String),
                  value: _tim.contains(orang['id_petugas']),
                  onChanged: _simpanAktif
                      ? null
                      : (dipilih) {
                          final id = orang['id_petugas'] as int;
                          setState(() {
                            if (dipilih == true) {
                              _tim.add(id);
                            } else {
                              _tim.remove(id);
                              if (_koordinator == id) _koordinator = null;
                            }
                          });
                        },
                ),
              DropdownButtonFormField<int>(
                key: ValueKey(_koordinator),
                initialValue: _koordinator,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Koordinator penyelesaian',
                ),
                items: [
                  for (final orang in petugas)
                    if (_tim.contains(orang['id_petugas']))
                      DropdownMenuItem(
                        value: orang['id_petugas'] as int,
                        child: Text(orang['nama'] as String),
                      ),
                ],
                onChanged: _simpanAktif || _tim.isEmpty
                    ? null
                    : (id) => setState(() => _koordinator = id),
              ),
            ],
          ),
        ],
      ),
      _KartuJadwal(
        children: [
          TextField(
            controller: _catatan,
            enabled: !_simpanAktif,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Catatan tugas'),
          ),
        ],
      ),
      if (_galat case final pesan?)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            pesan,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      FilledButton.icon(
        onPressed: _simpanAktif || petugas.isEmpty
            ? null
            : () => _simpan(idJadwalDiganti),
        icon: const Icon(Icons.save_outlined),
        label: Text(_simpanAktif ? 'Menyimpan…' : 'Simpan Jadwal'),
      ),
    ];
  }
}
class DashboardPetugas extends StatefulWidget {
  const DashboardPetugas({super.key, required this.akun, this.rute = '/'});

  final AkunAktif akun;
  final String rute;

  @override
  State<DashboardPetugas> createState() => _DashboardPetugasState();
}

class _DashboardPetugasState extends State<DashboardPetugas> {
  late Future<List<PenugasanPetugas>> _daftar;

  @override
  void initState() {
    super.initState();
    _daftar = _ambil();
  }

  Future<List<PenugasanPetugas>> _ambil() =>
      DatabaseHelper.instance.ambilPenugasanPetugas(widget.akun.id);

  void _muatUlang() {
    final daftar = _ambil();
    setState(() {
      _daftar = daftar;
    });
  }

  Future<void> _buka(int idJadwal) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailPenugasan(akun: widget.akun, idJadwal: idJadwal),
      ),
    );
    if (mounted) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => KerangkaPeran(
    peran: PeranAkun.petugas,
    ruteAktif: widget.rute,
    menu: const {'/': 'Dashboard'},
    onKembali: () async => _muatUlang(),
    child: FutureBuilder<List<PenugasanPetugas>>(
      future: _daftar,
      builder: (context, snapshot) {
        final jadwal = snapshot.data ?? const <PenugasanPetugas>[];
        final baru = jadwal.where((tugas) => tugas.belumDibaca).length;
        final aktif = jadwal
            .where((tugas) => tugas.jadwal.status != 'Selesai')
            .length;
        final notifikasi = widget.rute == '/petugas/notifikasi';
        final dashboard = widget.rute == '/';
        final tema = Theme.of(context);
        return KontenWarga(
          children: [
            JudulHalamanWarga(
              judul: dashboard
                  ? 'Dashboard Petugas'
                  : notifikasi
                  ? 'Notifikasi Penugasan'
                  : 'Jadwal Pengangkutan',
              deskripsi: dashboard
                  ? 'Halo, ${widget.akun.nama}. Buka penugasan untuk melihat lokasi dan tim.'
                  : notifikasi
                  ? 'Buka penugasan untuk membaca pemberitahuannya.'
                  : 'Waktu, lokasi, dan status pekerjaan yang ditugaskan kepada Anda.',
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(semanticsLabel: 'Memuat jadwal')
            else if (snapshot.hasError)
              KeadaanGlow(
                judul: 'Jadwal belum dapat dimuat',
                pesan: 'Muat ulang untuk mencoba kembali.',
                icon: Icons.error_outline,
                aksi: OutlinedButton(
                  onPressed: _muatUlang,
                  child: const Text('Muat ulang'),
                ),
              )
            else ...[
              if (dashboard) ...[
                KisiGlow(
                  lebarMinimum: 142,
                  children: [
                    _ringkasan(
                      'Tugas aktif',
                      aktif,
                      Icons.local_shipping_outlined,
                      '/petugas/jadwal',
                    ),
                    _ringkasan(
                      'Selesai',
                      jadwal.length - aktif,
                      Icons.task_alt,
                      '/petugas/jadwal',
                    ),
                    _ringkasan(
                      'Belum dibaca',
                      baru,
                      Icons.notifications_outlined,
                      '/petugas/notifikasi',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Jadwal Pengangkutan', style: tema.textTheme.titleLarge),
                const SizedBox(height: 12),
              ],
              if (jadwal.isEmpty)
                KeadaanGlow(
                  judul: notifikasi
                      ? 'Belum ada notifikasi penugasan'
                      : 'Belum ada penugasan',
                  pesan: 'Penugasan akan muncul setelah Admin menetapkan jadwal untuk Anda.',
                  icon: notifikasi
                      ? Icons.notifications_none
                      : Icons.event_busy_outlined,
                )
              else
                KisiGlow(
                  kolomMaksimal: 2,
                  lebarMinimum: 375,
                  children: [
                    for (final tugas in jadwal)
                      _kartuTugas(context, tugas, notifikasi),
                  ],
                ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: snapshot.connectionState == ConnectionState.waiting
                    ? null
                    : _muatUlang,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang jadwal'),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _ringkasan(
    String judul,
    int jumlah,
    IconData icon,
    String rute,
  ) => Card(
    child: InkWell(
      onTap: () async {
        await Navigator.pushNamed<void>(context, rute);
        if (mounted) _muatUlang();
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            Text('$jumlah', style: Theme.of(context).textTheme.headlineSmall),
            Text(judul),
          ],
        ),
      ),
    ),
  );

  Widget _kartuTugas(
    BuildContext context,
    PenugasanPetugas tugas,
    bool notifikasi,
  ) {
    final tema = Theme.of(context);
    return PanelGlow(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(tugas.kodeLaporan, style: tema.textTheme.titleMedium),
              LabelGlow(tugas.jadwal.status),
              if (tugas.belumDibaca) const LabelGlow('Belum dibaca'),
            ],
          ),
          Text(_waktuJadwal(tugas.jadwal), style: tema.textTheme.bodyMedium),
          Text(
            '${tugas.kecamatan} · ${tugas.peranTugas}',
            style: tema.textTheme.bodySmall,
          ),
          OutlinedButton.icon(
            onPressed: () => _buka(tugas.jadwal.id),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(notifikasi ? 'Buka penugasan' : 'Lihat detail'),
          ),
        ],
      ),
    );
  }
}

class _DetailPenugasan extends StatefulWidget {
  const _DetailPenugasan({required this.akun, required this.idJadwal});

  final AkunAktif akun;
  final int idJadwal;

  @override
  State<_DetailPenugasan> createState() => _DetailPenugasanState();
}

class _DetailPenugasanState extends State<_DetailPenugasan> {
  late var _detail = _ambil();
  bool _checkInAktif = false;

  Future<
    ({
      PenugasanPetugas tugas,
      List<Map<String, Object?>> tim,
      List<AktivitasPengangkutan> aktivitas,
    })?
  >
  _ambil() => DatabaseHelper.instance.bukaPenugasanPetugas(
    idPetugas: widget.akun.id,
    idJadwal: widget.idJadwal,
  );

  Future<void> _checkIn() async {
    if (_checkInAktif || !identical(SesiAkun.aktif, widget.akun)) return;
    setState(() => _checkInAktif = true);
    var pesan = 'Check-in tersimpan. Pengangkutan sedang dikerjakan.';
    try {
      await DatabaseHelper.instance.simpanAktivitasPengangkutan(
        idJadwal: widget.idJadwal,
        idPetugas: widget.akun.id,
        tahap: TahapPengangkutan.mulai,
        kunciKirim: 'check-in',
      );
    } on GalatJadwal catch (e) {
      pesan = e.pesan;
    } catch (_) {
      pesan = 'Check-in belum tersimpan. Coba lagi.';
    }
    if (!mounted) return;
    setState(() {
      _checkInAktif = false;
      _detail = _ambil();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _bukaForm(TahapPengangkutan tahap) async {
    final tersimpan = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormAktivitas(
        akun: widget.akun,
        idJadwal: widget.idJadwal,
        tahap: tahap,
      ),
    );
    if (!mounted) return;
    final detail = _ambil();
    setState(() {
      _detail = detail;
    });
    if (tersimpan == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aktivitas tersimpan.')));
    }
  }

  @override
  Widget build(BuildContext context) => KerangkaPeran(
    peran: PeranAkun.petugas,
    ruteAktif: '/petugas/jadwal',
    menu: const {'/': 'Dashboard'},
    child: FutureBuilder(
      future: _detail,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final tugas = detail?.tugas;
        return KontenWarga(
          children: [
            JudulHalamanWarga(
              judul: 'Detail Penugasan',
              deskripsi: tugas?.kodeLaporan,
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator()
            else if (snapshot.hasError)
              const Text(
                'Detail penugasan belum dapat dimuat. Kembali dan buka lagi.',
              )
            else if (detail == null || tugas == null)
              const Text(
                'Jadwal ini sudah berubah atau tidak ditugaskan kepada akun Anda.',
              )
            else ...[
              _KartuJadwal(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LabelGlow(tugas.jadwal.status),
                  ),
                  Text(_waktuJadwal(tugas.jadwal)),
                  Text('Peran Anda · ${tugas.peranTugas}'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (tugas.jadwal.status == 'Terjadwal')
                        FilledButton.icon(
                          onPressed: _checkInAktif ? null : _checkIn,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            _checkInAktif
                                ? 'Menyimpan…'
                                : TahapPengangkutan.mulai.aksi,
                          ),
                        ),
                      if (tugas.jadwal.status == 'Dikerjakan') ...[
                        FilledButton.icon(
                          onPressed: () =>
                              _bukaForm(TahapPengangkutan.tanggapan),
                          icon: const Icon(Icons.image_outlined),
                          label: Text(TahapPengangkutan.tanggapan.aksi),
                        ),
                        if (tugas.peranTugas == 'Koordinator')
                          OutlinedButton(
                            onPressed: () =>
                                _bukaForm(TahapPengangkutan.selesai),
                            child: Text(TahapPengangkutan.selesai.aksi),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
              _KartuJadwal(
                children: [
                  Text(
                    'Lokasi pengangkutan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SelectableText('${tugas.kecamatan} · ${tugas.lokasi}'),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).width < 760 ? 224 : 325,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PetaLaporan(
                        pusatAwal: LatLng(tugas.latitude, tugas.longitude),
                        titik: LatLng(tugas.latitude, tugas.longitude),
                      ),
                    ),
                  ),
                  SelectableText(
                    '${tugas.latitude.toStringAsFixed(6)}, '
                    '${tugas.longitude.toStringAsFixed(6)}',
                  ),
                  SelectableText(tugas.deskripsi),
                ],
              ),
              _KartuJadwal(
                children: [
                  Text(
                    'Tim penugasan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final orang in detail.tim)
                    Text('${orang['peran_tugas']} · ${orang['nama']}'),
                  if (tugas.catatan.isNotEmpty)
                    SelectableText('Catatan tugas · ${tugas.catatan}'),
                ],
              ),
              for (final aktivitas in detail.aktivitas)
                KartuAktivitasPengangkutan(aktivitas: aktivitas),
            ],
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Kembali ke jadwal'),
            ),
          ],
        );
      },
    ),
  );
}
class _FormAktivitas extends StatefulWidget {
  const _FormAktivitas({
    required this.akun,
    required this.idJadwal,
    required this.tahap,
  });

  final AkunAktif akun;
  final int idJadwal;
  final TahapPengangkutan tahap;

  @override
  State<_FormAktivitas> createState() => _FormAktivitasState();
}

class _FormAktivitasState extends State<_FormAktivitas> {
  final _catatan = TextEditingController();
  final _foto = <FotoLaporan>[];
  final _kunci =
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  bool _sibuk = false;
  String? _galat;

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _tambahFoto() async {
    if (_sibuk || _foto.length >= 3) return;
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      final hasil = await const LayananFoto().pilihFoto(
        kapasitasTersisa: 3 - _foto.length,
      );
      if (mounted) setState(() => _foto.addAll(hasil));
    } on FormatException catch (e) {
      if (mounted) setState(() => _galat = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _galat = 'Foto belum dapat dibuka. Pilih ulang berkas.');
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _simpan() async {
    if (_sibuk || !identical(SesiAkun.aktif, widget.akun)) return;
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      await DatabaseHelper.instance.simpanAktivitasPengangkutan(
        idJadwal: widget.idJadwal,
        idPetugas: widget.akun.id,
        tahap: widget.tahap,
        catatan: _catatan.text,
        kunciKirim: _kunci,
        foto: _foto,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on GalatJadwal catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } catch (_) {
      if (mounted) {
        setState(() => _galat = 'Perubahan belum tersimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selesai = widget.tahap == TahapPengangkutan.selesai;
    final tanggapan = widget.tahap == TahapPengangkutan.tanggapan;
    return PopScope(
      canPop: !_sibuk,
      child: AlertDialog(
        scrollable: true,
        title: Text(widget.tahap.aksi),
        content: SizedBox(
          width: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                selesai
                    ? 'Tambahkan 1–3 foto bukti penyelesaian, masing-masing maksimal 2 MB.'
                    : 'Tambahkan 1–3 foto kondisi pengangkutan saat ini, masing-masing maksimal 2 MB.',
              ),
              for (var i = 0; i < _foto.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_foto[i].namaBerkas),
                  trailing: IconButton(
                    onPressed: _sibuk
                        ? null
                        : () => setState(() => _foto.removeAt(i)),
                    tooltip: 'Hapus foto',
                    icon: const Icon(Icons.close),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _sibuk || _foto.length >= 3 ? null : _tambahFoto,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  selesai ? 'Tambah foto bukti' : 'Tambah foto progres',
                ),
              ),
              TextField(
                controller: _catatan,
                enabled: !_sibuk,
                maxLength: 2000,
                maxLines: selesai ? 4 : 2,
                decoration: InputDecoration(
                  labelText: tanggapan
                      ? 'Keterangan foto (opsional)'
                      : 'Catatan penyelesaian',
                ),
              ),
              if (_galat case final pesan?)
                Text(
                  pesan,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sibuk ? null : () => Navigator.maybePop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _sibuk ? null : _simpan,
            child: Text(
              _sibuk
                  ? 'Memproses…'
                  : tanggapan
                  ? 'Kirim Foto Progres'
                  : 'Simpan',
            ),
          ),
        ],
      ),
    );
  }
}

class KartuAktivitasPengangkutan extends StatelessWidget {
  const KartuAktivitasPengangkutan({super.key, required this.aktivitas});

  final AktivitasPengangkutan aktivitas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final fotoProgres = aktivitas.fotoProgres;
    final judul = fotoProgres ? 'Foto progres' : aktivitas.tahap;
    return _KartuJadwal(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            CircleAvatar(
              radius: 19,
              foregroundColor: tema.colorScheme.onPrimaryContainer,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Icon(
                fotoProgres
                    ? Icons.photo_camera_outlined
                    : Icons.check_circle_outline,
                size: 19,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    '$judul · ${aktivitas.petugas}',
                    style: tema.textTheme.titleMedium,
                  ),
                  Text(
                    waktuWibWarga(aktivitas.waktuUtc),
                    style: tema.textTheme.bodySmall,
                  ),
                  if (aktivitas.catatan.trim().isNotEmpty)
                    SelectableText(aktivitas.catatan),
                ],
              ),
            ),
          ],
        ),
        if (aktivitas.foto.isNotEmpty)
          KisiGlow(
            lebarMinimum: 170,
            children: [
              for (final foto in aktivitas.foto)
                Card(
                  child: InkWell(
                    onTap: () => _lihatFoto(context, foto),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.memory(
                          Uint8List.fromList(foto.bytes),
                          height: 116,
                          fit: BoxFit.cover,
                          cacheWidth: 360,
                          semanticLabel: foto.nama,
                          errorBuilder: (_, error, stackTrace) =>
                              const SizedBox(
                                height: 116,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            spacing: 8,
                            children: [
                              const Icon(Icons.zoom_in_outlined, size: 19),
                              Expanded(
                                child: Text(
                                  foto.nama,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _lihatFoto(BuildContext context, FotoAktivitasPengangkutan foto) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            aktivitas.fotoProgres
                ? 'Foto Progres Pengangkutan'
                : 'Bukti Penyelesaian',
          ),
          content: SizedBox(
            width: 640,
            height: (MediaQuery.sizeOf(context).height * .55)
                .clamp(120, 340)
                .toDouble(),
            child: InteractiveViewer(
              child: Image.memory(
                Uint8List.fromList(foto.bytes),
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) =>
                    const Center(child: Text('Foto tidak dapat ditampilkan.')),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
}

class _KartuJadwal extends StatelessWidget {
  const _KartuJadwal({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: children,
      ),
    ),
  );
}