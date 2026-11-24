import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sesi_akun.dart';
import '../theme/app_theme.dart';

enum MenuWarga {
  dashboard('Dashboard', '/'),
  buatLaporan('Buat Laporan', '/buat-laporan'),
  riwayat('Riwayat Laporan', '/riwayat-laporan'),
  notifikasi('Notifikasi', '/notifikasi');

  const MenuWarga(this.label, this.route);

  final String label;
  final String route;
}

class KerangkaWarga extends StatelessWidget {
  const KerangkaWarga({
    super.key,
    required this.menuAktif,
    required this.child,
    this.navigasiAktif = true,
    this.onKembali,
  });

  final MenuWarga menuAktif;
  final Widget child;
  final bool navigasiAktif;
  final Future<void> Function()? onKembali;

  @override
  Widget build(BuildContext context) => KerangkaPeran(
    peran: PeranAkun.warga,
    ruteAktif: menuAktif.route,
    menu: {for (final item in MenuWarga.values) item.route: item.label},
    navigasiAktif: navigasiAktif,
    onKembali: onKembali,
    child: child,
  );
}

class KerangkaPeran extends StatefulWidget {
  const KerangkaPeran({
    super.key,
    required this.peran,
    required this.ruteAktif,
    required this.menu,
    required this.child,
    this.navigasiAktif = true,
    this.onKembali,
  });

  final PeranAkun peran;
  final String ruteAktif;
  final Map<String, String> menu;
  final Widget child;
  final bool navigasiAktif;
  final Future<void> Function()? onKembali;

  @override
  State<KerangkaPeran> createState() => _KerangkaPeranState();
}

class _KerangkaPeranState extends State<KerangkaPeran> {
  static const _menuAdmin = {
    '/': 'Dashboard',
    '/admin/laporan': 'Laporan Masuk',
    '/admin/jadwal': 'Penjadwalan',
  };

  static const _menuPetugas = {
    '/': 'Dashboard',
    '/petugas/jadwal': 'Jadwal Pengangkutan',
    '/petugas/notifikasi': 'Notifikasi',
  };

  bool _ruteAktif = false;
  bool _pernahAktif = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final sekarangAktif = ModalRoute.isCurrentOf(context) ?? true;

    if (sekarangAktif && !_ruteAktif && _pernahAktif) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ruteAktif) {
          widget.onKembali?.call();
        }
      });
    }

    _ruteAktif = sekarangAktif;
    _pernahAktif = _pernahAktif || sekarangAktif;
  }

  void _buka(String rute) {
    if (!widget.navigasiAktif) return;

    final navigator = Navigator.of(context);

    if (rute == '/') {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    if (rute == widget.ruteAktif &&
        ModalRoute.of(context)?.settings.name == rute) {
      return;
    }

    navigator.pushNamed<Object?>(rute);
  }

  void _keluar() {
    if (!widget.navigasiAktif) return;

    SesiAkun.keluar();

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil<Object?>('/', (_) => false);
  }

  IconData _ikon(String rute) => switch (rute) {
    '/' => Icons.space_dashboard_outlined,
    '/buat-laporan' => Icons.add_circle_outline,
    '/notifikasi' || '/petugas/notifikasi' => Icons.notifications_outlined,
    '/admin/jadwal' || '/petugas/jadwal' => Icons.calendar_month_outlined,
    _ => Icons.receipt_long_outlined,
  };

  String _pendek(String rute) => switch (rute) {
    '/' => 'Beranda',
    '/buat-laporan' => 'Lapor',
    '/riwayat-laporan' => 'Riwayat',
    '/admin/laporan' => 'Laporan',
    '/admin/jadwal' || '/petugas/jadwal' => 'Jadwal',
    _ => 'Notifikasi',
  };

  String _pilihanAktif(Map<String, String> menu) {
    if (menu.containsKey(widget.ruteAktif)) {
      return widget.ruteAktif;
    }

    return switch (widget.peran) {
      PeranAkun.admin => '/admin/laporan',
      PeranAkun.petugas => '/petugas/jadwal',
      PeranAkun.warga => MenuWarga.riwayat.route,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;
    final desktop = lebar >= 1060;
    final ponsel = lebar < 760;
    final papanKetik = MediaQuery.viewInsetsOf(context).bottom > 0;
    final warna = Theme.of(context).colorScheme;

    final menu = switch (widget.peran) {
      PeranAkun.admin => _menuAdmin,
      PeranAkun.petugas => _menuPetugas,
      PeranAkun.warga => widget.menu,
    };

    final aktif = _pilihanAktif(menu);
    final rute = menu.keys.toList(growable: false);
    final bisaKembali = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: warna.surface,
        foregroundColor: warna.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: ponsel ? 60 : 68,
        automaticallyImplyLeading: false,
        leading: bisaKembali
            ? IconButton(
                tooltip: 'Kembali',
                onPressed: widget.navigasiAktif
                    ? () => Navigator.maybePop(context)
                    : null,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        titleSpacing: bisaKembali ? 0 : 16,
        title: const MerekGlow(),
        actions: [
          if (!ponsel)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LabelGlow(widget.peran.label, icon: Icons.person_outline),
            ),
          IconButton(
            key: const ValueKey('buka-pengaturan'),
            tooltip: 'Pengaturan',
            onPressed: widget.navigasiAktif ? () => _buka('/pengaturan') : null,
            icon: const Icon(Icons.settings_outlined),
          ),
          if (ponsel)
            IconButton(
              tooltip: 'Keluar',
              onPressed: widget.navigasiAktif ? _keluar : null,
              icon: const Icon(Icons.logout, size: 21),
            )
          else
            TextButton.icon(
              onPressed: widget.navigasiAktif ? _keluar : null,
              icon: const Icon(Icons.logout, size: 19),
              label: const Text('Keluar'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: warna.outlineVariant),
        ),
      ),
      bottomNavigationBar: ponsel && !papanKetik && rute.length >= 2
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: warna.outlineVariant)),
              ),
              child: NavigationBar(
                height: 68,
                animationDuration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                selectedIndex: math.max(0, rute.indexOf(aktif)),
                onDestinationSelected: widget.navigasiAktif
                    ? (index) => _buka(rute[index])
                    : null,
                destinations: [
                  for (final kunci in rute)
                    NavigationDestination(
                      enabled: widget.navigasiAktif,
                      tooltip: menu[kunci],
                      icon: Icon(_ikon(kunci)),
                      label: _pendek(kunci),
                    ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        bottom: !ponsel || papanKetik,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!ponsel)
              SizedBox(
                width: desktop ? 236 : 76,
                child: Material(
                  color: warna.surface,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: warna.outlineVariant),
                      ),
                    ),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        desktop ? 14 : 8,
                        22,
                        desktop ? 14 : 8,
                        12,
                      ),
                      children: [
                        if (desktop)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 0, 12),
                            child: Text(
                              widget.peran.label.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: warna.onSurfaceVariant,
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        for (final kunci in rute)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Semantics(
                              selected: kunci == aktif,
                              child: Tooltip(
                                message: menu[kunci]!,
                                child: TextButton(
                                  onPressed: widget.navigasiAktif
                                      ? () => _buka(kunci)
                                      : null,
                                  style: TextButton.styleFrom(
                                    alignment: desktop
                                        ? Alignment.centerLeft
                                        : Alignment.center,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: desktop ? 12 : 4,
                                    ),
                                    backgroundColor: kunci == aktif
                                        ? warna.primaryContainer
                                        : null,
                                    foregroundColor: kunci == aktif
                                        ? warna.onPrimaryContainer
                                        : warna.onSurfaceVariant,
                                  ),
                                  child: desktop
                                      ? Row(
                                          children: [
                                            Icon(_ikon(kunci), size: 21),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(menu[kunci]!)),
                                          ],
                                        )
                                      : Icon(_ikon(kunci), size: 22),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class MerekGlow extends StatelessWidget {
  const MerekGlow({super.key, this.terang = false});

  final bool terang;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: terang ? AppTheme.aksenTerang : warna.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.eco_outlined,
            size: 22,
            color: terang ? AppTheme.hijauGelap : warna.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            'Glow Up Bandung',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: terang ? Colors.white : warna.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
            ),
          ),
        ),
      ],
    );
  }
}

class LabelGlow extends StatelessWidget {
  const LabelGlow(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final gelap = tema.brightness == Brightness.dark;

    final (latar, teks, simbol) = switch (label.toLowerCase()) {
      'diterima' || 'valid' || 'selesai' => (
        skema.primaryContainer,
        skema.onPrimaryContainer,
        Icons.check_circle_outline,
      ),
      'diproses' || 'dikerjakan' || 'terjadwal' => (
        gelap ? const Color(0xFF233F56) : const Color(0xFFE5F0FC),
        gelap ? const Color(0xFFC4E2FF) : const Color(0xFF255580),
        Icons.schedule,
      ),
      'menunggu klarifikasi' || 'klarifikasi masuk' || 'belum dibaca' => (
        gelap ? const Color(0xFF483A26) : const Color(0xFFFFF0CF),
        gelap ? const Color(0xFFFFDEA1) : const Color(0xFF75501C),
        Icons.info_outline,
      ),
      'ditolak' || 'dibatalkan' || 'tidak valid' => (
        skema.errorContainer,
        skema.onErrorContainer,
        Icons.cancel_outlined,
      ),
      _ => (
        skema.surfaceContainerHigh,
        skema.onSurfaceVariant,
        Icons.circle_outlined,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? simbol, size: 14, color: teks),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: teks,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JudulHalamanWarga extends StatelessWidget {
  const JudulHalamanWarga({super.key, required this.judul, this.deskripsi});

  final String judul;
  final String? deskripsi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ponsel = MediaQuery.sizeOf(context).width < 760;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Semantics(
            header: true,
            child: Text(
              judul,
              style: ponsel
                  ? tema.textTheme.headlineSmall
                  : tema.textTheme.headlineMedium,
            ),
          ),
          if (deskripsi != null)
            Text(
              deskripsi!,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class KontenWarga extends StatelessWidget {
  const KontenWarga({
    super.key,
    required this.children,
    this.maxLebar = 1248,
    this.controller,
  });

  final List<Widget> children;
  final double maxLebar;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, batas) {
      final lebar = batas.maxWidth;
      final tepi = lebar < 540
          ? 16.0
          : lebar < 900
          ? 24.0
          : 32.0;

      final samping = math.max(tepi, (lebar - maxLebar) / 2 + tepi);

      return ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(samping, tepi, samping, 32),
        children: children,
      );
    },
  );
}

class PanelGlow extends StatelessWidget {
  const PanelGlow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class KisiGlow extends StatelessWidget {
  const KisiGlow({
    super.key,
    required this.children,
    this.lebarMinimum = 220,
    this.kolomMaksimal = 3,
    this.jarak = 12,
  });

  final List<Widget> children;
  final double lebarMinimum;
  final int kolomMaksimal;
  final double jarak;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, batas) {
      final kolom = ((batas.maxWidth + jarak) / (lebarMinimum + jarak))
          .floor()
          .clamp(1, kolomMaksimal)
          .toInt();

      final lebar = (batas.maxWidth - (kolom - 1) * jarak) / kolom;

      return Wrap(
        spacing: jarak,
        runSpacing: jarak,
        children: [
          for (final anak in children) SizedBox(width: lebar, child: anak),
        ],
      );
    },
  );
}

class KeadaanGlow extends StatelessWidget {
  const KeadaanGlow({
    super.key,
    required this.judul,
    required this.pesan,
    required this.icon,
    this.aksi,
  });

  final String judul;
  final String pesan;
  final IconData icon;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return PanelGlow(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Icon(icon, size: 28, color: tema.colorScheme.primary),
          Text(judul, style: tema.textTheme.titleMedium),
          Text(pesan, style: tema.textTheme.bodySmall),
          ?aksi,
        ],
      ),
    );
  }
}

String tanggalWarga(DateTime tanggal) =>
    '${tanggal.day.toString().padLeft(2, '0')}/'
    '${tanggal.month.toString().padLeft(2, '0')}/'
    '${tanggal.year}';

String waktuWibWarga(DateTime utc) {
  final wib = utc.toUtc().add(const Duration(hours: 7));

  return '${tanggalWarga(wib)} '
      '${wib.hour.toString().padLeft(2, '0')}:'
      '${wib.minute.toString().padLeft(2, '0')} WIB';
}
