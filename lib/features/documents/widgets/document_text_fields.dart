import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_text_field.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DocumentLabel(text: 'Title *', screenWidth: screenWidth),
        const SizedBox(height: 8),
        OpenVtsTextField(
          controller: titleController,
          hintText: 'e.g., Driving License',
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DocumentLabel(text: 'Tags (optional)', screenWidth: screenWidth),
        const SizedBox(height: 8),
        OpenVtsTextField(
          controller: tagsController,
          hintText: 'insurance, permit',
        ),
        const SizedBox(height: 6),
        Text(
          'Press Enter or comma to add tags.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        _DocumentLabel(
          text: 'Description (optional)',
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 8),
        OpenVtsTextField(
          controller: descriptionController,
          minLines: 3,
          maxLines: 4,
          hintText: 'Optional details about this document',
        ),
      ],
    );
  }
}

class _DocumentLabel extends StatelessWidget {
  const _DocumentLabel({required this.text, required this.screenWidth});

  final String text;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
