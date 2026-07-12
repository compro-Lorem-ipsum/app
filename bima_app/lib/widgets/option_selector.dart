import 'package:flutter/material.dart';
import 'app_theme.dart';

class OptionSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const OptionSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = selected == option;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: option == options.last ? 0 : 12),
            child: GestureDetector(
              onTap: () => onSelect(option),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.progressTrack : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.fieldBorder.withValues(alpha: 0.5)),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: AppText.semiBold.copyWith(fontSize: 14, color: isSelected ? AppColors.primary : Colors.black),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
