part of 'sub_user_details_screen.dart';

extension _SubUserDetailsHelpers on _SubUserDetailsScreenState {
  String _safe(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '—';
    return text;
  }

  bool _isLimitedAccess(UserSubUserItem? details) {
    final raw = details?.raw;
    if (raw == null) return false;
    final createdBy = _safe(raw['createdByUserId']?.toString());
    final primaryUser = _safe(raw['primaryUserId']?.toString());
    if (createdBy == '—' || primaryUser == '—') return false;
    return createdBy != primaryUser;
  }

  String _formatPhone(String prefix, String number) {
    final p = prefix.trim();
    final n = number.trim();
    if (p.isEmpty && n.isEmpty) return '—';
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$p $n';
  }

  String _initials(String source) {
    final clean = source.trim();
    if (clean.isEmpty || clean == '—') return '--';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  _DatePair _formatDateTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—') return const _DatePair('—', '');
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return _DatePair(text, '');
    final local = parsed.toLocal();
    final date = '${local.day}/${local.month}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return _DatePair(date, time);
  }
}
