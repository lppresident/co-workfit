import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/bloc/refresh_bloc.dart';
import 'package:co_workfit/core/bloc/refresh_state.dart';

/// Base class for all pages in the application
///
/// Provides consistent structure and behavior across pages
abstract class BasePage extends StatefulWidget {
  const BasePage({super.key});

  /// Page index for refresh targeting (optional)
  /// If null, page won't respond to refresh events
  int? get pageIndex => null;
}

/// Base state for pages
///
/// Provides lifecycle hooks and common functionality
abstract class BasePageState<T extends BasePage> extends State<T>
    with AutomaticKeepAliveClientMixin {
  bool _hasLoadedInitialData = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Safely load initial data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoadedInitialData) {
        _hasLoadedInitialData = true;
        loadInitialData();
      }
    });
  }

  /// Override this method to load initial data
  ///
  /// This is called after the first frame is rendered,
  /// ensuring BuildContext is ready for BLoC access
  void loadInitialData() {}

  /// Force reload data (called when same tab is tapped or pull-to-refresh)
  void reloadData() {
    loadInitialData();
  }

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final body = buildBody(context);

    // pageIndex가 설정된 경우 RefreshBloc 리스닝
    Widget scaffold = Scaffold(
      appBar: buildAppBar(context),
      body: useSafeArea ? SafeArea(child: body) : body,
      floatingActionButton: buildFloatingActionButton(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );

    if (widget.pageIndex != null) {
      return BlocListener<RefreshBloc, RefreshState>(
        listener: (context, state) {
          if (state is RefreshTriggered && state.pageIndex == widget.pageIndex) {
            reloadData();
          }
        },
        child: scaffold,
      );
    }

    return scaffold;
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
