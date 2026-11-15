# Revisi lokasi Glow Up Bandung

Revisi ini memperluas layanan ke Kota Bandung, Kabupaten Bandung, dan
Kabupaten Bandung Barat.

Data meliputi 596 desa/kelurahan pada 77 kecamatan.

Titik dari rekaman warga, -6.973041, 107.629362, sekarang tercakup sebagai
Sukapura, Dayeuhkolot, Kabupaten Bandung menurut data batas yang digunakan.

## Memasang berkas revisi

1. Tutup proses Flutter yang sedang berjalan dan salin cadangan proyek.
2. Terapkan seluruh isi file dari empat bagian penjelasan di chat.
   Path dihitung dari folder utama proyek yang berisi pubspec.yaml.
   Ganti isi file lama secara lengkap dan buat file baru pada path
   yang disebutkan.
3. Gunakan Python 3.10 atau lebih baru untuk menghasilkan data BIG lengkap.
   Script hanya memakai pustaka standar dan memverifikasi SHA-256 versi data.

```bash
python tools/siapkan_wilayah_bandung.py
```

4. Setelah semua file dan data terpasang, jalankan perintah pemeriksaan.
   Dependensi Flutter menggunakan pubspec.yaml dan pubspec.lock project.

```bash
flutter pub get
flutter analyze
flutter test test/lokasi_dan_foto_test.dart test/layanan_posisi_test.dart test/revisi_admin_test.dart
```

Pengujian Flutter tersebut perlu dijalankan di komputer pengembang.

File test/widget_test.dart masih mengacu pada alur lama dan memerlukan
penyesuaian tersendiri dengan alur login serta penyimpanan SQLite.

## Perubahan perilaku

- Kecamatan dan kabupaten/kota ditentukan dari polygon batas BIG
  yang tersedia lokal.
- Nama jalan ditambahkan ketika layanan alamat memberikan hasil
  yang sesuai.
- Alamat lengkap dari pin terkonfirmasi dipertahankan ketika laporan
  disimpan sehingga admin membaca informasi yang sama dengan warga.
- Pencarian perangkat meminta akurasi terbaik dan mengamati pembacaan
  selama maksimal 20 detik.
- Pencarian berhenti lebih awal jika perkiraan akurasi mencapai
  10 meter atau lebih baik.
- Jika target belum tercapai, pembacaan terbaik yang tersedia
  ditampilkan beserta perkiraan akurasinya.
- Data lokasi usang dan nilai akurasi yang tidak sah tidak dipakai
  sebagai pembacaan presisi.
- Mengetuk peta atau meninggalkan halaman menghentikan pencarian.
- Izin lokasi presisi, perkiraan lokasi, dan internet dideklarasikan
  untuk Android.
- Pengguna memberikan izin lokasi melalui sistem operasi.
- Pin dapat dipilih manual ketika GPS tidak tersedia.
- Kecamatan ditentukan dari pin dan data batas wilayah.
- Penerimaan laporan mengikuti cakupan tiga daerah yang disepakati.

## Pengujian Android dan Chrome

Pada Chrome, jalankan melalui localhost atau HTTPS dan izinkan
akses lokasi.

```bash
flutter run -d chrome --web-port 7357
```

Pada Android:

1. Aktifkan layanan lokasi.
2. Izinkan lokasi presisi untuk aplikasi.
3. Pilih perangkat Android pada VS Code.
4. Jalankan aplikasi.
5. Uji juga APK release karena izin internet dideklarasikan
   pada manifest utama.

| Kasus | Hasil yang perlu diperiksa |
| --- | --- |
| Pin Braga: -6.917474, 107.609810 | Sumur Bandung, Kota Bandung; dapat dikonfirmasi. |
| Pin rekaman: -6.973041, 107.629362 | Sukapura, Dayeuhkolot, Kabupaten Bandung; dapat dikonfirmasi. |
| Pin Lembang: -6.8171, 107.6171 | Lembang, Kabupaten Bandung Barat; dapat dikonfirmasi. |
| Pin Ciwidey: -7.1050, 107.4585 | Ciwidey, Kabupaten Bandung; dapat dikonfirmasi. |
| Pin Cimahi: -6.8720, 107.5420 | Di luar cakupan tiga daerah pilihan; konfirmasi ditahan. |
| Izin GPS ditolak atau GPS dimatikan | Pesan menjelaskan keadaan dan pemilihan manual tersedia. |
| Pembacaan GPS kurang teliti | Perkiraan akurasi terlihat; pengguna dapat mencoba lagi atau mengoreksi pin. |
| Geser pin selama GPS mencari | Pin manual tidak ditimpa hasil GPS yang datang belakangan. |
| Layanan nama jalan gagal | Desa/kelurahan, kecamatan, dan kabupaten/kota tetap terbaca dari data lokal. |
| Simpan lalu buka sebagai admin | Alamat lengkap dari pin yang sama tetap tersimpan. |
| Tutup dan buka kembali aplikasi | Laporan, keputusan, dan jadwal tetap terbaca dari SQLite. |

## Pengujian alur warga sampai petugas

1. Masuk sebagai warga.
2. Isi deskripsi laporan.
3. Unggah tiga foto berbeda dari kejadian yang sama.
4. Pilih kategori dan jenis sampah.
5. Pilih serta konfirmasi titik kejadian.
6. Lengkapi patokan bila diperlukan.
7. Kirim laporan dan catat kode yang dihasilkan.
8. Masuk sebagai admin.
9. Buka laporan dengan kode yang sama pada Laporan Masuk.
10. Periksa alamat, kecamatan, foto, kategori, dan deskripsi.
11. Isi kesimpulan dan simpan keputusan Sesuai.
12. Jadwalkan pengangkutan dengan waktu, tim, dan koordinator.
13. Masuk sebagai petugas yang ditugaskan.
14. Periksa lokasi serta jadwal penugasan.
15. Lakukan Check-in, kirim foto progres, dan selesaikan tugas
    melalui koordinator.
16. Masuk kembali sebagai warga dan periksa perkembangan
    pada laporan yang sama.
17. Tutup aplikasi sepenuhnya, buka kembali, lalu periksa
    data laporan dan penanganannya.

Sumber data wilayah dan formatnya dijelaskan pada:

assets/WILAYAH_BANDUNG.md