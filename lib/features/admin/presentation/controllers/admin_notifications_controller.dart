import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_recipient.dart';

class AdminNotificationsState {
  const AdminNotificationsState({
    this.items = const <AdminNotificationItem>[],
    this.recipients = const <AdminUserRecipient>[],
    this.isLoading = false,
    this.isLoadingRecipients = false,
    this.isSending = false,
    this.markingIds = const <String>{},
    this.isMarkingAll = false,
    this.error,
    this.recipientError,
    this.actionError,
  });

  final List<AdminNotificationItem> items;
  final List<AdminUserRecipient> recipients;
  final bool isLoading;
  final bool isLoadingRecipients;
  final bool isSending;
  final Set<String> markingIds;
  final bool isMarkingAll;
  final AppError? error;
  final AppError? recipientError;
  final AppError? actionError;

  AdminNotificationsState copyWith({
    List<AdminNotificationItem>? items,
    List<AdminUserRecipient>? recipients,
    bool? isLoading,
    bool? isLoadingRecipients,
    bool? isSending,
    Set<String>? markingIds,
    bool? isMarkingAll,
    Object? error = _unchanged,
    Object? recipientError = _unchanged,
    Object? actionError = _unchanged,
  }) {
    return AdminNotificationsState(
      items: items ?? this.items,
      recipients: recipients ?? this.recipients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRecipients: isLoadingRecipients ?? this.isLoadingRecipients,
      isSending: isSending ?? this.isSending,
      markingIds: markingIds ?? this.markingIds,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
      recipientError: identical(recipientError, _unchanged) ? this.recipientError : recipientError as AppError?,
      actionError: identical(actionError, _unchanged) ? this.actionError : actionError as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminNotificationsController extends StateNotifier<AdminNotificationsState> {
  AdminNotificationsController(this._ref) : super(const AdminNotificationsState());
  final Ref _ref;

  Future<bool> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(getAdminNotificationsUseCaseProvider)();
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(items: items, isLoading: false, error: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(items: const <AdminNotificationItem>[], isLoading: false, error: error);
        return false;
      },
    );
  }

  Future<bool> loadRecipients({String query = ''}) async {
    state = state.copyWith(isLoadingRecipients: true, recipientError: null);
    final result = await _ref.read(getAdminNotificationsUseCaseProvider).recipients(query: query);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(recipients: items, isLoadingRecipients: false, recipientError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(recipients: const <AdminUserRecipient>[], isLoadingRecipients: false, recipientError: error);
        return false;
      },
    );
  }

  Future<bool> markRead(String id) async {
    final itemId = id.trim();
    if (itemId.isEmpty) return false;
    state = state.copyWith(markingIds: <String>{...state.markingIds, itemId}, actionError: null);
    final result = await _ref.read(getAdminNotificationsUseCaseProvider).markRead(itemId);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        final next = state.items.map((item) {
          if (item.id != itemId) return item;
          final raw = Map<String, Object?>.from(item.raw)..['isRead'] = true..['read'] = true;
          return AdminNotificationItem(raw);
        }).toList();
        state = state.copyWith(items: next, markingIds: <String>{...state.markingIds}..remove(itemId), actionError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(markingIds: <String>{...state.markingIds}..remove(itemId), actionError: error);
        return false;
      },
    );
  }

  Future<bool> markAllRead() async {
    state = state.copyWith(isMarkingAll: true, actionError: null);
    final result = await _ref.read(getAdminNotificationsUseCaseProvider).markAllRead();
    if (!mounted) return false;
    return result.when(
      success: (_) {
        final next = state.items.map((item) => AdminNotificationItem(Map<String, Object?>.from(item.raw)..['isRead'] = true..['read'] = true)).toList();
        state = state.copyWith(items: next, isMarkingAll: false, actionError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isMarkingAll: false, actionError: error);
        return false;
      },
    );
  }

  Future<bool> send({required String channel, required List<String> userIds, String? subject, required String message}) async {
    state = state.copyWith(isSending: true, actionError: null);
    final result = await _ref.read(sendAdminNotificationUseCaseProvider)(
          channel: channel,
          userIds: userIds,
          subject: subject,
          message: message,
        );
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSending: false, actionError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isSending: false, actionError: error);
        return false;
      },
    );
  }
}
