import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'qr_download.dart';

void showTableQrDialog(BuildContext context, Map<String, dynamic> table) {
  final qrKey = GlobalKey();
  final url = Uri.https('bm-gold-cafe-2026.web.app', '/', {
    'table': table['id'] as String,
  }).toString();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('QR code · ${table['name']}'),
      content: SizedBox(
        width: 260,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF8F2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFF1E7D6)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QrImageView(
                            data: url,
                            size: 220,
                            padding: const EdgeInsets.all(10),
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      for (final alignment in [
                        Alignment.topLeft,
                        Alignment.topRight,
                        Alignment.bottomLeft,
                        Alignment.bottomRight,
                      ])
                        Align(
                          alignment: alignment,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: alignment.y < 0
                                      ? const BorderSide(
                                          color: Color(0xFFCF922D),
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                  bottom: alignment.y > 0
                                      ? const BorderSide(
                                          color: Color(0xFFCF922D),
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                  left: alignment.x < 0
                                      ? const BorderSide(
                                          color: Color(0xFFCF922D),
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                  right: alignment.x > 0
                                      ? const BorderSide(
                                          color: Color(0xFFCF922D),
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA8124),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Table',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${table['name']}',
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                'ID : ${table['id']}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce code ouvre le menu du café.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (kIsWeb)
          TextButton.icon(
            onPressed: () async {
              try {
                final boundary =
                    qrKey.currentContext?.findRenderObject()
                        as RenderRepaintBoundary?;
                if (boundary == null) {
                  throw StateError('QR code indisponible');
                }
                final image = await boundary.toImage(pixelRatio: 3);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                if (data == null) throw StateError('Image indisponible');
                downloadQr(
                  data.buffer.asUint8List(
                    data.offsetInBytes,
                    data.lengthInBytes,
                  ),
                  'table-${table['id']}.png',
                );
              } catch (error) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Téléchargement impossible : $error'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Télécharger'),
          ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            Navigator.pop(ctx);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Lien copié')));
          },
          child: const Text('Copier le lien'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _tables = [];
  bool _loading = true;
  int _selectedTab = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _client
          .from('cafe_tables')
          .select()
          .order('created_at');
      if (!mounted) return;
      setState(() {
        _tables = List<Map<String, dynamic>>.from(rows);
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Impossible de charger les tables. Vérifiez la connexion et la configuration des réservations.';
        _loading = false;
      });
    }
  }

  Future<void> _save(
    Map<String, dynamic>? table,
    Map<String, dynamic> values, {
    int? suggestedNumber,
  }) async {
    try {
      if (table == null) {
        await _client.rpc(
          'create_numbered_cafe_table',
          params: {
            'p_name': values['name'],
            'p_capacity': values['capacity'],
            'p_suggested_number': suggestedNumber,
          },
        );
      } else {
        await _client
            .from('cafe_tables')
            .update(values)
            .eq('id', table['id'])
            .eq('booked', table['booked'])
            .select()
            .single();
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement impossible : $error')),
        );
      }
    }
  }

  Future<void> _tableDialog([Map<String, dynamic>? table]) async {
    int? suggestedNumber;
    if (table == null) {
      try {
        suggestedNumber =
            (await _client.rpc('peek_next_cafe_table_number') as num).toInt();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La numérotation des tables doit être configurée dans Supabase.',
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
    }
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(
      text: table?['name'] as String? ?? '$suggestedNumber',
    );
    final capacity = TextEditingController(text: '${table?['capacity'] ?? 4}');
    final client = TextEditingController(
      text: table?['guest_name'] as String? ?? '',
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD2A64A),
            surface: Color(0xFF211F1E),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: Color(0xFFE1CFAD), fontSize: 13),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCC5BE)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD2A64A), width: 2),
            ),
            counterStyle: TextStyle(color: Color(0xFFCCC5BE)),
          ),
        ),
        child: AlertDialog(
          backgroundColor: const Color(0xFF211F1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            table == null ? 'Ajouter une table' : 'Modifier la table',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      maxLength: 80,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nom ou numéro de table',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Indiquez un nom.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: capacity,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de places',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) {
                        final number = int.tryParse(value ?? '');
                        return number == null || number < 1 || number > 100
                            ? 'Entrez un nombre entre 1 et 100.'
                            : null;
                      },
                    ),
                    if (table != null) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: client,
                        maxLength: 100,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Réservée au nom de (facultatif)',
                          helperText:
                              'Un nom indique que la table est réservée.',
                          helperMaxLines: 2,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFFD2A64A)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD2A64A),
                foregroundColor: const Color(0xFF211F1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, {
                    'name': name.text.trim(),
                    'capacity': int.parse(capacity.text),
                    if (table != null) ...{
                      'guest_name': client.text.trim().isEmpty
                          ? null
                          : client.text.trim(),
                      if (client.text.trim().isNotEmpty) 'booked': true,
                    },
                  });
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await _save(table, result, suggestedNumber: suggestedNumber);
    }
    name.dispose();
    capacity.dispose();
    client.dispose();
  }

  Future<void> _bookDialog(Map<String, dynamic> table) async {
    final guest = TextEditingController(
      text: table['guest_name'] as String? ?? '',
    );
    final phone = TextEditingController(
      text: table['guest_phone'] as String? ?? '',
    );
    DateTime? when = table['booked_for'] == null
        ? null
        : DateTime.tryParse(table['booked_for'] as String)?.toLocal();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('Réserver ${table['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: guest,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nom du client (facultatif)',
                  ),
                ),
                TextField(
                  controller: phone,
                  maxLength: 40,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (facultatif)',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(
                    when == null
                        ? 'Date et heure (facultatif)'
                        : '${when!.day.toString().padLeft(2, '0')}/${when!.month.toString().padLeft(2, '0')}/${when!.year}  ${when!.hour.toString().padLeft(2, '0')}:${when!.minute.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final initial = when ?? DateTime.now();
                    final day = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (day == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(initial),
                    );
                    if (time != null) {
                      refresh(
                        () => when = DateTime(
                          day.year,
                          day.month,
                          day.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  },
                ),
                if (when != null)
                  TextButton(
                    onPressed: () => refresh(() => when = null),
                    child: const Text('Effacer la date'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'booked': true,
                'guest_name': guest.text.trim().isEmpty
                    ? null
                    : guest.text.trim(),
                'guest_phone': phone.text.trim().isEmpty
                    ? null
                    : phone.text.trim(),
                'booked_for': when?.toUtc().toIso8601String(),
              }),
              child: const Text('Réserver'),
            ),
          ],
        ),
      ),
    );
    if (result != null) await _save(table, result);
    guest.dispose();
    phone.dispose();
  }

  Future<void> _delete(Map<String, dynamic> table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la table ?'),
        content: Text(
          'Le QR code de ${table['name']} sera retiré de la liste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _client
          .from('cafe_tables')
          .delete()
          .eq('id', table['id'])
          .select()
          .single();
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression impossible : $error')),
        );
      }
    }
  }

  Widget _tableCard(Map<String, dynamic> table) {
    final booked = table['booked'] == true;
    final when = table['booked_for'] == null
        ? null
        : DateTime.tryParse(table['booked_for'] as String)?.toLocal();
    final details = [
      if (table['guest_name'] != null) 'Réservée pour : ${table['guest_name']}',
      if (table['guest_phone'] != null) table['guest_phone'],
      if (when != null)
        '${when.day}/${when.month}/${when.year} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFECE4DE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: booked
                    ? const Color(0xFFFFE9E2)
                    : const Color(0xFFE4F3E5),
                child: Text(
                  booked ? '● Réservée' : '● Disponible',
                  style: TextStyle(
                    fontSize: 10,
                    color: booked
                        ? const Color(0xFFAA5136)
                        : const Color(0xFF278147),
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Options de la table',
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert,
                  size: 19,
                  color: Color(0xFF716E6A),
                ),
                onSelected: (value) {
                  if (value == 'edit') _tableDialog(table);
                  if (value == 'delete') _delete(table);
                  if (value == 'details') _bookDialog(table);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Modifier la table'),
                  ),
                  if (booked)
                    const PopupMenuItem(
                      value: 'details',
                      child: Text('Modifier la réservation'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/reservation_table.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 105,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: const Color(0xFFECE4DE),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        table['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF292725),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Color(0xFF7E7B78),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${table['capacity']} place(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF706D6A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (booked && details.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF706D6A),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => showTableQrDialog(context, table),
                            tooltip: 'QR code',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.qr_code,
                              size: 20,
                              color: Color(0xFFB58A38),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => booked
                                  ? _save(table, {
                                      'booked': false,
                                      'guest_name': null,
                                      'guest_phone': null,
                                      'booked_for': null,
                                    })
                                  : _bookDialog(table),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB28736),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 34),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: Text(
                                booked ? 'Libérer' : 'Réserver',
                                maxLines: 1,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, int count, String label) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: const Color(0xFFB78B39)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6D6966),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(int booked) {
    final labels = ['Vos tables', 'Réservations', 'Statistiques'];
    return Column(
      children: [
        SizedBox(
          height: 132,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/background.jfif',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -.25),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xC9000000)],
                  ),
                ),
              ),
              const Positioned(
                left: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réservations',
                      style: TextStyle(
                        fontSize: 23,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Gérez vos tables et réservations',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    SizedBox(height: 7),
                    SizedBox(
                      width: 32,
                      child: Divider(
                        color: Color(0xFFD0A54E),
                        thickness: 2,
                        height: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
          child: Row(
            children: [
              _summaryItem(
                Icons.table_restaurant_outlined,
                _tables.length,
                'Table(s)',
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE8DED7)),
              _summaryItem(
                Icons.event_available_outlined,
                booked,
                'Réservée(s)',
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE8DED7)),
              _summaryItem(
                Icons.chair_outlined,
                _tables.length - booked,
                'Disponible(s)',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: List.generate(
              labels.length,
              (index) => Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = index),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTab == index
                              ? const Color(0xFFB58A38)
                              : const Color(0xFFE8DED7),
                          width: _selectedTab == index ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: _selectedTab == index
                            ? const Color(0xFFAC7E2A)
                            : const Color(0xFF494746),
                        fontWeight: _selectedTab == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final booked = _tables.where((table) => table['booked'] == true).length;
    final shown = _selectedTab == 1
        ? _tables.where((table) => table['booked'] == true).toList()
        : _tables;
    final seats = _tables.fold<int>(
      0,
      (total, table) => total + (table['capacity'] as int),
    );
    return Theme(
      data: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC39439)),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF5F1),
        floatingActionButton: _selectedTab == 2
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _tableDialog(),
                backgroundColor: const Color(0xFFB28736),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une table'),
              ),
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) => RefreshIndicator(
                          onRefresh: _load,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: _overview(booked)),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  8,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Text(
                                    [
                                      'Vos tables',
                                      'Réservations',
                                      'Statistiques',
                                    ][_selectedTab],
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF292725),
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedTab == 2)
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    100,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: const Text(
                                            'Tables disponibles',
                                          ),
                                          trailing: Text(
                                            '${_tables.length - booked}',
                                          ),
                                        ),
                                        ListTile(
                                          title: const Text('Tables réservées'),
                                          trailing: Text('$booked'),
                                        ),
                                        ListTile(
                                          title: const Text(
                                            'Nombre total de places',
                                          ),
                                          trailing: Text('$seats'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (shown.isEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 45,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _selectedTab == 1
                                            ? 'Aucune table réservée.'
                                            : 'Ajoutez votre première table.',
                                        style: const TextStyle(
                                          color: Color(0xFF77716A),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    110,
                                  ),
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) =>
                                          _tableCard(shown[index]),
                                      childCount: shown.length,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              constraints.maxWidth >= 650
                                              ? 2
                                              : 1,
                                          crossAxisSpacing: 24,
                                          mainAxisSpacing: 0,
                                          mainAxisExtent: 220,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton.filled(
                        tooltip: 'Retour',
                        onPressed: () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
