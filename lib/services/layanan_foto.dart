import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/foto_laporan.dart';
import 'pemeriksaan_foto.dart';

class LayananFoto {
  const LayananFoto();

  Future<List<FotoLaporan>> pilihFoto({
    required int kapasitasTersisa,
  }) async {
    if (
      kapasitasTersisa < 1 ||
      kapasitasTersisa > 3
    ) {
      throw const FormatException(
        'Maksimal 3 foto untuk satu laporan.',
      );
    }

    final pilihan = await FilePicker.pickFiles(
      dialogTitle: 'Pilih foto laporan sampah',
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
      ],
    );

    if (pilihan.isEmpty) {
      return const [];
    }

    if (pilihan.length > kapasitasTersisa) {
      throw FormatException(
        'Pilih maksimal $kapasitasTersisa '
        'foto tambahan.',
      );
    }

    final hasil = <FotoLaporan>[];

    for (final berkas in pilihan) {
      final bytesAsli = await _bacaBerkas(
        berkas,
      );

      try {
        final foto = await PemeriksaanFoto.siapkan(
          namaBerkas: berkas.name,
          bytes: bytesAsli,
        );

        hasil.add(foto);
      } on FormatException catch (galat) {
        throw FormatException(
          'Foto "${berkas.name}": ${galat.message}',
        );
      }
    }

    return List<FotoLaporan>.unmodifiable(
      hasil,
    );
  }

  Future<Uint8List> _bacaBerkas(
    PlatformFile berkas,
  ) async {
    final ukuran =
        berkas.lengthSync() ??
        await berkas.length();

    if (
      ukuran != null &&
      ukuran > FotoLaporan.maksimumUkuranByte
    ) {
      throw FormatException(
        'Foto "${berkas.name}" melebihi 2 MB.',
      );
    }

    if (ukuran == 0) {
      throw FormatException(
        'Berkas "${berkas.name}" kosong.',
      );
    }

    final penampung = BytesBuilder(
      copy: false,
    );

    await for (
      final bagian in berkas.readAsByteStream()
    ) {
      if (
        penampung.length + bagian.length >
        FotoLaporan.maksimumUkuranByte
      ) {
        throw FormatException(
          'Foto "${berkas.name}" melebihi 2 MB.',
        );
      }

      penampung.add(bagian);
    }

    final data = penampung.takeBytes();

    if (data.isEmpty) {
      throw FormatException(
        'Foto "${berkas.name}" belum terbaca. '
        'Pilih ulang berkasnya.',
      );
    }

    if (
      ukuran != null &&
      ukuran > 0 &&
      ukuran != data.length
    ) {
      throw FormatException(
        'Foto "${berkas.name}" belum terbaca lengkap. '
        'Pilih ulang berkasnya.',
      );
    }

    return data;
  }
}