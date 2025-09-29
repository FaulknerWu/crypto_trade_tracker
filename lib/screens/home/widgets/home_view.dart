import 'package:flutter/material.dart';

import 'home_top_toolbar.dart';
import 'navigation_pane.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.isRefreshing,
    required this.onRefresh,
    required this.activeItem,
    required this.onNavigationChanged,
    required this.content,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;
  final String activeItem;
  final ValueChanged<String> onNavigationChanged;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          HomeTopToolbar(isRefreshing: isRefreshing, onRefresh: onRefresh),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: Row(
              children: [
                HomeNavigationPane(
                  activeItem: activeItem,
                  onItemSelected: onNavigationChanged,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
