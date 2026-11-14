import 'dart:io';

final changes = <String, String>{};
final tokens = RegExp(r'\w+|[^\s]');

String source(String path) => changes[path] ?? File(path).readAsStringSync();

void change(String path, String Function(String) edit) {
  changes[path] = edit(source(path));
}

void page(String name, String Function(String) edit) =>
    change('lib/pages/$name.dart', edit);

RegExp anchor(String value) {
  final parts = tokens.allMatches(value).map((m) => m[0]!).toList();
  const closers = {')', ']', '}'};
  final result = StringBuffer();
  for (var i = 0; i < parts.length; i++) {
    if (i > 0) result.write(r'\s*');
    final part = parts[i];
    if (part == ',' && i + 1 < parts.length && closers.contains(parts[i + 1])) {
      result.write(',?');
    } else {
      if (closers.contains(part) && i > 0 && parts[i - 1] != ',') {
        result.write(r',?\s*');
      }
      result.write(RegExp.escape(part));
    }
  }
  return RegExp(result.toString());
}

String replace(String value, String before, String after) {
  final match = anchor(before).firstMatch(value);
  if (match == null) throw FormatException('Potongan kode tidak cocok: $before');
  return value.replaceRange(match.start, match.end, after);
}

String between(
  String value,
  String start,
  String end,
  String Function(String) edit,
) {
  final from = anchor(start).firstMatch(value);
  if (from == null) throw FormatException('Awal bagian tidak ditemukan: $start');
  final to = anchor(end).allMatches(value, from.end).firstOrNull;
  if (to == null) throw FormatException('Akhir bagian tidak ditemukan: $end');
  return value.replaceRange(
    from.start,
    to.start,
    edit(value.substring(from.start, to.start)),
  );
}

void main() {
  try {
    if (!File('pubspec.yaml').existsSync() ||
        !File('lib/services/sesi_akun.dart').existsSync()) {
      throw StateError(
        'Jalankan di folder proyek Glow Up Bandung dengan modul tiga peran.',
      );
    }

    const theme = 'lib/theme/app_theme.dart';
    const shell = 'lib/widgets/kerangka_warga.dart';
    final sudahRedesign = source(shell).contains('class MerekGlow');
    changes[theme] = temaBiru;

    if (!sudahRedesign) {
      changes[shell] = kerangkaBiru;
      perbaruiHalaman();
    } else {
      for (final path in [shell, 'lib/pages/login.dart', 'lib/pages/beranda.dart']) {
        change(
          path,
          (s) => s
              .replaceAll('AppTheme.hijauGelap', 'AppTheme.biruGelap')
              .replaceAll('AppTheme.hijauSedang', 'AppTheme.biruSedang')
              .replaceAll('0xFFE1F4E7', '0xFFE3EEFF')
              .replaceAll('0x55CCEDAD', '0x5085B9FF'),
        );
      }
    }

    final pending = changes.entries.where(
      (entry) => !File(entry.key).existsSync() ||
          File(entry.key).readAsStringSync() != entry.value,
    ).toList();

    if (pending.isEmpty) {
      stdout.writeln('Redesign biru sudah terpasang.');
      return;
    }

    final backup = Directory('cadangan_ui_${DateTime.now().millisecondsSinceEpoch}');
    for (final entry in pending) {
      final file = File(entry.key);
      if (file.existsSync()) {
        final saved = File('${backup.path}/${entry.key}.bak');
        saved.parent.createSync(recursive: true);
        file.copySync(saved.path);
      }
    }

    final written = <File>[];
    try {
      for (final entry in pending) {
        final file = File(entry.key);
        file.parent.createSync(recursive: true);
        written.add(file);
        file.writeAsStringSync(entry.value);
      }
    } catch (_) {
      for (final file in written) {
        final saved = File('${backup.path}/${file.path}.bak');
        if (saved.existsSync()) {
          saved.copySync(file.path);
        } else if (file.existsSync()) {
          file.deleteSync();
        }
      }
      rethrow;
    }

    stdout.writeln('${pending.length} file diperbarui. Cadangan ada di ${backup.path}.');
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

const temaBiru = r"""
import 'package:flutter/material.dart';

class AppTheme {
  static const warnaDasar = Color(0xFF2055C7);
  static const biruGelap = Color(0xFF142B58);
  static const biruSedang = Color(0xFF214EA5);
  static const aksenTerang = Color(0xFFDBEAFF);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: warnaDasar, brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFFB1CAFF) : warnaDasar,
      onPrimary: dark ? const Color(0xFF142B58) : Colors.white,
      primaryContainer: dark ? const Color(0xFF253D6A) : const Color(0xFFE0EBFF),
      onPrimaryContainer: dark ? const Color(0xFFE3EEFF) : const Color(0xFF193C83),
      surface: dark ? const Color(0xFF192336) : Colors.white,
      onSurface: dark ? const Color(0xFFEAF0FD) : const Color(0xFF18263C),
      onSurfaceVariant: dark ? const Color(0xFFBAC9DF) : const Color(0xFF4F6079),
      outlineVariant: dark ? const Color(0xFF3B4B65) : const Color(0xFFDCE5F2),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: colors, fontFamily: 'Roboto');
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    const buttonText = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

    return base.copyWith(
      scaffoldBackgroundColor: dark ? const Color(0xFF111A2A) : const Color(0xFFF3F6FC),
      focusColor: colors.primary.withValues(alpha: .18),
      hoverColor: colors.primary.withValues(alpha: .08),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(fontSize: 38, height: 1.12,
          letterSpacing: -.9, fontWeight: FontWeight.w800),
        headlineMedium: const TextStyle(fontSize: 30, height: 1.16,
          letterSpacing: -.6, fontWeight: FontWeight.w800),
        headlineSmall: const TextStyle(fontSize: 24, height: 1.2,
          letterSpacing: -.4, fontWeight: FontWeight.w800),
        titleLarge: const TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: colors.onSurface),
        bodySmall: TextStyle(fontSize: 13, height: 1.45, color: colors.onSurfaceVariant),
      ).apply(displayColor: colors.onSurface, bodyColor: colors.onSurface),
      cardTheme: CardThemeData(
        color: colors.surface, surfaceTintColor: Colors.transparent,
        elevation: 0, margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true, fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: border, enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.primary, width: 2)),
        errorBorder: border.copyWith(borderSide: BorderSide(color: colors.error)),
        focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: colors.error, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48), shape: shape, textStyle: buttonText,
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48), shape: shape, textStyle: buttonText,
        side: BorderSide(color: colors.outlineVariant),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        minimumSize: const Size(48, 48), shape: shape, textStyle: buttonText,
      )),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
      )),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: colors.outlineVariant), shape: shape,
        selectedColor: colors.primaryContainer,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface, surfaceTintColor: Colors.transparent, shape: shape,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface, indicatorColor: colors.primaryContainer,
        elevation: 0,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        for (final platform in TargetPlatform.values) platform: const _FadeGlow(),
      }),
    );
  }
}

class _FadeGlow extends PageTransitionsBuilder {
  const _FadeGlow();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 190);

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
      child: child,
    );
  }
}
""";

const kerangkaBiru = r"""
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
  const KerangkaWarga({super.key, required this.menuAktif, required this.child,
    this.navigasiAktif = true, this.onKembali});
  final MenuWarga menuAktif;
  final Widget child;
  final bool navigasiAktif;
  final Future<void> Function()? onKembali;

  @override
  Widget build(BuildContext context) => KerangkaPeran(
    peran: PeranAkun.warga, ruteAktif: menuAktif.route,
    menu: {for (final item in MenuWarga.values) item.route: item.label},
    navigasiAktif: navigasiAktif, onKembali: onKembali, child: child,
  );
}

class KerangkaPeran extends StatefulWidget {
  const KerangkaPeran({super.key, required this.peran, required this.ruteAktif,
    required this.menu, required this.child, this.navigasiAktif = true, this.onKembali});
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
  bool? _current;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = ModalRoute.isCurrentOf(context) ?? true;
    if (active && _current == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _current == true) widget.onKembali?.call();
      });
    }
    _current = active;
  }

  void _buka(String route) {
    final current = ModalRoute.of(context);
    final nav = Navigator.of(context);
    if (route == '/') {
      nav.popUntil((r) => r.isFirst);
    } else if (current?.settings.name != route) {
      nav.pushNamed<Object?>(route);
    }
  }

  void _keluar() {
    SesiAkun.keluar();
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil<Object?>('/', (_) => false);
  }

  (String, IconData) _tab(String path) => switch (path) {
    '/' => ('Beranda', Icons.space_dashboard_outlined),
    '/buat-laporan' => ('Lapor', Icons.add_circle_outline),
    '/riwayat-laporan' => ('Riwayat', Icons.receipt_long_outlined),
    '/admin/jadwal' || '/petugas/jadwal' => ('Jadwal', Icons.calendar_month_outlined),
    '/notifikasi' || '/petugas/notifikasi' => ('Notifikasi', Icons.notifications_outlined),
    _ => ('Laporan', Icons.inbox_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final desktop = width >= 1060;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final colors = Theme.of(context).colorScheme;
    final entries = switch (widget.peran) {
      PeranAkun.warga => widget.menu,
      PeranAkun.admin => const {
        '/': 'Dashboard', '/admin/laporan': 'Daftar Laporan', '/admin/jadwal': 'Penjadwalan',
      },
      PeranAkun.petugas => const {
        '/': 'Dashboard', '/petugas/jadwal': 'Jadwal Pengangkutan',
        '/petugas/notifikasi': 'Notifikasi',
      },
    }.entries.toList();
    final index = entries.indexWhere((item) => item.key == widget.ruteAktif);
    final selected = index >= 0 ? index : 1;
    final back = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface, surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false, toolbarHeight: mobile ? 60 : 68,
        titleSpacing: back ? 0 : 16,
        leading: back ? IconButton(
          tooltip: 'Kembali', icon: const Icon(Icons.arrow_back),
          onPressed: widget.navigasiAktif ? () => Navigator.maybePop(context) : null,
        ) : null,
        title: const MerekGlow(),
        actions: [
          if (!mobile) Center(child: LabelGlow(widget.peran.label, icon: Icons.person_outline)),
          const SizedBox(width: 8),
          IconButton(tooltip: 'Keluar', icon: const Icon(Icons.logout),
            onPressed: widget.navigasiAktif ? _keluar : null),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outlineVariant)),
      ),
      bottomNavigationBar: mobile && !keyboard ? NavigationBar(
        height: 68, selectedIndex: selected,
        animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero : const Duration(milliseconds: 180),
        onDestinationSelected: widget.navigasiAktif ? (i) => _buka(entries[i].key) : null,
        destinations: [
          for (final entry in entries) NavigationDestination(
            enabled: widget.navigasiAktif, tooltip: entry.value,
            icon: Icon(_tab(entry.key).$2), label: _tab(entry.key).$1,
          ),
        ],
      ) : null,
      body: SafeArea(top: false, bottom: !mobile || keyboard, child: Row(children: [
        if (!mobile) SizedBox(width: desktop ? 232 : 72, child: Material(
          color: colors.surface,
          child: ListView(padding: EdgeInsets.all(desktop ? 14 : 8), children: [
            if (desktop) Padding(padding: const EdgeInsets.fromLTRB(12, 8, 0, 12),
              child: Text(widget.peran.label.toUpperCase(), style: Theme.of(context)
                .textTheme.labelSmall?.copyWith(letterSpacing: 1.5))),
            for (final (i, entry) in entries.indexed)
              Padding(padding: const EdgeInsets.only(bottom: 5), child: Semantics(
                selected: selected == i,
                child: Tooltip(message: entry.value, child: TextButton(
                  onPressed: widget.navigasiAktif ? () => _buka(entry.key) : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: i == selected ? colors.primaryContainer : null,
                    foregroundColor: i == selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                  ),
                  child: desktop ? Row(spacing: 10, children: [
                    Icon(_tab(entry.key).$2, size: 21), Expanded(child: Text(entry.value)),
                  ]) : Icon(_tab(entry.key).$2, size: 22),
                )),
              )),
          ]),
        )),
        Expanded(child: widget.child),
      ])),
    );
  }
}

class MerekGlow extends StatelessWidget {
  const MerekGlow({super.key, this.terang = false});
  final bool terang;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, spacing: 10, children: [
      DecoratedBox(
        decoration: BoxDecoration(color: terang ? AppTheme.aksenTerang : c.primaryContainer,
          borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(9),
          child: Icon(Icons.eco_outlined, size: 20,
            color: terang ? AppTheme.biruGelap : c.onPrimaryContainer)),
      ),
      Flexible(child: Text('Glow Up Bandung', maxLines: 1, overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: terang ? Colors.white : c.onSurface))),
    ]);
  }
}

class BannerGlow extends StatelessWidget {
  const BannerGlow({super.key, required this.judul, required this.pesan,
    this.aksi, this.icon = Icons.location_on_outlined});
  final String judul;
  final String pesan;
  final Widget? aksi;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(colors: [AppTheme.biruGelap, AppTheme.biruSedang])),
    child: Padding(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 760 ? 20 : 28),
      child: LayoutBuilder(builder: (context, space) => Row(spacing: 20, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10,
          children: [
            Semantics(header: true, child: Text(judul, style: Theme.of(context)
              .textTheme.headlineSmall?.copyWith(color: Colors.white))),
            Text(pesan, style: const TextStyle(color: Color(0xFFE3EEFF), height: 1.45)),
            if (aksi != null) aksi!,
          ],
        )),
        if (space.maxWidth > 570)
          ExcludeSemantics(child: Icon(icon, color: const Color(0x8285B9FF), size: 90)),
      ])),
    ),
  );
}

class JudulHalamanWarga extends StatelessWidget {
  const JudulHalamanWarga({super.key, required this.judul, this.deskripsi});
  final String judul;
  final String? deskripsi;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
        Semantics(header: true, child: Text(judul, style: MediaQuery.sizeOf(context).width < 760
          ? text.headlineSmall : text.headlineMedium)),
        if (deskripsi case final subtitle?) Text(subtitle, style: text.bodySmall),
      ]),
    );
  }
}

class KontenWarga extends StatelessWidget {
  const KontenWarga({super.key, required this.children, this.maxLebar = 1240});
  final List<Widget> children;
  final double maxLebar;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
    final inset = size.maxWidth < 540 ? 16.0 : size.maxWidth < 950 ? 24.0 : 32.0;
    final side = math.max(inset, (size.maxWidth - maxLebar) / 2);
    return ListView(padding: EdgeInsets.fromLTRB(side, inset, side, 30), children: children);
  });
}

class PanelGlow extends StatelessWidget {
  const PanelGlow({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: padding, child: child));
}

class KisiGlow extends StatelessWidget {
  const KisiGlow({super.key, required this.children, this.lebarMinimum = 210,
    this.kolomMaksimal = 3, this.jarak = 12});
  final List<Widget> children;
  final double lebarMinimum;
  final int kolomMaksimal;
  final double jarak;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final count = ((box.maxWidth + jarak) / (lebarMinimum + jarak))
      .floor().clamp(1, kolomMaksimal);
    final width = (box.maxWidth - (count - 1) * jarak) / count;
    return Wrap(spacing: jarak, runSpacing: jarak, children: [
      for (final child in children) SizedBox(width: width, child: child),
    ]);
  });
}

class LabelGlow extends StatelessWidget {
  const LabelGlow(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final dark = c.brightness == Brightness.dark;
    final (bg, fg, mark) = switch (label.toLowerCase()) {
      'selesai' || 'diterima' || 'valid' => (
        dark ? const Color(0xFF214738) : const Color(0xFFDFF5E9),
        dark ? const Color(0xFFB3EACB) : const Color(0xFF216446), Icons.task_alt),
      'ditolak' || 'tidak valid' || 'dibatalkan' => (
        c.errorContainer, c.onErrorContainer, Icons.cancel_outlined),
      'menunggu klarifikasi' || 'klarifikasi masuk' || 'belum dibaca' => (
        dark ? const Color(0xFF503A1D) : const Color(0xFFFFF0CC),
        dark ? const Color(0xFFFFD88E) : const Color(0xFF775016), Icons.info_outline),
      _ => (c.primaryContainer, c.onPrimaryContainer, Icons.circle_outlined),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: 5, children: [
          Icon(icon ?? mark, size: 15, color: fg),
          Flexible(child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}

class KeadaanGlow extends StatelessWidget {
  const KeadaanGlow({super.key, required this.judul, required this.pesan, required this.icon, this.aksi});
  final String judul;
  final String pesan;
  final IconData icon;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) => PanelGlow(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
      Icon(icon, size: 27, color: Theme.of(context).colorScheme.primary),
      Text(judul, style: Theme.of(context).textTheme.titleMedium),
      Text(pesan, style: Theme.of(context).textTheme.bodySmall),
      if (aksi case final action?) action,
    ],
  ));
}

String tanggalWarga(DateTime t) =>
  '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

String waktuWibWarga(DateTime utc) {
  final t = utc.toUtc().add(const Duration(hours: 7));
  return '${tanggalWarga(t)} ${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')} WIB';
}
""";

void perbaruiHalaman() {
  page('login', (s) {
    s = replace(
      s,
      "import '../services/sesi_akun.dart';",
      "import '../services/sesi_akun.dart';\nimport '../widgets/kerangka_warga.dart';",
    );
    s = between(s, 'return Scaffold(', 'Card( child: Padding(', (_) => r"""
return Scaffold(body: SafeArea(child: LayoutBuilder(builder: (context, viewport) {
  final lebar = viewport.maxWidth >= 900;
  const pengantar = BannerGlow(
    judul: 'Pelaporan sampah Kota Bandung',
    pesan: 'Kirim laporan, pantau penanganan, dan lihat bukti pengangkutan.',
    icon: Icons.eco_outlined, aksi: MerekGlow(terang: true),
  );
  final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
""");
    s = replace(
      s,
      "title: const Text('Lihat akun demo'),",
      "leading: const Icon(Icons.people_outline), title: const Text('Pilih akun demo'),",
    );
    s = between(
      s,
      'for (final akun in SesiAkun.daftarDemo.entries)',
      '], ), ), ],',
      (_) => r"""
for (final akun in SesiAkun.daftarDemo.entries)
  ListTile(title: Text(akun.value.label), subtitle: Text(akun.key),
    trailing: const Icon(Icons.arrow_forward, size: 18),
    onTap: _sibuk ? null : () => setState(() {
      _email.text = akun.key;
      _sandi.text = SesiAkun.kataSandiDemo;
      _galat = null;
    })),
""",
    );
    final demo = s.indexOf('for (final akun in SesiAkun.daftarDemo.entries)');
    final offset = anchor('], ), ),').allMatches(s, demo).first.end;

    return s.substring(0, offset) + r"""
  ]);
  final inset = lebar ? 32.0 : 16.0;
  return SingleChildScrollView(padding: EdgeInsets.all(inset),
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: lebar ? (viewport.maxHeight - inset * 2)
        .clamp(0.0, double.infinity) : 0.0),
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: lebar ? 1040 : 480),
        child: lebar
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 24,
              children: [const Expanded(child: pengantar), Expanded(child: form)])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16,
              children: [pengantar, form]),
      )),
    ),
  );
})));
  }
}
""";
  });

  page('beranda', (s) {
    s = between(
      s,
      'const JudulHalamanWarga(',
      'if (!_memuat && _laporan.isEmpty)',
      (_) => r"""
BannerGlow(judul: _nama.isEmpty ? 'Dashboard Warga' : 'Halo, $_nama',
  pesan: 'Laporkan tumpukan sampah dan pantau penanganannya.',
  aksi: FilledButton.icon(
    onPressed: _memuat ? null : () => _buka(MenuWarga.buatLaporan.route),
    icon: const Icon(Icons.add), label: const Text('Buat Laporan'),
    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDBEAFF),
      foregroundColor: const Color(0xFF142B58)),
  )),
const SizedBox(height: 18),
if (_memuat) const LinearProgressIndicator(semanticsLabel: 'Memuat laporan'),
if (_galat case final pesan?)
  KeadaanGlow(judul: 'Laporan belum tersedia', pesan: pesan, icon: Icons.error_outline,
    aksi: OutlinedButton(onPressed: _muat, child: const Text('Muat ulang')))
else if (!_memuat) ...[
  KisiGlow(lebarMinimum: 132, kolomMaksimal: 4, children: [
    _ringkasan('Total laporan', _laporan.length, Icons.receipt_long_outlined, MenuWarga.riwayat),
    _ringkasan('Klarifikasi', _laporan.where((l) => l.statusPenanganan ==
      StatusPenanganan.menungguKlarifikasi).length, Icons.chat_bubble_outline, MenuWarga.riwayat),
    _ringkasan('Selesai', _laporan.where((l) => l.statusPenanganan.nilaiDatabase == 'Selesai').length,
      Icons.task_alt, MenuWarga.riwayat),
    _ringkasan('Belum dibaca', _belumDibaca, Icons.notifications_outlined, MenuWarga.notifikasi),
  ]),
  const SizedBox(height: 22),
  Row(children: [
    Expanded(child: Text('Laporan terbaru', style: Theme.of(context).textTheme.titleLarge)),
    TextButton(onPressed: () => _buka(MenuWarga.riwayat.route), child: const Text('Lihat semua')),
  ]),
  const SizedBox(height: 8),
""",
    );
    s = replace(s, '..._laporan.take(2).map', '..._laporan.take(4).map');
    s = replace(
      s,
      r"""Text('${laporan.kodeLaporan} · ${laporan.statusPenanganan.nilaiDatabase}',
      style: Theme.of(context).textTheme.titleMedium),""",
      r"""
Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
  Text(laporan.kodeLaporan ?? 'Laporan', style: Theme.of(context).textTheme.titleMedium),
  LabelGlow(laporan.statusPenanganan.nilaiDatabase),
]),
""",
    );
    return s.trimRight().replaceFirst(RegExp(r'}$'), r"""
  Widget _ringkasan(String label, int count, IconData icon, MenuWarga menu) {
    final theme = Theme.of(context);
    return Card(child: InkWell(onTap: () => _buka(menu.route),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          Text('$count', style: theme.textTheme.headlineSmall),
          Text(label, style: theme.textTheme.bodySmall),
        ]),
      ),
    ));
  }
}
""");
  });

  page('buat_laporan', (s) {
    s = replace(
      s,
      'child: Align(alignment: Alignment.topLeft, child: ConstrainedBox('
      ' constraints: const BoxConstraints(maxWidth: 1120), child: hasil != null',
      'child: hasil != null',
    );
    s = replace(
      s,
      'child: ListView( padding: const EdgeInsets.all(20), children: [',
      'child: KontenWarga(maxLebar: 920, children: [',
    );
    s = replace(
      s,
      'const SizedBox(height: 32), ], ), ), ), ), ), );',
      'const SizedBox(height: 16), ], ), ), ), );',
    );

    const groups = [
      ('Deskripsi Laporan', 'Unggah Foto', 'description_outlined'),
      ('Unggah Foto', 'Kategori Laporan', 'photo_library_outlined'),
      ('Kategori Laporan', 'Jenis Sampah', 'category_outlined'),
      ('Jenis Sampah', 'Lokasi', 'recycling'),
      ('Lokasi', 'Deskripsi Lokasi', 'location_on_outlined'),
      ('Deskripsi Lokasi', null, 'signpost_outlined'),
    ];
    for (final (label, next, icon) in groups) {
      final start = "_judul('$label'),";
      final end = next == null ? 'if (state.pesanError != null)' : "_judul('$next'),";
      s = between(s, start, end, (body) {
        final contents = body.substring(anchor(start).firstMatch(body)!.end)
            .trimRight().replaceFirst(RegExp(r'const SizedBox\(height: 20\),\s*$'), '');
        return "_seksi('$label', Icons.$icon, [\n$contents]),\nconst SizedBox(height: 14),\n";
      });
    }
    s = between(s, "_seksi('Kategori Laporan',", "_seksi('Lokasi',", (body) {
      final end = body.replaceAll(RegExp(r'const SizedBox\(height: 14\),\s*'), '');
      return "KisiGlow(kolomMaksimal: 2, lebarMinimum: 320, children: [\n$end]),\n"
          "const SizedBox(height: 14),\n";
    });
    return between(s, 'Widget _judul(', 'Widget _tampilanBerhasil', (_) => r"""
Widget _seksi(String judul, IconData icon, List<Widget> children) => PanelGlow(
  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 9, children: [
    Row(spacing: 10, children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      Expanded(child: Text(judul, style: Theme.of(context).textTheme.titleMedium)),
    ]),
    ...children,
  ]),
);

""");
  });

  page('riwayat_laporan', (s) {
    s = between(s, "_label('Status'),", 'if (_semua.isEmpty)', (body) {
      body = replace(
        body,
        "_label('Status'),",
        "PanelGlow(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: ["
        " Text('Filter laporan', style: Theme.of(context).textTheme.titleMedium),"
        " KisiGlow(children: [",
      );
      body = replace(
        body,
        "InputDecoration(hintText: 'Semua status')",
        "InputDecoration(labelText: 'Status', hintText: 'Semua status')",
      );
      body = replace(body, r"""
const SizedBox(height: 14), _label('Tanggal awal'),
_kolomTanggal(_awalPilihan, () => _pilihTanggal(true)),
const SizedBox(height: 14), _label('Tanggal akhir'),
_kolomTanggal(_akhirPilihan, () => _pilihTanggal(false)),
""", r"""
_kolomTanggal('Tanggal awal', _awalPilihan, () => _pilihTanggal(true)),
_kolomTanggal('Tanggal akhir', _akhirPilihan, () => _pilihTanggal(false)),
]),
""");
      return replace(body, r"""
const SizedBox(height: 18),
FilledButton(onPressed: _terapkanFilter, child: const Text('Terapkan Filter')),
const SizedBox(height: 10),
OutlinedButton(onPressed: _resetFilter, child: const Text('Reset Filter')),
const SizedBox(height: 18),
""", r"""
Wrap(spacing: 8, runSpacing: 6, children: [
  FilledButton.icon(onPressed: _terapkanFilter, icon: const Icon(Icons.filter_list),
    label: const Text('Terapkan Filter')),
  TextButton(onPressed: _resetFilter, child: const Text('Reset Filter')),
]),
])),
const SizedBox(height: 16),
""");
    });

    s = between(s, 'Widget _label(String label)', 'Widget _kolomTanggal', (_) => '');
    s = replace(
      s,
      'Widget _kolomTanggal(DateTime? tanggal, VoidCallback pilih)',
      'Widget _kolomTanggal(String label, DateTime? tanggal, VoidCallback pilih)',
    );
    s = replace(
      s,
      "Text(tanggal == null ? 'Pilih tanggal' : tanggalWarga(tanggal))",
      r"""Text(tanggal == null ? label : '$label · ${tanggalWarga(tanggal)}')""",
    );
    s = replace(
      s,
      r"""Text('${item.kodeLaporan} · ${item.statusPenanganan.nilaiDatabase}',
      style: Theme.of(context).textTheme.titleMedium),""",
      r"""
Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
  Text(item.kodeLaporan ?? 'Laporan', style: Theme.of(context).textTheme.titleMedium),
  LabelGlow(item.statusPenanganan.nilaiDatabase),
]),
""",
    );
    s = replace(s, "this.namaWarga = '',", "this.namaWarga = '', this.bukaAktivitas = false,");
    s = replace(s, 'final String namaWarga;', 'final String namaWarga; final bool bukaAktivitas;');
    s = replace(
      s,
      ': ListView(padding: const EdgeInsets.all(20), children: [',
      ': DefaultTabController(length: 2, initialIndex: widget.bukaAktivitas ? 1 : 0,'
      ' child: Column(children: ['
      " const TabBar(tabs: [Tab(text: 'Ringkasan'), Tab(text: 'Penanganan')]),"
      ' Expanded(child: TabBarView(physics: const NeverScrollableScrollPhysics(), children: ['
      ' KontenWarga(children: [',
    );
    s = replace(
      s,
      'Chip(label: Text(laporan.statusPenanganan.nilaiDatabase))',
      'LabelGlow(laporan.statusPenanganan.nilaiDatabase)',
    );
    s = between(
      s,
      "_bagian('Pelapor', _namaWarga),",
      "_bagian('Foto kondisi sampah',",
      (fields) => "KisiGlow(children: [\n$fields]),\n",
    );
    s = replace(
      s,
      'SizedBox(height: 320, child: PetaLaporan(',
      'SizedBox(height: MediaQuery.sizeOf(context).width < 760 ? 230 : 320, child: PetaLaporan(',
    );
    s = replace(s, 'if (laporan.diterimaAtUtc case final waktu?)', r"""
]),
KontenWarga(children: [
  JudulHalamanWarga(judul: 'Penanganan Laporan', deskripsi: laporan.kodeLaporan),
  if (laporan.diterimaAtUtc case final waktu?)
""");
    return replace(
      s,
      'const SizedBox(height: 24), ]), )),',
      'const SizedBox(height: 24), ]), ])), ])), )),',
    );
  });

  page('notifikasi_warga', (s) {
    s = replace(s, 'bool _membuka = false;', 'bool _membuka = false; bool _belumSaja = false;');
    s = replace(
      s,
      'builder: (_) => DetailLaporanTersimpan( idLaporan: item.idLaporan, idWarga: widget.idWarga,',
      "builder: (_) => DetailLaporanTersimpan(idLaporan: item.idLaporan, idWarga: widget.idWarga,"
      " bukaAktivitas: item.jenis == 'tanggapan',",
    );
    s = replace(s, 'else if (_daftar.isEmpty)', r"""
else ...[
Wrap(spacing: 8, runSpacing: 8, children: [
  ChoiceChip(label: const Text('Semua'), selected: !_belumSaja,
    onSelected: (_) => setState(() => _belumSaja = false)),
  ChoiceChip(label: Text('Belum dibaca (${_daftar.where((n) => !n.sudahDibaca).length})'),
    selected: _belumSaja, onSelected: (_) => setState(() => _belumSaja = true)),
]),
const SizedBox(height: 14),
if (!_daftar.any((n) => !_belumSaja || !n.sudahDibaca))
""");
    s = replace(
      s,
      'else ..._daftar.map',
      'else ..._daftar.where((n) => !_belumSaja || !n.sudahDibaca).map',
    );
    s = replace(
      s,
      "const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Belum ada notifikasi untuk akun Anda.')))",
      "const KeadaanGlow(judul: 'Tidak ada notifikasi', pesan: 'Pembaruan laporan akan tampil di sini.', icon: Icons.notifications_none)",
    );
    return replace(
      s,
      ')), const SizedBox(height: 12), Align(',
      ')), ], const SizedBox(height: 12), Align(',
    );
  });

  page('dashboard_operasional', (s) {
    s = replace(
      s,
      'this.daftarLengkap = false}',
      'this.daftarLengkap = false, this.khususJadwal = false}',
    );
    s = replace(s, 'final bool daftarLengkap;', 'final bool daftarLengkap; final bool khususJadwal;');
    s = replace(
      s,
      "ruteAktif: widget.daftarLengkap ? '/admin/laporan' : '/',",
      "ruteAktif: widget.khususJadwal ? '/admin/jadwal' : widget.daftarLengkap ? '/admin/laporan' : '/',",
    );
    s = replace(
      s,
      "judul: widget.daftarLengkap ? 'Daftar dan Riwayat Laporan' : 'Dashboard Admin',",
      "judul: widget.khususJadwal ? 'Penjadwalan Pengangkutan' : widget.daftarLengkap ?"
      " 'Daftar dan Riwayat Laporan' : 'Dashboard Admin',",
    );
    s = replace(
      s,
      'deskripsi: widget.daftarLengkap',
      "deskripsi: widget.khususJadwal ? 'Atur tim dan waktu pengangkutan.' : widget.daftarLengkap",
    );
    s = replace(
      s,
      'if (!widget.daftarLengkap) ...[',
      'if (!widget.daftarLengkap && !widget.khususJadwal) ...[',
    );
    s = replace(
      s,
      'if (widget.daftarLengkap) _panelFilter(), ..._isiLaporan(snapshot.data ?? const []),',
      r"""
if (widget.khususJadwal) ..._isiJadwal(snapshot.data ?? const [])
else ...[
  if (widget.daftarLengkap) _panelFilter(),
  ..._isiLaporan(snapshot.data ?? const []),
],
""",
    );
    s = replace(s, 'List<Widget> _isiLaporan(List<Map<String, Object?>> semua) {', r"""
List<Widget> _isiJadwal(List<Map<String, Object?>> semua) {
  final siap = semua.where(_siapJadwal).toList();
  final jalan = semua.where((l) => l['status_penanganan'] == 'Diproses').toList();
  return [
    for (final (judul, daftar, aktif) in [
      ('Siap dijadwalkan', siap, false), ('Penugasan berjalan', jalan, true),
    ]) ...[
      Text(judul, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      if (daftar.isEmpty)
        const KeadaanGlow(judul: 'Belum ada laporan',
          pesan: 'Daftar ini diperbarui setelah status laporan berubah.', icon: Icons.event_busy_outlined)
      else KisiGlow(lebarMinimum: 380, kolomMaksimal: 2, children: [
        for (final item in daftar) _kartuLaporan(item, jadwalAktif: aktif),
      ]),
      const SizedBox(height: 20),
    ],
  ];
}

List<Widget> _isiLaporan(List<Map<String, Object?>> semua) {
""");
    s = replace(
      s,
      'Wrap(spacing: 10, runSpacing: 10, children: [',
      'KisiGlow(lebarMinimum: 128, kolomMaksimal: 5, children: [',
    );
    s = replace(
      s,
      'Widget _kartuLaporan(Map<String, Object?> item)',
      'Widget _kartuLaporan(Map<String, Object?> item, {bool jadwalAktif = false})',
    );
    s = replace(s, 'if (_siapJadwal(item))', 'if (_siapJadwal(item) || jadwalAktif)');
    s = replace(
      s,
      "label: const Text('Jadwalkan Pengangkutan'),",
      "label: Text(jadwalAktif ? 'Lihat jadwal' : 'Jadwalkan Pengangkutan'),",
    );
    s = replace(s, 'Chip(label: Text(status))', 'LabelGlow(status)');
    return replace(s, "Chip(label: Text('Klarifikasi masuk'))", "LabelGlow('Klarifikasi masuk')");
  });

  page('jadwal_operasional', (s) {
    s = replace(
      s,
      'const DashboardPetugas({super.key, required this.akun});',
      "const DashboardPetugas({super.key, required this.akun, this.rute = '/'}); final String rute;",
    );
    s = replace(
      s,
      "peran: PeranAkun.petugas, ruteAktif: '/',",
      'peran: PeranAkun.petugas, ruteAktif: widget.rute,',
    );
    s = replace(s, 'final baru = jadwal.where((tugas) => tugas.belumDibaca).length;', r"""
final baru = jadwal.where((tugas) => tugas.belumDibaca).length;
final notifikasi = widget.rute == '/petugas/notifikasi';
final daftar = notifikasi ? jadwal.where((tugas) => tugas.belumDibaca).toList() : jadwal;
""");
    s = replace(
      s,
      "judul: 'Dashboard Petugas',",
      "judul: notifikasi ? 'Notifikasi Penugasan'"
      " : widget.rute == '/' ? 'Dashboard Petugas' : 'Jadwal Pengangkutan',",
    );
    s = replace(
      s,
      "Text('Jadwal Pengangkutan', style: Theme.of(context).textTheme.titleLarge),",
      "if (widget.rute == '/') Text('Jadwal Pengangkutan', style: Theme.of(context).textTheme.titleLarge),",
    );
    s = replace(s, 'else if (jadwal.isEmpty)', 'else if (daftar.isEmpty)');
    s = replace(
      s,
      "Text('Belum ada penugasan', style:",
      "Text(notifikasi ? 'Semua penugasan sudah dibaca' : 'Belum ada penugasan', style:",
    );
    s = replace(
      s,
      "const Text('Jadwal akan muncul ketika Admin menugaskan akun Anda.'),",
      "Text(notifikasi ? 'Buka menu Jadwal untuk melihat penugasan.'"
      " : 'Jadwal akan muncul ketika Admin menugaskan akun Anda.'),",
    );
    s = replace(s, 'for (final tugas in jadwal)', 'for (final tugas in daftar)');
    s = replace(
      s,
      "peran: PeranAkun.admin, ruteAktif: '',",
      "peran: PeranAkun.admin, ruteAktif: '/admin/jadwal',",
    );
    s = replace(s, 'Chip(label: Text(tugas.jadwal.status))', 'LabelGlow(tugas.jadwal.status)');
    s = replace(s, "Chip(label: Text('Belum dibaca'))", "LabelGlow('Belum dibaca')");
    s = replace(
      s,
      'Text(tugas.jadwal.status, style: Theme.of(context).textTheme.titleMedium)',
      'Align(alignment: Alignment.centerLeft, child: LabelGlow(tugas.jadwal.status))',
    );
    s = replace(s, 'height: 280,', 'height: MediaQuery.sizeOf(context).width < 760 ? 220 : 320,');
    s = replace(s, 'setState(() => _data = _muat())', 'setState(() { _data = _muat(); })');
    s = replace(s, 'setState(() => _daftar = _ambil())', 'setState(() { _daftar = _ambil(); })');
    s = replace(s, 'setState(() => _detail = _ambil())', 'setState(() { _detail = _ambil(); })');
    return replace(s, 'label: Text(foto.nama),', r"""
label: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(foto.bytes,
    width: 128, height: 76, cacheWidth: 256, fit: BoxFit.cover,
    errorBuilder: (_, error, stack) => const Icon(Icons.broken_image_outlined))),
  SizedBox(width: 128, child: Text(foto.nama, maxLines: 2, overflow: TextOverflow.ellipsis)),
]),
""");
  });

  page('pemeriksaan_admin', (s) {
    s = replace(
      s,
      "deskripsi: 'Bukti  /  Checklist  /  Keputusan',",
      'deskripsi: bahan.laporan.kodeLaporan,',
    );
    s = replace(s, "judul: bahan.laporan.kodeLaporan ?? 'Laporan',", "judul: 'Status pemeriksaan',");
    s = replace(
      s,
      'Chip(label: Text(bahan.laporan.statusPenanganan.nilaiDatabase))',
      'LabelGlow(bahan.laporan.statusPenanganan.nilaiDatabase)',
    );
    return replace(s, '...switch (_tahap) {', r"""
if (_tahap != _TahapPemeriksaan.bukti || bahan.keputusan.isEmpty) ...[
  Text('Tahap ${_tahap.index + 1} dari 3'),
  const SizedBox(height: 8),
  LinearProgressIndicator(value: (_tahap.index + 1) / 3),
  const SizedBox(height: 14),
],
...switch (_tahap) {
""");
  });

  page('klarifikasi_warga', (s) {
    s = replace(s, 'child: KontenWarga(children: [', 'child: KontenWarga(maxLebar: 920, children: [');
    return between(
      s,
      "_KartuKlarifikasi(judul: 'Bukti tambahan'",
      'if (_galat case final pesan?)',
      (body) => 'KisiGlow(kolomMaksimal: 2, lebarMinimum: 310, children: [\n$body]),\n'
          'const SizedBox(height: 12),\n',
    );
  });

  page('pilih_lokasi_laporan', (s) {
    s = replace(
      s,
      'child: Align(alignment: Alignment.topLeft, child: ConstrainedBox('
      ' constraints: const BoxConstraints(maxWidth: 1120), child: ListView('
      ' padding: const EdgeInsets.all(16), children: [',
      'child: KontenWarga(children: [',
    );
    s = replace(s, "judul: 'Mencari Titik Lokasi',", "judul: 'Tentukan Lokasi',");
    s = replace(
      s,
      'SizedBox( height: 380, child: PetaLaporan(',
      'ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox('
      ' height: MediaQuery.sizeOf(context).width < 760 ? 270 : 420, child: PetaLaporan(',
    );
    s = replace(
      s,
      '), ), const SizedBox(height: 16), Text(titik == null',
      '), )), const SizedBox(height: 16), PanelGlow(child: Column('
      'crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: [ Text(titik == null',
    );
    return replace(
      s,
      "child: const Text('Kembali ke Formulir'), ), ], ), ), ),",
      "child: const Text('Kembali ke Formulir'), ), ])), ]),",
    );
  });

  change('lib/navigation/app_routes.dart', (s) => replace(s, 'daftarLaporanAdmin: _untukPeran(', r"""
'/admin/jadwal': _untukPeran(PeranAkun.admin, (akun) => DashboardAdmin(akun: akun, khususJadwal: true)),
'/petugas/jadwal': _untukPeran(PeranAkun.petugas, (akun) => DashboardPetugas(akun: akun, rute: '/petugas/jadwal')),
'/petugas/notifikasi': _untukPeran(PeranAkun.petugas,
  (akun) => DashboardPetugas(akun: akun, rute: '/petugas/notifikasi')),
daftarLaporanAdmin: _untukPeran(
"""));

  changes['lib/pages/route_tidak_dikenal.dart'] = r"""
import 'package:flutter/material.dart';
import '../widgets/kerangka_warga.dart';

class RouteTidakDikenal extends StatelessWidget {
  const RouteTidakDikenal({super.key, this.namaRoute});
  final String? namaRoute;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
      child: KeadaanGlow(judul: 'Halaman tidak ditemukan',
        pesan: namaRoute ?? 'Kembali ke dashboard untuk melanjutkan.',
        icon: Icons.search_off,
        aksi: FilledButton.icon(
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          icon: const Icon(Icons.arrow_back), label: const Text('Kembali ke Dashboard'),
        )),
    ),
  )));
}
""";
}