import 'package:flutter/material.dart';

class HomeTopToolbar extends StatelessWidget {
  const HomeTopToolbar({
    super.key,
    required this.isRefreshing,
    required this.onRefresh,
    this.onOpenSettings,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenSettings;

  static const _menuItems = ['文件', '视图', '账户', '数据', '帮助'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '合约交易管理台',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 32),
          ..._menuItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                item,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: '刷新',
            onPressed: isRefreshing ? null : onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '偏好设置',
            onPressed: onOpenSettings ?? () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}
