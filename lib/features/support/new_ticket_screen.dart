import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/models/admin_list_item.dart';
import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/admin_users_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';

class SupportNewTicketScreen extends StatefulWidget {
  const SupportNewTicketScreen.admin({
    super.key,
    this.preSelectedUser,
    this.forMyTickets = false,
  }) : _role = SupportRole.admin;

  const SupportNewTicketScreen.user({super.key})
    : _role = SupportRole.user,
      preSelectedUser = null,
      forMyTickets = false;

  const SupportNewTicketScreen.superadmin({super.key})
    : _role = SupportRole.superadmin,
      preSelectedUser = null,
      forMyTickets = false;

  final SupportRole _role;
  final AdminUserListItem? preSelectedUser;
  final bool forMyTickets;

  @override
  State<SupportNewTicketScreen> createState() => _SupportNewTicketScreenState();
}

class _SupportNewTicketScreenState extends State<SupportNewTicketScreen> {
  final CancelToken _loadToken = CancelToken();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  late final SupportRoleConfig _config;
  late final SupportRepositoryAdapter _repository;

  bool _submitting = false;
  bool _loadingAssignees = false;
  bool _assigneeErrorShown = false;

  final List<PickedFilePayload> _attachments = <PickedFilePayload>[];

  List<AdminUserListItem> _users = <AdminUserListItem>[];
  List<AdminListItem> _admins = <AdminListItem>[];

  AdminUserListItem? _selectedUser;
  AdminListItem? _selectedAdmin;

  String? _selectedCategory;
  String? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _config = _configFor(widget._role);
    _repository = SupportRepositoryFactory.forRole(widget._role);
    _selectedCategory = _categoryOptions.first;
    _selectedPriority = _priorityOptions.first;

    if (_config.role == SupportRole.admin) {
      if (widget.forMyTickets) {
        _selectedUser = null;
      } else if (widget.preSelectedUser != null) {
        _selectedUser = widget.preSelectedUser;
      } else {
        _loadUsers();
      }
    }

    if (_config.role == SupportRole.superadmin) {
      _loadAdmins();
    }
  }

  @override
  void dispose() {
    _loadToken.cancel('SupportNewTicketScreen disposed');
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  SupportRoleConfig _configFor(SupportRole role) {
    switch (role) {
      case SupportRole.admin:
        return SupportRoleConfigs.admin;
      case SupportRole.user:
        return SupportRoleConfigs.user;
      case SupportRole.superadmin:
        return SupportRoleConfigs.superadmin;
    }
  }

  List<String> get _categoryOptions {
    switch (_config.role) {
      case SupportRole.admin:
        return const <String>[
          'INSTALLATION',
          'SERVER',
          'BILLING',
          'MAPS',
          'TECHNICAL',
          'GENERAL',
          'OTHER',
        ];
      case SupportRole.user:
        return const <String>[
          'SERVER',
          'NOTIFICATION',
          'INSTALLATION',
          'MAPS',
          'BILLING',
          'OTHERS',
        ];
      case SupportRole.superadmin:
        return const <String>['BILLING', 'TECHNICAL', 'OTHER'];
    }
  }

  List<String> get _priorityOptions {
    switch (_config.role) {
      case SupportRole.admin:
        return const <String>['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
      case SupportRole.user:
        return const <String>['LOW', 'MEDIUM', 'HIGH'];
      case SupportRole.superadmin:
        return const <String>['LOW', 'MEDIUM', 'HIGH'];
    }
  }

  bool get _showAttachmentSection {
    if (_config.role == SupportRole.admin) {
      return widget.forMyTickets;
    }
    return _config.role == SupportRole.superadmin;
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _loadingAssignees = true);

    try {
      final result = await AppContainer.instance.adminUsersRepository.getUsers(
        page: 1,
        limit: 200,
        cancelToken: _loadToken,
      );

      if (!mounted) return;
      result.when(
        success: (items) {
          setState(() {
            _users = items;
            _loadingAssignees = false;
          });
        },
        failure: (error) {
          setState(() => _loadingAssignees = false);
          if (_assigneeErrorShown) return;
          _assigneeErrorShown = true;
          final message =
              (error is ApiException &&
                  (error.statusCode == 401 || error.statusCode == 403))
              ? 'Not authorized to load users.'
              : "Couldn't load users.";
          _showError(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAssignees = false);
      if (_assigneeErrorShown) return;
      _assigneeErrorShown = true;
      _showError("Couldn't load users.");
    }
  }

  Future<void> _loadAdmins() async {
    if (!mounted) return;
    setState(() => _loadingAssignees = true);

    try {
      final result = await AppContainer.instance.superadminRepository.getAdmins(
        page: 1,
        limit: 200,
        cancelToken: _loadToken,
      );

      if (!mounted) return;
      result.when(
        success: (items) {
          setState(() {
            _admins = items;
            _loadingAssignees = false;
          });
        },
        failure: (error) {
          setState(() => _loadingAssignees = false);
          if (_assigneeErrorShown) return;
          _assigneeErrorShown = true;
          final message =
              (error is ApiException &&
                  (error.statusCode == 401 || error.statusCode == 403))
              ? 'Not authorized to load admins.'
              : "Couldn't load admins.";
          _showError(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAssignees = false);
      if (_assigneeErrorShown) return;
      _assigneeErrorShown = true;
      _showError("Couldn't load admins.");
    }
  }

  String _titleCase(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    return v
        .toLowerCase()
        .split(RegExp(r'\s+|_+|-+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    OpenVtsFeedback.success(context, message);
  }

  void _showWarning(String message) {
    if (!mounted) return;
    OpenVtsFeedback.warning(context, message);
  }

  void _showError(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (_config.role == SupportRole.admin &&
        !widget.forMyTickets &&
        _selectedUser == null) {
      _showWarning('Select a user first.');
      return;
    }

    if (_config.role == SupportRole.superadmin && _selectedAdmin == null) {
      _showWarning('Select an admin.');
      return;
    }

    if (title.isEmpty || message.isEmpty) {
      _showWarning('Title and message are required.');
      return;
    }

    if (_config.role == SupportRole.superadmin && message.length < 10) {
      _showWarning('Message must be at least 10 characters.');
      return;
    }

    if (_selectedCategory == null || _selectedPriority == null) {
      _showWarning('Select category and priority.');
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = true);

    final draft = SupportCreateTicketDraft(
      title: title,
      message: message,
      category: _selectedCategory,
      priority: _selectedPriority,
      userId: _config.role == SupportRole.admin && !widget.forMyTickets
          ? _selectedUser?.id
          : null,
      adminId: _config.role == SupportRole.superadmin
          ? _selectedAdmin?.id
          : null,
      attachments: _showAttachmentSection
          ? _attachments
          : const <PickedFilePayload>[],
    );

    final result = await _repository.createTicket(
      draft,
      cancelToken: _loadToken,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _submitting = false);
        _showSuccess('Ticket created.');
        Navigator.pop(context, true);
      },
      failure: (error) {
        setState(() => _submitting = false);
        final message = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't create ticket.";
        _showError(message);
      },
    );
  }

  Future<void> _pickAttachment() async {
    if (_submitting) return;

    if (_config.role == SupportRole.superadmin && _attachments.length >= 5) {
      _showWarning('Max 5 files allowed.');
      return;
    }

    final file = await pickSingleFilePayload();
    if (file == null || !mounted) return;

    if (_config.role == SupportRole.superadmin &&
        file.bytes.length > 5 * 1024 * 1024) {
      _showWarning('Max file size is 5MB.');
      return;
    }

    setState(() => _attachments.add(file));
  }

  Widget _buildRoleAppBar() {
    final title = _config.role == SupportRole.admin && widget.forMyTickets
        ? 'My Ticket'
        : 'Create Ticket';

    switch (_config.role) {
      case SupportRole.admin:
        return AdminHomeAppBar(
          title: title,
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context),
        );
      case SupportRole.user:
        return UserHomeAppBar(
          title: title,
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context),
        );
      case SupportRole.superadmin:
        return SuperAdminHomeAppBar(
          title: title,
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context),
        );
    }
  }

  Future<T?> _pickAssignee<T>({
    required String title,
    required List<T> items,
    required String Function(T item) titleFor,
    required String Function(T item) subtitleFor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return OpenVtsModal.showBottomSheet<T>(
      context: context,
      child: Builder(
        builder: (ctx) {
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          titleFor(item),
                          style: AppFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          subtitleFor(item),
                          style: AppFonts.roboto(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssigneeSection() {
    final cs = Theme.of(context).colorScheme;

    if (_config.role == SupportRole.admin && widget.forMyTickets) {
      return const SizedBox.shrink();
    }

    final isAdminAssignee = _config.role == SupportRole.superadmin;
    final label = isAdminAssignee ? 'Admin' : 'User';
    final selectedText = isAdminAssignee
        ? (_selectedAdmin != null
              ? (_selectedAdmin!.name.isNotEmpty
                    ? _selectedAdmin!.name
                    : _selectedAdmin!.email.isNotEmpty
                    ? _selectedAdmin!.email
                    : _selectedAdmin!.id)
              : 'Select admin')
        : (_selectedUser != null
              ? (_selectedUser!.fullName.isNotEmpty
                    ? _selectedUser!.fullName
                    : _selectedUser!.email.isNotEmpty
                    ? _selectedUser!.email
                    : _selectedUser!.id)
              : 'Select user');

    final disabled = widget.preSelectedUser != null && !isAdminAssignee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: AppFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingAssignees)
          const LinearProgressIndicator(minHeight: 2)
        else
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: disabled
                ? null
                : () async {
                    if (isAdminAssignee) {
                      final chosen = await _pickAssignee<AdminListItem>(
                        title: 'Select Admin',
                        items: _admins,
                        titleFor: (item) {
                          if (item.name.isNotEmpty) return item.name;
                          if (item.email.isNotEmpty) return item.email;
                          return item.id;
                        },
                        subtitleFor: (item) {
                          if (item.email.isNotEmpty) return item.email;
                          return item.id;
                        },
                      );
                      if (chosen != null && mounted) {
                        setState(() => _selectedAdmin = chosen);
                      }
                    } else {
                      final chosen = await _pickAssignee<AdminUserListItem>(
                        title: 'Select User',
                        items: _users,
                        titleFor: (item) {
                          if (item.fullName.isNotEmpty) return item.fullName;
                          if (item.email.isNotEmpty) return item.email;
                          return item.id;
                        },
                        subtitleFor: (item) {
                          if (item.email.isNotEmpty) return item.email;
                          return item.id;
                        },
                      );
                      if (chosen != null && mounted) {
                        setState(() => _selectedUser = chosen);
                      }
                    }
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: disabled ? cs.onSurface.withValues(alpha: 0.04) : null,
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedText,
                      style: AppFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!disabled)
                    Icon(
                      Icons.expand_more,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                hp,
                topPadding + AppUtils.appBarHeightCustom + 28,
                hp,
                hp,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _config.role == SupportRole.admin && !widget.forMyTickets
                          ? 'Create Ticket (on behalf of User)'
                          : _config.role == SupportRole.superadmin
                          ? 'Create Ticket (on behalf of Admin)'
                          : 'Create Ticket',
                      style: AppFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildAssigneeSection(),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: _categoryOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(_titleCase(item)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCategory = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                            ),
                            items: _priorityOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(_titleCase(item)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedPriority = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OpenVtsTextField(
                      controller: _titleController,
                      maxLength: _config.role == SupportRole.superadmin
                          ? 30
                          : 60,
                      labelText: 'Title',
                      hintText: 'Brief description of the issue',
                    ),
                    const SizedBox(height: 8),
                    OpenVtsTextField(
                      controller: _messageController,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: _config.role == SupportRole.superadmin
                          ? 1000
                          : null,
                      labelText: 'Message',
                      hintText: 'Describe the issue in detail',
                    ),
                    if (_showAttachmentSection) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Attachments',
                            style: AppFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _submitting ? null : _pickAttachment,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _attachments.map((file) {
                            return Chip(
                              label: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: Text(
                                  file.filename,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: _submitting
                                  ? null
                                  : () => setState(
                                      () => _attachments.remove(file),
                                    ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              _submitting ? 'Submitting...' : 'Create Ticket',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(left: hp, right: hp, top: 0, child: _buildRoleAppBar()),
        ],
      ),
    );
  }
}
