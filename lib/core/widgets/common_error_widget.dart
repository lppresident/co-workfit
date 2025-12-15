import 'package:flutter/material.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

/// Common error widget with retry functionality
class CommonErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? retryButtonText;

  const CommonErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryButtonText ?? '다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
