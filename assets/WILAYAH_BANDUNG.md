# Data wilayah layanan Bandung

Cakupan yang disepakati pada 15 November 2026 adalah Kota Bandung,
Kabupaten Bandung, dan Kabupaten Bandung Barat.

`wilayah_bandung.json` memuat 596 desa/kelurahan pada 77 kecamatan:

| Kabupaten atau kota | Desa dan kelurahan |
| --- | ---: |
| Kota Bandung | 151 |
| Kabupaten Bandung | 280 |
| Kabupaten Bandung Barat | 165 |

Sumber: Badan Informasi Geospasial, layanan BATAS_DESAKEL_AR,
edisi Juni 2026.

Diambil pada 15 November 2026 dari:

https://geoservices.big.go.id/rbi/rest/services/BATASWILAYAH/BATAS_DESAKEL_AR/MapServer/0

Filter sumber:

KDPKAB IN ('32.04','32.17','32.73')

Geometri diminta dalam EPSG:4326 dengan enam angka desimal.

Cipelah, Tanimulya, dan Baranangsiang mempertahankan presisi asli
sumber untuk menghindari perpotongan cincin akibat pembulatan.

Koordinat Z dibuang; bentuk cincin dan lubang dipertahankan.

Data tidak diperluas menggunakan kotak pembatas atau pencocokan
kata Bandung pada alamat.

Setiap baris berisi:

[nama_desa_kelurahan, kecamatan, cincin_polygon, kabupaten_kota]

Setiap koordinat berurutan:

[longitude, latitude]

Cincin pertama adalah batas luar.
Cincin berikutnya adalah lubang.

Data batas disimpan lokal agar pengenalan kecamatan tidak
bergantung pada keberhasilan pencarian nama jalan.

Ketelitian digit koordinat bukan ukuran akurasi GPS.

Antarmuka menampilkan perkiraan akurasi yang dilaporkan perangkat
dan tetap menyediakan koreksi pin.

Data lengkap dapat dihasilkan melalui:

python tools/siapkan_wilayah_bandung.py

Script memverifikasi SHA-256 versi revisi sebelum mengganti file:

c2143bf2e69dae029bb627b9375cdff9f688bd811322afb5a95c659f1aaed1ba