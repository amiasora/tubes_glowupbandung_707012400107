import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

typedef DetailLokasi = ({String kecamatan, String? kelurahan, String alamat});

class LayananLokasi {
  LayananLokasi({AssetBundle? aset, http.Client? jaringan})
    : _aset = aset ?? rootBundle,
      _jaringan = jaringan ?? http.Client();

  static final instance = LayananLokasi();
  final AssetBundle _aset;
  final http.Client _jaringan;
  Future<List<_Wilayah>>? _wilayah;
  final _alamatTersimpan = <String, DetailLokasi?>{};
  final _pencarianAktif = <String, Future<DetailLokasi?>>{};
  final _jedaJaringan = Stopwatch()..start();
  int _jaringanBerikutnya = 0;
  int _nomorAlamat = 0;
  static const _alamatLayanan = String.fromEnvironment(
    'GUB_GEOCODER_URL',
    defaultValue: 'https://photon.komoot.io/reverse',
  );

  Future<List<_Wilayah>> _dataWilayah() async {
    try {
      return await (_wilayah ??= _muat());
    } catch (_) {
      _wilayah = null;
      rethrow;
    }
  }

  Future<List<List<LatLng>>> batasKota() async => [
    for (final wilayah in await _dataWilayah()) wilayah.cincin.first,
  ];

  Future<DetailLokasi?> cari(LatLng titik) async {
    final wilayah = await _dataWilayah();
    final cocok = wilayah.where((item) => item.memuat(titik)).toList();
    final kecamatan = cocok.map((item) => item.kecamatan).toSet();
    if (kecamatan.length != 1) return null;

    final namaKecamatan = kecamatan.single;
    final kelurahan = cocok.length == 1 ? cocok.single.kelurahan : null;
    return (
      kecamatan: namaKecamatan,
      kelurahan: kelurahan,
      alamat: [
        if (kelurahan != null) 'Kelurahan $kelurahan',
        'Kecamatan $namaKecamatan',
        'Kota Bandung',
        'Jawa Barat',
      ].join(', '),
    );
  }

  /// Perkaya pin dengan data OSM. Polygon lokal tetap menjadi dasar penerimaan
  /// laporan dan sumber kecamatan di dalam Kota Bandung.
  Future<DetailLokasi?> cariAlamatPeta(LatLng titik, DetailLokasi? lokal) {
    if (_alamatLayanan.isEmpty) return Future.value(lokal);
    final lintang = titik.latitude.toStringAsFixed(6);
    final bujur = titik.longitude.toStringAsFixed(6);
    final kunci = '$lintang,$bujur';
    if (_alamatTersimpan.containsKey(kunci)) {
      return Future.value(_alamatTersimpan[kunci] ?? lokal);
    }
    final aktif = _pencarianAktif[kunci];
    if (aktif != null) return aktif;
    final nomor = ++_nomorAlamat;
    return _pencarianAktif[kunci] = _ambilAlamat(lintang, bujur, lokal, nomor)
        .whenComplete(() {
          _pencarianAktif.remove(kunci);
        });
  }

  Future<DetailLokasi?> _ambilAlamat(
    String lintang,
    String bujur,
    DetailLokasi? lokal,
    int nomor,
  ) async {
    final jeda = _jaringanBerikutnya - _jedaJaringan.elapsedMilliseconds;
    if (jeda > 0) await Future<void>.delayed(Duration(milliseconds: jeda));
    if (nomor != _nomorAlamat) return lokal;
    _jaringanBerikutnya = _jedaJaringan.elapsedMilliseconds + 1100;
    try {
      final dasar = Uri.parse(_alamatLayanan);
      final url = dasar.replace(
        queryParameters: {
          ...dasar.queryParameters,
          'lat': lintang,
          'lon': bujur,
          'limit': '1',
        },
      );
      final respons = await _jaringan
          .get(url)
          .timeout(const Duration(seconds: 5));
      if (respons.statusCode != 200) return lokal;
      final json = jsonDecode(utf8.decode(respons.bodyBytes));
      final fitur = (json as Map<String, dynamic>)['features'] as List<dynamic>;
      DetailLokasi? hasil = lokal;
      if (fitur.isNotEmpty) {
        final properti =
            (fitur.first as Map<String, dynamic>)['properties']
                as Map<String, dynamic>;
        hasil = _gabungkanAlamat(properti, lokal);
      }
      if (_alamatTersimpan.length >= 64) {
        _alamatTersimpan.remove(_alamatTersimpan.keys.first);
      }
      _alamatTersimpan['$lintang,$bujur'] = hasil;
      return hasil;
    } on Exception {
      return lokal;
    } on TypeError {
      return lokal;
    }
  }

  DetailLokasi? _gabungkanAlamat(
    Map<String, dynamic> data,
    DetailLokasi? lokal,
  ) {
    String? teks(String kunci) {
      final nilai = data[kunci];
      return nilai is String && nilai.trim().isNotEmpty ? nilai.trim() : null;
    }

    final kota = teks('county');
    final jalan = teks('street');
    final nomor = teks('housenumber');
    final kecamatan = teks('city');
    final desa = teks('district');
    final provinsi = teks('state');
    if (teks('countrycode')?.toUpperCase() != 'ID') return lokal;

    if (lokal != null) {
      final kotaCocok = kota?.toLowerCase() == 'kota bandung';
      final kelurahanCocok =
          kecamatan?.toLowerCase() == 'bandung' &&
          desa != null &&
          desa.toLowerCase() == lokal.kelurahan?.toLowerCase();
      final jalanCocok =
          provinsi?.toLowerCase() == 'jawa barat' &&
          (kotaCocok || kelurahanCocok);
      if (!jalanCocok || jalan == null) return lokal;
      return (
        kecamatan: lokal.kecamatan,
        kelurahan: lokal.kelurahan,
        alamat: [jalan, ?nomor, lokal.alamat].join(', '),
      );
    }

    if (kota == null || kecamatan == null || provinsi == null) return null;
    return (
      kecamatan: kecamatan,
      kelurahan: desa,
      alamat: [
        ?jalan,
        ?nomor,
        ?desa,
        'Kecamatan $kecamatan',
        kota,
        provinsi,
      ].join(', '),
    );
  }

  Future<List<_Wilayah>> _muat() async {
    final isi = await _aset.loadString('assets/wilayah_bandung.json');
    final data = jsonDecode(isi) as List<dynamic>;
    return data.map((item) => _Wilayah(item as List<dynamic>)).toList();
  }
}

class _Wilayah {
  _Wilayah(List<dynamic> data)
    : kelurahan = data[0] as String,
      kecamatan = switch (data[1] as String) {
        'Astanaanyar' => 'Astana Anyar',
        'Buahbatu' => 'Buah Batu',
        'Ujungberung' => 'Ujung Berung',
        final nama => nama,
      },
      cincin = (data[2] as List<dynamic>)
          .map(
            (ring) => (ring as List<dynamic>)
                .map((pair) {
                  final xy = pair as List<dynamic>;
                  return LatLng(
                    (xy[1] as num).toDouble(),
                    (xy[0] as num).toDouble(),
                  );
                })
                .toList(growable: false),
          )
          .toList(growable: false) {
    final luar = cincin.first;
    selatan = utara = luar.first.latitude;
    barat = timur = luar.first.longitude;
    for (final p in luar) {
      if (p.latitude < selatan) selatan = p.latitude;
      if (p.latitude > utara) utara = p.latitude;
      if (p.longitude < barat) barat = p.longitude;
      if (p.longitude > timur) timur = p.longitude;
    }
  }

  final String kelurahan;
  final String kecamatan;
  final List<List<LatLng>> cincin;
  late double selatan, utara, barat, timur;

  bool memuat(LatLng titik) {
    if (titik.latitude < selatan ||
        titik.latitude > utara ||
        titik.longitude < barat ||
        titik.longitude > timur) {
      return false;
    }
    return _diDalam(titik, cincin.first) &&
        !cincin.skip(1).any((lubang) => _diDalam(titik, lubang));
  }

  bool _diDalam(LatLng titik, List<LatLng> batas) {
    var diDalam = false;
    for (int i = 0, j = batas.length - 1; i < batas.length; j = i++) {
      final a = batas[i];
      final b = batas[j];
      if ((a.latitude > titik.latitude) == (b.latitude > titik.latitude)) {
        continue;
      }
      final perpotongan =
          a.longitude +
          (titik.latitude - a.latitude) *
              (b.longitude - a.longitude) /
              (b.latitude - a.latitude);
      if (titik.longitude < perpotongan) diDalam = !diDalam;
    }
    return diDalam;
  }
}