import 'package:flutter/material.dart';

class HomeNavigationPane extends StatelessWidget {
  const HomeNavigationPane({
    super.key,
    required this.activeItem,
    this.onItemSelected,
  });

  final String activeItem;
  final ValueChanged<String>? onItemSelected;

  static const _navigationGroups = <_NavigationGroupConfig>[
    _NavigationGroupConfig(title: '账户', items: ['仪表盘', '交易账户', '资金流动']),
    _NavigationGroupConfig(
      title: '报表',
      items: ['资产净值', '仓位分析', '收益报表', '交易记录', '图表面板'],
    ),
    _NavigationGroupConfig(title: '类别', items: ['标签管理', '策略类型']),
    _NavigationGroupConfig(title: '常规数据', items: ['货币', '设置']),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      color: Colors.grey.shade50,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          _buildNavigationHeader(theme),
          for (final group in _navigationGroups) ...[
            _buildNavigationGroupTitle(theme, group.title),
            ...group.items.map(
              (item) => _buildNavigationItem(
                theme,
                item,
                isActive: item == activeItem,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Text(
        '导航',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildNavigationGroupTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    ThemeData theme,
    String label, {
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onItemSelected?.call(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isActive
                      ? theme.colorScheme.primary
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.grey.shade700,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationGroupConfig {
  const _NavigationGroupConfig({required this.title, required this.items});

  final String title;
  final List<String> items;
}
