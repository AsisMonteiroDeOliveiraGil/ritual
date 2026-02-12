import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/features/habits/presentation/providers/new_habit_draft_provider.dart';

class AddHabitCategoryScreen extends ConsumerWidget {
  const AddHabitCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFF111111);
    const accent = Color(0xFFC63C54);
    final categories = [
      _CategoryItem(
        label: 'Dejar un mal hábito',
        icon: Icons.block,
        color: Color(0xFFE24B3C),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Arte',
        icon: Icons.brush,
        color: Color(0xFFFF3B5B),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Meditación',
        icon: Icons.self_improvement,
        color: Color(0xFFD44BC4),
        iconName: 'skin',
      ),
      _CategoryItem(
        label: 'Estudio',
        icon: Icons.school,
        color: Color(0xFF8E5CF6),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Deportes',
        icon: Icons.pedal_bike,
        color: Color(0xFF4F79F6),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Entretenimiento',
        icon: Icons.movie,
        color: Color(0xFF00B3C7),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Social',
        icon: Icons.forum,
        color: Color(0xFF14B89A),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Finanzas',
        icon: Icons.attach_money,
        color: Color(0xFF17B86D),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Salud',
        icon: Icons.add,
        color: Color(0xFF7FC34A),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Trabajo',
        icon: Icons.work,
        color: Color(0xFF99B01F),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Nutrición',
        icon: Icons.restaurant,
        color: Color(0xFFF4B23C),
        iconName: 'water',
      ),
      _CategoryItem(
        label: 'Hogar',
        icon: Icons.home,
        color: Color(0xFFF28E2B),
        iconName: 'check',
      ),
      _CategoryItem(
        label: 'Al aire libre',
        icon: Icons.terrain,
        color: Color(0xFFE46E2E),
        iconName: 'sun',
      ),
      _CategoryItem(
        label: 'Otro',
        icon: Icons.category,
        color: Color(0xFFE64B2E),
        iconName: 'check',
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Selecciona una categoría para tu hábito',
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.0,
                ),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == categories.length) {
                    return _CreateCategoryTile(
                      onTap: () {},
                    );
                  }
                  final item = categories[index];
                    return _CategoryTile(
                      item: item,
                      onTap: () {
                        ref.read(newHabitDraftProvider.notifier).setCategory(
                              label: item.label,
                              iconName: item.iconName,
                              color: item.color.toARGB32(),
                            );
                        context.push('/habit/new/eval');
                      },
                    );
                },
              ),
            ),
            const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final String iconName;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.iconName,
  });
}

class _CategoryTile extends StatelessWidget {
  final _CategoryItem item;
  final VoidCallback? onTap;

  const _CategoryTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: Colors.black87, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCategoryTile extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateCategoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Crear categoría',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '5 disponibles',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white54, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: const [
              _Dot(active: true),
              _Dot(active: false),
              _Dot(active: false),
              _Dot(active: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accent : Colors.transparent,
        border: Border.all(color: accent, width: 1),
      ),
    );
  }
}
