import 'dart:typed_data';

import '../models/foto_laporan.dart';
import 'pemroses_foto_native.dart'
    if (dart.library.js_interop) 'pemroses_foto_web.dart';

typedef PasanganFoto = ({int pertama, int kedua, bool identik, int jarakPola});
typedef _SidikFoto = ({String piksel, List<bool> pola});

class PemeriksaanFoto {
  const PemeriksaanFoto._();

  static final _cache = Expando<Future<_SidikFoto>>('sidik foto laporan');

  static Future<FotoLaporan> siapkan({
    required String namaBerkas,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty || bytes.length > FotoLaporan.maksimumUkuranByte) {
      throw const FormatException(
        'Ukuran foto harus lebih dari 0 dan maksimal 2 MB.',
      );
    }
    final hasil = await prosesFoto(bytes, kompres: true);
    final foto = FotoLaporan.baru(
      namaBerkas: namaBerkas,
      bytes: hasil.hasil ?? bytes,
    );
    _cache[foto] = Future.value((piksel: hasil.piksel, pola: hasil.pola));
    return foto;
  }

  static Future<List<PasanganFoto>> bandingkan(List<FotoLaporan> foto) async {
    final daftar = List<FotoLaporan>.of(foto);
    if (daftar.length < 2) return const [];
    final sidik = <_SidikFoto>[];
    for (final item in daftar) {
      sidik.add(await (_cache[item] ??= _bacaSidik(item)));
    }
    return [
      for (var i = 0; i < sidik.length; i++)
        for (var j = i + 1; j < sidik.length; j++)
          (
            pertama: i + 1,
            kedua: j + 1,
            identik:
                daftar[i].hash == daftar[j].hash ||
                sidik[i].piksel == sidik[j].piksel,
            jarakPola: _jarak(sidik[i].pola, sidik[j].pola),
          ),
    ];
  }

  static Future<_SidikFoto> _bacaSidik(FotoLaporan foto) async {
    try {
      final hasil = await prosesFoto(foto.dataFoto, kompres: false);
      return (piksel: hasil.piksel, pola: hasil.pola);
    } catch (_) {
      _cache[foto] = null;
      rethrow;
    }
  }

  static int _jarak(List<bool> awal, List<bool> akhir) {
    var jarak = 0;
    for (var i = 0; i < awal.length; i++) {
      if (awal[i] != akhir[i]) jarak++;
    }
    return jarak;
  }

  static String? pesanFotoIdentik(List<PasanganFoto> hasil) {
    for (final pasangan in hasil) {
      if (pasangan.identik) {
        return 'Foto ${pasangan.pertama} dan Foto ${pasangan.kedua} sama. Ganti salah satunya.';
      }
    }
    return null;
  }
}