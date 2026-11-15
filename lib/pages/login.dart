import 'package:flutter/material.dart';

import '../services/sesi_akun.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_warga.dart';

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({
    super.key,
  });

  @override
  State<HalamanLogin> createState() =>
      _HalamanLoginState();
}

class _HalamanLoginState
    extends State<HalamanLogin> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();

  bool _sibuk = false;
  bool _sembunyikanSandi = true;

  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();

    super.dispose();
  }

  Future<void> _masuk() async {
    if (
      _sibuk ||
      !(_form.currentState?.validate() ?? false)
    ) {
      return;
    }

    setState(() {
      _sibuk = true;
      _galat = null;
    });

    FocusScope.of(context).unfocus();

    try {
      final akun = await SesiAkun.periksaKredensial(
        email: _email.text,
        kataSandi: _sandi.text,
      );

      if (
        !mounted ||
        ModalRoute.of(context)?.isCurrent != true
      ) {
        return;
      }

      if (akun == null) {
        setState(() {
          _galat =
              'Email atau kata sandi tidak sesuai.';
        });

        return;
      }

      SesiAkun.aktifkan(akun);

      Navigator.of(context)
          .pushNamedAndRemoveUntil<Object?>(
            '/',
            (_) => false,
          );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _galat =
            'Akun belum dapat dimuat. '
            'Coba masuk kembali.';
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, batas) {
            final lebar = batas.maxWidth >= 900;
            final form = _formMasuk(context);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: lebar ? 32 : 16,
                vertical: lebar ? 34 : 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: lebar
                      ? (
                          batas.maxHeight - 68
                        ).clamp(
                          0.0,
                          double.infinity,
                        )
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: lebar ? 1060 : 480,
                    ),
                    child: lebar
                        ? Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            spacing: 28,
                            children: [
                              Expanded(
                                child: _pengantar(
                                  context,
                                  true,
                                ),
                              ),
                              Expanded(
                                child: form,
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            spacing: 16,
                            children: [
                              _pengantar(
                                context,
                                false,
                              ),
                              form,
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pengantar(
    BuildContext context,
    bool lebar,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [
          AppTheme.hijauGelap,
          AppTheme.hijauSedang,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Padding(
      padding: EdgeInsets.all(
        lebar ? 32 : 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        spacing: 16,
        children: [
          const MerekGlow(
            terang: true,
          ),

          if (lebar) ...[
            const SizedBox(height: 22),
            const Icon(
              Icons.eco_outlined,
              size: 96,
              color: AppTheme.aksenTerang,
            ),
          ],

          Text(
            'Pelaporan sampah wilayah Bandung',
            style:
                (
                  lebar
                      ? Theme.of(context)
                            .textTheme
                            .headlineLarge
                      : Theme.of(context)
                            .textTheme
                            .headlineSmall
                )?.copyWith(
                  color: Colors.white,
                ),
          ),

          const Text(
            'Kirim laporan, pantau penanganan, '
            'dan lihat bukti pengangkutan.',
            style: TextStyle(
              color: Color(0xFFE1F4E7),
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _formMasuk(
    BuildContext context,
  ) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        PanelGlow(
          padding: const EdgeInsets.all(22),
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  const JudulHalamanWarga(
                    judul: 'Masuk',
                    deskripsi:
                        'Gunakan akun Glow Up Bandung Anda.',
                  ),

                  TextFormField(
                    controller: _email,
                    enabled: !_sibuk,
                    autofillHints: const [
                      AutofillHints.username,
                    ],
                    autocorrect: false,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(
                        Icons.mail_outline,
                      ),
                    ),
                    validator: (nilai) =>
                        nilai == null ||
                            nilai.trim().isEmpty
                        ? 'Masukkan email akun.'
                        : null,
                  ),

                  TextFormField(
                    controller: _sandi,
                    enabled: !_sibuk,
                    autofillHints: const [
                      AutofillHints.password,
                    ],
                    obscureText: _sembunyikanSandi,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction:
                        TextInputAction.done,
                    onFieldSubmitted: (_) {
                      _masuk();
                    },
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _sembunyikanSandi
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        onPressed: _sibuk
                            ? null
                            : () {
                                setState(() {
                                  _sembunyikanSandi =
                                      !_sembunyikanSandi;
                                });
                              },
                        icon: Icon(
                          _sembunyikanSandi
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (nilai) =>
                        nilai == null || nilai.isEmpty
                        ? 'Masukkan kata sandi.'
                        : null,
                  ),

                  if (_galat case final pesan?)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        pesan,
                        style: TextStyle(
                          color: tema.colorScheme.error,
                        ),
                      ),
                    ),

                  FilledButton.icon(
                    onPressed: _sibuk
                        ? null
                        : _masuk,
                    icon: _sibuk
                        ? const SizedBox.square(
                            dimension: 18,
                            child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                          )
                        : const Icon(
                            Icons.arrow_forward,
                          ),
                    label: Text(
                      _sibuk
                          ? 'Memeriksa akun…'
                          : 'Masuk',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Card(
          child: ExpansionTile(
            leading: const Icon(
              Icons.people_outline,
            ),
            title: const Text(
              'Pilih akun demo',
            ),
            childrenPadding:
                const EdgeInsets.fromLTRB(
                  14,
                  0,
                  14,
                  12,
                ),
            expandedCrossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SelectableText(
                'Kata sandi semua akun demo '
                '${SesiAkun.kataSandiDemo}',
              ),

              for (
                final akun
                    in SesiAkun.daftarDemo.entries
              )
                ListTile(
                  title: Text(
                    akun.value.label,
                  ),
                  subtitle: Text(
                    akun.key,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                  ),
                  onTap: _sibuk
                      ? null
                      : () {
                          setState(() {
                            _email.text = akun.key;
                            _sandi.text =
                                SesiAkun.kataSandiDemo;
                            _galat = null;
                          });
                        },
                ),
            ],
          ),
        ),
      ],
    );
  }
}