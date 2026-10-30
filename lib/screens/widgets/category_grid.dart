import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category.dart';

class CategoryGrid extends StatelessWidget {
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const CategoryGrid({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Category.defaultCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = Category.defaultCategories[index];
          final isSelected = cat.id == selectedCategoryId;

          return GestureDetector(
            onTap: () => onCategorySelected(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 76,
              decoration: BoxDecoration(
                color: isSelected ? cat.color.withValues(alpha: 0.18) : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? cat.color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat.icon,
                    size: 26,
                    color: isSelected ? cat.color : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
