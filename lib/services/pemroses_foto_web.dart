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
}) async {
  final pekerja = _Worker('gub_foto_worker.js'.toJS);
  final respons = Completer<_Jawaban>();
  try {
    pekerja.onmessage = ((_Pesan pesan) {
      if (!respons.isCompleted) respons.complete(pesan.data);
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
    pekerja.postMessage(_Masukan(data: data.toJS, kompres: kompres.toJS));

    final hasil = await respons.future.timeout(const Duration(seconds: 25));
    if (hasil.galat case final galat?) throw FormatException(galat.toDart);

    return (
      piksel: hasil.piksel!.toDart,
      pola: [for (final bit in hasil.pola!.toDart.split('')) bit == '1'],
      hasil: hasil.data?.toDart,
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