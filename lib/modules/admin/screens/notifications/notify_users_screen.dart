// lib/screens/notifications/notify_users_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifyUsersScreen extends StatefulWidget {
  const NotifyUsersScreen({super.key});

  @override
  State<NotifyUsersScreen> createState() => _NotifyUsersScreenState();
}

class _NotifyUsersScreenState extends State<NotifyUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, String>> _allUsers = const [
    {'initials': 'AB', 'name': 'Aarav Bansal', 'email': 'aarav@acme.io'},
    {'initials': 'MS', 'name': 'Meera Shah', 'email': 'meera@delta.com'},
    {'initials': 'RV', 'name': 'Riya Verma', 'email': 'riya@orbit.ai'},
    {'initials': 'KS', 'name': 'Kabir Singh', 'email': 'kabir@lumen.app'},
    {'initials': 'ZK', 'name': 'Zara Khan', 'email': 'zara@north.dev'},
    {'initials': 'DP', 'name': 'Dev Patel', 'email': 'dev@zento.io'},
  ];

  final Set<String> _selectedEmails = {};
  List<bool> _channels = [true, false]; // [email, in-app]

  @override
  void initState() {
    super.initState();
    _messageController.text = "Hello, this is a quick update for you.";
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchController.text.trim().toLowerCase();
    setState(() {

    });
  }

  

  int get _recipientCount => _selectedEmails.length;
  int get _channelCount => _channels.where((c) => c).length;

  

  Future<void> _openUserMultiSelectDialog() async {
  final tempSelected = Set<String>.from(_selectedEmails);

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // ✅ KEY FIX
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8), // tighter content
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),

        title: Text(
          'Select recipients',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),

        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Filter users...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Users list
              Flexible(
                child: StatefulBuilder(
                  builder: (context, dialogSetState) {
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: _allUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final u = _allUsers[i];
                        final email = u['email']!;
                        final name = u['name']!;
                        final initials = u['initials'] ??
                            name
                                .split(' ')
                                .map((s) => s.isNotEmpty ? s[0] : '')
                                .take(2)
                                .join();

                        final selected = tempSelected.contains(email);

                        return CheckboxListTile(
                          value: selected,
                          onChanged: (v) {
                            dialogSetState(() {
                              v == true
                                  ? tempSelected.add(email)
                                  : tempSelected.remove(email);
                            });
                          },

                          // 🔽 tighten tile spacing
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,

                          title: Text(
                            name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            email,
                            style: GoogleFonts.inter(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          secondary: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.12),
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedEmails
                  ..clear()
                  ..addAll(tempSelected);
              });
              Navigator.of(ctx).pop();
            },
            child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      );
    },
  );
}


  Future<void> _sendNotifications() async {
    if (_recipientCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one recipient.')));
      return;
    }
    if (_channelCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one channel.')));
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message cannot be empty.')));
      return;
    }

    final recipients = _selectedEmails.toList();
    final channels = <String>[];
    if (_channels[0]) channels.add('email');
    if (_channels[1]) channels.add('in_app');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending to ${recipients.length} recipient(s) • ${channels.length} channel(s)')),
    );

    await Future.delayed(const Duration(milliseconds: 700));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications queued successfully.')));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double pad = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    final selectedUsers = _allUsers.where((u) => _selectedEmails.contains(u['email'])).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(pad * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notify Users",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Search input
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withOpacity(0.04)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: cs.onSurface.withOpacity(0.6)),
                    hintText: 'Search users by name or email',
                    hintStyle: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.6)),
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.transparent, width: 0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text("Channels"),
              SizedBox(height: pad - 2),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _channelPill(
                      label: 'Email',
                      value: _channels[0],
                      onTap: () => setState(() => _channels[0] = !_channels[0]),
                      cs: cs,
                    ),
                    const SizedBox(width: 8),
                    _channelPill(
                      label: 'In-app',
                      value: _channels[1],
                      onTap: () => setState(() => _channels[1] = !_channels[1]),
                      cs: cs,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _MultiSelectDropdown(
                label: 'Recipients',
                hint: 'Select recipients',
                width: w,
                selectedUsers: selectedUsers,
                onTap: _openUserMultiSelectDialog,
                onClear: () {
                  setState(() {
                    _selectedEmails.clear();
                  });
                },
              ),
              const SizedBox(height: 12),

              // Message input card
              Card(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Subject (optional)", style: GoogleFonts.inter(fontSize: fs - 2)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'Write a short subject',
                          hintStyle: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.6)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: cs.surfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text("Message *", style: GoogleFonts.inter(fontSize: fs - 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))],
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Write your message here',
                            hintStyle: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.6)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: cs.surfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Footer actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: cs.primary.withOpacity(0.28)),
                        foregroundColor: cs.primary,
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: Text('Send', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _channelPill({
    required String label,
    required bool value,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? cs.primary.withOpacity(0.12) : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: value ? cs.primary : cs.onSurface.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(value ? Icons.check_circle : Icons.circle_outlined, size: 18, color: value ? cs.primary : cs.onSurface.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(color: value ? cs.primary : cs.onSurface.withOpacity(0.9), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final double width;
  final List<Map<String, String>> selectedUsers;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _MultiSelectDropdown({
    required this.label,
    required this.hint,
    required this.width,
    required this.selectedUsers,
    required this.onTap,
    required this.onClear,
  });

  String _summaryText() {
    if (selectedUsers.isEmpty) return '';
    if (selectedUsers.length == 1) return selectedUsers.first['name']!;
    final first = selectedUsers.first['name']!;
    final others = selectedUsers.length - 1;
    return '$first and $others other${others > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withOpacity(0.04)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedUsers.isEmpty ? hint : _summaryText(),
                    style: GoogleFonts.inter(
                      color: selectedUsers.isEmpty ? cs.onSurface.withOpacity(0.6) : cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedUsers.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.clear, size: 20, color: cs.onSurface.withOpacity(0.6)),
                    ),
                  ),
                Icon(Icons.arrow_drop_down, color: cs.onSurface.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
