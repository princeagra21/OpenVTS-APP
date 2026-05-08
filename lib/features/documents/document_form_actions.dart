import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/models/superadmin_document_type.dart';
import 'package:open_vts/design_system/components/open_vts_modal.dart';
import 'package:open_vts/features/documents/widgets/document_type_selector.dart';

class DocumentFormActions {
  const DocumentFormActions._();

  static Future<DateTime?> pickExpiryDate(BuildContext context) async {
    final result = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(12),
      value: const [],
    );

    if (result == null || result.isEmpty || result.first == null) {
      return null;
    }

    final selectedDate = result.first!;
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  }

  static Future<PlatformFile?> pickDocumentFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowMultiple: false,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'webp',
      ],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.single;
  }

  static Future<SuperadminDocumentType?> openDocumentTypePicker({
    required BuildContext context,
    required List<SuperadminDocumentType> docTypes,
    required SuperadminDocumentType? selectedDocType,
    required bool loadingDocTypes,
  }) {
    return OpenVtsModal.showBottomSheet<SuperadminDocumentType>(
      context: context,
      child: DocumentTypeSelectionSheet(
        docTypes: docTypes,
        selectedDocType: selectedDocType,
        loadingDocTypes: loadingDocTypes,
      ),
    );
  }
}
