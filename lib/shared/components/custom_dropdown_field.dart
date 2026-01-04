import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String hintText;
  final IconData? prefixIcon;
  final Function(T?) onChanged;
  final double fontSize;
  final String Function(T)? itemLabelBuilder;

  const CustomDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.hintText,
    this.prefixIcon,
    required this.onChanged,
    required this.fontSize,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
      style: GoogleFonts.inter(fontSize: fontSize, color: colorScheme.onSurface),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: colorScheme.onSurface.withOpacity(0.5),
          fontSize: fontSize,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: colorScheme.primary, size: 22) 
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabelBuilder != null ? itemLabelBuilder!(item) : item.toString(),
            style: GoogleFonts.inter(fontSize: fontSize),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}