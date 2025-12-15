import 'package:flutter/material.dart';

/// Standard AppBar for consistent UI across the app
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const StandardAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}

/// Common AppBar actions
class AppBarActions {
  AppBarActions._();

  /// Refresh icon button
  static Widget refresh(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: onPressed,
      tooltip: '새로고침',
    );
  }

  /// Filter icon button
  static Widget filter(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: onPressed,
      tooltip: '필터',
    );
  }

  /// Sort icon button
  static Widget sort(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.sort),
      onPressed: onPressed,
      tooltip: '정렬',
    );
  }

  /// Search icon button
  static Widget search(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: onPressed,
      tooltip: '검색',
    );
  }

  /// Settings icon button
  static Widget settings(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: onPressed,
      tooltip: '설정',
    );
  }

  /// More (vertical dots) menu button
  static Widget menu<T>({
    required List<PopupMenuEntry<T>> items,
    required void Function(T) onSelected,
    String? tooltip,
  }) {
    return PopupMenuButton<T>(
      icon: const Icon(Icons.more_vert),
      tooltip: tooltip ?? '메뉴',
      itemBuilder: (context) => items,
      onSelected: onSelected,
    );
  }
}
