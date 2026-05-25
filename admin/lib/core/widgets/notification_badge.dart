import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/data/providers/auth_providers.dart';

/// Provider for unread notifications count
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final authUser = ref.watch(authStateProvider).value;

  if (authUser == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: authUser.uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Notification badge widget that shows unread count
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return unreadCount.when(
      data: (count) {
        if (count == 0 && !showZero) {
          return child;
        }

        return Badge(
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          child: child,
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// Notification indicator for sidebar nav items
class NavItemBadge extends ConsumerWidget {
  final String collection; // 'shipments', 'affiliates', 'customers', etc.
  final String? statusFilter; // Optional status filter (e.g., 'pending')
  final Widget child;

  const NavItemBadge({
    super.key,
    required this.collection,
    this.statusFilter,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return child;
        }

        final count = snapshot.data!.docs.length;
        if (count == 0) return child;

        return Badge(
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(fontSize: 9),
          ),
          backgroundColor: Colors.orange,
          child: child,
        );
      },
    );
  }

  Stream<QuerySnapshot> _getStream() {
    var query = FirebaseFirestore.instance
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots();
  }
}
