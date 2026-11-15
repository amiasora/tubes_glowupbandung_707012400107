import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tubes_glowupbandung_707012400107/services/layanan_posisi.dart';

void main() {
  final sekarang = DateTime.utc(2026, 11, 15, 1);

  Position posisi(
    double akurasi, {
    DateTime? waktu,
  }) => Position(
    latitude: -6.973041,
    longitude: 107.629362,
    timestamp: waktu ?? sekarang,
    accuracy: akurasi,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  test(
    'memilih pembacaan terbaik dan berhenti ketika target tercapai',
    () async {
      final sumber = StreamController<Position>();

      addTearDown(sumber.close);

      final layanan = LayananPosisi(
        sumber: () => sumber.stream,
        sekarang: () => sekarang,
      );

      final hasil = layanan.cari();

      sumber.add(posisi(100));
      sumber.add(posisi(50));
      sumber.add(posisi(80));
      sumber.add(posisi(8));

      expect(
        (await hasil).accuracy,
        8,
      );

      expect(
        sumber.hasListener,
        isFalse,
      );
    },
  );

  test(
    'batas waktu mengembalikan pembacaan terbaik yang tersedia',
    () async {
      final sumber = StreamController<Position>();

      addTearDown(sumber.close);

      final layanan = LayananPosisi(
        sumber: () => sumber.stream,
        sekarang: () => sekarang,
        batasWaktu: const Duration(
          milliseconds: 20,
        ),
      );

      final hasil = layanan.cari();

      sumber.add(posisi(80));
      sumber.add(posisi(40));
      sumber.add(posisi(60));

      expect(
        (await hasil).accuracy,
        40,
      );

      expect(
        sumber.hasListener,
        isFalse,
      );
    },
  );

  test(
    'pembacaan usang dan akurasi tak diketahui tidak dianggap presisi',
    () async {
      final sumber = StreamController<Position>();

      addTearDown(sumber.close);

      final layanan = LayananPosisi(
        sumber: () => sumber.stream,
        sekarang: () => sekarang,
        batasWaktu: const Duration(
          milliseconds: 20,
        ),
      );

      final hasil = layanan.cari();

      final pemeriksaan = expectLater(
        hasil,
        throwsA(
          isA<TimeoutException>(),
        ),
      );

      sumber.add(
        posisi(
          1,
          waktu: sekarang.subtract(
            const Duration(minutes: 1),
          ),
        ),
      );

      sumber.add(posisi(0));
      sumber.add(posisi(double.nan));

      await pemeriksaan;

      expect(
        sumber.hasListener,
        isFalse,
      );
    },
  );

  test(
    'pemilihan manual membatalkan pencarian perangkat',
    () async {
      final sumber = StreamController<Position>();

      addTearDown(sumber.close);

      final layanan = LayananPosisi(
        sumber: () => sumber.stream,
      );

      final hasil = layanan.cari();

      final pemeriksaan = expectLater(
        hasil,
        throwsA(
          isA<PencarianPosisiDibatalkan>(),
        ),
      );

      layanan.batal();

      await pemeriksaan;

      expect(
        sumber.hasListener,
        isFalse,
      );
    },
  );
}