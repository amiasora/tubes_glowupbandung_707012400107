import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../pages/beranda.dart';
import '../pages/laporan.dart';
import '../pages/profil.dart';

class KerangkaNavigasi extends StatefulWidget {
  const KerangkaNavigasi({super.key});

  @override
  State<KerangkaNavigasi> createState() =>
      _KerangkaNavigasiState();
}

class _KerangkaNavigasiState
    extends State<KerangkaNavigasi> {
  int indeksAktif = 0;

  final List<Widget> halaman = const [
    Beranda(),
    Laporan(),
    Profil(),
  ];

  void pilihTujuan(int indeks) {
    setState(() {
      indeksAktif = indeks;
    });
  }

  void bukaMenuPendukung(
    BuildContext context,
    String route,
  ) {
    Navigator.pop(context);

    Navigator.pushNamed(
      context,
      route,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.sizeOf(context).width;
    final layarLebar = lebarLayar >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glow Up Bandung'),
        centerTitle: true,
      ),

      drawer: NavigationDrawer(
        onDestinationSelected: (indeks) {
          if (indeks < 3) {
            Navigator.pop(context);
            pilihTujuan(indeks);
          } else if (indeks == 3) {
            bukaMenuPendukung(
              context,
              AppRoutes.riwayatLaporan,
            );
          } else if (indeks == 4) {
            bukaMenuPendukung(
              context,
              AppRoutes.pengaturan,
            );
          } else if (indeks == 5) {
            bukaMenuPendukung(
              context,
              AppRoutes.tentangAplikasi,
            );
          }
        },
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(
              28,
              24,
              16,
              12,
            ),
            child: Text(
              'Glow Up Bandung',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Beranda'),
          ),

          NavigationDrawerDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report),
            label: Text('Laporan'),
          ),

          NavigationDrawerDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profil'),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 10,
            ),
            child: Divider(),
          ),

          NavigationDrawerDestination(
            icon: Icon(Icons.history),
            label: Text('Riwayat Laporan'),
          ),

          NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            label: Text('Pengaturan'),
          ),

          NavigationDrawerDestination(
            icon: Icon(Icons.info_outline),
            label: Text('Tentang Aplikasi'),
          ),
        ],
      ),

      body: Row(
        children: [
          if (layarLebar)
            NavigationRail(
              selectedIndex: indeksAktif,
              onDestinationSelected: pilihTujuan,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Icon(
                  Icons.eco,
                  size: 32,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Beranda'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.report_outlined),
                  selectedIcon: Icon(Icons.report),
                  label: Text('Laporan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profil'),
                ),
              ],
            ),

          Expanded(
            child: IndexedStack(
              index: indeksAktif,
              children: halaman,
            ),
          ),
        ],
      ),

      bottomNavigationBar: layarLebar
          ? null
          : NavigationBar(
              selectedIndex: indeksAktif,
              onDestinationSelected: pilihTujuan,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.report_outlined),
                  selectedIcon: Icon(Icons.report),
                  label: 'Laporan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }
}