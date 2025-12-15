import 'package:flutter/material.dart';

/// Base class for all pages in the application
///
/// Provides consistent structure and behavior across pages
abstract class BasePage extends StatefulWidget {
  const BasePage({super.key});
}

/// Base state for pages
///
/// Provides lifecycle hooks and common functionality
abstract class BasePageState<T extends BasePage> extends State<T> {
  @override
  void initState() {
    super.initState();
    // Safely load initial data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadInitialData();
      }
    });
  }

  /// Override this method to load initial data
  ///
  /// This is called after the first frame is rendered,
  /// ensuring BuildContext is ready for BLoC access
  void loadInitialData() {}

  /// Build the AppBar for this page
  ///
  /// Override to customize AppBar
  PreferredSizeWidget? buildAppBar(BuildContext context) => null;

  /// Build the body of this page
  ///
  /// This is the main content area
  Widget buildBody(BuildContext context);

  /// Build the floating action button
  ///
  /// Override to add FAB
  Widget? buildFloatingActionButton(BuildContext context) => null;

  /// Build the bottom navigation bar
  ///
  /// Override to add bottom nav
  Widget? buildBottomNavigationBar(BuildContext context) => null;

  /// Whether to use SafeArea for the body
  ///
  /// Default is true
  bool get useSafeArea => true;

  @override
  Widget build(BuildContext context) {
    final body = buildBody(context);

    return Scaffold(
      appBar: buildAppBar(context),
      body: useSafeArea ? SafeArea(child: body) : body,
      floatingActionButton: buildFloatingActionButton(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }
}

/// Base class for pages with BLoC
///
/// Provides convenient access to BLoC and common patterns
abstract class BlocPage<B, S> extends BasePage {
  const BlocPage({super.key});
}

/// Base state for pages with BLoC
abstract class BlocPageState<T extends BlocPage, B, S> extends BasePageState<T> {
  /// Handle BLoC state changes that require side effects
  ///
  /// Use this for SnackBars, Dialogs, Navigation
  void handleBlocListener(BuildContext context, S state) {}

  /// Build UI based on BLoC state
  ///
  /// Override to customize state-based UI
  Widget buildBlocContent(BuildContext context, S state);

  @override
  Widget buildBody(BuildContext context) {
    return buildBlocContent(context, null as S);
  }
}
