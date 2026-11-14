import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

typedef HasilPemrosesanFoto = ({
  String piksel,
  List<bool> pola,
  Uint8List? hasil,
});

Future<HasilPemrosesanFoto> prosesFoto(
  Uint8List data, {
  required bool kompres,
}) => compute(_proses, (data, kompres), debugLabel: 'Foto Glow Up Bandung');

HasilPemrosesanFoto _proses((Uint8List, bool) masukan) {
  final (bytes, kompres) = masukan;
  final jpg =
      bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
  final decoder = jpg ? img.JpegDecoder(maxPixels: 24000000) : img.PngDecoder();
  final info = decoder.startDecode(bytes);
  if (info == null || info.width * info.height > 24000000) {
    throw const FormatException('Foto rusak atau melebihi 24 megapiksel.');
  }
  final asli = decoder.decodeFrame(0);
  if (asli == null) throw const FormatException('Foto belum dapat dibaca.');
  final simpanAsli =
      (asli.hasExif && !asli.exif.isEmpty) || asli.iccProfile != null;
  final gambar =
      asli.hasExif &&
          asli.exif.imageIfd.hasOrientation &&
          asli.exif.imageIfd.orientation != 1
      ? img.bakeOrientation(asli)
      : asli;

  final ukuran = ByteData(8)
    ..setUint32(0, gambar.width)
    ..setUint32(4, gambar.height);
  final penerima = _PenerimaDigest();
  sha256.startChunkedConversion(penerima)
    ..add(ukuran.buffer.asUint8List())
    ..add(gambar.getBytes(order: img.ChannelOrder.rgba))
    ..close();
  final kecil = img.grayscale(
    img.copyResize(
      gambar,
      width: 9,
      height: 8,
      interpolation: img.Interpolation.average,
    ),
  );

  Uint8List? hasil;
  if (kompres && jpg && !simpanAsli) {
    const batasSisi = 1600;
    final sisi = gambar.width > gambar.height ? gambar.width : gambar.height;
    if (sisi > batasSisi || bytes.length > 450000) {
      final diperkecil = sisi <= batasSisi
          ? gambar
          : img.copyResize(
              gambar,
              width: gambar.width >= gambar.height ? batasSisi : null,
              height: gambar.height > gambar.width ? batasSisi : null,
              interpolation: img.Interpolation.average,
            );
      final kandidat = img.encodeJpg(diperkecil, quality: 84);
      if (kandidat.length < bytes.length) hasil = kandidat;
    }
  }

  return (
    piksel: penerima.digest.toString(),
    pola: [
      for (var y = 0; y < 8; y++)
        for (var x = 0; x < 8; x++)
          kecil.getPixel(x, y).r > kecil.getPixel(x + 1, y).r,
    ],
    hasil: hasil,
  );
}

class _PenerimaDigest implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}