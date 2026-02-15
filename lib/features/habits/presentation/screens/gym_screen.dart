import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({super.key});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  static const Color _accent = Color(0xFFC63C54);
  static const Color _doneDayColor = Color(0xFF00C565);
  static const List<String> _trainingTypes = <String>[
    'Pecho',
    'Espalda',
    'Bíceps',
    'Tríceps',
    'Hombro',
    'Pierna',
  ];
  late DateTime _visibleMonth;
  late final PageController _monthPageController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _monthPageController = PageController(initialPage: 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>>? _attendanceRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('gym_attendance');
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateLabel(DateTime date) {
    final month = switch (date.month) {
      1 => 'Enero',
      2 => 'Febrero',
      3 => 'Marzo',
      4 => 'Abril',
      5 => 'Mayo',
      6 => 'Junio',
      7 => 'Julio',
      8 => 'Agosto',
      9 => 'Septiembre',
      10 => 'Octubre',
      11 => 'Noviembre',
      _ => 'Diciembre',
    };
    return '${date.day} $month ${date.year}';
  }

  Future<void> _saveDayTraining(DateTime date) async {
    final ref = _attendanceRef();
    if (ref == null) return;
    final key = _dateKey(date);
    final doc = ref.doc(key);
    final snap = await doc.get();
    final existingTypes = snap.exists
        ? ((snap.data()?['trainingTypes'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList())
        : <String>[];

    final selection = await _showTrainingTypeDialog(
      initialSelection: existingTypes,
      allowDelete: snap.exists,
    );
    if (selection == null) return;
    if (selection.isEmpty) {
      await doc.delete();
      return;
    }

    await doc.set({
      'dateKey': key,
      'trainingTypes': selection,
      'createdAt': snap.exists
          ? (snap.data()?['createdAt'] ?? FieldValue.serverTimestamp())
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<String>?> _showTrainingTypeDialog({
    required List<String> initialSelection,
    required bool allowDelete,
  }) async {
    final selected = <String>{...initialSelection};
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de entrenamiento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._trainingTypes.map(
                    (type) => CheckboxListTile(
                      value: selected.contains(type),
                      onChanged: (value) {
                        setStateSheet(() {
                          if (value == true) {
                            selected.add(type);
                          } else {
                            selected.remove(type);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: _accent,
                      checkColor: Colors.white,
                      title: Text(
                        type,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (allowDelete)
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(<String>[]),
                          child: const Text(
                            'Desmarcar día',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (selected.isEmpty) return;
                          Navigator.of(context).pop(selected.toList()..sort());
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _monthName(int month) {
    return switch (month) {
      1 => 'Enero',
      2 => 'Febrero',
      3 => 'Marzo',
      4 => 'Abril',
      5 => 'Mayo',
      6 => 'Junio',
      7 => 'Julio',
      8 => 'Agosto',
      9 => 'Septiembre',
      10 => 'Octubre',
      11 => 'Noviembre',
      _ => 'Diciembre',
    };
  }

  Widget _buildMonthGrid({
    required DateTime month,
    required Set<String> doneDays,
    required Map<String, List<String>> dayTypes,
  }) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leadingEmpty = firstDay.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final trailingEmpty = (7 - (totalCells % 7)) % 7;
    final gridCount = totalCells + trailingEmpty;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: gridCount,
      itemBuilder: (context, index) {
        if (index < leadingEmpty || index >= leadingEmpty + daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = index - leadingEmpty + 1;
        final date = DateTime(month.year, month.month, day);
        final key = _dateKey(date);
        final isDone = doneDays.contains(key);
        final isSelected =
            _selectedDate != null && DateUtils.isSameDay(date, _selectedDate);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(date.year, date.month, date.day);
            });
          },
          onDoubleTap: () async {
            if (!isDone) return;
            final ref = _attendanceRef();
            if (ref == null) return;
            final messenger = ScaffoldMessenger.of(context);
            await ref.doc(key).delete();
            if (!mounted) return;
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Entrenamiento eliminado'),
                duration: Duration(milliseconds: 900),
              ),
            );
          },
          onLongPress: () => _saveDayTraining(date),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = (constraints.biggest.shortestSide * 1.08).clamp(
                24.0,
                44.0,
              );
              return Center(
                child: Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(side * 0.42),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : isDone
                          ? _doneDayColor
                          : const Color(0xFF2A2E35),
                      width: isSelected ? 2.2 : 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (side * 0.48).clamp(12.0, 18.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRef = _attendanceRef();
    final monthTitle = _monthName(_visibleMonth.month);

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: const Text(
          'Gimnasio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: attendanceRef == null
          ? const Center(
              child: Text(
                'Inicia sesión para guardar tus días de gym.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: attendanceRef.snapshots(),
              builder: (context, snapshot) {
                final doneDays = <String>{};
                final dayTypes = <String, List<String>>{};
                for (final doc in snapshot.data?.docs ?? const []) {
                  final key = doc.data()['dateKey']?.toString();
                  if (key != null && key.isNotEmpty) {
                    doneDays.add(key);
                    final types =
                        (doc.data()['trainingTypes'] as List<dynamic>? ??
                                const [])
                            .map((e) => e.toString())
                            .where((e) => e.isNotEmpty)
                            .toList();
                    dayTypes[key] = types;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _monthPageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white70,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$monthTitle ${_visibleMonth.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _monthPageController.animateToPage(
                              2,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        _WeekdayHeader('L'),
                        _WeekdayHeader('M'),
                        _WeekdayHeader('X'),
                        _WeekdayHeader('J'),
                        _WeekdayHeader('V'),
                        _WeekdayHeader('S'),
                        _WeekdayHeader('D'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gridSpacing = 8.0;
                        final cellSide =
                            (constraints.maxWidth - (gridSpacing * 6)) / 7;
                        final monthGridHeight =
                            (cellSide * 6) + (gridSpacing * 5);
                        return SizedBox(
                          height: monthGridHeight + 2,
                          child: PageView(
                            controller: _monthPageController,
                            onPageChanged: (page) {
                              if (page == 1) return;
                              setState(() {
                                _visibleMonth = DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month + (page == 2 ? 1 : -1),
                                );
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted &&
                                    _monthPageController.hasClients) {
                                  _monthPageController.jumpToPage(1);
                                }
                              });
                            },
                            children: [
                              _buildMonthGrid(
                                month: DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month - 1,
                                ),
                                doneDays: doneDays,
                                dayTypes: dayTypes,
                              ),
                              _buildMonthGrid(
                                month: _visibleMonth,
                                doneDays: doneDays,
                                dayTypes: dayTypes,
                              ),
                              _buildMonthGrid(
                                month: DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month + 1,
                                ),
                                doneDays: doneDays,
                                dayTypes: dayTypes,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Builder(
                      builder: (context) {
                        final selected = _selectedDate;
                        if (selected == null) {
                          return const SizedBox.shrink();
                        }
                        final selectedKey = _dateKey(selected);
                        final selectedTypes =
                            dayTypes[selectedKey] ?? const <String>[];
                        final selectedDone = doneDays.contains(selectedKey);
                        return Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF171717),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF252525)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateLabel(selected),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!selectedDone)
                                const Text(
                                  'Sin entrenamiento registrado.',
                                  style: TextStyle(color: Colors.white60),
                                )
                              else ...[
                                const Text(
                                  'Entrenamiento realizado:',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: selectedTypes
                                      .map(
                                        (type) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _accent.withValues(
                                              alpha: 0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: _accent.withValues(
                                                alpha: 0.45,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            type,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pulsa para ver detalle · Mantén pulsado para registrar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;

  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white60,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
