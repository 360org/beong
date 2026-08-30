import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:flutter/material.dart';

/// Lưới chọn icon chuyên nghiệp phân theo danh mục (6 Tabs), hỗ trợ tìm kiếm và mở rộng.
class IconPickerGrid extends StatefulWidget {
  const IconPickerGrid({
    required this.iconKeys,
    required this.selected,
    required this.onSelected,
    this.initialCount = 8,
    super.key,
  });

  final List<String> iconKeys;
  final String selected;
  final ValueChanged<String> onSelected;
  final int initialCount;

  @override
  State<IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconPickerGridState extends State<IconPickerGrid> {
  Future<void> _openFullPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FullIconPickerModal(
        selected: widget.selected,
        onSelected: (key) {
          Navigator.of(ctx).pop();
          widget.onSelected(key);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.iconKeys;
    final initialCount = widget.initialCount;
    final sub = keys.take(initialCount).toList();
    if (widget.selected.isNotEmpty &&
        !sub.contains(widget.selected) &&
        keys.contains(widget.selected)) {
      sub.add(widget.selected);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final key in sub)
              _IconChoice(
                iconKey: key,
                selected: key == widget.selected,
                onTap: () => widget.onSelected(key),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: () => _openFullPicker(context),
          icon: const Icon(Icons.grid_view_rounded, size: 18),
          label: Text(
            'Xem kho icon đầy đủ (100+ hình)',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

class _FullIconPickerModal extends StatefulWidget {
  const _FullIconPickerModal({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<_FullIconPickerModal> createState() => _FullIconPickerModalState();
}

class _FullIconPickerModalState extends State<_FullIconPickerModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kIconCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Container(
      height: media.size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SheetHeader(title: 'Chọn biểu tượng (100+)'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm icon...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: context.colors.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          if (_searchQuery.isEmpty)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: context.colors.primary,
              unselectedLabelColor: context.semantic.onSurfaceMuted,
              indicatorColor: context.colors.primary,
              tabs: [
                for (final cat in kIconCategories)
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(cat.iconKey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          cat.nameVi,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const Divider(height: 1),
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      for (final cat in kIconCategories)
                        _buildIconGrid(cat.keys),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final matches = taskIcons.keys
        .where((k) => k.toLowerCase().contains(_searchQuery))
        .toList();
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy icon phù hợp',
          style: context.text.bodyMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
      );
    }
    return _buildIconGrid(matches);
  }

  Widget _buildIconGrid(List<String> keys) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: keys.length,
      itemBuilder: (context, idx) {
        final key = keys[idx];
        return _IconChoice(
          iconKey: key,
          selected: key == widget.selected,
          onTap: () => widget.onSelected(key),
        );
      },
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.15)
          : context.colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AppIcon(iconKey, size: 28),
          ),
        ),
      ),
    );
  }
}
