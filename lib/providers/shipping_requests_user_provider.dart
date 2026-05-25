import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider for current authenticated user
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

/// Map Firestore status to UI status
String _mapStatusToUI(String firestoreStatus) {
  switch (firestoreStatus) {
    case 'pending':
      return 'Processing';
    case 'approved':
      return 'Approved';
    case 'inTransit':
      return 'In Transit';
    case 'delivered':
      return 'Delivered';
    case 'rejected':
      return 'Cancelled';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Processing';
  }
}

/// Provider for user's shipping requests from Firestore
/// Filters by requesterId and returns real-time stream
/// Also includes guest requests where email matches (for users who first submitted as guest)
final userShippingRequestsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = ref.watch(currentUserProvider);

  final db = FirebaseFirestore.instance;

  try {
    Stream<QuerySnapshot> stream;

    if (user != null) {
      // For logged-in users: get own requests + guest requests with same email
      // This handles the case where user first submitted as guest then registered
      stream = db
          .collection('shippingRequests')
          .where('requesterId', whereIn: [user.uid, 'guest'])
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots();
    } else {
      // For guests/unauthenticated users
      yield [];
      return;
    }

    await for (final snapshot in stream) {
      final requests = snapshot.docs.map((doc) {
        final data = doc.data()! as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?) ?? Timestamp.now();

        // Filter: if guest request, only show if email matches current user
        final isGuestRequest = data['requesterId'] == 'guest';
        final requesterEmail = (data['senderEmail'] as String?) ?? (data['clientEmail'] as String?) ?? '';
        if (isGuestRequest && requesterEmail != user.email) {
          return null; // Will be filtered out
        }

        return {
          'id': doc.id,
          // Map Firestore fields to UI format
          'trackingNumber': (data['trackingNumber'] as String?) ?? 'N/A',
          'status': _mapStatusToUI((data['status'] as String?) ?? 'pending'),
          'origin': (data['origin'] as String?) ?? 'Unknown',
          'destination': (data['destination'] as String?) ?? 'Unknown',
          'recipient': (data['clientName'] as String?) ?? 'Guest',
          'date': createdAt.toDate(),
          'createdAt': createdAt.toDate().toIso8601String(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String(),
        };
      }).where((req) => req != null).cast<Map<String, dynamic>>().toList();

      yield requests;
    }
  } catch (e) {
    // Silently fail - return empty list
    yield [];
  }
});

/// Provider for filtering/searching shipping requests
/// Call with status filter: 'All', 'Processing', 'Approved', 'In Transit', 'Delivered', 'Cancelled'
final filteredUserShippingRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
  (ref, statusFilter) async {
    final requestsAsync = ref.watch(userShippingRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (statusFilter == null || statusFilter == 'All') {
          return requests;
        } else {
          return requests
              .where((req) => req['status'] == statusFilter)
              .toList();
        }
      },
      error: (error, stackTrace) => [],
      loading: () => [],
    );
  },
);

/// Provider to get detailed shipping request by ID
final shippingRequestDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, requestId) async {
    final db = FirebaseFirestore.instance;
    try {
      final doc = await db.collection('shippingRequests').doc(requestId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      // Silently fail - return null
      return null;
    }
  },
);

/// State for paginated shipping requests
class PaginatedShippingRequestsState {
  final List<Map<String, dynamic>> requests;
  final DocumentSnapshot? lastDoc;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  PaginatedShippingRequestsState({
    this.requests = const [],
    this.lastDoc,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedShippingRequestsState copyWith({
    List<Map<String, dynamic>>? requests,
    DocumentSnapshot? lastDoc,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedShippingRequestsState(
      requests: requests ?? this.requests,
      lastDoc: lastDoc ?? this.lastDoc,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Provider for paginated user's shipping requests with Load More support
final paginatedShippingRequestsProvider = StateNotifierProvider.family<
    PaginatedShippingRequestsNotifier, PaginatedShippingRequestsState, String>(
  (ref, userId) => PaginatedShippingRequestsNotifier(userId),
);

class PaginatedShippingRequestsNotifier
    extends StateNotifier<PaginatedShippingRequestsState> {
  final String _userId;
  final _db = FirebaseFirestore.instance;
  static const int _pageSize = 20;

  PaginatedShippingRequestsNotifier(this._userId)
      : super(PaginatedShippingRequestsState()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load user's own requests
      final userQuery = await _db
          .collection('shippingRequests')
          .where('requesterId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      final userRequests = userQuery.docs.map(_mapDocToRequest).toList();
      final userLastDoc = userQuery.docs.isEmpty ? null : userQuery.docs.last;

      // Also check for guest requests with same email
      // We'll fetch user's email first, but for now just combine
      final allRequests = [...userRequests];

      state = state.copyWith(
        requests: allRequests,
        lastDoc: userLastDoc,
        isLoading: false,
        hasMore: userQuery.docs.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      Query query = _db
          .collection('shippingRequests')
          .where('requesterId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (state.lastDoc != null) {
        query = query.startAfterDocument(state.lastDoc!);
      }

      final querySnapshot = await query.get();

      final newRequests = querySnapshot.docs.map(_mapDocToRequest).toList();
      final hasMore = querySnapshot.docs.length >= _pageSize;
      final lastDoc =
          querySnapshot.docs.isEmpty ? null : querySnapshot.docs.last;

      state = state.copyWith(
        requests: [...state.requests, ...newRequests],
        lastDoc: lastDoc,
        isLoading: false,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = PaginatedShippingRequestsState();
    await _loadInitial();
  }

  Map<String, dynamic> _mapDocToRequest(QueryDocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp?) ?? Timestamp.now();

    return {
      'id': doc.id,
      'trackingNumber': (data['trackingNumber'] as String?) ?? 'N/A',
      'status': _mapStatusToUI((data['status'] as String?) ?? 'pending'),
      'origin': (data['origin'] as String?) ?? 'Unknown',
      'destination': (data['destination'] as String?) ?? 'Unknown',
      'recipient': (data['clientName'] as String?) ?? 'Guest',
      'date': createdAt.toDate(),
      'createdAt': createdAt.toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ??
          DateTime.now().toIso8601String(),
    };
  }

  String _mapStatusToUI(String firestoreStatus) {
    switch (firestoreStatus) {
      case 'pending':
        return 'Processing';
      case 'approved':
        return 'Approved';
      case 'inTransit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'rejected':
        return 'Cancelled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }
}
