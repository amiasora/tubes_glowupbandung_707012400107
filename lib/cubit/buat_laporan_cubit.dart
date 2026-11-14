import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../db/database_helper.dart';
import '../models/foto_laporan.dart';
import '../models/laporan_sampah.dart';
import '../models/referensi_laporan.dart';
import '../models/titik_laporan.dart';
import '../services/layanan_foto.dart';
import '../services/pemeriksaan_foto.dart';

const _tetap = Object();

class BuatLaporanState {
  BuatLaporanState({
    required this.idWarga,
    required this.kunciKirim,
    this.namaWarga = '',
    List<KategoriLaporan> daftarKategori = const [],
    List<JenisSampah> daftarJenisSampah = const [],
    this.deskripsiLaporan = '',
    this.deskripsiLokasi = '',
    this.idKategori,
    Set<int> jenisDipilih = const <int>{},
    List<FotoLaporan> foto = const [],
    this.lokasi,
    this.referensiSiap = false,
    this.memuatReferensi = false,
    this.memprosesFoto = false,
    this.menyimpan = false,
    this.pesanError,
    this.hasilSimpan,
  }) : daftarKategori = List<KategoriLaporan>.unmodifiable(daftarKategori),
       daftarJenisSampah = List<JenisSampah>.unmodifiable(daftarJenisSampah),
       jenisDipilih = Set<int>.unmodifiable(jenisDipilih),
       foto = List<FotoLaporan>.unmodifiable(foto);

  final int idWarga;
  final String kunciKirim;
  final String namaWarga;
  final List<KategoriLaporan> daftarKategori;
  final List<JenisSampah> daftarJenisSampah;
  final String deskripsiLaporan;
  final String deskripsiLokasi;
  final int? idKategori;
  final Set<int> jenisDipilih;
  final List<FotoLaporan> foto;
  final TitikLaporan? lokasi;
  final bool referensiSiap;
  final bool memuatReferensi;
  final bool memprosesFoto;
  final bool menyimpan;
  final String? pesanError;
  final LaporanSampah? hasilSimpan;

  bool get sibuk => memuatReferensi || memprosesFoto || menyimpan;

  String? get pesanValidasi {
    if (!referensiSiap || namaWarga.trim().isEmpty) {
      return 'Data pilihan belum siap. Muat ulang terlebih dahulu.';
    }

    final panjangDeskripsi = deskripsiLaporan.trim().runes.length;
    if (panjangDeskripsi < 10 || panjangDeskripsi > 2000) {
      return 'Deskripsi laporan harus berisi 10 sampai 2.000 karakter.';
    }
    if (foto.length != 3) {
      return 'Sertakan tepat 3 foto laporan.';
    }
    if (idKategori == null ||
        !daftarKategori.any(
          (item) => item.idKategori == idKategori && item.aktif,
        )) {
      return 'Pilih kategori laporan yang tersedia.';
    }

    final jenisAktif = daftarJenisSampah
        .where((item) => item.aktif)
        .map((item) => item.idJenis)
        .toSet();
    if (jenisDipilih.isEmpty || !jenisDipilih.every(jenisAktif.contains)) {
      return 'Pilih minimal satu jenis sampah yang tersedia.';
    }
    if (lokasi == null) {
      return 'Pilih dan konfirmasi titik lokasi kejadian.';
    }

    final panjangLokasi = deskripsiLokasi.trim().runes.length;
    if (panjangLokasi != 0 && (panjangLokasi < 5 || panjangLokasi > 500)) {
      return 'Jika diisi, patokan harus berisi 5 sampai 500 karakter.';
    }
    return null;
  }

  bool get bolehKirim => !sibuk && hasilSimpan == null && pesanValidasi == null;

  // Penanda _tetap membedakan nilai yang tidak diubah dan nilai
  // nullable yang sengaja dikosongkan, misalnya lokasi: null.
  BuatLaporanState copyWith({
    String? namaWarga,
    List<KategoriLaporan>? daftarKategori,
    List<JenisSampah>? daftarJenisSampah,
    String? deskripsiLaporan,
    String? deskripsiLokasi,
    Object? idKategori = _tetap,
    Set<int>? jenisDipilih,
    List<FotoLaporan>? foto,
    Object? lokasi = _tetap,
    bool? referensiSiap,
    bool? memuatReferensi,
    bool? memprosesFoto,
    bool? menyimpan,
    Object? pesanError = _tetap,
    Object? hasilSimpan = _tetap,
  }) {
    return BuatLaporanState(
      idWarga: idWarga,
      kunciKirim: kunciKirim,
      namaWarga: namaWarga ?? this.namaWarga,
      daftarKategori: daftarKategori ?? this.daftarKategori,
      daftarJenisSampah: daftarJenisSampah ?? this.daftarJenisSampah,
      deskripsiLaporan: deskripsiLaporan ?? this.deskripsiLaporan,
      deskripsiLokasi: deskripsiLokasi ?? this.deskripsiLokasi,
      idKategori: identical(idKategori, _tetap)
          ? this.idKategori
          : idKategori as int?,
      jenisDipilih: jenisDipilih ?? this.jenisDipilih,
      foto: foto ?? this.foto,
      lokasi: identical(lokasi, _tetap) ? this.lokasi : lokasi as TitikLaporan?,
      referensiSiap: referensiSiap ?? this.referensiSiap,
      memuatReferensi: memuatReferensi ?? this.memuatReferensi,
      memprosesFoto: memprosesFoto ?? this.memprosesFoto,
      menyimpan: menyimpan ?? this.menyimpan,
      pesanError: identical(pesanError, _tetap)
          ? this.pesanError
          : pesanError as String?,
      hasilSimpan: identical(hasilSimpan, _tetap)
          ? this.hasilSimpan
          : hasilSimpan as LaporanSampah?,
    );
  }
}

class BuatLaporanCubit extends Cubit<BuatLaporanState> {
  BuatLaporanCubit({
    required int idWarga,
    DatabaseHelper? databaseHelper,
    LayananFoto? layananFoto,
  }) : _database = databaseHelper ?? DatabaseHelper.instance,
       _layananFoto = layananFoto ?? const LayananFoto(),
       super(BuatLaporanState(idWarga: idWarga, kunciKirim: _buatKunciKirim()));

  final DatabaseHelper _database;
  final LayananFoto _layananFoto;
  Object? _galatTerakhir;

  // Dapat diperiksa melalui debugger tanpa menampilkan SQL kepada pengguna.
  Object? get galatTerakhir => _galatTerakhir;

  bool get _bolehUbah => !state.sibuk && state.hasilSimpan == null;

  Future<void> muatReferensi() async {
    if (isClosed || state.sibuk || state.hasilSimpan != null) return;

    _galatTerakhir = null;
    emit(
      state.copyWith(
        memuatReferensi: true,
        referensiSiap: false,
        pesanError: null,
      ),
    );

    try {
      final kategori = await _database.ambilKategoriAktif();
      final jenis = await _database.ambilJenisSampahAktif();
      final warga = await _database.ambilWargaAktif();

      Map<String, Object?>? pemilik;
      for (final item in warga) {
        if (item['id_warga'] == state.idWarga) {
          pemilik = item;
          break;
        }
      }

      if (pemilik == null) {
        throw StateError('Akun warga tidak tersedia atau tidak aktif.');
      }
      if (kategori.isEmpty || jenis.isEmpty) {
        throw StateError('Kategori atau jenis sampah belum tersedia.');
      }
      if (isClosed) return;

      final kategoriMasihAda = kategori.any(
        (item) => item.idKategori == state.idKategori,
      );
      final jenisTersedia = jenis.map((item) => item.idJenis).toSet();

      emit(
        state.copyWith(
          namaWarga: pemilik['nama'] as String,
          daftarKategori: kategori,
          daftarJenisSampah: jenis,
          idKategori: kategoriMasihAda ? state.idKategori : null,
          jenisDipilih: state.jenisDipilih
              .where(jenisTersedia.contains)
              .toSet(),
          memuatReferensi: false,
          referensiSiap: true,
          pesanError: null,
        ),
      );
    } catch (galat) {
      if (isClosed) return;
      emit(
        state.copyWith(
          memuatReferensi: false,
          referensiSiap: false,
          pesanError: _pesanGalat(
            galat,
            'Data pilihan belum dapat dimuat. Coba muat ulang.',
          ),
        ),
      );
    }
  }

  void ubahDeskripsi(String nilai) {
    if (isClosed || !_bolehUbah || nilai == state.deskripsiLaporan) return;
    emit(state.copyWith(deskripsiLaporan: nilai, pesanError: null));
  }

  void ubahDeskripsiLokasi(String nilai) {
    if (isClosed || !_bolehUbah || nilai == state.deskripsiLokasi) return;
    emit(state.copyWith(deskripsiLokasi: nilai, pesanError: null));
  }

  void pilihKategori(int? idKategori) {
    if (isClosed || !_bolehUbah) return;
    if (idKategori != null &&
        !state.daftarKategori.any(
          (item) => item.idKategori == idKategori && item.aktif,
        )) {
      emit(state.copyWith(pesanError: 'Kategori tidak tersedia.'));
      return;
    }
    emit(state.copyWith(idKategori: idKategori, pesanError: null));
  }

  void ubahJenisSampah(int idJenis, bool dipilih) {
    if (isClosed || !_bolehUbah) return;
    if (!state.daftarJenisSampah.any(
      (item) => item.idJenis == idJenis && item.aktif,
    )) {
      emit(state.copyWith(pesanError: 'Jenis sampah tidak tersedia.'));
      return;
    }

    final pilihan = Set<int>.of(state.jenisDipilih);
    if (dipilih) {
      pilihan.add(idJenis);
    } else {
      pilihan.remove(idJenis);
    }
    emit(state.copyWith(jenisDipilih: pilihan, pesanError: null));
  }

  void tetapkanLokasi(TitikLaporan lokasi) {
    if (isClosed || !_bolehUbah) return;
    emit(state.copyWith(lokasi: lokasi, pesanError: null));
  }

  void hapusLokasi() {
    if (isClosed || !_bolehUbah) return;
    emit(state.copyWith(lokasi: null, pesanError: null));
  }

  Future<void> tambahFoto() async {
    if (isClosed || !_bolehUbah) return;
    if (state.foto.length >= 3) {
      emit(state.copyWith(pesanError: 'Maksimal 3 foto untuk satu laporan.'));
      return;
    }

    _galatTerakhir = null;
    final kapasitas = 3 - state.foto.length;
    emit(state.copyWith(memprosesFoto: true, pesanError: null));

    try {
      final tambahan = await _layananFoto.pilihFoto(
        kapasitasTersisa: kapasitas,
      );
      if (isClosed) return;
      final semua = [...state.foto, ...tambahan];
      final hasil = await PemeriksaanFoto.bandingkan(semua);
      final peringatan = PemeriksaanFoto.pesanFotoIdentik(hasil);
      if (peringatan != null) throw FormatException(peringatan);
      if (isClosed) return;

      emit(state.copyWith(foto: semua, memprosesFoto: false, pesanError: null));
    } catch (galat) {
      if (isClosed) return;
      emit(
        state.copyWith(
          memprosesFoto: false,
          pesanError: _pesanGalat(
            galat,
            'Foto belum dapat ditambahkan. Coba pilih kembali.',
          ),
        ),
      );
    }
  }

  void hapusFoto(int indeks) {
    if (isClosed || !_bolehUbah) return;
    if (indeks < 0 || indeks >= state.foto.length) return;

    final daftar = List<FotoLaporan>.of(state.foto)..removeAt(indeks);
    emit(state.copyWith(foto: daftar, pesanError: null));
  }

  Future<LaporanSampah?> kirim() async {
    if (isClosed || state.sibuk) return null;

    final form = state;
    if (form.hasilSimpan != null) return form.hasilSimpan;

    final pesan = form.pesanValidasi;
    if (pesan != null) {
      emit(state.copyWith(pesanError: pesan));
      return null;
    }

    final titik = form.lokasi!;
    final laporan = LaporanSampah(
      idWarga: form.idWarga,
      idKategori: form.idKategori!,
      deskripsiLaporan: form.deskripsiLaporan.trim(),
      deskripsiLokasi: form.deskripsiLokasi.trim().isEmpty
          ? (titik.alamatPeta ?? titik.kecamatan)
          : form.deskripsiLokasi.trim(),
      alamatPeta: titik.alamatPeta,
      kecamatan: titik.kecamatan,
      latitude: titik.latitude,
      longitude: titik.longitude,
      metodeLokasi: titik.metodeLokasi,
      lokasiDikonfirmasiAtUtc: titik.dikonfirmasiAtUtc,
      dibuatAtUtc: DateTime.now().toUtc(),
      kunciKirim: form.kunciKirim,
    );

    _galatTerakhir = null;
    emit(state.copyWith(menyimpan: true, pesanError: null));

    try {
      final hasil = await _database.tambahLaporan(
        laporan,
        idJenisSampah: form.jenisDipilih.toList(growable: false),
        foto: form.foto,
      );
      if (isClosed) return null;

      emit(
        state.copyWith(menyimpan: false, hasilSimpan: hasil, pesanError: null),
      );
      return hasil;
    } catch (galat) {
      if (isClosed) return null;
      emit(
        state.copyWith(
          menyimpan: false,
          pesanError: _pesanGalat(
            galat,
            'Laporan belum berhasil disimpan. Isian tetap ada; coba lagi.',
          ),
        ),
      );
      return null;
    }
  }

  void mulaiFormBaru() {
    if (isClosed || state.sibuk) return;

    _galatTerakhir = null;
    emit(
      BuatLaporanState(
        idWarga: state.idWarga,
        namaWarga: state.namaWarga,
        daftarKategori: state.daftarKategori,
        daftarJenisSampah: state.daftarJenisSampah,
        referensiSiap: state.referensiSiap,
        kunciKirim: _buatKunciKirim(),
      ),
    );
  }

  String _pesanGalat(Object galat, String pesanUmum) {
    _galatTerakhir = galat;
    if (galat is FormatException) return galat.message;
    if (galat is ArgumentError) {
      return galat.message?.toString() ?? pesanUmum;
    }
    if (galat is StateError) return galat.message;
    return pesanUmum;
  }
}

String _buatKunciKirim() {
  final acak = Random.secure();
  return List<String>.generate(
    16,
    (_) => acak.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}