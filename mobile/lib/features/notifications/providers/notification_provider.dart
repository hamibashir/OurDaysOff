import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  Timer? _pollingTimer;

  NotificationNotifier(this._repository) : super(const NotificationState()) {
    loadNotifications();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      loadNotifications(isSilent: true);
    });
  }

  Future<void> loadNotifications({bool isSilent = false}) async {
    if (!isSilent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final res = await _repository.getNotifications();
      state = state.copyWith(
        notifications: res.data,
        unreadCount: res.unreadCount,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      if (!isSilent) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> markAsRead(int id) async {
    final prevNotifications = state.notifications;
    final prevUnread = state.unreadCount;

    // Optimistic update
    final updatedList = prevNotifications.map((n) {
      if (n.id == id && !n.isRead) {
        return n.copyWith(readAt: DateTime.now());
      }
      return n;
    }).toList();

    final newUnread = (prevUnread > 0) ? prevUnread - 1 : 0;
    state = state.copyWith(
      notifications: updatedList,
      unreadCount: newUnread,
    );

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      // Revert if API call fails
      state = state.copyWith(
        notifications: prevNotifications,
        unreadCount: prevUnread,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final prevNotifications = state.notifications;
    final prevUnread = state.unreadCount;

    final now = DateTime.now();
    final updatedList = prevNotifications.map((n) {
      return n.isRead ? n : n.copyWith(readAt: now);
    }).toList();

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    );

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      state = state.copyWith(
        notifications: prevNotifications,
        unreadCount: prevUnread,
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider.select((s) => s.unreadCount));
});
