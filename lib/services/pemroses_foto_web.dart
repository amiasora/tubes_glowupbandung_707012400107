import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

typedef HasilPemrosesanFoto = ({
  String piksel,
  List<bool> pola,
  Uint8List? hasil,
});

Future<HasilPemrosesanFoto> prosesFoto(
  Uint8List data, {
  required bool kompres,
  Uri? alamatPekerja,
}) async {
  // FotoLaporan menyimpan byte sebagai unmodifiable view.
  // Salin agar JavaScript menerima Uint8Array biasa.
  final salinan = Uint8List.fromList(data);

  final pekerja = _Worker(
    (alamatPekerja?.toString() ?? 'gub_foto_worker.js').toJS,
  );

  final respons = Completer<_Jawaban>();

  try {
    pekerja.onmessage = ((_Pesan pesan) {
      if (!respons.isCompleted) {
        respons.complete(pesan.data);
      }
    }).toJS;

    pekerja.onerror = ((JSObject _) {
      if (!respons.isCompleted) {
        respons.completeError(
          const FormatException(
            'Pemroses foto belum termuat. Muat ulang aplikasi.',
          ),
        );
      }
    }).toJS;

    pekerja.onmessageerror = ((JSObject _) {
      if (!respons.isCompleted) {
        respons.completeError(
          const FormatException(
            'Hasil pemrosesan foto belum dapat diterima. Coba lagi.',
          ),
        );
      }
    }).toJS;

    pekerja.postMessage(_Masukan(data: salinan.toJS, kompres: kompres.toJS));

    final hasil = await respons.future.timeout(const Duration(seconds: 25));

    if (hasil.galat case final galat?) {
      throw FormatException(galat.toDart);
    }

    final piksel = hasil.piksel?.toDart;
    final pola = hasil.pola?.toDart;

    if (piksel == null ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(piksel) ||
        pola == null ||
        !RegExp(r'^[01]{64}$').hasMatch(pola)) {
      throw const FormatException(
        'Hasil pemeriksaan foto tidak lengkap. Coba lagi.',
      );
    }

    return (
      piksel: piksel,
      pola: [for (final bit in pola.split('')) bit == '1'],
      hasil: switch (hasil.data) {
        final bytes? => Uint8List.fromList(bytes.toDart),
        null => null,
      },
    );
  } on TimeoutException {
    throw const FormatException(
      'Pemrosesan foto terlalu lama. Pilih foto yang lebih kecil.',
    );
  } finally {
    pekerja.terminate();
  }
}

@JS('Worker')
extension type _Worker._(JSObject _) implements JSObject {
  external _Worker(JSString url);

  external set onmessage(JSFunction fungsi);
  external set onerror(JSFunction fungsi);
  external set onmessageerror(JSFunction fungsi);

  external void postMessage(_Masukan pesan);
  external void terminate();
}

@JS()
extension type _Masukan._(JSObject _) implements JSObject {
  external _Masukan({required JSUint8Array data, required JSBoolean kompres});
}

extension type _Pesan._(JSObject _) implements JSObject {
  external _Jawaban get data;
}

extension type _Jawaban._(JSObject _) implements JSObject {
  external JSString? get galat;
  external JSString? get piksel;
  external JSString? get pola;
  external JSUint8Array? get data;
}
