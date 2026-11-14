import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/foto_laporan.dart';
import '../models/jadwal_pengangkutan.dart';
import '../models/klarifikasi_laporan.dart';
import '../models/laporan_sampah.dart';
import '../models/notifikasi_laporan.dart';
import '../models/penanganan_laporan.dart';
import '../models/referensi_laporan.dart';
import '../models/verifikasi_laporan.dart';
import '../services/layanan_lokasi.dart';
import '../services/pemeriksaan_foto.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _namaDatabase = 'glowup_bandung.db';
  static const int _versiDatabase = 10;

  Future<Database>? _koneksi;

  Future<Database> get database async {
    final koneksi = _koneksi ??= _bukaDatabase();

    try {
      return await koneksi;
    } catch (_) {
      if (identical(_koneksi, koneksi)) {
        _koneksi = null;
      }
      rethrow;
    }
  }

  Future<Database> _bukaDatabase() async {
    final lokasi = kIsWeb
        ? _namaDatabase
        : p.join(await getDatabasesPath(), _namaDatabase);

    return openDatabase(
      lokasi,
      version: _versiDatabase,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final perintah in _skemaVersi1) {
          await db.execute(perintah);
        }
        await _isiReferensiDemo(db);
        await _buatTabelVersi2(db);
        await _buatTabelVersi3(db);
        await _buatTabelVersi4(db);
        await _buatTabelVersi5(db);
        await _buatTabelVersi6(db);
        await _buatTabelVersi7(db);
        await _buatTabelVersi8(db);
        await _buatTabelVersi9(db);
        await _buatTabelVersi10(db);
      },
      onUpgrade: (db, versiLama, versiBaru) async {
        if (versiLama < 2 && versiBaru >= 2) {
          await _buatTabelVersi2(db);
        }
        if (versiLama < 3 && versiBaru >= 3) {
          await _buatTabelVersi3(db);
        }
        if (versiLama < 4 && versiBaru >= 4) {
          await _buatTabelVersi4(db);
        }
        if (versiLama < 5 && versiBaru >= 5) {
          await _buatTabelVersi5(db);
        }
        if (versiLama < 6 && versiBaru >= 6) {
          await _buatTabelVersi6(db);
        }
        if (versiLama < 7 && versiBaru >= 7) {
          await _buatTabelVersi7(db);
        }
        if (versiLama < 8 && versiBaru >= 8) {
          await _buatTabelVersi8(db);
        }
        if (versiLama < 9 && versiBaru >= 9) {
          await _buatTabelVersi9(db);
        }
        if (versiLama < 10 && versiBaru >= 10) {
          await _buatTabelVersi10(db);
        }
      },
    );
  }

  Future<void> _buatTabelVersi10(Database db) async {
    await db.execute('ALTER TABLE laporan ADD COLUMN alamat_peta TEXT');
    await db.execute(
      'ALTER TABLE laporan ADD COLUMN nama_kategori_saat_kirim TEXT',
    );
    await db.execute("""
      UPDATE laporan SET nama_kategori_saat_kirim = (
        SELECT nama_kategori FROM kategori WHERE kategori.id_kategori = laporan.id_kategori
      )
    """);
    // Pertahankan CHECK dan FK tabel lama, termasuk riwayat keputusan v9.
    await db.execute("""
      ALTER TABLE verifikasi ADD COLUMN hasil_revisi TEXT
        CHECK (hasil_revisi IS NULL OR hasil_revisi IN (
          'Sesuai', 'Tidak sesuai', 'Belum dapat dipastikan'
        ))
    """);
    await db.execute("""
      CREATE TRIGGER validasi_verifikasi_baru BEFORE INSERT ON verifikasi
      WHEN NEW.hasil_revisi IS NULL OR NOT (
        (NEW.hasil_revisi = 'Sesuai' AND NEW.hasil = 'Valid') OR
        (NEW.hasil_revisi = 'Tidak sesuai' AND NEW.hasil = 'Tidak valid') OR
        (NEW.hasil_revisi = 'Belum dapat dipastikan' AND NEW.hasil = 'Perlu verifikasi')
      )
      BEGIN
        SELECT RAISE(ABORT, 'Hasil keputusan baru tidak valid');
      END
    """);
  }

  // CREATE: laporan, pilihan jenis, foto dan status awal disimpan bersama.
  Future<LaporanSampah> tambahLaporan(
    LaporanSampah laporan, {
    required List<int> idJenisSampah,
    required List<FotoLaporan> foto,
  }) async {
    // Ambil salinan daftar sebelum operasi asinkron dimulai.
    final jenis = idJenisSampah.toSet().toList(growable: false);
    final daftarFoto = List<FotoLaporan>.unmodifiable(foto);

    final db = await database;
    final kirimanSama = await db.query(
      'laporan',
      where: 'id_warga = ? AND kunci_kirim = ?',
      whereArgs: [laporan.idWarga, laporan.kunciKirim],
      limit: 1,
    );
    if (kirimanSama.isNotEmpty) {
      return LaporanSampah.fromMap(kirimanSama.single);
    }

    _validasiLaporanBaru(laporan, jenis, daftarFoto);
    final detail = await LayananLokasi.instance.cari(
      LatLng(laporan.latitude, laporan.longitude),
    );
    if (detail == null || detail.kecamatan != laporan.kecamatan) {
      throw const FormatException(
        'Pilih kembali titik lokasi di Kota Bandung.',
      );
    }
    final pasangan = await PemeriksaanFoto.bandingkan(daftarFoto);
    final fotoSama = PemeriksaanFoto.pesanFotoIdentik(pasangan);
    if (fotoSama != null) throw FormatException(fotoSama);

    return db.transaction<LaporanSampah>((txn) async {
      final sebelumnya = await txn.query(
        'laporan',
        where: 'id_warga = ? AND kunci_kirim = ?',
        whereArgs: [laporan.idWarga, laporan.kunciKirim],
        limit: 1,
      );

      if (sebelumnya.isNotEmpty) {
        return LaporanSampah.fromMap(sebelumnya.single);
      }

      final warga = await txn.query(
        'warga',
        columns: ['id_warga'],
        where: 'id_warga = ? AND aktif = ?',
        whereArgs: [laporan.idWarga, 1],
        limit: 1,
      );

      final kategori = await txn.query(
        'kategori',
        columns: ['nama_kategori'],
        where: 'id_kategori = ? AND aktif = ?',
        whereArgs: [laporan.idKategori, 1],
        limit: 1,
      );

      if (warga.isEmpty || kategori.isEmpty) {
        throw StateError('Akun warga atau kategori tidak tersedia.');
      }

      final placeholder = List.filled(jenis.length, '?').join(', ');
      final jenisAktif = await txn.query(
        'jenis_sampah',
        columns: ['id_jenis'],
        where: 'aktif = ? AND id_jenis IN ($placeholder)',
        whereArgs: [1, ...jenis],
      );

      if (jenisAktif.length != jenis.length) {
        throw StateError('Salah satu jenis sampah tidak tersedia.');
      }

      final waktu = DateTime.now().toUtc().toIso8601String();
      final data = <String, Object?>{
        ...laporan.toMap(),
        'alamat_peta': detail.alamat,
        'nama_kategori_saat_kirim': kategori.single['nama_kategori'],
        'kode_laporan': 'TMP-${laporan.idWarga}-${laporan.kunciKirim}',
        'status_penanganan': StatusPenanganan.baru.nilaiDatabase,
        'dibuat_at_utc': waktu,
        'versi': 1,
      };

      final id = await txn.insert('laporan', data);
      final kode = 'GUB-${id.toString().padLeft(6, '0')}';

      final jumlahDiubah = await txn.update(
        'laporan',
        {'kode_laporan': kode},
        where: 'id_laporan = ? AND id_warga = ?',
        whereArgs: [id, laporan.idWarga],
      );

      if (jumlahDiubah != 1) {
        throw StateError('Kode laporan gagal ditetapkan.');
      }

      for (final idJenis in jenis) {
        await txn.insert('laporan_jenis', {
          'id_laporan': id,
          'id_jenis': idJenis,
        });
      }

      for (final item in daftarFoto) {
        await txn.insert('foto', {
          ...item.toMap(),
          'data_foto': Uint8List.fromList(item.dataFoto),
          'id_laporan': id,
          'diunggah_at_utc': waktu,
        });
      }

      await txn.insert('riwayat_status', {
        'id_laporan': id,
        'status_lama': null,
        'status_baru': StatusPenanganan.baru.nilaiDatabase,
        'event_key': 'laporan:$id:dibuat',
        'diubah_at_utc': waktu,
      });

      // Pemberitahuan dan laporan berada dalam transaksi yang sama.
      // Retry pengiriman mengembalikan laporan lama sebelum mencapai bagian ini.
      await txn.insert('notifikasi_warga', {
        'id_warga': laporan.idWarga,
        'id_laporan': id,
        'event_key': 'laporan:$id:dibuat',
        'jenis': 'pengiriman',
        'judul': 'Laporan berhasil dikirim',
        'ringkasan':
            'Laporan tersimpan. Status: Baru. Menunggu peninjauan admin.',
        'dibuat_at_utc': waktu,
      });

      final tersimpan = await txn.query(
        'laporan',
        where: 'id_laporan = ? AND id_warga = ?',
        whereArgs: [id, laporan.idWarga],
        limit: 1,
      );

      return LaporanSampah.fromMap(tersimpan.single);
    });
  }

  void _validasiLaporanBaru(
    LaporanSampah laporan,
    List<int> jenis,
    List<FotoLaporan> foto,
  ) {
    if (laporan.idLaporan != null ||
        laporan.kodeLaporan != null ||
        laporan.statusPenanganan != StatusPenanganan.baru ||
        laporan.idLaporanUtama != null ||
        laporan.idVerifikasiTerakhir != null ||
        laporan.diterimaAtUtc != null ||
        laporan.selesaiAtUtc != null) {
      throw ArgumentError(
        'Gunakan objek laporan baru tanpa ID, kode, atau hasil penanganan.',
      );
    }

    if (laporan.kunciKirim.trim().isEmpty || laporan.kunciKirim.length > 64) {
      throw ArgumentError('Kunci pengiriman tidak valid.');
    }

    if (jenis.isEmpty || jenis.any((id) => id <= 0)) {
      throw ArgumentError('Pilih minimal satu jenis sampah yang tersedia.');
    }

    if (foto.length != 3) {
      throw ArgumentError('Sertakan tepat 3 foto laporan.');
    }

    for (final item in foto) {
      if (item.idFoto != null ||
          item.idLaporan != null ||
          item.sumber != SumberFoto.warga) {
        throw ArgumentError('Gunakan foto baru untuk laporan warga.');
      }

      if (item.ukuranByte < 1 ||
          item.ukuranByte > FotoLaporan.maksimumUkuranByte) {
        throw ArgumentError(
          'Ukuran foto harus lebih dari 0 dan maksimal 2 MB.',
        );
      }

      if (item.mimeType != 'image/jpeg' && item.mimeType != 'image/png') {
        throw ArgumentError('Foto harus berformat JPG, JPEG, atau PNG.');
      }
    }
  }

  Future<List<LaporanSampah>> ambilLaporanWarga(int idWarga) async {
    final db = await database;
    final hasil = await db.query(
      'laporan',
      where: 'id_warga = ?',
      whereArgs: [idWarga],
      orderBy: 'id_laporan DESC',
    );

    return hasil.map(LaporanSampah.fromMap).toList();
  }

  Future<LaporanSampah?> ambilDetailLaporan({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    final hasil = await db.query(
      'laporan',
      where: 'id_laporan = ? AND id_warga = ?',
      whereArgs: [idLaporan, idWarga],
      limit: 1,
    );

    if (hasil.isEmpty) return null;
    return LaporanSampah.fromMap(hasil.single);
  }

  Future<List<FotoLaporan>> ambilFotoLaporan({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    final hasil = await db.rawQuery(
      '''
      SELECT f.*
      FROM foto AS f
      JOIN laporan AS l ON l.id_laporan = f.id_laporan
      WHERE f.id_laporan = ? AND l.id_warga = ? AND f.id_klarifikasi IS NULL AND f.id_pembaruan IS NULL AND f.id_tanggapan IS NULL
      ORDER BY f.id_foto ASC
    ''',
      [idLaporan, idWarga],
    );

    return hasil.map(FotoLaporan.fromMap).toList();
  }

  Future<List<JenisSampah>> ambilJenisSampahLaporan({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    final hasil = await db.rawQuery(
      '''
      SELECT j.*
      FROM jenis_sampah AS j
      JOIN laporan_jenis AS lj ON lj.id_jenis = j.id_jenis
      JOIN laporan AS l ON l.id_laporan = lj.id_laporan
      WHERE lj.id_laporan = ? AND l.id_warga = ?
      ORDER BY j.nama_jenis ASC
    ''',
      [idLaporan, idWarga],
    );

    return hasil.map(JenisSampah.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> ambilWargaAktif() async {
    final db = await database;
    return db.query(
      'warga',
      where: 'aktif = ?',
      whereArgs: [1],
      orderBy: 'nama ASC',
    );
  }

  Future<String?> ambilNamaAkunDemo({
    required String peran,
    required int idAkun,
  }) async {
    final (tabel, kolomId) = switch (peran) {
      'warga' => ('warga', 'id_warga'),
      'admin' => ('admin', 'id_admin'),
      'petugas' => ('petugas', 'id_petugas'),
      _ => throw ArgumentError.value(peran, 'peran', 'Peran tidak dikenal.'),
    };
    final db = await database;
    final hasil = await db.query(
      tabel,
      columns: ['nama'],
      where: '$kolomId = ? AND aktif = ?',
      whereArgs: [idAkun, 1],
      limit: 1,
    );
    return hasil.isEmpty ? null : hasil.single['nama'] as String;
  }

  Future<List<Map<String, Object?>>> ambilRingkasanLaporanAdmin(
    int idAdmin,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT l.id_laporan, l.kode_laporan, l.status_penanganan, l.kecamatan,
             l.dibuat_at_utc, l.deskripsi_lokasi,
             COALESCE(l.nama_kategori_saat_kirim, k.nama_kategori) AS nama_kategori,
             COALESCE(v.hasil_revisi, v.hasil) AS hasil_verifikasi, kf.dibuat_at_utc AS klarifikasi_masuk_at_utc, l.versi
      FROM laporan AS l
      JOIN kategori AS k ON k.id_kategori = l.id_kategori
      LEFT JOIN verifikasi AS v ON v.id_verifikasi = l.id_verifikasi_terakhir
      LEFT JOIN klarifikasi AS kf
        ON kf.id_verifikasi_permintaan = l.id_verifikasi_terakhir
       AND kf.id_laporan = l.id_laporan AND kf.id_warga = l.id_warga
       AND kf.id_verifikasi_tindak_lanjut IS NULL
       AND l.status_penanganan = 'Menunggu klarifikasi'
      WHERE EXISTS (
        SELECT 1 FROM admin WHERE id_admin = ? AND aktif = 1
      )
      ORDER BY CASE WHEN l.status_penanganan = 'Baru' OR kf.id_klarifikasi IS NOT NULL
                    THEN 0 ELSE 1 END,
               COALESCE(kf.dibuat_at_utc, l.dibuat_at_utc) DESC, l.id_laporan DESC
    ''',
      [idAdmin],
    );
  }

  Future<List<KategoriLaporan>> ambilKategoriAktif() async {
    final db = await database;
    final hasil = await db.query(
      'kategori',
      where: 'aktif = ?',
      whereArgs: [1],
      orderBy: 'nama_kategori ASC',
    );
    return hasil.map(KategoriLaporan.fromMap).toList();
  }

  Future<List<JenisSampah>> ambilJenisSampahAktif() async {
    final db = await database;
    final hasil = await db.query(
      'jenis_sampah',
      where: 'aktif = ?',
      whereArgs: [1],
      orderBy: 'nama_jenis ASC',
    );
    return hasil.map(JenisSampah.fromMap).toList();
  }

  Future<List<NotifikasiLaporan>> ambilNotifikasiWarga(int idWarga) async {
    final db = await database;
    final hasil = await db.rawQuery(
      '''
      SELECT n.*, l.kode_laporan
      FROM notifikasi_warga AS n
      JOIN laporan AS l ON l.id_laporan = n.id_laporan
      WHERE n.id_warga = ? AND l.id_warga = ?
      ORDER BY n.id_notifikasi DESC
    ''',
      [idWarga, idWarga],
    );
    return hasil.map(NotifikasiLaporan.fromMap).toList();
  }

  Future<void> tandaiNotifikasiDibaca({
    required int idNotifikasi,
    required int idWarga,
  }) async {
    final db = await database;
    await db.update(
      'notifikasi_warga',
      {'dibaca_at_utc': DateTime.now().toUtc().toIso8601String()},
      where: '''id_notifikasi = ? AND id_warga = ?
        AND dibaca_at_utc IS NULL
        AND id_laporan IN (SELECT id_laporan FROM laporan WHERE id_warga = ?)''',
      whereArgs: [idNotifikasi, idWarga, idWarga],
    );
  }

  Future<Map<String, Object?>?> ambilVerifikasiTerakhir({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    final hasil = await db.rawQuery(
      '''
      SELECT COALESCE(v.hasil_revisi, v.hasil) AS hasil_tampil, v.*, a.nama AS nama_admin
      FROM verifikasi AS v
      JOIN laporan AS l ON l.id_laporan = v.id_laporan
      JOIN admin AS a ON a.id_admin = v.id_admin
      WHERE l.id_laporan = ? AND l.id_warga = ?
        AND v.id_verifikasi = l.id_verifikasi_terakhir
      LIMIT 1
    ''',
      [idLaporan, idWarga],
    );
    return hasil.isEmpty ? null : hasil.single;
  }

  Future<List<Map<String, Object?>>> ambilRiwayatStatus({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT r.* FROM riwayat_status AS r
      JOIN laporan AS l ON l.id_laporan = r.id_laporan
      WHERE l.id_laporan = ? AND l.id_warga = ?
      ORDER BY r.id_riwayat ASC
    ''',
      [idLaporan, idWarga],
    );
  }

  Future<BahanPemeriksaan?> ambilBahanPemeriksaan({
    required int idAdmin,
    required int idLaporan,
  }) async {
    final db = await database;
    return db.transaction<BahanPemeriksaan?>((txn) async {
      await _pastikanAdminAktif(txn, idAdmin);
      final baris = await txn.rawQuery(
        '''
        SELECT l.*, COALESCE(l.nama_kategori_saat_kirim, k.nama_kategori) AS nama_kategori
        FROM laporan AS l
        JOIN kategori AS k ON k.id_kategori = l.id_kategori
        WHERE l.id_laporan = ?
      ''',
        [idLaporan],
      );
      if (baris.isEmpty) return null;
      final data = baris.single;

      final foto = await txn.query(
        'foto',
        where: '''id_laporan = ? AND id_klarifikasi IS NULL
          AND id_pembaruan IS NULL AND id_tanggapan IS NULL''',
        whereArgs: [idLaporan],
        orderBy: 'id_foto ASC',
      );
      final jenis = await txn.rawQuery(
        '''
        SELECT j.*
        FROM jenis_sampah AS j
        JOIN laporan_jenis AS lj ON lj.id_jenis = j.id_jenis
        WHERE lj.id_laporan = ?
        ORDER BY j.nama_jenis ASC
      ''',
        [idLaporan],
      );
      final keputusan = await txn.rawQuery(
        '''
        SELECT COALESCE(v.hasil_revisi, v.hasil) AS hasil_tampil, v.*, a.nama AS nama_admin, utama.kode_laporan AS kode_utama
        FROM verifikasi AS v
        JOIN admin AS a ON a.id_admin = v.id_admin
        JOIN laporan AS l ON l.id_laporan = v.id_laporan
        LEFT JOIN laporan AS utama ON utama.id_laporan = l.id_laporan_utama
        WHERE v.id_laporan = ?
        ORDER BY v.id_verifikasi DESC
      ''',
        [idLaporan],
      );
      final checklist = await txn.rawQuery(
        '''
        SELECT c.*
        FROM checklist_verifikasi AS c
        JOIN verifikasi AS v ON v.id_verifikasi = c.id_verifikasi
        WHERE v.id_laporan = ?
        ORDER BY c.id_checklist ASC
      ''',
        [idLaporan],
      );
      final riwayatStatus = await txn.query(
        'riwayat_status',
        where: 'id_laporan = ?',
        whereArgs: [idLaporan],
        orderBy: 'id_riwayat ASC',
      );

      final klarifikasi = await _ambilKlarifikasi(
        txn,
        idLaporan,
        data['id_warga'] as int,
      );
      return (
        laporan: LaporanSampah.fromMap(data),
        versi: data['versi'] as int,
        kategori: data['nama_kategori'] as String,
        foto: foto
            .map(
              (item) => (
                foto: FotoLaporan.fromMap(item),
                diunggah: DateTime.parse(item['diunggah_at_utc'] as String),
              ),
            )
            .toList(growable: false),
        jenis: jenis.map(JenisSampah.fromMap).toList(growable: false),
        riwayatStatus: riwayatStatus,
        keputusan: keputusan,
        checklist: checklist,
        klarifikasi: klarifikasi,
        aktivitas: await _ambilAktivitas(txn, idLaporan),
      );
    });
  }
  Future<void> simpanVerifikasi({
    required int idAdmin,
    required int idLaporan,
    required int versi,
    required HasilVerifikasi hasil,
    required String kesimpulan,
    String? kebutuhanKlarifikasi,
    int? idUsulanLokasi,
  }) async {
    final dasar = kesimpulan.trim();
    final kebutuhan = kebutuhanKlarifikasi?.trim() ?? '';
    if (dasar.isEmpty || dasar.length > 2000) {
      throw const GalatVerifikasi('Isi kesimpulan maksimal 2.000 karakter.');
    }
    if (hasil == HasilVerifikasi.belumDapatDipastikan &&
        (kebutuhan.isEmpty || kebutuhan.length > 2000)) {
      throw const GalatVerifikasi('Isi informasi yang perlu dilengkapi warga.');
    }

    final db = await database;
    await db.transaction((txn) async {
      await _pastikanAdminAktif(txn, idAdmin);
      final laporan = await txn.query(
        'laporan',
        where: 'id_laporan = ?',
        whereArgs: [idLaporan],
        limit: 1,
      );
      if (laporan.isEmpty) {
        throw const GalatVerifikasi(
          'Laporan tidak ditemukan.',
          muatUlang: true,
        );
      }
      final data = laporan.single;
      final statusLama = data['status_penanganan'] as String;
      final tinjauUlang =
          statusLama == HasilVerifikasi.belumDapatDipastikan.statusBaru;
      if (data['versi'] != versi ||
          (statusLama != StatusPenanganan.baru.nilaiDatabase && !tinjauUlang)) {
        throw const GalatVerifikasi(
          'Laporan sudah berubah. Muat ulang untuk melihat data terbaru.',
          muatUlang: true,
        );
      }

      int? idKlarifikasi;
      if (tinjauUlang) {
        final daftar = await txn.query(
          'klarifikasi',
          columns: ['id_klarifikasi'],
          where: '''id_laporan = ? AND id_warga = ?
            AND id_verifikasi_permintaan = ? AND id_verifikasi_tindak_lanjut IS NULL''',
          whereArgs: [
            idLaporan,
            data['id_warga'],
            data['id_verifikasi_terakhir'],
          ],
          limit: 1,
        );
        if (daftar.isEmpty) {
          throw const GalatVerifikasi(
            'Warga belum menjawab permintaan klarifikasi.',
            muatUlang: true,
          );
        }
        idKlarifikasi = daftar.single['id_klarifikasi'] as int;
      }

      LokasiKlarifikasi? lokasiBaru;
      if (idUsulanLokasi != null) {
        final usulan = await txn.query(
          'klarifikasi',
          columns: ['lokasi_usulan'],
          where: 'id_klarifikasi = ? AND id_laporan = ? AND id_warga = ?',
          whereArgs: [idUsulanLokasi, idLaporan, data['id_warga']],
          limit: 1,
        );
        if (!tinjauUlang ||
            idUsulanLokasi != idKlarifikasi ||
            hasil != HasilVerifikasi.sesuai ||
            usulan.isEmpty ||
            usulan.single['lokasi_usulan'] == null) {
          throw const GalatVerifikasi(
            'Usulan lokasi tidak tersedia untuk keputusan ini.',
          );
        }
        lokasiBaru = LokasiKlarifikasi.dariJson(usulan.single['lokasi_usulan']);
      }

      final waktu = DateTime.now().toUtc().toIso8601String();
      final idKeputusan = await txn.insert('verifikasi', {
        'id_laporan': idLaporan,
        'id_admin': idAdmin,
        'hasil': hasil.nilaiLama,
        'hasil_revisi': hasil.label,
        'alasan': dasar,
        'kebutuhan_klarifikasi': hasil == HasilVerifikasi.belumDapatDipastikan
            ? kebutuhan
            : null,
        'diperiksa_at_utc': waktu,
      });
      final diubah = await txn.update(
        'laporan',
        {
          'status_penanganan': hasil.statusBaru,
          'id_verifikasi_terakhir': idKeputusan,
          if (lokasiBaru != null) ...lokasiBaru.toMap(),
          if (hasil == HasilVerifikasi.sesuai)
            'diterima_at_utc': data['diterima_at_utc'] ?? waktu,
          'versi': versi + 1,
        },
        where: 'id_laporan = ? AND versi = ? AND status_penanganan = ?',
        whereArgs: [idLaporan, versi, statusLama],
      );
      if (diubah != 1) {
        throw const GalatVerifikasi(
          'Laporan sudah berubah. Muat ulang untuk melihat data terbaru.',
          muatUlang: true,
        );
      }

      if (idKlarifikasi != null) {
        final ditinjau = await txn.update(
          'klarifikasi',
          {'id_verifikasi_tindak_lanjut': idKeputusan},
          where:
              'id_klarifikasi = ? AND id_laporan = ? AND id_verifikasi_tindak_lanjut IS NULL',
          whereArgs: [idKlarifikasi, idLaporan],
        );
        if (ditinjau != 1) {
          throw const GalatVerifikasi(
            'Klarifikasi sudah diperiksa. Muat laporan terbaru.',
            muatUlang: true,
          );
        }
      }

      final event = 'verifikasi:$idKeputusan:status';
      await txn.insert('riwayat_status', {
        'id_laporan': idLaporan,
        'id_verifikasi': idKeputusan,
        'status_lama': statusLama,
        'status_baru': hasil.statusBaru,
        'event_key': event,
        'diubah_at_utc': waktu,
      });
      final mintaKlarifikasi = hasil == HasilVerifikasi.belumDapatDipastikan;
      final isi = mintaKlarifikasi ? kebutuhan : dasar;
      final ringkasan = isi.runes.length > 250
          ? '${String.fromCharCodes(isi.runes.take(250))}…'
          : isi;
      await txn.insert('notifikasi_warga', {
        'id_warga': data['id_warga'],
        'id_laporan': idLaporan,
        'event_key': event,
        'jenis': 'status',
        'judul': mintaKlarifikasi
            ? 'Laporan perlu klarifikasi'
            : 'Perubahan status laporan',
        'ringkasan':
            '${data['kode_laporan']} · $statusLama → ${hasil.statusBaru}\n$ringkasan',
        'dibuat_at_utc': waktu,
      });
    });
  }

  Future<void> _pastikanAdminAktif(Transaction txn, int idAdmin) async {
    final admin = await txn.query(
      'admin',
      columns: ['id_admin'],
      where: 'id_admin = ? AND aktif = ?',
      whereArgs: [idAdmin, 1],
      limit: 1,
    );
    if (admin.isEmpty) {
      throw const GalatVerifikasi('Akun admin tidak aktif.');
    }
  }

  Future<({String kode, String status})?> ambilRingkasanLaporanUtama({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    final hasil = await db.rawQuery(
      '''
      SELECT utama.kode_laporan, utama.status_penanganan
      FROM laporan AS duplikat
      JOIN laporan AS utama ON utama.id_laporan = duplikat.id_laporan_utama
      WHERE duplikat.id_laporan = ? AND duplikat.id_warga = ?
        AND duplikat.status_penanganan = ?
    ''',
      [
        idLaporan,
        idWarga,
        StatusPenanganan.ditutupSebagaiDuplikat.nilaiDatabase,
      ],
    );
    if (hasil.isEmpty) return null;
    final utama = hasil.single;
    return (
      kode: utama['kode_laporan'] as String,
      status: utama['status_penanganan'] as String,
    );
  }

  Future<List<Map<String, Object?>>> ambilPetugasAktifJadwal(
    int idAdmin,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT id_petugas, nama FROM petugas
      WHERE aktif = 1 AND EXISTS (
        SELECT 1 FROM admin WHERE id_admin = ? AND aktif = 1
      )
      ORDER BY nama ASC, id_petugas ASC
    ''',
      [idAdmin],
    );
  }

  Future<JadwalPengangkutan?> ambilJadwalAktifAdmin({
    required int idAdmin,
    required int idLaporan,
  }) async {
    final db = await database;
    final data = await db.rawQuery(
      '''
      SELECT j.id_jadwal, j.mulai_at_utc, j.estimasi_selesai_at_utc, j.status_jadwal
      FROM jadwal AS j
      WHERE j.id_laporan = ? AND j.aktif = 1 AND EXISTS (
        SELECT 1 FROM admin WHERE id_admin = ? AND aktif = 1
      )
    ''',
      [idLaporan, idAdmin],
    );
    return data.isEmpty ? null : JadwalPengangkutan.fromMap(data.single);
  }

  Future<JadwalPengangkutan?> ambilJadwalAktifWarga({
    required int idWarga,
    required int idLaporan,
  }) async {
    final db = await database;
    final data = await db.rawQuery(
      '''
      SELECT j.id_jadwal, j.mulai_at_utc, j.estimasi_selesai_at_utc, j.status_jadwal
      FROM jadwal AS j
      JOIN laporan AS l ON l.id_laporan = j.id_laporan
      WHERE j.id_laporan = ? AND l.id_warga = ? AND j.aktif = 1
    ''',
      [idLaporan, idWarga],
    );
    return data.isEmpty ? null : JadwalPengangkutan.fromMap(data.single);
  }

  Future<void> simpanJadwalPengangkutan({
    required int idAdmin,
    required int idLaporan,
    required int versiLaporan,
    int? idJadwalDiganti,
    required DateTime mulai,
    required DateTime selesai,
    required Set<int> idTim,
    required int idKoordinator,
    required String catatan,
  }) async {
    final tim = Set<int>.of(idTim);
    final teks = catatan.trim();
    if (tim.isEmpty || !tim.contains(idKoordinator)) {
      throw const GalatJadwal('Pilih petugas dan satu koordinator dari tim.');
    }
    if (!selesai.isAfter(mulai)) {
      throw const GalatJadwal('Perkiraan selesai harus setelah jam mulai.');
    }
    if (teks.length > 2000) {
      throw const GalatJadwal('Catatan tugas maksimal 2.000 karakter.');
    }

    final mulaiUtc = mulai.toUtc().toIso8601String();
    final selesaiUtc = selesai.toUtc().toIso8601String();
    final db = await database;
    await db.transaction((txn) async {
      await _pastikanAdminAktif(txn, idAdmin);
      final sekarang = DateTime.now().toUtc();
      if (mulai.isBefore(sekarang)) {
        throw const GalatJadwal(
          'Pilih tanggal dan jam mulai yang belum lewat.',
        );
      }
      final baris = await txn.rawQuery(
        '''
        SELECT l.kode_laporan, l.id_warga, l.status_penanganan, l.versi, COALESCE(v.hasil_revisi, v.hasil) AS hasil
        FROM laporan AS l
        JOIN verifikasi AS v
          ON v.id_verifikasi = l.id_verifikasi_terakhir AND v.id_laporan = l.id_laporan
        WHERE l.id_laporan = ? AND l.id_laporan_utama IS NULL
      ''',
        [idLaporan],
      );
      final laporan = baris.isEmpty ? null : baris.single;
      final statusAwal = idJadwalDiganti == null ? 'Diterima' : 'Diproses';
      if (laporan == null ||
          !HasilVerifikasi.sesuai.cocok(laporan['hasil']) ||
          laporan['status_penanganan'] != statusAwal ||
          laporan['versi'] != versiLaporan) {
        throw const GalatJadwal(
          'Laporan belum memenuhi syarat atau sudah berubah. Buka kembali detail laporan.',
        );
      }

      final jadwalAktif = await txn.query(
        'jadwal',
        columns: ['id_jadwal', 'status_jadwal'],
        where: 'id_laporan = ? AND aktif = ?',
        whereArgs: [idLaporan, 1],
      );
      final aktif = jadwalAktif.isEmpty ? null : jadwalAktif.single;
      if (aktif?['id_jadwal'] != idJadwalDiganti ||
          (aktif != null && aktif['status_jadwal'] != 'Terjadwal')) {
        throw const GalatJadwal(
          'Jadwal sudah berubah atau pekerjaan sudah dimulai.',
        );
      }

      final tanda = List.filled(tim.length, '?').join(', ');
      final petugas = await txn.query(
        'petugas',
        columns: ['id_petugas'],
        where: 'aktif = ? AND id_petugas IN ($tanda)',
        whereArgs: [1, ...tim],
      );
      if (petugas.length != tim.length) {
        throw const GalatJadwal(
          'Ada petugas yang sudah tidak aktif. Pilih ulang tim.',
        );
      }
      final bentrok = await txn.rawQuery(
        '''
        SELECT p.nama, l.kode_laporan
        FROM jadwal AS j
        JOIN jadwal_petugas AS jp ON jp.id_jadwal = j.id_jadwal
        JOIN petugas AS p ON p.id_petugas = jp.id_petugas
        JOIN laporan AS l ON l.id_laporan = j.id_laporan
        WHERE j.aktif = 1 AND j.status_jadwal IN ('Terjadwal', 'Dikerjakan')
          AND j.id_jadwal IS NOT ?
          AND j.mulai_at_utc < ? AND j.estimasi_selesai_at_utc > ?
          AND jp.id_petugas IN ($tanda)
        ORDER BY j.mulai_at_utc, jp.id_petugas
        LIMIT 1
      ''',
        [idJadwalDiganti, selesaiUtc, mulaiUtc, ...tim],
      );
      if (bentrok.isNotEmpty) {
        final tugas = bentrok.single;
        throw GalatJadwal(
          '${tugas['nama']} sudah bertugas pada ${tugas['kode_laporan']} di rentang ini. '
          'Ganti jam atau anggota tim.',
        );
      }

      if (idJadwalDiganti != null) {
        final diubah = await txn.update(
          'jadwal',
          {'aktif': 0, 'status_jadwal': 'Dibatalkan'},
          where:
              'id_jadwal = ? AND id_laporan = ? AND aktif = ? AND status_jadwal = ?',
          whereArgs: [idJadwalDiganti, idLaporan, 1, 'Terjadwal'],
        );
        if (diubah != 1) throw const GalatJadwal('Jadwal lama sudah berubah.');
      }

      final waktu = sekarang.toIso8601String();
      final idJadwal = await txn.insert('jadwal', {
        'id_laporan': idLaporan,
        'id_admin': idAdmin,
        'mulai_at_utc': mulaiUtc,
        'estimasi_selesai_at_utc': selesaiUtc,
        'catatan': teks,
        'dibuat_at_utc': waktu,
      });
      for (final idPetugas in tim) {
        await txn.insert('jadwal_petugas', {
          'id_jadwal': idJadwal,
          'id_petugas': idPetugas,
          'peran_tugas': idPetugas == idKoordinator ? 'Koordinator' : 'Anggota',
        });
        await txn.insert('notifikasi_petugas', {
          'id_jadwal': idJadwal,
          'id_petugas': idPetugas,
          'dibuat_at_utc': waktu,
        });
      }

      final diubah = await txn.update(
        'laporan',
        {'status_penanganan': 'Diproses', 'versi': versiLaporan + 1},
        where: 'id_laporan = ? AND versi = ? AND status_penanganan = ?',
        whereArgs: [idLaporan, versiLaporan, statusAwal],
      );
      if (diubah != 1) throw const GalatJadwal('Laporan sudah berubah.');

      final event = 'jadwal:$idJadwal:ditetapkan';
      if (idJadwalDiganti == null) {
        await txn.insert('riwayat_status', {
          'id_laporan': idLaporan,
          'id_jadwal': idJadwal,
          'status_lama': statusAwal,
          'status_baru': 'Diproses',
          'event_key': event,
          'diubah_at_utc': waktu,
        });
      }
      await txn.insert('notifikasi_warga', {
        'id_warga': laporan['id_warga'],
        'id_laporan': idLaporan,
        'event_key': event,
        'jenis': 'status',
        'judul': idJadwalDiganti == null
            ? 'Jadwal pengangkutan ditetapkan'
            : 'Jadwal pengangkutan diperbarui',
        'ringkasan': idJadwalDiganti == null
            ? '${laporan['kode_laporan']} · Diterima → Diproses. Lihat jadwal di detail laporan.'
            : '${laporan['kode_laporan']} · Lihat waktu terbaru di detail laporan.',
        'dibuat_at_utc': waktu,
      });
    });
  }

  Future<List<PenugasanPetugas>> ambilPenugasanPetugas(int idPetugas) async {
    final db = await database;
    final hasil = await db.rawQuery(
      '$_pilihPenugasanPetugas ORDER BY j.mulai_at_utc ASC, j.id_jadwal ASC',
      [idPetugas],
    );
    return hasil.map(PenugasanPetugas.fromMap).toList(growable: false);
  }

  Future<
    ({
      PenugasanPetugas tugas,
      List<Map<String, Object?>> tim,
      List<AktivitasPengangkutan> aktivitas,
    })?
  >
  bukaPenugasanPetugas({required int idPetugas, required int idJadwal}) async {
    final db = await database;
    return db.transaction((txn) async {
      final hasil = await txn.rawQuery(
        '$_pilihPenugasanPetugas AND j.id_jadwal = ?',
        [idPetugas, idJadwal],
      );
      if (hasil.isEmpty) return null;

      final tim = await txn.rawQuery(
        '''
        SELECT p.nama, jp.peran_tugas
        FROM jadwal_petugas AS jp
        JOIN petugas AS p ON p.id_petugas = jp.id_petugas
        WHERE jp.id_jadwal = ?
        ORDER BY jp.peran_tugas DESC, p.nama ASC, p.id_petugas ASC
      ''',
        [idJadwal],
      );
      await txn.update(
        'notifikasi_petugas',
        {'dibaca_at_utc': DateTime.now().toUtc().toIso8601String()},
        where: 'id_jadwal = ? AND id_petugas = ? AND dibaca_at_utc IS NULL',
        whereArgs: [idJadwal, idPetugas],
      );
      final data = hasil.single;
      final aktivitas = await _ambilAktivitas(
        txn,
        data['id_laporan'] as int,
        idJadwal: idJadwal,
      );
      return (
        tugas: PenugasanPetugas.fromMap(data),
        tim: tim,
        aktivitas: aktivitas,
      );
    });
  }

  static const _pilihPenugasanPetugas = '''
    SELECT j.id_jadwal, j.id_laporan, j.mulai_at_utc, j.estimasi_selesai_at_utc, j.status_jadwal, j.catatan,
           l.kode_laporan, l.kecamatan, l.deskripsi_lokasi, l.deskripsi_laporan,
           l.latitude, l.longitude, jp.peran_tugas,
           CASE WHEN n.id_jadwal IS NOT NULL AND n.dibaca_at_utc IS NULL
                THEN 1 ELSE 0 END AS belum_dibaca
    FROM jadwal_petugas AS jp
    JOIN petugas AS p ON p.id_petugas = jp.id_petugas AND p.aktif = 1
    JOIN jadwal AS j ON j.id_jadwal = jp.id_jadwal
    JOIN laporan AS l ON l.id_laporan = j.id_laporan
    LEFT JOIN notifikasi_petugas AS n
      ON n.id_jadwal = jp.id_jadwal AND n.id_petugas = jp.id_petugas
    WHERE jp.id_petugas = ? AND j.aktif = 1
  ''';
  Future<List<KlarifikasiLaporan>> ambilKlarifikasiWarga({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    return _ambilKlarifikasi(db, idLaporan, idWarga);
  }

  Future<List<KlarifikasiLaporan>> _ambilKlarifikasi(
    DatabaseExecutor db,
    int idLaporan,
    int idWarga,
  ) async {
    final daftar = await db.rawQuery(
      '''
      SELECT k.*, vp.kebutuhan_klarifikasi, COALESCE(vt.hasil_revisi, vt.hasil) AS hasil_tindak_lanjut
      FROM klarifikasi AS k
      JOIN laporan AS l ON l.id_laporan = k.id_laporan AND l.id_warga = k.id_warga
      JOIN verifikasi AS vp ON vp.id_verifikasi = k.id_verifikasi_permintaan
      LEFT JOIN verifikasi AS vt ON vt.id_verifikasi = k.id_verifikasi_tindak_lanjut
      WHERE k.id_laporan = ? AND k.id_warga = ?
      ORDER BY k.id_klarifikasi DESC
    ''',
      [idLaporan, idWarga],
    );
    if (daftar.isEmpty) return const [];

    final foto = await db.rawQuery(
      '''
      SELECT f.id_klarifikasi, f.nama_berkas, f.data_foto
      FROM foto AS f
      JOIN klarifikasi AS k
        ON k.id_klarifikasi = f.id_klarifikasi AND k.id_laporan = f.id_laporan
      JOIN laporan AS l ON l.id_laporan = k.id_laporan AND l.id_warga = k.id_warga
      WHERE k.id_laporan = ? AND k.id_warga = ?
      ORDER BY f.id_foto ASC
    ''',
      [idLaporan, idWarga],
    );
    final bukti = <int, List<BuktiKlarifikasi>>{};
    for (final row in foto) {
      final id = row['id_klarifikasi'] as int;
      final data = (row['data_foto'] as List).cast<int>();
      (bukti[id] ??= []).add((
        nama: row['nama_berkas'] as String,
        bytes: Uint8List.fromList(data),
      ));
    }
    return [
      for (final row in daftar)
        KlarifikasiLaporan.fromMap(
          row,
          bukti[row['id_klarifikasi']] ?? const [],
        ),
    ];
  }

  Future<void> simpanKlarifikasi({
    required int idLaporan,
    required int idWarga,
    required int idPermintaan,
    required String penjelasan,
    required List<FotoLaporan> foto,
    LokasiKlarifikasi? lokasi,
  }) async {
    final teks = penjelasan.trim();
    final bukti = List<FotoLaporan>.of(foto);
    if (teks.isEmpty && bukti.isEmpty && lokasi == null) {
      throw const GalatKlarifikasi(
        'Tambahkan penjelasan, foto, atau koreksi lokasi.',
      );
    }
    if (teks.runes.length > 2000 || bukti.length > 3) {
      throw const GalatKlarifikasi(
        'Maksimal 2.000 karakter dan 3 foto per balasan.',
      );
    }
    if (lokasi != null &&
        (!lokasi.latitude.isFinite ||
            lokasi.latitude.abs() > 90 ||
            !lokasi.longitude.isFinite ||
            lokasi.longitude.abs() > 180 ||
            lokasi.kecamatan.trim().isEmpty ||
            lokasi.kecamatan.runes.length > 50 ||
            !const ['perangkat', 'peta'].contains(lokasi.metode) ||
            DateTime.tryParse(lokasi.dikonfirmasiUtc) == null ||
            lokasi.patokan.trim().runes.length < 5 ||
            lokasi.patokan.runes.length > 500)) {
      throw const GalatKlarifikasi(
        'Konfirmasi titik dan isi patokan lokasi 5–500 karakter.',
      );
    }
    for (final item in bukti) {
      if (item.idFoto != null ||
          item.idLaporan != null ||
          item.ukuranByte < 1 ||
          item.ukuranByte > FotoLaporan.maksimumUkuranByte ||
          (item.mimeType != 'image/jpeg' && item.mimeType != 'image/png')) {
        throw const GalatKlarifikasi(
          'Pilih foto baru berformat JPG atau PNG, maksimal 2 MB.',
        );
      }
    }

    final db = await database;
    await db.transaction((txn) async {
      final hasil = await txn.rawQuery(
        '''
        SELECT l.*
        FROM laporan AS l
        JOIN verifikasi AS v
          ON v.id_laporan = l.id_laporan AND v.id_verifikasi = l.id_verifikasi_terakhir
        JOIN warga AS w ON w.id_warga = l.id_warga AND w.aktif = 1
        WHERE l.id_laporan = ? AND l.id_warga = ? AND v.id_verifikasi = ?
          AND l.status_penanganan = ? AND COALESCE(v.hasil_revisi, v.hasil) IN (?, ?)
          AND NOT EXISTS (
            SELECT 1 FROM klarifikasi WHERE id_verifikasi_permintaan = v.id_verifikasi
          )
      ''',
        [
          idLaporan,
          idWarga,
          idPermintaan,
          HasilVerifikasi.belumDapatDipastikan.statusBaru,
          HasilVerifikasi.belumDapatDipastikan.label,
          HasilVerifikasi.belumDapatDipastikan.nilaiLama,
        ],
      );
      if (hasil.isEmpty) {
        throw const GalatKlarifikasi(
          'Permintaan sudah berubah atau sudah dijawab. Buka kembali detail laporan.',
        );
      }

      final row = hasil.single;
      final sekarang = DateTime.now().toUtc().toIso8601String();
      final id = await txn.insert('klarifikasi', {
        'id_laporan': idLaporan,
        'id_warga': idWarga,
        'id_verifikasi_permintaan': idPermintaan,
        'penjelasan': teks,
        'lokasi_awal': lokasi == null
            ? null
            : jsonEncode(LokasiKlarifikasi.fromMap(row).toMap()),
        'lokasi_usulan': lokasi == null ? null : jsonEncode(lokasi.toMap()),
        'dibuat_at_utc': sekarang,
      });
      for (final item in bukti) {
        await txn.insert('foto', {
          ...item.toMap(),
          'id_laporan': idLaporan,
          'sumber': 'Klarifikasi',
          'id_klarifikasi': id,
          'data_foto': Uint8List.fromList(item.dataFoto),
          'diunggah_at_utc': sekarang,
        });
      }

      final versi = row['versi'] as int;
      final diubah = await txn.update(
        'laporan',
        {'versi': versi + 1},
        where:
            'id_laporan = ? AND id_warga = ? AND versi = ? AND id_verifikasi_terakhir = ?',
        whereArgs: [idLaporan, idWarga, versi, idPermintaan],
      );
      if (diubah != 1) {
        throw const GalatKlarifikasi(
          'Laporan sudah berubah. Buka kembali detail laporan.',
        );
      }
    });
  }

  Future<void> simpanAktivitasPengangkutan({
    required int idJadwal,
    required int idPetugas,
    required TahapPengangkutan tahap,
    String catatan = '',
    required String kunciKirim,
    List<FotoLaporan> foto = const [],
  }) async {
    final teks = catatan.trim();
    final bukti = List<FotoLaporan>.of(foto);
    final mulai = tahap == TahapPengangkutan.mulai;
    final selesai = tahap == TahapPengangkutan.selesai;
    final tanggapan = tahap == TahapPengangkutan.tanggapan;
    final isi = teks.isNotEmpty
        ? teks
        : switch (tahap) {
            TahapPengangkutan.mulai =>
              'Petugas mulai mengerjakan pengangkutan.',
            TahapPengangkutan.tanggapan => 'Foto progres pengangkutan.',
            _ => '',
          };
    if (isi.isEmpty || isi.runes.length > 2000) {
      throw const GalatJadwal('Isi catatan dengan 1–2.000 karakter.');
    }
    if (kunciKirim.isEmpty || kunciKirim.length > 64) {
      throw const GalatJadwal('Coba buka kembali detail penugasan.');
    }
    if ((selesai || tanggapan) && (bukti.isEmpty || bukti.length > 3)) {
      throw GalatJadwal(
        selesai
            ? 'Sertakan 1–3 foto bukti penyelesaian.'
            : 'Sertakan 1–3 foto progres pengangkutan.',
      );
    }
    if (!selesai && !tanggapan && bukti.isNotEmpty) {
      throw const GalatJadwal('Kirim foto melalui aksi Kirim Foto Progres.');
    }
    for (final item in bukti) {
      if (item.idFoto != null ||
          item.idLaporan != null ||
          item.ukuranByte < 1 ||
          item.ukuranByte > FotoLaporan.maksimumUkuranByte ||
          (item.mimeType != 'image/jpeg' && item.mimeType != 'image/png')) {
        throw const GalatJadwal(
          'Gunakan foto baru JPG atau PNG maksimal 2 MB.',
        );
      }
    }

    final db = await database;
    await db.transaction((txn) async {
      final hasil = await txn.rawQuery(
        '''
        SELECT j.id_laporan, j.status_jadwal, jp.peran_tugas,
               l.id_warga, l.kode_laporan, l.status_penanganan, l.versi
        FROM jadwal_petugas AS jp
        JOIN petugas AS p ON p.id_petugas = jp.id_petugas AND p.aktif = 1
        JOIN jadwal AS j ON j.id_jadwal = jp.id_jadwal AND j.aktif = 1
        JOIN laporan AS l ON l.id_laporan = j.id_laporan
        WHERE jp.id_jadwal = ? AND jp.id_petugas = ?
      ''',
        [idJadwal, idPetugas],
      );
      if (hasil.isEmpty) {
        throw const GalatJadwal(
          'Penugasan sudah berubah atau bukan milik akun Anda.',
        );
      }

      final tugas = hasil.single;
      final idLaporan = tugas['id_laporan'] as int;
      final statusJadwal = tugas['status_jadwal'] as String;
      final statusLaporan = tugas['status_penanganan'] as String;
      final waktu = DateTime.now().toUtc().toIso8601String();
      final tabel = tanggapan ? 'tanggapan' : 'pembaruan_pekerjaan';
      final pernahDikirim = await txn.query(
        tabel,
        where: 'id_jadwal = ? AND id_petugas = ? AND kunci_kirim = ?',
        whereArgs: [idJadwal, idPetugas, kunciKirim],
        limit: 1,
      );
      if (pernahDikirim.isNotEmpty) return;

      final statusWajib = mulai ? 'Terjadwal' : 'Dikerjakan';
      if (statusJadwal != statusWajib || statusLaporan != 'Diproses') {
        throw const GalatJadwal(
          'Tahap tugas sudah berubah. Muat ulang penugasan.',
        );
      }
      if (selesai && tugas['peran_tugas'] != 'Koordinator') {
        throw const GalatJadwal(
          'Hanya koordinator yang dapat menyelesaikan tugas.',
        );
      }

      final int idAktivitas;
      if (tanggapan) {
        idAktivitas = await txn.insert('tanggapan', {
          'id_laporan': idLaporan,
          'id_jadwal': idJadwal,
          'id_petugas': idPetugas,
          'isi': isi,
          'dibuat_at_utc': waktu,
          'kunci_kirim': kunciKirim,
        });
      } else {
        idAktivitas = await txn.insert('pembaruan_pekerjaan', {
          'id_jadwal': idJadwal,
          'id_petugas': idPetugas,
          'tahap': tahap.label,
          'catatan': isi,
          'dicatat_at_utc': waktu,
          'selesai_at_utc': selesai ? waktu : null,
          'kunci_kirim': kunciKirim,
        });
      }
      for (final item in bukti) {
        await txn.insert('foto', {
          ...item.toMap(),
          'id_laporan': idLaporan,
          'sumber': 'Petugas',
          if (tanggapan)
            'id_tanggapan': idAktivitas
          else
            'id_pembaruan': idAktivitas,
          'data_foto': Uint8List.fromList(item.dataFoto),
          'diunggah_at_utc': waktu,
        });
      }
      if (tanggapan) {
        final potongan = isi.runes.length > 200
            ? '${String.fromCharCodes(isi.runes.take(200))}…'
            : isi;
        await txn.insert('notifikasi_warga', {
          'id_warga': tugas['id_warga'],
          'id_laporan': idLaporan,
          'event_key': 'tanggapan:$idAktivitas',
          'jenis': 'tanggapan',
          'judul': 'Foto progres pengangkutan',
          'ringkasan': '${tugas['kode_laporan']} · $potongan',
          'dibuat_at_utc': waktu,
        });
        return;
      }

      final diubah = await txn.update(
        'jadwal',
        {'status_jadwal': selesai ? 'Selesai' : 'Dikerjakan'},
        where: 'id_jadwal = ? AND aktif = ? AND status_jadwal = ?',
        whereArgs: [idJadwal, 1, statusJadwal],
      );
      if (diubah != 1) throw const GalatJadwal('Jadwal sudah berubah.');
      if (!selesai) return;

      final versi = tugas['versi'] as int;
      final laporanDiubah = await txn.update(
        'laporan',
        {
          'status_penanganan': 'Selesai',
          'selesai_at_utc': waktu,
          'versi': versi + 1,
        },
        where: 'id_laporan = ? AND versi = ? AND status_penanganan = ?',
        whereArgs: [idLaporan, versi, 'Diproses'],
      );
      if (laporanDiubah != 1) throw const GalatJadwal('Laporan sudah berubah.');
      final event = 'pembaruan:$idAktivitas:selesai';
      await txn.insert('riwayat_status', {
        'id_laporan': idLaporan,
        'id_jadwal': idJadwal,
        'id_pembaruan': idAktivitas,
        'status_lama': 'Diproses',
        'status_baru': 'Selesai',
        'event_key': event,
        'diubah_at_utc': waktu,
      });
      await txn.insert('notifikasi_warga', {
        'id_warga': tugas['id_warga'],
        'id_laporan': idLaporan,
        'event_key': event,
        'jenis': 'status',
        'judul': 'Pengangkutan selesai',
        'ringkasan':
            '${tugas['kode_laporan']} · Lihat catatan dan foto bukti di detail laporan.',
        'dibuat_at_utc': waktu,
      });
    });
  }

  Future<List<AktivitasPengangkutan>> ambilAktivitasWarga({
    required int idLaporan,
    required int idWarga,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final pemilik = await txn.query(
        'laporan',
        columns: ['id_laporan'],
        where: 'id_laporan = ? AND id_warga = ?',
        whereArgs: [idLaporan, idWarga],
        limit: 1,
      );
      if (pemilik.isEmpty) return const <AktivitasPengangkutan>[];
      return _ambilAktivitas(txn, idLaporan);
    });
  }

  Future<List<AktivitasPengangkutan>> _ambilAktivitas(
    DatabaseExecutor db,
    int idLaporan, {
    int? idJadwal,
  }) async {
    final data = await db.rawQuery(
      '''
      SELECT 'pembaruan' AS jenis, b.id_pembaruan AS id_aktivitas,
             b.tahap, b.catatan, b.dicatat_at_utc AS waktu_utc, p.nama AS nama_petugas
      FROM pembaruan_pekerjaan AS b
      JOIN jadwal AS j ON j.id_jadwal = b.id_jadwal
      JOIN petugas AS p ON p.id_petugas = b.id_petugas
      WHERE j.id_laporan = ? AND (? IS NULL OR j.id_jadwal = ?)
      UNION ALL
      SELECT 'tanggapan', t.id_tanggapan, 'Tanggapan', t.isi, t.dibuat_at_utc, p.nama
      FROM tanggapan AS t
      JOIN petugas AS p ON p.id_petugas = t.id_petugas
      WHERE t.id_laporan = ? AND (? IS NULL OR t.id_jadwal = ?)
      ORDER BY waktu_utc DESC, id_aktivitas DESC
    ''',
      [idLaporan, idJadwal, idJadwal, idLaporan, idJadwal, idJadwal],
    );

    final foto = await db.rawQuery(
      '''
      SELECT CASE WHEN t.id_tanggapan IS NULL THEN 'pembaruan' ELSE 'tanggapan' END AS jenis,
             COALESCE(b.id_pembaruan, t.id_tanggapan) AS id_aktivitas,
             f.nama_berkas, f.data_foto
      FROM foto AS f
      LEFT JOIN pembaruan_pekerjaan AS b ON b.id_pembaruan = f.id_pembaruan
      LEFT JOIN tanggapan AS t ON t.id_tanggapan = f.id_tanggapan AND t.id_laporan = f.id_laporan
      JOIN jadwal AS j ON j.id_jadwal = COALESCE(b.id_jadwal, t.id_jadwal)
                       AND j.id_laporan = f.id_laporan
      WHERE f.id_laporan = ? AND (? IS NULL OR j.id_jadwal = ?)
      ORDER BY f.id_foto
    ''',
      [idLaporan, idJadwal, idJadwal],
    );
    final bukti = <(String, int), List<FotoAktivitasPengangkutan>>{};
    for (final row in foto) {
      final kunci = (row['jenis'] as String, row['id_aktivitas'] as int);
      (bukti[kunci] ??= []).add((
        nama: row['nama_berkas'] as String,
        bytes: Uint8List.fromList((row['data_foto'] as List).cast<int>()),
      ));
    }
    return [
      for (final row in data)
        AktivitasPengangkutan.fromMap(
          row,
          bukti[(row['jenis'] as String, row['id_aktivitas'] as int)] ??
              const [],
        ),
    ];
  }

  Future<void> _buatTabelVersi9(Database db) async {
    for (final perintah in _skemaVersi9) {
      await db.execute(perintah);
    }
  }

  static const List<String> _skemaVersi9 = [
    '''
    ALTER TABLE foto ADD COLUMN id_tanggapan INTEGER REFERENCES tanggapan(id_tanggapan)
      CHECK (id_tanggapan IS NULL OR (
        id_pembaruan IS NULL AND id_klarifikasi IS NULL AND sumber = 'Petugas'
      ))
    ''',
  ];

  Future<void> _buatTabelVersi8(Database db) async {
    for (final perintah in _skemaVersi8) {
      await db.execute(perintah);
    }
  }

  static const List<String> _skemaVersi8 = [
    '''
    CREATE TABLE pembaruan_pekerjaan (
      id_pembaruan INTEGER PRIMARY KEY AUTOINCREMENT,
      id_jadwal INTEGER NOT NULL,
      id_petugas INTEGER NOT NULL,
      tahap TEXT NOT NULL CHECK (tahap IN ('Mulai', 'Perkembangan', 'Selesai')),
      catatan TEXT NOT NULL CHECK (length(trim(catatan)) BETWEEN 1 AND 2000),
      dicatat_at_utc TEXT NOT NULL,
      selesai_at_utc TEXT,
      kunci_kirim TEXT NOT NULL,
      FOREIGN KEY (id_jadwal, id_petugas) REFERENCES jadwal_petugas(id_jadwal, id_petugas),
      CHECK ((tahap = 'Selesai') = (selesai_at_utc IS NOT NULL)),
      UNIQUE (id_jadwal, id_petugas, kunci_kirim)
    )
    ''',
    '''
    CREATE UNIQUE INDEX idx_satu_penyelesaian ON pembaruan_pekerjaan(id_jadwal)
    WHERE tahap = 'Selesai'
    ''',
    '''
    CREATE TABLE tanggapan (
      id_tanggapan INTEGER PRIMARY KEY AUTOINCREMENT,
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      id_jadwal INTEGER NOT NULL,
      id_petugas INTEGER NOT NULL,
      isi TEXT NOT NULL CHECK (length(trim(isi)) BETWEEN 1 AND 2000),
      dibuat_at_utc TEXT NOT NULL,
      kunci_kirim TEXT NOT NULL,
      FOREIGN KEY (id_jadwal, id_petugas) REFERENCES jadwal_petugas(id_jadwal, id_petugas),
      UNIQUE (id_jadwal, id_petugas, kunci_kirim)
    )
    ''',
    '''
    CREATE INDEX idx_tanggapan_laporan ON tanggapan(id_laporan, id_jadwal)
    ''',
    '''
    ALTER TABLE foto ADD COLUMN id_pembaruan INTEGER REFERENCES pembaruan_pekerjaan(id_pembaruan)
    ''',
    '''
    ALTER TABLE riwayat_status ADD COLUMN id_pembaruan INTEGER REFERENCES pembaruan_pekerjaan(id_pembaruan)
    ''',
  ];

  Future<void> _buatTabelVersi7(Database db) async {
    for (final perintah in _skemaVersi7) {
      await db.execute(perintah);
    }
  }

  static const List<String> _skemaVersi7 = [
    '''
    CREATE TABLE klarifikasi (
      id_klarifikasi INTEGER PRIMARY KEY AUTOINCREMENT,
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      id_warga INTEGER NOT NULL REFERENCES warga(id_warga),
      id_verifikasi_permintaan INTEGER NOT NULL UNIQUE,
      penjelasan TEXT NOT NULL DEFAULT '' CHECK (length(penjelasan) <= 2000),
      lokasi_awal TEXT,
      lokasi_usulan TEXT,
      dibuat_at_utc TEXT NOT NULL,
      id_verifikasi_tindak_lanjut INTEGER UNIQUE,
      FOREIGN KEY (id_laporan, id_verifikasi_permintaan)
        REFERENCES verifikasi(id_laporan, id_verifikasi),
      FOREIGN KEY (id_laporan, id_verifikasi_tindak_lanjut)
        REFERENCES verifikasi(id_laporan, id_verifikasi),
      CHECK ((lokasi_awal IS NULL) = (lokasi_usulan IS NULL))
    )
    ''',
    '''
    CREATE INDEX idx_klarifikasi_laporan ON klarifikasi(id_laporan, id_klarifikasi)
    ''',
    '''
    ALTER TABLE foto ADD COLUMN id_klarifikasi INTEGER REFERENCES klarifikasi(id_klarifikasi)
    ''',
  ];

  Future<void> _buatTabelVersi6(Database db) async {
    for (final perintah in _skemaVersi6) {
      await db.execute(perintah);
    }
  }

  static const List<String> _skemaVersi6 = [
    '''
    CREATE TABLE jadwal (
      id_jadwal INTEGER PRIMARY KEY AUTOINCREMENT,
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      id_admin INTEGER NOT NULL REFERENCES admin(id_admin),
      mulai_at_utc TEXT NOT NULL,
      estimasi_selesai_at_utc TEXT NOT NULL CHECK (estimasi_selesai_at_utc > mulai_at_utc),
      aktif INTEGER NOT NULL DEFAULT 1 CHECK (aktif IN (0, 1)),
      status_jadwal TEXT NOT NULL DEFAULT 'Terjadwal'
        CHECK (status_jadwal IN ('Terjadwal', 'Dikerjakan', 'Selesai', 'Dibatalkan')),
      catatan TEXT NOT NULL DEFAULT '' CHECK (length(catatan) <= 2000),
      dibuat_at_utc TEXT NOT NULL
    )
    ''',
    '''
    CREATE UNIQUE INDEX idx_satu_jadwal_aktif ON jadwal(id_laporan) WHERE aktif = 1
    ''',
    '''
    CREATE TABLE jadwal_petugas (
      id_jadwal INTEGER NOT NULL REFERENCES jadwal(id_jadwal),
      id_petugas INTEGER NOT NULL REFERENCES petugas(id_petugas),
      peran_tugas TEXT NOT NULL CHECK (peran_tugas IN ('Koordinator', 'Anggota')),
      PRIMARY KEY (id_jadwal, id_petugas)
    )
    ''',
    '''
    CREATE UNIQUE INDEX idx_satu_koordinator ON jadwal_petugas(id_jadwal)
    WHERE peran_tugas = 'Koordinator'
    ''',
    '''
    CREATE INDEX idx_jadwal_petugas ON jadwal_petugas(id_petugas, id_jadwal)
    ''',
    '''
    CREATE TABLE notifikasi_petugas (
      id_jadwal INTEGER NOT NULL,
      id_petugas INTEGER NOT NULL,
      dibuat_at_utc TEXT NOT NULL,
      dibaca_at_utc TEXT,
      PRIMARY KEY (id_jadwal, id_petugas),
      FOREIGN KEY (id_jadwal, id_petugas) REFERENCES jadwal_petugas(id_jadwal, id_petugas)
    )
    ''',
    '''
    ALTER TABLE riwayat_status ADD COLUMN id_jadwal INTEGER REFERENCES jadwal(id_jadwal)
    ''',
  ];

  Future<void> _buatTabelVersi5(Database db) async {
    for (final perintah in _skemaVersi5) {
      await db.execute(perintah);
    }
  }

  static const List<String> _skemaVersi5 = [
    '''
    CREATE TABLE checklist_verifikasi (
      id_checklist INTEGER PRIMARY KEY AUTOINCREMENT,
      id_verifikasi INTEGER NOT NULL REFERENCES verifikasi(id_verifikasi),
      indikator TEXT NOT NULL CHECK (indikator IN (
        'foto', 'deskripsi', 'lokasi', 'waktu', 'duplikasi', 'sumber'
      )),
      hasil TEXT NOT NULL CHECK (hasil IN (
        'Sesuai', 'Tidak sesuai', 'Belum dapat dinilai'
      )),
      temuan TEXT NOT NULL DEFAULT '' CHECK (length(temuan) <= 2000),
      UNIQUE (id_verifikasi, indikator)
    )
    ''',
    '''
    ALTER TABLE riwayat_status
    ADD COLUMN id_verifikasi INTEGER REFERENCES verifikasi(id_verifikasi)
    ''',
  ];

  Future<void> _buatTabelVersi4(Database db) async {
    await db.execute('''
      CREATE TABLE petugas (
        id_petugas INTEGER PRIMARY KEY,
        nama TEXT NOT NULL,
        aktif INTEGER NOT NULL DEFAULT 1 CHECK (aktif IN (0, 1))
      )
    ''');
    await db.insert('petugas', {'id_petugas': 1, 'nama': 'Petugas A'});
    await db.insert('petugas', {'id_petugas': 2, 'nama': 'Petugas B'});
  }

  Future<void> _buatTabelVersi3(Database db) async {
    for (final perintah in _skemaVersi3) {
      await db.execute(perintah);
    }
    // Migrasi menambahkan notifikasi kirim untuk laporan lokal yang sudah ada,
    // tanpa menghapus laporan, foto, jenis sampah, atau riwayat sebelumnya.
    await db.execute('''
      INSERT OR IGNORE INTO notifikasi_warga
        (id_warga, id_laporan, event_key, jenis, judul, ringkasan, dibuat_at_utc)
      SELECT id_warga, id_laporan, 'laporan:' || id_laporan || ':dibuat',
        'pengiriman', 'Laporan berhasil dikirim',
        'Laporan tersimpan. Status saat pengiriman: Baru.', dibuat_at_utc
      FROM laporan ORDER BY id_laporan ASC
    ''');
  }

  static const List<String> _skemaVersi3 = [
    '''
    CREATE TABLE notifikasi_warga (
      id_notifikasi INTEGER PRIMARY KEY AUTOINCREMENT,
      id_warga INTEGER NOT NULL REFERENCES warga(id_warga),
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      event_key TEXT NOT NULL,
      jenis TEXT NOT NULL CHECK (jenis IN ('pengiriman', 'status', 'tanggapan')),
      judul TEXT NOT NULL CHECK (length(trim(judul)) > 0),
      ringkasan TEXT NOT NULL,
      dibuat_at_utc TEXT NOT NULL,
      dibaca_at_utc TEXT,
      UNIQUE (id_warga, event_key)
    )
    ''',
    '''
    CREATE INDEX idx_notifikasi_warga
    ON notifikasi_warga(id_warga, id_notifikasi DESC)
    ''',
  ];

  Future<void> _isiReferensiDemo(Database db) async {
    await db.insert('warga', {'id_warga': 1, 'nama': 'Annisa'});
    await db.insert('warga', {'id_warga': 2, 'nama': 'Warga Demo'});
    await db.insert('admin', {'id_admin': 1, 'nama': 'Admin Demo'});
    final data = await rootBundle.loadString('assets/kategori_awal.json');
    final kategori = jsonDecode(data) as List<dynamic>;
    for (final row in kategori) {
      await db.insert('kategori', (row as Map).cast<String, Object?>());
    }
  }

  Future<void> _buatTabelVersi2(Database db) async {
    for (final perintah in _skemaVersi2) {
      await db.execute(perintah);
    }

    const namaJenis = [
      'Organik',
      'Plastik',
      'Kertas',
      'Logam',
      'Kaca',
      'Residu',
    ];
    for (var i = 0; i < namaJenis.length; i++) {
      await db.insert('jenis_sampah', {
        'id_jenis': i + 1,
        'nama_jenis': namaJenis[i],
      });
    }
  }

  static const List<String> _skemaVersi1 = [
    '''
    CREATE TABLE warga (
      id_warga INTEGER PRIMARY KEY,
      nama TEXT NOT NULL,
      aktif INTEGER NOT NULL DEFAULT 1 CHECK (aktif IN (0, 1))
    )
    ''',
    '''
    CREATE TABLE admin (
      id_admin INTEGER PRIMARY KEY,
      nama TEXT NOT NULL,
      aktif INTEGER NOT NULL DEFAULT 1 CHECK (aktif IN (0, 1))
    )
    ''',
    '''
    CREATE TABLE kategori (
      id_kategori INTEGER PRIMARY KEY,
      nama_kategori TEXT NOT NULL UNIQUE,
      aktif INTEGER NOT NULL DEFAULT 1 CHECK (aktif IN (0, 1))
    )
    ''',
    '''
    CREATE TABLE laporan (
      id_laporan INTEGER PRIMARY KEY AUTOINCREMENT,
      kode_laporan TEXT NOT NULL UNIQUE,
      id_warga INTEGER NOT NULL REFERENCES warga(id_warga),
      id_kategori INTEGER NOT NULL REFERENCES kategori(id_kategori),
      deskripsi_laporan TEXT NOT NULL
        CHECK (length(trim(deskripsi_laporan)) BETWEEN 10 AND 2000),
      deskripsi_lokasi TEXT NOT NULL
        CHECK (length(trim(deskripsi_lokasi)) BETWEEN 5 AND 500),
      kecamatan TEXT NOT NULL CHECK (length(trim(kecamatan)) > 0),
      latitude REAL NOT NULL CHECK (latitude BETWEEN -90 AND 90),
      longitude REAL NOT NULL CHECK (longitude BETWEEN -180 AND 180),
      metode_lokasi TEXT NOT NULL
        CHECK (metode_lokasi IN ('perangkat', 'peta')),
      lokasi_dikonfirmasi_at_utc TEXT NOT NULL,
      status_penanganan TEXT NOT NULL DEFAULT 'Baru'
        CHECK (status_penanganan IN (
          'Baru', 'Diterima', 'Diproses', 'Menunggu klarifikasi',
          'Ditutup sebagai duplikat', 'Ditolak', 'Selesai'
        )),
      dibuat_at_utc TEXT NOT NULL,
      diterima_at_utc TEXT,
      selesai_at_utc TEXT,
      id_laporan_utama INTEGER REFERENCES laporan(id_laporan),
      id_verifikasi_terakhir INTEGER,
      kunci_kirim TEXT NOT NULL
        CHECK (length(trim(kunci_kirim)) BETWEEN 1 AND 64),
      versi INTEGER NOT NULL DEFAULT 1 CHECK (versi >= 1),
      UNIQUE (id_warga, kunci_kirim),
      FOREIGN KEY (id_laporan, id_verifikasi_terakhir)
        REFERENCES verifikasi(id_laporan, id_verifikasi),
      CHECK (id_laporan_utama IS NULL OR id_laporan_utama <> id_laporan),
      CHECK (
        status_penanganan <> 'Ditutup sebagai duplikat' OR
        id_laporan_utama IS NOT NULL
      ),
      CHECK (
        status_penanganan NOT IN ('Diterima', 'Diproses', 'Selesai') OR
        diterima_at_utc IS NOT NULL
      ),
      CHECK (status_penanganan <> 'Selesai' OR selesai_at_utc IS NOT NULL)
    )
    ''',
    '''
    CREATE TABLE verifikasi (
      id_verifikasi INTEGER PRIMARY KEY AUTOINCREMENT,
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      id_admin INTEGER NOT NULL REFERENCES admin(id_admin),
      hasil TEXT NOT NULL CHECK (hasil IN (
        'Valid', 'Perlu verifikasi', 'Duplikat', 'Tidak valid'
      )),
      alasan TEXT NOT NULL
        CHECK (length(trim(alasan)) BETWEEN 1 AND 2000),
      catatan TEXT NOT NULL DEFAULT '',
      kebutuhan_klarifikasi TEXT,
      diperiksa_at_utc TEXT NOT NULL,
      UNIQUE (id_laporan, id_verifikasi),
      CHECK (
        hasil <> 'Perlu verifikasi' OR
        (
          kebutuhan_klarifikasi IS NOT NULL AND
          length(trim(kebutuhan_klarifikasi)) > 0
        )
      )
    )
    ''',
    '''
    CREATE TABLE riwayat_status (
      id_riwayat INTEGER PRIMARY KEY AUTOINCREMENT,
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      status_lama TEXT,
      status_baru TEXT NOT NULL,
      event_key TEXT NOT NULL UNIQUE,
      diubah_at_utc TEXT NOT NULL
    )
    ''',
    '''
    CREATE INDEX idx_laporan_warga
    ON laporan(id_warga, id_laporan DESC)
    ''',
    '''
    CREATE INDEX idx_riwayat_laporan
    ON riwayat_status(id_laporan, id_riwayat)
    ''',
  ];

  static const List<String> _skemaVersi2 = [
    '''
    CREATE TABLE jenis_sampah (
      id_jenis INTEGER PRIMARY KEY,
      nama_jenis TEXT NOT NULL UNIQUE,
      aktif INTEGER NOT NULL DEFAULT 1 CHECK (aktif IN (0, 1))
    )
    ''',
    '''
    CREATE TABLE laporan_jenis (
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      id_jenis INTEGER NOT NULL REFERENCES jenis_sampah(id_jenis),
      PRIMARY KEY (id_laporan, id_jenis)
    )
    ''',
    '''
    CREATE TABLE foto (
      id_foto INTEGER PRIMARY KEY AUTOINCREMENT,
      id_laporan INTEGER NOT NULL REFERENCES laporan(id_laporan),
      sumber TEXT NOT NULL
        CHECK (sumber IN ('Warga', 'Petugas', 'Klarifikasi')),
      nama_berkas TEXT NOT NULL CHECK (length(trim(nama_berkas)) > 0),
      mime_type TEXT NOT NULL
        CHECK (mime_type IN ('image/jpeg', 'image/png')),
      ukuran_byte INTEGER NOT NULL
        CHECK (ukuran_byte BETWEEN 1 AND 2000000),
      sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
      data_foto BLOB NOT NULL
        CHECK (typeof(data_foto) = 'blob' AND length(data_foto) = ukuran_byte),
      diunggah_at_utc TEXT NOT NULL
    )
    ''',
    '''
    CREATE INDEX idx_foto_laporan
    ON foto(id_laporan, id_foto)
    ''',
  ];
}