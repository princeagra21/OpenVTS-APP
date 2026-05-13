class SupportPermissions {
  const SupportPermissions({
    this.canViewMyTicketsTab = false,
    this.canUpdateStatus = false,
    this.canSendInternalNotes = false,
    this.canCreateTicketForOtherUsers = false,
    this.canCreateTicketForAdmins = false,
    this.canOpenFullscreenChat = false,
    this.canAttachFiles = true,
    this.canChooseCategory = true,
    this.canChoosePriority = true,
  });

  final bool canViewMyTicketsTab;
  final bool canUpdateStatus;
  final bool canSendInternalNotes;
  final bool canCreateTicketForOtherUsers;
  final bool canCreateTicketForAdmins;
  final bool canOpenFullscreenChat;
  final bool canAttachFiles;
  final bool canChooseCategory;
  final bool canChoosePriority;
}
