import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_providers.dart';

/// Widget that handles auth state and route protection
class AuthRedirect extends ConsumerWidget {
  final Widget unauthenticatedWidget;
  final Widget authenticatedWidget;
  final Widget? loadingWidget;

  const AuthRedirect({
    required this.unauthenticatedWidget,
    required this.authenticatedWidget,
    this.loadingWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return authenticatedWidget;
        } else {
          return unauthenticatedWidget;
        }
      },
      loading: () => loadingWidget ?? const _LoadingScreen(),
      error: (error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Authentication Error: $error'),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget that requires admin authentication
class AdminProtectedWidget extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AdminProtectedWidget({required this.child, this.fallback, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final isLoading = ref.watch(authStateProvider).isLoading;

    if (isLoading) {
      return const _LoadingScreen();
    }

    if (isAdmin) {
      return child;
    }

    return fallback ??
        Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'You need admin privileges to access this page',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
  }
}

/// Widget that requires super admin authentication
class SuperAdminProtectedWidget extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const SuperAdminProtectedWidget({
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final isLoading = ref.watch(authStateProvider).isLoading;

    if (isLoading) {
      return const _LoadingScreen();
    }

    if (isSuperAdmin) {
      return child;
    }

    return fallback ??
        Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'You need super admin privileges to access this page',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
  }
}

/// Widget that requires specific permission
class PermissionProtectedWidget extends ConsumerWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionProtectedWidget({
    required this.permission,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user?.hasPermission(permission) ?? false) {
          return child;
        }
        return fallback ??
            Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.block_outlined,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Permission Denied',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You do not have permission to access this resource',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
      },
      loading: () => const _LoadingScreen(),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}

/// Loading screen displayed during auth state check
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text('Loading...', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
