import 'package:flutter/material.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_error_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';

/// Mixin for pages with loading/error/empty states
mixin LoadableMixin<T extends StatefulWidget> on State<T> {
  /// Build loading state UI
  Widget buildLoadingState({String? message}) {
    return CommonLoadingWidget(message: message);
  }

  /// Build error state UI
  Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
  }) {
    return CommonErrorWidget(
      message: message,
      onRetry: onRetry ?? () {},
    );
  }

  /// Build empty state UI
  Widget buildEmptyState({
    required String message,
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return CommonEmptyWidget(
      message: message,
      icon: icon,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Generic state handler
  Widget handleStates<S>({
    required S state,
    required bool Function(S) isLoading,
    required bool Function(S) isError,
    required bool Function(S) isEmpty,
    required String Function(S) getErrorMessage,
    required Widget Function(S) buildContent,
    String? loadingMessage,
    String? emptyMessage,
    IconData? emptyIcon,
    VoidCallback? onRetry,
  }) {
    if (isLoading(state)) {
      return buildLoadingState(message: loadingMessage);
    }

    if (isError(state)) {
      return buildErrorState(
        message: getErrorMessage(state),
        onRetry: onRetry,
      );
    }

    if (isEmpty(state)) {
      return buildEmptyState(
        message: emptyMessage ?? 'No data available',
        icon: emptyIcon,
        onAction: onRetry,
        actionText: onRetry != null ? 'Retry' : null,
      );
    }

    return buildContent(state);
  }
}
