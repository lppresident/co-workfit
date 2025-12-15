import 'package:flutter/material.dart';

/// Mixin for pages with TabBar
mixin TabbedMixin<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late TabController tabController;

  /// Number of tabs
  int get tabCount;

  /// Tab labels
  List<String> get tabLabels;

  /// Tab widgets
  List<Widget> get tabViews;

  /// Called when tab changes
  void onTabChanged(int index) {}

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabCount, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        onTabChanged(tabController.index);
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  /// Build TabBar for AppBar
  PreferredSizeWidget buildTabBar() {
    return TabBar(
      controller: tabController,
      tabs: tabLabels.map((label) => Tab(text: label)).toList(),
    );
  }

  /// Build TabBarView for body
  Widget buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: tabViews,
    );
  }
}
