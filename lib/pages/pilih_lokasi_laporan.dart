import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/laporan_sampah.dart';
import '../models/titik_laporan.dart';
import '../services/layanan_lokasi.dart';
import '../widgets/kerangka_warga.dart';

const _pusatBandung = LatLng(-6.917474, 107.609810);

class PilihLokasiLaporan extends StatefulWidget {
  const PilihLokasiLaporan({super.key, this.lokasiAwal});

  final TitikLaporan? lokasiAwal;

  @override
  State<PilihLokasiLaporan> createState() => _PilihLokasiLaporanState();
}

class _PilihLokasiLaporanState extends State<PilihLokasiLaporan> {
  final _peta = MapController();
  LatLng? _pilihan;
  DetailLokasi? _detail;
  bool _diKotaBandung = false;
  List<Polyline> _batasKota = const [];
  Timer? _jedaDetail;
  int _permintaanDetail = 0;
  bool _mencariDetail = false;
  String? _pesanDetail;
  MetodeLokasi _metode = MetodeLokasi.peta;
  bool _petaSiap = false;
  bool _mencariLokasi = false;
  int _permintaanLokasi = 0;
  String? _pesan;

  @override
  void initState() {
    super.initState();
    unawaited(_muatBatasKota());
    final awal = widget.lokasiAwal;
    if (awal != null) {
      _pilihan = LatLng(awal.latitude, awal.longitude);
      _jadwalkanDetail(_pilihan!);
      _metode = awal.metodeLokasi;
    }
  }

  @override
  void dispose() {
    _permintaanLokasi++;
    _permintaanDetail++;
    _jedaDetail?.cancel();
    _peta.dispose();
    super.dispose();
  }

  Future<void> _muatBatasKota() async {
    try {
      final batas = await LayananLokasi.instance.batasKota();
      if (!mounted) return;
      setState(() {
        _batasKota = [
          for (final titik in batas)
            Polyline(points: titik, color: const Color(0xFF6685A6)),
        ];
      });
    } catch (_) {
      // Pesan kegagalan data wilayah ditampilkan ketika pin dipilih.
    }
  }

  void _pilihManual(LatLng titik) {
    _permintaanLokasi++; // Hasil GPS yang terlambat tidak boleh menimpa pin.
    final bujur = ((titik.longitude + 180) % 360 + 360) % 360 - 180;
    setState(() {
      _pilihan = LatLng(
        double.parse(titik.latitude.toStringAsFixed(6)),
        double.parse(bujur.toStringAsFixed(6)),
      );
      _jadwalkanDetail(_pilihan!);
      _metode = MetodeLokasi.peta;
      _mencariLokasi = false;
      _pesan = null;
    });
  }

  void _jadwalkanDetail(LatLng titik) {
    final nomor = ++_permintaanDetail;
    _jedaDetail?.cancel();
    _detail = null;
    _diKotaBandung = false;
    _pesanDetail = null;
    _mencariDetail = true;
    _jedaDetail = Timer(const Duration(milliseconds: 350), () async {
      final layanan = LayananLokasi.instance;
      try {
        final lokal = await layanan.cari(titik);
        if (!mounted || nomor != _permintaanDetail) return;
        setState(() {
          _diKotaBandung = lokal != null;
          _detail = lokal;
        });
        final alamat = await layanan.cariAlamatPeta(titik, lokal);
        if (!mounted || nomor != _permintaanDetail) return;
        setState(() {
          _detail = alamat;
          _mencariDetail = false;
          if (lokal == null) {
            _pesanDetail = alamat == null
                ? 'Wilayah pin belum dikenali. Pilih titik lain di Kota Bandung atau coba lagi.'
                : 'Alamat terdeteksi di luar Kota Bandung. Pindahkan pin ke Kota Bandung untuk membuat laporan.';
          }
        });
      } catch (_) {
        if (!mounted || nomor != _permintaanDetail) return;
        setState(() {
          _mencariDetail = false;
          _pesanDetail = 'Data wilayah belum dapat dibaca. Coba lagi.';
        });
      }
    });
  }

  void _geserPin(DragUpdateDetails gerakan) {
    final titik = _pilihan;
    if (!_petaSiap || titik == null) return;
    final posisiLayar = _peta.camera.latLngToScreenOffset(titik);
    _pilihManual(
      _peta.camera.screenOffsetToLatLng(posisiLayar + gerakan.delta),
    );
  }

  Future<void> _gunakanLokasiPerangkat() async {
    final nomor = ++_permintaanLokasi;
    setState(() {
      _mencariLokasi = true;
      _pesan = null;
    });
    try {
      if (!kIsWeb) {
        var izin = await Geolocator.checkPermission();
        if (!mounted || nomor != _permintaanLokasi) return;
        if (izin == LocationPermission.denied) {
          izin = await Geolocator.requestPermission();
        }
        if (!mounted || nomor != _permintaanLokasi) return;
        if (izin == LocationPermission.denied ||
            izin == LocationPermission.deniedForever) {
          throw const PermissionDeniedException('Izin lokasi tidak diberikan.');
        }
      }
      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted || nomor != _permintaanLokasi) return;
      final titik = LatLng(
        double.parse(posisi.latitude.toStringAsFixed(6)),
        double.parse(posisi.longitude.toStringAsFixed(6)),
      );
      setState(() {
        _pilihan = titik;
        _jadwalkanDetail(titik);
        _metode = MetodeLokasi.perangkat;
        _mencariLokasi = false;
      });
      if (_petaSiap) _peta.move(titik, 16);
    } catch (galat) {
      if (!mounted || nomor != _permintaanLokasi) return;
      setState(() {
        _mencariLokasi = false;
        _pesan = switch (galat) {
          PermissionDeniedException() =>
            'Izin lokasi tidak diberikan. Ketuk peta untuk memilih titik manual.',
          TimeoutException() =>
            'Pencarian GPS terlalu lama. Ketuk peta untuk memilih titik manual.',
          _ =>
            'Lokasi perangkat belum tersedia. Ketuk peta untuk memilih titik manual.',
        };
      });
    }
  }

  void _konfirmasi() {
    final titik = _pilihan;
    final detail = _detail;
    if (!_petaSiap ||
        _mencariLokasi ||
        !_diKotaBandung ||
        titik == null ||
        detail == null) {
      return;
    }
    Navigator.pop(
      context,
      TitikLaporan.konfirmasi(
        latitude: titik.latitude,
        longitude: titik.longitude,
        kecamatan: detail.kecamatan,
        alamatPeta: detail.alamat,
        metodeLokasi: _metode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titik = _pilihan;
    return KerangkaWarga(
      menuAktif: MenuWarga.buatLaporan,
      navigasiAktif: !_mencariLokasi,
      child: KontenWarga(
        children: [
          const JudulHalamanWarga(
            judul: 'Tentukan Lokasi',
            deskripsi:
                'Ketuk peta atau gunakan lokasi perangkat, lalu sesuaikan pin dengan titik kejadian.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _mencariLokasi || !_petaSiap
                    ? null
                    : _gunakanLokasiPerangkat,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _mencariLokasi
                      ? 'Mencari lokasi…'
                      : 'Gunakan lokasi perangkat',
                ),
              ),
              OutlinedButton.icon(
                onPressed: titik == null || !_petaSiap
                    ? null
                    : () => _peta.move(titik, 16),
                icon: const Icon(Icons.location_searching),
                label: const Text('Lihat pin'),
              ),
              OutlinedButton.icon(
                onPressed: !_petaSiap
                    ? null
                    : () => _peta.move(_pusatBandung, 14),
                icon: const Icon(Icons.location_city_outlined),
                label: const Text('Pusat Kota Bandung'),
              ),
            ],
          ),
          if (_mencariLokasi) const LinearProgressIndicator(),
          if (_pesan != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_pesan!),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).width < 760 ? 285 : 430,
              child: PetaLaporan(
                controller: _peta,
                pusatAwal: _pilihan ?? _pusatBandung,
                titik: titik,
                batasCadangan: _batasKota,
                onTap: _pilihManual,
                onGeserPin: _geserPin,
                onMapReady: () {
                  if (mounted) setState(() => _petaSiap = true);
                },
              ),
            ),
          ),
          PanelGlow(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  titik == null
                      ? 'Belum ada titik yang dipilih.'
                      : 'Latitude: ${titik.latitude.toStringAsFixed(6)}\n'
                            'Longitude: ${titik.longitude.toStringAsFixed(6)}\n'
                            'Sumber: ${_metode == MetodeLokasi.perangkat ? 'Lokasi perangkat' : 'Pilihan pada peta'}',
                ),
                if (_mencariDetail)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Mencari detail lokasi',
                  ),
                if (_detail case final detail?) ...[
                  Text(
                    detail.alamat,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_diKotaBandung)
                    const Text(
                      'Tambahkan nama jalan atau patokan di formulir bila diperlukan.',
                    ),
                ],
                if (_pesanDetail case final pesan?) ...[
                  Text(pesan),
                  if (titik != null && _detail == null)
                    TextButton(
                      onPressed: () => setState(() => _jadwalkanDetail(titik)),
                      child: const Text('Coba lagi'),
                    ),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          _petaSiap &&
                              !_mencariLokasi &&
                              _diKotaBandung &&
                              titik != null &&
                              _detail != null
                          ? _konfirmasi
                          : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Konfirmasi Titik Lokasi'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('Kembali ke Formulir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Peta bersama untuk pemilihan titik dan rincian laporan tersimpan.
class PetaLaporan extends StatefulWidget {
  const PetaLaporan({
    super.key,
    this.controller,
    required this.pusatAwal,
    this.titik,
    this.batasCadangan = const [],
    this.onTap,
    this.onGeserPin,
    this.onMapReady,
    this.onKesiapanBerubah,
  });

  final MapController? controller;
  final LatLng pusatAwal;
  final LatLng? titik;
  final List<Polyline> batasCadangan;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<DragUpdateDetails>? onGeserPin;
  final VoidCallback? onMapReady;
  final ValueChanged<bool>? onKesiapanBerubah;

  @override
  State<PetaLaporan> createState() => _PetaLaporanState();
}

enum _StatusGambar { memuat, siap, gagal }

class _PetaLaporanState extends State<PetaLaporan> {
  late final MapController _controller = widget.controller ?? MapController();
  final _gambar = Map<TileImage, _StatusGambar>.identity();
  bool _siap = false;
  int _generasi = 0;
  NetworkTileProvider _penyediaTile = _buatPenyediaTile();

  static NetworkTileProvider _buatPenyediaTile() =>
      NetworkTileProvider(attemptDecodeOfHttpErrorResponses: false);

  bool get _stadiaLokal =>
      kIsWeb &&
      {'localhost', '127.0.0.1', '[::1]', '::1'}.contains(Uri.base.host);

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _catat(TileImage gambar, _StatusGambar? status, int generasi) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generasi != _generasi) return;
      setState(() {
        if (status == null) {
          _gambar.remove(gambar);
        } else {
          _gambar[gambar] = status;
        }
      });
      final siap = _gambar.values.contains(_StatusGambar.siap);
      if (siap != _siap) {
        _siap = siap;
        widget.onKesiapanBerubah?.call(siap);
      }
    });
  }

  void _muatUlang() {
    setState(() {
      _generasi++;
      _penyediaTile = _buatPenyediaTile();
      _gambar.clear();
      _siap = false;
    });
    widget.onKesiapanBerubah?.call(false);
  }

  Future<void> _bukaAtribusi() async {
    try {
      final terbuka = await launchUrl(
        Uri.parse(
          _stadiaLokal
              ? 'https://stadiamaps.com/attribution/'
              : 'https://www.openstreetmap.org/copyright',
        ),
      );
      if (!terbuka && mounted) _pesanAtribusi();
    } catch (_) {
      if (mounted) _pesanAtribusi();
    }
  }

  void _pesanAtribusi() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informasi atribusi peta belum dapat dibuka.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gagal =
        !_siap &&
        _gambar.isNotEmpty &&
        !_gambar.values.contains(_StatusGambar.memuat);
    final generasi = _generasi;
    final titik = widget.titik;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.pusatAwal,
              initialZoom: titik == null ? 13 : 16,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: widget.onTap == null
                  ? null
                  : (posisi, koordinat) => widget.onTap!(koordinat),
              onMapReady: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) widget.onMapReady?.call();
                });
              },
            ),
            children: [
              TileLayer(
                key: ValueKey(generasi),
                urlTemplate: _stadiaLokal
                    ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tubes_glowupbandung_707012400107',
                maxNativeZoom: 19,
                panBuffer: 0,
                tileProvider: _penyediaTile,
                evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                tileBuilder: (context, child, gambar) => _PantauGambar(
                  key: ObjectKey(gambar),
                  gambar: gambar,
                  onStatus: (status) => _catat(gambar, status, generasi),
                  child: child,
                ),
              ),
              if (!_siap && widget.batasCadangan.isNotEmpty)
                PolylineLayer(polylines: widget.batasCadangan),
              if (titik != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: titik,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onPanUpdate: widget.onGeserPin,
                        child: const Icon(
                          Icons.location_pin,
                          size: 48,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Perbesar peta',
                    onPressed: () => _controller.move(
                      _controller.camera.center,
                      (_controller.camera.zoom + 1).clamp(3.0, 19.0).toDouble(),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Perkecil peta',
                    onPressed: () => _controller.move(
                      _controller.camera.center,
                      (_controller.camera.zoom - 1).clamp(3.0, 19.0).toDouble(),
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ),
          if (!_siap && !gagal)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (gagal)
            Positioned(
              left: 8,
              right: 64,
              top: 8,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gambar peta belum termuat. Periksa koneksi internet.',
                      ),
                      TextButton(
                        onPressed: _muatUlang,
                        child: const Text('Muat ulang peta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: _bukaAtribusi,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  child: Text(
                    _stadiaLokal
                        ? '© Stadia Maps · © OpenMapTiles · © OpenStreetMap'
                        : '© OpenStreetMap contributors',
                    style: const TextStyle(color: Colors.black87, fontSize: 10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PantauGambar extends StatefulWidget {
  const _PantauGambar({
    super.key,
    required this.gambar,
    required this.onStatus,
    required this.child,
  });

  final TileImage gambar;
  final ValueChanged<_StatusGambar?> onStatus;
  final Widget child;

  @override
  State<_PantauGambar> createState() => _PantauGambarState();
}

class _PantauGambarState extends State<_PantauGambar> {
  _StatusGambar? _terakhir;

  @override
  void initState() {
    super.initState();
    widget.gambar.addListener(_periksa);
    _periksa();
  }

  @override
  void didUpdateWidget(covariant _PantauGambar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.gambar, widget.gambar)) {
      oldWidget.gambar.removeListener(_periksa);
      oldWidget.onStatus(null);
      widget.gambar.addListener(_periksa);
      _terakhir = null;
      _periksa();
    }
  }

  void _periksa() {
    final status = widget.gambar.loadError
        ? _StatusGambar.gagal
        : widget.gambar.imageInfo != null
        ? _StatusGambar.siap
        : _StatusGambar.memuat;
    if (status == _terakhir) return;
    _terakhir = status;
    widget.onStatus(status);
  }

  @override
  void dispose() {
    widget.gambar.removeListener(_periksa);
    widget.onStatus(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}