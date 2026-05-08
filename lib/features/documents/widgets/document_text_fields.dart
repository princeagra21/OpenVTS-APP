import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';

class DocumentTitleField extends StatelessWidget {
  const DocumentTitleField({
    super.key,
    required this.contextForDecoration,
    required this.screenWidth,
    required this.labelSize,
    required this.titleController,
  });

  final BuildContext contextForDecoration;
  final double screenWidth;
  final double labelSize;
  final TextEditingController titleController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DocumentLabel(text: 'Title *', screenWidth: screenWidth),
        const SizedBox(height: 8),
        TextField(
          controller: titleController,
          style: AppFonts.roboto(fontSize: labelSize, color: cs.onSurface),
          decoration: _fieldDecoration(
            contextForDecoration,
            hint: 'e.g., Driving License',
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: AppFonts.roboto(
        color: cs.onSurface.withValues(alpha: 0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(width),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }
}

class DocumentTagsAndDescriptionFields extends StatelessWidget {
  const DocumentTagsAndDescriptionFields({
    super.key,
    required this.contextForDecoration,
    required this.screenWidth,
    required this.labelSize,
    required this.tagsController,
    required this.descriptionController,
  });

  final BuildContext contextForDecoration;
  final double screenWidth;
  final double labelSize;
  final TextEditingController tagsController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DocumentLabel(text: 'Tags (optional)', screenWidth: screenWidth),
        const SizedBox(height: 8),
        TextField(
          controller: tagsController,
          style: AppFonts.roboto(fontSize: labelSize, color: cs.onSurface),
          decoration: _fieldDecoration(
            contextForDecoration,
            hint: 'insurance, permit',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Press Enter or comma to add tags.',
          style: AppFonts.roboto(
            fontSize: labelSize - 4,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 24),
        _DocumentLabel(
          text: 'Description (optional)',
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descriptionController,
          minLines: 3,
          maxLines: 4,
          style: AppFonts.roboto(fontSize: labelSize, color: cs.onSurface),
          decoration: _fieldDecoration(
            contextForDecoration,
            hint: 'Optional details about this document',
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: AppFonts.roboto(
        color: cs.onSurface.withValues(alpha: 0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(width),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }
}

class _DocumentLabel extends StatelessWidget {
  const _DocumentLabel({required this.text, required this.screenWidth});

  final String text;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      style: AppFonts.roboto(
        fontSize: 12 * (screenWidth / 420).clamp(0.9, 1.0),
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: cs.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}
