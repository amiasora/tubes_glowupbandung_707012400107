@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tubes_glowupbandung_707012400107/models/foto_laporan.dart';
import 'package:tubes_glowupbandung_707012400107/services/pemroses_foto_web.dart';

Uri pekerjaUji(String kode) => Uri.dataFromString(
  kode,
  mimeType: 'application/javascript',
  encoding: utf8,
  base64: true,
);

void main() {
  test('byte foto tersimpan dapat dikirim ke worker tanpa diubah', () async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
      'AAAAC0lEQVR42mP8/x8AAwMCAO+aY9sAAAAASUVORK5CYII=',
    );

    final baru = FotoLaporan.baru(namaBerkas: 'uji.png', bytes: bytes);

    final tersimpan = FotoLaporan.fromMap({
      ...baru.toMap(),
      'id_foto': 1,
      'id_laporan': 1,
    });

    final sebelum = Uint8List.fromList(tersimpan.dataFoto);

    expect(() => tersimpan.dataFoto[0] = 0, throwsUnsupportedError);

    final hasil = await prosesFoto(
      tersimpan.dataFoto,
      kompres: false,
      alamatPekerja: pekerjaUji('''
self.onmessage = ({ data: pesan }) => {
  if (!(pesan.data instanceof Uint8Array)) {
    self.postMessage({
      galat: 'Byte bukan Uint8Array.'
    });
    return;
  }

  if (pesan.data[0] !== 137 || pesan.kompres !== false) {
    self.postMessage({
      galat: 'Isi pesan berubah.'
    });
    return;
  }

  self.postMessage({
    piksel: 'a'.repeat(64),
    pola: '01'.repeat(32),
    data: null
  });
};
'''),
    );

    expect(hasil.piksel, List.filled(64, 'a').join());

    expect(hasil.pola, hasLength(64));

    expect(hasil.pola.take(4).toList(), [false, true, false, true]);

    expect(hasil.hasil, isNull);

    expect(tersimpan.dataFoto, orderedEquals(sebelum));
  });

  test('galat dari worker diteruskan sebagai FormatException', () async {
    await expectLater(
      prosesFoto(
        Uint8List.fromList([1, 2, 3]),
        kompres: false,
        alamatPekerja: pekerjaUji('''
self.onmessage = () => {
  self.postMessage({
    galat: 'Foto uji rusak.'
  });
};
'''),
      ),
      throwsA(
        isA<FormatException>().having(
          (galat) => galat.message,
          'message',
          'Foto uji rusak.',
        ),
      ),
    );
  });

  test('respons worker yang tidak lengkap ditolak', () async {
    await expectLater(
      prosesFoto(
        Uint8List.fromList([1, 2, 3]),
        kompres: false,
        alamatPekerja: pekerjaUji('''
self.onmessage = () => {
  self.postMessage({
    piksel: 'tidak-valid',
    pola: '01',
    data: null
  });
};
'''),
      ),
      throwsA(
        isA<FormatException>().having(
          (galat) => galat.message,
          'message',
          'Hasil pemeriksaan foto tidak lengkap. Coba lagi.',
        ),
      ),
    );
  });
}
