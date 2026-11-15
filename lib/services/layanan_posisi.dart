import 'dart:async';

import 'package:geolocator/geolocator.dart';

class PencarianPosisiDibatalkan implements Exception {
  const PencarianPosisiDibatalkan();
}

/// Ambil pembacaan terbaik selama pencarian singkat
/// yang dimulai pengguna.
///
/// Nilai accuracy berasal dari perangkat, bukan
/// jaminan ketepatan aplikasi.
class LayananPosisi {
  LayananPosisi({
    Stream<Position> Function()? sumber,
    this.batasWaktu = const Duration(seconds: 20),
    this.targetAkurasiMeter = 10,
    DateTime Function()? sekarang,
  }) : _sumber = sumber ?? _posisiPerangkat,
       _sekarang = sekarang ?? DateTime.now;

  static Stream<Position> _posisiPerangkat() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );

  final Stream<Position> Function() _sumber;
  final DateTime Function() _sekarang;

  final Duration batasWaktu;
  final double targetAkurasiMeter;

  StreamSubscription<Position>? _langganan;
  Timer? _timer;
  Completer<Position>? _hasil;
  Position? _terbaik;

  Future<Position> cari({
    void Function(Position)? onPembaruan,
  }) {
    batal();

    final hasil = Completer<Position>();
    final dimulai = _sekarang().toUtc();

    _hasil = hasil;
    _terbaik = null;

    _timer = Timer(
      batasWaktu,
      () {
        if (identical(_hasil, hasil)) {
          _selesai(
            galat: TimeoutException(
              'Lokasi belum diperoleh.',
            ),
          );
        }
      },
    );

    try {
      _langganan = _sumber().listen(
        (posisi) {
          if (
            !identical(_hasil, hasil) ||
            !_sah(posisi, dimulai)
          ) {
            return;
          }

          if (
            _terbaik == null ||
            posisi.accuracy < _terbaik!.accuracy
          ) {
            _terbaik = posisi;
            onPembaruan?.call(posisi);
          }

          if (
            _terbaik!.accuracy <= targetAkurasiMeter
          ) {
            _selesai();
          }
        },
        onError: (Object galat) {
          if (identical(_hasil, hasil)) {
            _selesai(galat: galat);
          }
        },
        onDone: () {
          if (identical(_hasil, hasil)) {
            _selesai(
              galat: StateError(
                'Pembacaan lokasi telah berakhir.',
              ),
            );
          }
        },
      );

      if (!identical(_hasil, hasil)) {
        _hentikan();
      }
    } catch (galat) {
      _selesai(galat: galat);
    }

    return hasil.future;
  }

  bool _sah(
    Position posisi,
    DateTime dimulai,
  ) {
    final umur = _sekarang()
        .toUtc()
        .difference(
          posisi.timestamp.toUtc(),
        );

    return posisi.latitude.isFinite &&
        posisi.latitude.abs() <= 90 &&
        posisi.longitude.isFinite &&
        posisi.longitude.abs() <= 180 &&
        posisi.accuracy.isFinite &&
        posisi.accuracy > 0 &&
        !posisi.timestamp.toUtc().isBefore(
          dimulai.subtract(
            const Duration(seconds: 5),
          ),
        ) &&
        umur >= const Duration(seconds: -5) &&
        umur <= const Duration(seconds: 30);
  }

  void _selesai({
    Object? galat,
  }) {
    final hasil = _hasil;
    final terbaik = _terbaik;

    _hasil = null;
    _hentikan();

    if (
      hasil == null ||
      hasil.isCompleted
    ) {
      return;
    }

    if (terbaik != null) {
      hasil.complete(terbaik);
    } else {
      hasil.completeError(
        galat ??
            StateError(
              'Lokasi belum tersedia.',
            ),
      );
    }
  }

  void _hentikan() {
    _timer?.cancel();
    _timer = null;

    unawaited(
      _langganan?.cancel(),
    );

    _langganan = null;
  }

  void batal() {
    final hasil = _hasil;

    _hasil = null;
    _hentikan();

    if (
      hasil != null &&
      !hasil.isCompleted
    ) {
      hasil.completeError(
        const PencarianPosisiDibatalkan(),
      );
    }
  }
}