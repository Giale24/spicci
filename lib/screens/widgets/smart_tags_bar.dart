import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category.dart';

class SmartTagsBar extends StatelessWidget {
  final String categoryId;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;
  final bool isNoteFieldVisible;
  final VoidCallback onToggleNoteField;

  const SmartTagsBar({
    super.key,
    required this.categoryId,
    required this.selectedTag,
    required this.onTagSelected,
    required this.isNoteFieldVisible,
    required this.onToggleNoteField,
  });

  @override
  Widget build(BuildContext context) {
    final category = Category.byId(categoryId);
    final tags = category.smartTags;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Tasto rapido per aprire la nota manuale (se l'utente vuole digitare)
          ActionChip(
            avatar: Icon(
              isNoteFieldVisible ? Icons.keyboard_hide_outlined : Icons.edit_note_rounded,
              size: 16,
              color: isNoteFieldVisible ? AppColors.purpleLight : AppColors.textSecondary,
            ),
            label: Text(
              isNoteFieldVisible ? 'Nascondi nota' : '+ Nota',
              style: TextStyle(
                fontSize: 12,
                color: isNoteFieldVisible ? AppColors.purpleLight : AppColors.textSecondary,
              ),
            ),
            backgroundColor: AppColors.surfaceElevated,
            side: BorderSide(
              color: isNoteFieldVisible ? AppColors.purple : AppColors.border,
              width: 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: onToggleNoteField,
          ),
          const SizedBox(width: 8),

          // Bolle Smart Tag cliccabili istantanee
          ...tags.map((tag) {
            final isSelected = selectedTag == tag;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(tag),
                selected: isSelected,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                ),
                backgroundColor: AppColors.surfaceCard,
                selectedColor: category.color,
                checkmarkColor: Colors.black,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? category.color : AppColors.border,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (selected) {
                  onTagSelected(selected ? tag : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
