import 'package:flutter/material.dart';

/// Mixin for pages that support pull-to-refresh
mixin RefreshableMixin<T extends StatefulWidget> on State<T> {
  /// Whether refresh is currently in progress
  bool _isRefreshing = false;

  /// Override this to handle refresh logic
  Future<void> onRefresh();

  /// Build content with RefreshIndicator
  Widget buildRefreshableContent({
    required Widget child,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_isRefreshing) return;

        setState(() => _isRefreshing = true);

        try {
          await onRefresh();
        } finally {
          if (mounted) {
            setState(() => _isRefreshing = false);
          }
        }
      },
      child: child,
    );
  }
}
