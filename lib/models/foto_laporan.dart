import 'dart:typed_data';

import 'package:crypto/crypto.dart';

enum SumberFoto {
  warga('Warga'),
  petugas('Petugas'),
  klarifikasi('Klarifikasi');

  const SumberFoto(this.nilaiDatabase);
  final String nilaiDatabase;
}

class FotoLaporan {
  FotoLaporan._({
    this.idFoto,
    this.idLaporan,
    required this.sumber,
    required this.namaBerkas,
    required this.mimeType,
    required this.hash,
    required Uint8List bytes,
  }) : dataFoto = Uint8List.fromList(bytes).asUnmodifiableView();

  factory FotoLaporan.baru({
    required String namaBerkas,
    required Uint8List bytes,
  }) {
    if (bytes.isEmpty || bytes.length > maksimumUkuranByte) {
      throw const FormatException(
        'Ukuran foto harus lebih dari 0 dan maksimal 2 MB.',
      );
    }
    final jpg =
        bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    const tandaPng = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    final png =
        bytes.length >= tandaPng.length &&
        List.generate(
          tandaPng.length,
          (i) => i,
        ).every((i) => bytes[i] == tandaPng[i]);
    if (!jpg && !png) {
      throw FormatException('Foto "$namaBerkas" harus berformat JPG atau PNG.');
    }
    return FotoLaporan._(
      sumber: SumberFoto.warga,
      namaBerkas: namaBerkas,
      mimeType: jpg ? 'image/jpeg' : 'image/png',
      hash: sha256.convert(bytes).toString(),
      bytes: bytes,
    );
  }

  factory FotoLaporan.fromMap(Map<String, Object?> row) => FotoLaporan._(
    idFoto: row['id_foto'] as int,
    idLaporan: row['id_laporan'] as int,
    sumber: SumberFoto.values.firstWhere(
      (nilai) => nilai.nilaiDatabase == row['sumber'],
    ),
    namaBerkas: row['nama_berkas'] as String,
    mimeType: row['mime_type'] as String,
    hash: row['sha256'] as String,
    bytes: Uint8List.fromList((row['data_foto'] as List).cast<int>()),
  );

  Map<String, Object?> toMap() => {
    'sumber': sumber.nilaiDatabase,
    'nama_berkas': namaBerkas,
    'mime_type': mimeType,
    'ukuran_byte': ukuranByte,
    'sha256': hash,
    'data_foto': dataFoto,
  };

  static const maksimumUkuranByte = 2000000;
  final int? idFoto;
  final int? idLaporan;
  final SumberFoto sumber;
  final String namaBerkas;
  final String mimeType;
  final String hash;
  final Uint8List dataFoto;
  int get ukuranByte => dataFoto.length;
}