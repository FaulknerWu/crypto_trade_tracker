
import 'package:flutter/material.dart';

import '../../../models/exchange.dart';
import '../../../models/trade.dart';
import 'trade_table.dart';

class TradeRecordsWorkspace extends StatelessWidget {
  const TradeRecordsWorkspace({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.totalPnl,
    required this.selectedView,
    required this.onSelectedViewChanged,
    required this.selectedAccount,
    required this.onSelectedAccountChanged,
    required this.showOnlyOpenTrades,
    required this.onShowOnlyOpenTradesChanged,
    required this.onCreateTrade,
    required this.onRefresh,
    required this.trades,
    required this.exchanges,
    required this.exchangeById,
  });

  final bool isLoading;
  final String? errorMessage;
  final double totalPnl;
  final String selectedView;
  final ValueChanged<String> onSelectedViewChanged;
  final String selectedAccount;
  final ValueChanged<String> onSelectedAccountChanged;
  final bool showOnlyOpenTrades;
  final ValueChanged<bool> onShowOnlyOpenTradesChanged;
  final VoidCallback onCreateTrade;
  final VoidCallback onRefresh;
  final List<Trade> trades;
  final List<Exchange> exchanges;
  final Map<int, Exchange> exchangeById;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return _ErrorView(message: errorMessage!, onRetry: onRefresh);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TradeRecordsHeader(
          totalPnl: totalPnl,
          selectedView: selectedView,
          onSelectedViewChanged: onSelectedViewChanged,
          selectedAccount: selectedAccount,
          onSelectedAccountChanged: onSelectedAccountChanged,
          showOnlyOpenTrades: showOnlyOpenTrades,
          onShowOnlyOpenTradesChanged: onShowOnlyOpenTradesChanged,
          onCreateTrade: onCreateTrade,
          isCreateDisabled: isLoading,
          accountNames: _buildAccountNames(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: trades.isEmpty
                  ? Center(
                      child: Text(
                        '尚未记录任何交易。点击上方“新增交易”开始记录。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TradeTable(
                        trades: trades,
                        exchangeById: exchangeById,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _buildAccountNames() {
    return ['全部账户', ...exchanges.map((exchange) => exchange.name)];
  }
}

class _TradeRecordsHeader extends StatelessWidget {
  const _TradeRecordsHeader({
    required this.totalPnl,
    required this.selectedView,
    required this.onSelectedViewChanged,
    required this.selectedAccount,
    required this.onSelectedAccountChanged,
    required this.showOnlyOpenTrades,
    required this.onShowOnlyOpenTradesChanged,
    required this.onCreateTrade,
    required this.isCreateDisabled,
    required this.accountNames,
  });

  final double totalPnl;
  final String selectedView;
  final ValueChanged<String> onSelectedViewChanged;
  final String selectedAccount;
  final ValueChanged<String> onSelectedAccountChanged;
  final bool showOnlyOpenTrades;
  final ValueChanged<bool> onShowOnlyOpenTradesChanged;
  final VoidCallback onCreateTrade;
  final bool isCreateDisabled;
  final List<String> accountNames;

  static const _views = ['标准视图', '紧凑视图'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '交易记录',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const compactBreakpoint = 920.0;
              final isCompact = constraints.maxWidth < compactBreakpoint;

              final viewSelector = _buildDropdown(
                context,
                label: '视图',
                value: selectedView,
                options: _views,
                onChanged: onSelectedViewChanged,
              );
              final accountSelector = _buildDropdown(
                context,
                label: '账户',
                value: selectedAccount,
                options: accountNames,
                onChanged: onSelectedAccountChanged,
              );
              final createButton = FilledButton.icon(
                onPressed: isCreateDisabled ? null : onCreateTrade,
                icon: const Icon(Icons.add),
                label: const Text('新增交易'),
              );
              final viewOptions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: showOnlyOpenTrades,
                    onChanged: (checked) =>
                        onShowOnlyOpenTradesChanged(checked ?? false),
                  ),
                  const Text('仅显示未平仓'),
                ],
              );
              final pnlText = Text(
                '净盈亏: ${_formatCurrency(totalPnl)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: totalPnl >= 0 ? Colors.green : Colors.red,
                ),
              );
              final searchField = SizedBox(
                width: isCompact ? constraints.maxWidth : 220,
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '搜索',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );

              if (!isCompact) {
                return Row(
                  children: [
                    viewSelector,
                    const SizedBox(width: 16),
                    accountSelector,
                    const SizedBox(width: 16),
                    createButton,
                    const Spacer(),
                    viewOptions,
                    const SizedBox(width: 12),
                    pnlText,
                    const SizedBox(width: 16),
                    searchField,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [viewSelector, accountSelector, createButton],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [viewOptions, pnlText, searchField],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.expand_more, size: 18),
              isDense: true,
              items: options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (selected) {
                if (selected != null) {
                  onChanged(selected);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(2)}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('数据加载失败', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}
