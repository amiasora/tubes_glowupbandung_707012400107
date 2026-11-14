import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import 'package:tubes_glowupbandung_707012400107/services/layanan_lokasi.dart';
import 'package:tubes_glowupbandung_707012400107/services/pemeriksaan_foto.dart';

void main() {
  const braga = LatLng(-6.917474, 107.609810);
  const dayeuhkolot = LatLng(-6.973041, 107.629362);

  MockClient pencari(
    Map<String, String> properti, {
    void Function(Uri)? periksa,
  }) => MockClient((permintaan) async {
    periksa?.call(permintaan.url);
    return http.Response(
      jsonEncode({
        'features': [
          {
            'properties': {
              'countrycode': 'ID',
              'state': 'Jawa Barat',
              ...properti,
            },
          },
        ],
      }),
      200,
    );
  });

  test('melengkapi nama jalan sambil memakai kecamatan dari polygon', () async {
    final layanan = LayananLokasi(
      aset: _AsetUji(),
      jaringan: pencari(
        {
          'city': 'Bandung',
          'county': 'Lengkong',
          'district': 'Braga',
          'street': 'Jalan Braga',
          'housenumber': '58',
        },
        periksa: (url) {
          expect(url.queryParameters['lat'], '-6.917474');
          expect(url.queryParameters['lon'], '107.609810');
        },
      ),
    );
    final lokal = await layanan.cari(braga);
    final hasil = await layanan.cariAlamatPeta(braga, lokal);
    expect(hasil?.alamat, contains('Jalan Braga, 58'));
    expect(hasil?.kecamatan, 'Sumur Bandung');
    expect((await layanan.batasKota()).length, greaterThan(100));
  });

  test('mengenali alamat luar kota dan memakai cache pencarian', () async {
    var panggilan = 0;
    final layanan = LayananLokasi(
      aset: _AsetUji(),
      jaringan: pencari({
        'city': 'Dayeuhkolot',
        'county': 'Kabupaten Bandung',
        'district': 'Sukapura',
        'street': 'Danau Galau',
      }, periksa: (_) => panggilan++),
    );
    final lokal = await layanan.cari(dayeuhkolot);
    expect(lokal, isNull);
    final hasil = await layanan.cariAlamatPeta(dayeuhkolot, lokal);
    expect(hasil?.alamat, contains('Kabupaten Bandung'));
    expect(hasil?.kecamatan, 'Dayeuhkolot');
    expect(hasil?.kelurahan, 'Sukapura');
    expect(await layanan.cariAlamatPeta(dayeuhkolot, lokal), hasil);
    expect(panggilan, 1);
  });

  test('kecamatan lokal tetap tersedia saat geocoder gagal', () async {
    final layanan = LayananLokasi(
      aset: _AsetUji(),
      jaringan: MockClient((_) async => http.Response('Tidak tersedia', 503)),
    );
    final lokal = await layanan.cari(braga);
    expect(lokal?.kecamatan, 'Sumur Bandung');
    expect(await layanan.cariAlamatPeta(braga, lokal), lokal);
  });

  test('kompresi JPEG, deteksi duplikat, dan perlindungan EXIF', () async {
    final besar = img.Image(width: 2000, height: 1000);
    img.fill(besar, color: img.ColorRgb8(160, 72, 40));
    final asli = img.encodeJpg(besar, quality: 98);
    final pertama = await PemeriksaanFoto.siapkan(
      namaBerkas: 'pertama.jpg',
      bytes: asli,
    );
    final kedua = await PemeriksaanFoto.siapkan(
      namaBerkas: 'salinan.jpg',
      bytes: asli,
    );
    expect(pertama.ukuranByte, lessThan(asli.length));
    expect(img.decodeJpg(pertama.dataFoto)?.width, 1600);

    besar.exif.exifIfd[0x9003] = '2026:11:13 20:27:34';
    final berExif = img.encodeJpg(besar);
    final ketiga = await PemeriksaanFoto.siapkan(
      namaBerkas: 'ber-metadata.jpg',
      bytes: berExif,
    );
    expect(ketiga.dataFoto, orderedEquals(berExif));
    expect(ketiga.hash, isNot(pertama.hash));
    final pasangan = await PemeriksaanFoto.bandingkan([pertama, kedua, ketiga]);
    expect(pasangan[0].identik, isTrue);

    await expectLater(
      PemeriksaanFoto.siapkan(
        namaBerkas: 'rusak.jpg',
        bytes: Uint8List.fromList([255, 216, 255, 217]),
      ),
      throwsFormatException,
    );
  });
}

class _AsetUji extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}