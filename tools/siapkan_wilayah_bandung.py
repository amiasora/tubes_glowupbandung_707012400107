#!/usr/bin/env python3
"""Menghasilkan data BIG lengkap yang dipakai revisi lokasi Bandung.

Jalankan dari folder proyek:
    python tools/siapkan_wilayah_bandung.py

Memerlukan Python 3.10+ dan internet, menggunakan pustaka standar Python.
"""

from __future__ import annotations

import hashlib
import json
import math
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path


ENDPOINT = (
    "https://geoservices.big.go.id/rbi/rest/services/"
    "BATASWILAYAH/BATAS_DESAKEL_AR/MapServer/0/query"
)

KABUPATEN_KOTA = {
    "32.04": "Kabupaten Bandung",
    "32.17": "Kabupaten Bandung Barat",
    "32.73": "Kota Bandung",
}

JUMLAH_WILAYAH = {
    "Kabupaten Bandung": 280,
    "Kabupaten Bandung Barat": 165,
    "Kota Bandung": 151,
}

PRESISI_SUMBER = {
    "Cipelah",
    "Tanimulya",
    "Baranangsiang",
}

SHA256_REVISI = (
    "c2143bf2e69dae029bb627b9375cdff9f688bd811322afb5a95c659f1aaed1ba"
)

AKAR_PROYEK = Path(__file__).resolve().parents[1]
TUJUAN = AKAR_PROYEK / "assets" / "wilayah_bandung.json"


def ambil_fitur(parameter: dict[str, str]) -> list[dict]:
    url = ENDPOINT + "?" + urllib.parse.urlencode(parameter)
    galat_terakhir: Exception | None = None

    for percobaan in range(3):
        try:
            permintaan = urllib.request.Request(
                url,
                headers={
                    "User-Agent": "GlowUpBandung-DataSetup/1.0",
                },
            )

            with urllib.request.urlopen(
                permintaan,
                timeout=45,
            ) as respons:
                data = json.loads(
                    respons.read().decode("utf-8")
                )

            if not isinstance(data, dict):
                raise ValueError(
                    "Respons BIG bukan objek JSON."
                )

            if "error" in data:
                raise ValueError(
                    "Layanan BIG: " + str(data["error"])
                )

            if data.get("exceededTransferLimit"):
                raise ValueError(
                    "Respons BIG belum memuat semua wilayah."
                )

            fitur = data.get("features")

            if not isinstance(fitur, list):
                raise ValueError(
                    "Daftar fitur BIG tidak ditemukan."
                )

            return fitur

        except (OSError, ValueError) as galat:
            galat_terakhir = galat

            if percobaan < 2:
                time.sleep(percobaan + 1)

    raise RuntimeError(
        "Data BIG belum berhasil diambil. "
        "Berkas lama tetap dipertahankan. "
        f"Rincian: {galat_terakhir}"
    ) from galat_terakhir


def cincin_dua_dimensi(fitur: dict) -> list:
    geometri = fitur.get("geometry") or {}

    if geometri.get("type") != "Polygon":
        raise ValueError(
            "Jenis geometri sumber berubah; "
            "perlu ditinjau kembali."
        )

    hasil = []

    for cincin in geometri.get("coordinates", []):
        titik = []

        for koordinat in cincin:
            if len(koordinat) < 2:
                raise ValueError(
                    "Koordinat sumber tidak lengkap."
                )

            xy = koordinat[:2]

            if not all(
                isinstance(angka, (int, float))
                and not isinstance(angka, bool)
                and math.isfinite(angka)
                for angka in xy
            ):
                raise ValueError(
                    "Koordinat sumber tidak sah."
                )

            if not (
                -180 <= xy[0] <= 180
                and -90 <= xy[1] <= 90
            ):
                raise ValueError(
                    "Koordinat berada di luar rentang geografis."
                )

            titik.append(xy)

        if len(titik) < 4 or titik[0] != titik[-1]:
            raise ValueError(
                "Cincin batas wilayah belum tertutup."
            )

        hasil.append(titik)

    if not hasil:
        raise ValueError(
            "Polygon batas wilayah kosong."
        )

    return hasil


def main() -> None:
    parameter = {
        "f": "geojson",
        "where": "KDPKAB IN ('32.04','32.17','32.73')",
        "outFields": (
            "NAMOBJ,WADMKC,WADMKK,"
            "KDEPUM,KDCPUM,KDPKAB"
        ),
        "returnGeometry": "true",
        "outSR": "4326",
        "geometryPrecision": "6",
        "resultRecordCount": "1000",
        "orderByFields": "KDEPUM",
    }

    print(
        "Mengambil batas BIG untuk tiga wilayah Bandung..."
    )

    fitur = ambil_fitur(parameter)

    fitur.sort(
        key=lambda item: item["properties"]["KDEPUM"]
    )

    if len(fitur) != 596:
        raise ValueError(
            f"Diharapkan 596 wilayah, diperoleh {len(fitur)}."
        )

    kode_presisi = [
        item["properties"]["KDEPUM"]
        for item in fitur
        if item["properties"]["NAMOBJ"] in PRESISI_SUMBER
    ]

    if len(kode_presisi) != 3:
        raise ValueError(
            "Tiga wilayah dengan presisi sumber "
            "tidak ditemukan."
        )

    parameter_presisi = dict(parameter)
    parameter_presisi.pop("geometryPrecision")

    parameter_presisi["where"] = (
        "KDEPUM IN ("
        + ",".join(
            "'" + kode + "'"
            for kode in kode_presisi
        )
        + ")"
    )

    presisi = {
        item["properties"]["KDEPUM"]: item
        for item in ambil_fitur(parameter_presisi)
    }

    if set(presisi) != set(kode_presisi):
        raise ValueError(
            "Data presisi sumber belum lengkap."
        )

    baris = []
    kode_terlihat = set()
    kecamatan = set()

    for item in fitur:
        properti = item["properties"]
        kode = properti["KDEPUM"]

        if kode in kode_terlihat:
            raise ValueError(
                "Kode wilayah ganda: " + kode
            )

        kode_terlihat.add(kode)

        kabupaten_kota = KABUPATEN_KOTA[
            properti["KDPKAB"]
        ]

        nama_kecamatan = properti["WADMKC"]
        nama = properti["NAMOBJ"]

        geometri = presisi.get(kode, item)

        baris.append(
            [
                nama,
                nama_kecamatan,
                cincin_dua_dimensi(geometri),
                kabupaten_kota,
            ]
        )

        kecamatan.add(
            (kabupaten_kota, nama_kecamatan)
        )

    jumlah_per_daerah = dict(
        Counter(item[3] for item in baris)
    )

    if jumlah_per_daerah != JUMLAH_WILAYAH:
        raise ValueError(
            "Jumlah desa/kelurahan per daerah tidak cocok."
        )

    if len(kecamatan) != 77:
        raise ValueError(
            "Jumlah kecamatan tidak cocok "
            "dengan versi revisi."
        )

    isi = (
        json.dumps(
            baris,
            ensure_ascii=False,
            separators=(",", ":"),
        )
        + "\n"
    ).encode("utf-8")

    sidik = hashlib.sha256(isi).hexdigest()

    if sidik != SHA256_REVISI:
        raise ValueError(
            "Isi layanan BIG berbeda dari versi revisi "
            "15 November 2026. "
            "Berkas belum diganti; data baru perlu "
            "diverifikasi. "
            f"SHA-256 yang diterima: {sidik}"
        )

    TUJUAN.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    sementara = TUJUAN.with_suffix(".json.tmp")
    sementara.write_bytes(isi)
    sementara.replace(TUJUAN)

    print(f"Selesai: {TUJUAN}")

    print(
        "596 desa/kelurahan, 77 kecamatan, "
        "tiga kabupaten/kota."
    )

    print(f"SHA-256: {sidik}")


if __name__ == "__main__":
    try:
        main()
    except Exception as galat:
        print(
            f"GAGAL: {galat}",
            file=sys.stderr,
        )
        raise SystemExit(1)