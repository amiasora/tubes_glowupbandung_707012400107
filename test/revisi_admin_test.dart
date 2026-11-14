import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tubes_glowupbandung_707012400107/db/database_helper.dart';
import 'package:tubes_glowupbandung_707012400107/models/foto_laporan.dart';
import 'package:tubes_glowupbandung_707012400107/models/laporan_sampah.dart';
import 'package:tubes_glowupbandung_707012400107/models/penanganan_laporan.dart';
import 'package:tubes_glowupbandung_707012400107/models/verifikasi_laporan.dart';
import 'package:tubes_glowupbandung_707012400107/main.dart';
import 'package:tubes_glowupbandung_707012400107/navigation/app_routes.dart';
import 'package:tubes_glowupbandung_707012400107/pages/pilih_lokasi_laporan.dart';
import 'package:tubes_glowupbandung_707012400107/services/layanan_lokasi.dart';
import 'package:tubes_glowupbandung_707012400107/services/sesi_akun.dart';
import 'package:tubes_glowupbandung_707012400107/services/pemeriksaan_foto.dart';
import 'package:tubes_glowupbandung_707012400107/widgets/kerangka_warga.dart';

FotoLaporan foto(int warna, {String? nama, int level = 6}) {
  final gambar = img.Image(width: 20, height: 20);
  img.fill(gambar, color: img.ColorRgb8(warna, 120, 200));
  return FotoLaporan.baru(
    namaBerkas: nama ?? '$warna.png',
    bytes: Uint8List.fromList(img.encodePng(gambar, level: level)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final database = DatabaseHelper.instance;
  late Directory direktoriUji;
  late AkunAktif admin;
  late AkunAktif warga;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    direktoriUji = await Directory.systemTemp.createTemp('gub-test-');
    await databaseFactory.setDatabasesPath(direktoriUji.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (panggilan) async => direktoriUji.path,
        );
  });

  test(
    'pin mendeteksi kelurahan dan kecamatan serta menolak luar kota',
    () async {
      final layanan = LayananLokasi.instance;
      final braga = await layanan.cari(const LatLng(-6.917474, 107.609810));
      expect(braga?.kelurahan, 'Braga');
      expect(braga?.kecamatan, 'Sumur Bandung');
      expect(braga?.alamat, contains('Kota Bandung'));
      expect(
        (await layanan.cari(const LatLng(-6.9025, 107.6186)))?.kecamatan,
        'Bandung Wetan',
      );
      expect(await layanan.cari(const LatLng(-6.962957, 106.940032)), isNull);
    },
  );

  test('membedakan tiga pasangan dan mendeteksi piksel identik', () async {
    final berbeda = await PemeriksaanFoto.bandingkan([
      foto(10),
      foto(20),
      foto(30),
    ]);
    expect(berbeda.map((p) => (p.pertama, p.kedua)), [(1, 2), (1, 3), (2, 3)]);
    expect(PemeriksaanFoto.pesanFotoIdentik(berbeda), isNull);
    final a = foto(10, nama: 'awal.png', level: 0);
    final b = foto(10, nama: 'baru.png', level: 9);
    expect(a.hash, isNot(b.hash));
    final sama = await PemeriksaanFoto.bandingkan([a, foto(50), b]);
    expect(
      PemeriksaanFoto.pesanFotoIdentik(sama),
      contains('Foto 1 dan Foto 3'),
    );
  });

  test(
    'kategori dinamis, tiga keputusan, klarifikasi dan penugasan tetap terhubung',
    () async {
      final db = await database.database;
      final idKategori = await db.insert('kategori', {
        'nama_kategori': 'Kategori uji',
      });
      expect(
        (await database.ambilKategoriAktif()).map((k) => k.idKategori),
        contains(idKategori),
      );
      final contohFoto = [foto(10), foto(20), foto(30)];

      LaporanSampah baru(String kunci, {String kecamatan = 'Sumur Bandung'}) =>
          LaporanSampah(
            idWarga: 1,
            idKategori: idKategori,
            deskripsiLaporan: 'Laporan pengujian timbulan sampah',
            deskripsiLokasi: 'Dekat trotoar',
            kecamatan: kecamatan,
            latitude: -6.917474,
            longitude: 107.609810,
            metodeLokasi: MetodeLokasi.peta,
            dibuatAtUtc: DateTime.now().toUtc(),
            lokasiDikonfirmasiAtUtc: DateTime.now().toUtc(),
            kunciKirim: kunci,
          );

      Future<LaporanSampah> simpan(String kunci) => database.tambahLaporan(
        baru(kunci),
        idJenisSampah: [1],
        foto: contohFoto,
      );

      await expectLater(
        database.tambahLaporan(
          baru('salah-kecamatan', kecamatan: 'Andir'),
          idJenisSampah: [1],
          foto: contohFoto,
        ),
        throwsFormatException,
      );
      await expectLater(
        database.tambahLaporan(
          baru('duplikat-foto'),
          idJenisSampah: [1],
          foto: [foto(1), foto(2), foto(1)],
        ),
        throwsFormatException,
      );

      final diterima = await simpan('diterima');
      await simpan('ui-masuk');
      admin = (await SesiAkun.periksaKredensial(
        email: 'admin@glowup.test',
        kataSandi: SesiAkun.kataSandiDemo,
      ))!;
      warga = (await SesiAkun.periksaKredensial(
        email: 'warga@glowup.test',
        kataSandi: SesiAkun.kataSandiDemo,
      ))!;
      final ditolak = await simpan('ditolak');
      final klarifikasi = await simpan('klarifikasi');
      expect(diterima.alamatPeta, contains('Braga'));
      expect(diterima.namaKategoriSaatKirim, 'Kategori uji');

      Future<void> putuskan(
        LaporanSampah laporan,
        HasilVerifikasi hasil, {
        String? kebutuhan,
      }) async {
        final detail = (await database.ambilBahanPemeriksaan(
          idAdmin: 1,
          idLaporan: laporan.idLaporan!,
        ))!;
        await database.simpanVerifikasi(
          idAdmin: 1,
          idLaporan: laporan.idLaporan!,
          versi: detail.versi,
          hasil: hasil,
          kesimpulan: 'Hasil pemeriksaan bukti dan lokasi.',
          kebutuhanKlarifikasi: kebutuhan,
        );
        final hasilBaru = await database.ambilVerifikasiTerakhir(
          idLaporan: laporan.idLaporan!,
          idWarga: 1,
        );
        expect(hasilBaru?['hasil_tampil'], hasil.label);
      }

      await putuskan(diterima, HasilVerifikasi.sesuai);
      await putuskan(ditolak, HasilVerifikasi.tidakSesuai);
      await putuskan(
        klarifikasi,
        HasilVerifikasi.belumDapatDipastikan,
        kebutuhan: 'Lengkapi informasi lokasi.',
      );
      final permintaan = (await database.ambilVerifikasiTerakhir(
        idLaporan: klarifikasi.idLaporan!,
        idWarga: 1,
      ))!;
      await database.simpanKlarifikasi(
        idLaporan: klarifikasi.idLaporan!,
        idWarga: 1,
        idPermintaan: permintaan['id_verifikasi'] as int,
        penjelasan: 'Tumpukan berada dekat trotoar.',
        foto: const [],
      );
      await putuskan(klarifikasi, HasilVerifikasi.sesuai);

      final mulai = DateTime.now().toUtc().add(const Duration(days: 1));
      final bahan = (await database.ambilBahanPemeriksaan(
        idAdmin: 1,
        idLaporan: diterima.idLaporan!,
      ))!;
      await database.simpanJadwalPengangkutan(
        idAdmin: 1,
        idLaporan: diterima.idLaporan!,
        versiLaporan: bahan.versi,
        mulai: mulai,
        selesai: mulai.add(const Duration(hours: 2)),
        idTim: {1},
        idKoordinator: 1,
        catatan: '',
      );
      final tugas = (await database.ambilPenugasanPetugas(1)).single;
      await database.simpanAktivitasPengangkutan(
        idJadwal: tugas.jadwal.id,
        idPetugas: 1,
        tahap: TahapPengangkutan.mulai,
        kunciKirim: 'check-in-uji',
      );
      await database.simpanAktivitasPengangkutan(
        idJadwal: tugas.jadwal.id,
        idPetugas: 1,
        tahap: TahapPengangkutan.tanggapan,
        kunciKirim: 'progres-uji',
        foto: [foto(40)],
      );
      await database.simpanAktivitasPengangkutan(
        idJadwal: tugas.jadwal.id,
        idPetugas: 1,
        tahap: TahapPengangkutan.selesai,
        kunciKirim: 'selesai-uji',
        catatan: 'Sampah sudah diangkut.',
        foto: [foto(41)],
      );
      final selesai = await database.ambilDetailLaporan(
        idLaporan: diterima.idLaporan!,
        idWarga: 1,
      );
      expect(selesai?.statusPenanganan, StatusPenanganan.selesai);

      await db.update(
        'kategori',
        {'nama_kategori': 'Sudah diganti', 'aktif': 0},
        where: 'id_kategori = ?',
        whereArgs: [idKategori],
      );
      expect(
        (await database.ambilKategoriAktif()).map((k) => k.idKategori),
        isNot(contains(idKategori)),
      );
      expect(
        (await database.ambilBahanPemeriksaan(
          idAdmin: 1,
          idLaporan: diterima.idLaporan!,
        ))?.kategori,
        'Kategori uji',
      );
      expect((await simpan('diterima')).idLaporan, diterima.idLaporan);
    },
  );

  for (final ukuran in [const Size(1366, 900), const Size(390, 844)]) {
    testWidgets('Laporan Masuk dan panduan foto pada lebar ${ukuran.width}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = ukuran;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(SesiAkun.keluar);

      Future<void> tungguTampil(Finder finder) async {
        for (var i = 0; i < 40; i++) {
          if (finder.evaluate().isNotEmpty) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pump(const Duration(milliseconds: 60));
        }
        expect(finder, findsWidgets);
      }

      SesiAkun.aktifkan(admin);
      await tester.runAsync(() async {
        await tester.pumpWidget(const AplikasiGlowUpBandung());
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pushNamed<void>(AppRoutes.daftarLaporanAdmin);
        await tester.pump();
      });
      await tester.pump(const Duration(milliseconds: 400));
      final daftarTinjau = find.text('Tinjau laporan');
      final isiHalaman = find
          .descendant(
            of: find.byType(KontenWarga),
            matching: find.byType(Scrollable),
          )
          .first;
      await tungguTampil(daftarTinjau);
      for (
        var i = 0;
        i < 5 && daftarTinjau.hitTestable().evaluate().isEmpty;
        i++
      ) {
        await tester.drag(isiHalaman, const Offset(0, -220));
        await tester.pump(const Duration(milliseconds: 200));
      }
      final tinjau = daftarTinjau.hitTestable().first;
      await tester.runAsync(() async {
        await tester.tap(tinjau);
        await tester.pump();
      });
      final detail = find.text('Detail laporan', findRichText: true);
      await tungguTampil(detail);
      expect(
        ModalRoute.of(tester.element(detail))?.settings.name,
        AppRoutes.daftarLaporanAdmin,
      );
      final keputusan = find.text('Kesimpulan dan keputusan Admin');
      expect(keputusan, findsOneWidget);
      expect(
        tester.getTopLeft(keputusan).dy,
        greaterThan(tester.getTopLeft(detail).dy),
      );
      final menu = tester.widget<DropdownButton<HasilVerifikasi>>(
        find.byType(DropdownButton<HasilVerifikasi>).first,
      );
      expect(menu.items!.map((item) => (item.child as Text).data), [
        'Sesuai',
        'Tidak sesuai',
        'Belum dapat dipastikan',
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      SesiAkun.aktifkan(warga);
      await tester.runAsync(() async {
        await tester.pumpWidget(const AplikasiGlowUpBandung());
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pushNamed<void>(AppRoutes.buatLaporan);
        await tester.pump();
      });
      final panduan = find.textContaining('Foto 1 · Ambil dari jarak');
      await tungguTampil(panduan);
      expect(
        find.textContaining('Foto 2 · Ambil dari samping'),
        findsOneWidget,
      );
      expect(find.textContaining('Foto 3 · Ambil detail'), findsOneWidget);
      final bukaPeta = find.text('Mencari Titik Lokasi');
      final isiForm = find
          .descendant(
            of: find.byType(KontenWarga),
            matching: find.byType(Scrollable),
          )
          .first;
      for (var i = 0; i < 8 && bukaPeta.hitTestable().evaluate().isEmpty; i++) {
        await tester.drag(isiForm, const Offset(0, -220));
        await tester.pump(const Duration(milliseconds: 160));
      }
      await tester.tap(bukaPeta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final peta = find.byType(PetaLaporan);
      expect(peta, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(peta);
        await tester.pump(const Duration(milliseconds: 200));
      });
      await tungguTampil(find.textContaining('Kecamatan Sumur Bandung'));
      expect(find.textContaining('Kelurahan Braga'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}