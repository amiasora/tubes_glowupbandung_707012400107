import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfiWeb;

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HalamanUjiSqlite(),
    ),
  );
}

// Singleton: satu pengelola koneksi untuk pengujian.
class UjiDatabaseHelper {
  UjiDatabaseHelper._();

  static final UjiDatabaseHelper instance = UjiDatabaseHelper._();

  Future<Database>? _koneksi;

  Future<Database> get database {
    return _koneksi ??= openDatabase(
      'glowup_uji_sqlite.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE catatan_uji (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            isi TEXT NOT NULL,
            dibuat_at_utc TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> tambahData() async {
    final db = await database;

    return db.insert('catatan_uji', {
      'isi': 'Pengujian persistensi Glow Up Bandung',
      'dibuat_at_utc': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> bacaData() async {
    final db = await database;

    return db.query(
      'catatan_uji',
      columns: ['id', 'isi', 'dibuat_at_utc'],
      orderBy: 'id DESC',
    );
  }

  Future<String> bacaVersiSqlite() async {
    final db = await database;
    final hasil = await db.rawQuery('SELECT sqlite_version() AS versi');

    return hasil.single['versi'].toString();
  }
}

class HalamanUjiSqlite extends StatefulWidget {
  const HalamanUjiSqlite({super.key});

  @override
  State<HalamanUjiSqlite> createState() => _HalamanUjiSqliteState();
}

class _HalamanUjiSqliteState extends State<HalamanUjiSqlite> {
  final _database = UjiDatabaseHelper.instance;

  List<Map<String, Object?>> _daftar = [];
  String _versiSqlite = '-';
  String? _pesanError;
  bool _sibuk = false;

  @override
  void initState() {
    super.initState();

    // Saat halaman dibuka, hanya membaca data yang sudah tersimpan.
    _proses();
  }

  Future<void> _proses({bool tambah = false}) async {
    if (_sibuk) return;

    setState(() {
      _sibuk = true;
      _pesanError = null;
    });

    try {
      if (tambah) {
        await _database.tambahData();
      }

      final daftar = await _database.bacaData();
      final versi = await _database.bacaVersiSqlite();

      if (!mounted) return;

      setState(() {
        _daftar = daftar;
        _versiSqlite = versi;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _pesanError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _sibuk = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uji SQLite Glow Up Bandung')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi SQLite: $_versiSqlite'),
            const SizedBox(height: 8),
            Text(
              'Jumlah data tersimpan: ${_daftar.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _sibuk ? null : () => _proses(tambah: true),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah data uji'),
                ),
                OutlinedButton.icon(
                  onPressed: _sibuk ? null : () => _proses(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat ulang data'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_sibuk) const LinearProgressIndicator(),
            if (_pesanError != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                'Gagal mengakses SQLite:\n$_pesanError',
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _daftar.isEmpty
                  ? const Center(child: Text('Belum ada data uji.'))
                  : ListView.builder(
                      itemCount: _daftar.length,
                      itemBuilder: (context, index) {
                        final data = _daftar[index];

                        return Card(
                          child: ListTile(
                            title: Text('#${data['id']} — ${data['isi']}'),
                            subtitle: Text(
                              'Waktu UTC: ${data['dibuat_at_utc']}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
