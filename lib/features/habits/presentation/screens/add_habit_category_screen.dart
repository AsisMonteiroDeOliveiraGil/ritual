import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/features/habits/presentation/providers/new_habit_draft_provider.dart';

class AddHabitCategoryScreen extends ConsumerStatefulWidget {
  const AddHabitCategoryScreen({super.key});

  @override
  ConsumerState<AddHabitCategoryScreen> createState() =>
      _AddHabitCategoryScreenState();
}

class _AddHabitCategoryScreenState extends ConsumerState<AddHabitCategoryScreen> {
  late final List<_CategoryItem> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List<_CategoryItem>.from(_defaultCategories);
  }

  void _selectCategory(_CategoryItem item) {
    ref.read(newHabitDraftProvider.notifier).setCategory(
          label: item.label,
          iconCodePoint: item.icon.codePoint,
          iconName: item.iconName,
          color: item.color.toARGB32(),
        );
    context.push('/habit/new/eval');
  }

  Future<void> _openCreateCategorySheet() async {
    final created = await showModalBottomSheet<_CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const _CreateCategorySheet(),
    );
    if (created == null) return;
    setState(() {
      _categories.add(created);
    });
    _selectCategory(created);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111111);
    const accent = Color(0xFFC63C54);

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
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == _categories.length) {
                    return _CreateCategoryTile(
                      onTap: _openCreateCategorySheet,
                    );
                  }
                  final item = _categories[index];
                  return _CategoryTile(
                    item: item,
                    onTap: () => _selectCategory(item),
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

const _defaultCategories = <_CategoryItem>[
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

class _CreateCategorySheet extends StatefulWidget {
  const _CreateCategorySheet();

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
  static const _icons = <IconData>[
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.pedal_bike,
    Icons.self_improvement,
    Icons.restaurant,
    Icons.fitness_center,
    Icons.book,
    Icons.work,
    Icons.home,
  ];

  static const _colors = <Color>[
    Color(0xFFFF3B5B),
    Color(0xFFD44BC4),
    Color(0xFF8E5CF6),
    Color(0xFF4F79F6),
    Color(0xFF00B3C7),
    Color(0xFF14B89A),
    Color(0xFF17B86D),
    Color(0xFF7FC34A),
    Color(0xFFF4B23C),
    Color(0xFFE46E2E),
  ];

  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = const Color(0xFFFF3B5B);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _nameController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para la categoría')),
      );
      return;
    }
    Navigator.of(context).pop(
      _CategoryItem(
        label: label,
        icon: _selectedIcon,
        color: _selectedColor,
        iconName: _iconNameFromIcon(_selectedIcon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nueva categoría',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _SheetField(
            icon: Icons.edit,
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFC63C54),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Nombre de categoría',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SheetField(
            icon: Icons.crop_original,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons
                  .map(
                    (icon) => _ChoiceChip(
                      selected: icon == _selectedIcon,
                      child: Icon(icon, color: Colors.white70, size: 18),
                      onTap: () => setState(() => _selectedIcon = icon),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _SheetField(
            icon: Icons.invert_colors,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors
                  .map(
                    (color) => _ChoiceChip(
                      selected: color == _selectedColor,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onTap: () => setState(() => _selectedColor = color),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _submit,
              child: const Text(
                'CREAR CATEGORÍA',
                style: TextStyle(
                  color: Color(0xFFC63C54),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _SheetField({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFC63C54) : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

String _iconNameFromIcon(IconData icon) {
  if (icon == Icons.self_improvement) return 'skin';
  if (icon == Icons.restaurant) return 'water';
  if (icon == Icons.terrain) return 'sun';
  return 'check';
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
                    'Personalizada',
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
