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
    required this.selectedExchangeId,
    required this.onSelectedExchangeChanged,
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
  final int? selectedExchangeId;
  final ValueChanged<int?> onSelectedExchangeChanged;
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
    final filteredTrades = selectedExchangeId == null
        ? trades
        : trades
              .where((trade) => trade.exchangeId == selectedExchangeId)
              .toList();
    final isCompactView = selectedView == _TradeRecordsHeader.views.last;
    final tableKey = ValueKey(
      '${selectedExchangeId ?? 'all'}-${filteredTrades.map(_tradeIdentifier).join(',')}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TradeRecordsHeader(
          totalPnl: totalPnl,
          selectedView: selectedView,
          onSelectedViewChanged: onSelectedViewChanged,
          selectedExchangeId: selectedExchangeId,
          onSelectedExchangeChanged: onSelectedExchangeChanged,
          onCreateTrade: onCreateTrade,
          isCreateDisabled: isLoading,
          exchanges: exchanges,
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
              child: filteredTrades.isEmpty
                  ? Center(
                      child: Text(
                        selectedExchangeId == null
                            ? '尚未记录任何交易。点击上方“新增交易”开始记录。'
                            : '该交易所暂无交易记录。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TradeTable(
                        key: tableKey,
                        trades: filteredTrades,
                        exchangeById: exchangeById,
                        isCompactView: isCompactView,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TradeRecordsHeader extends StatelessWidget {
  const _TradeRecordsHeader({
    required this.totalPnl,
    required this.selectedView,
    required this.onSelectedViewChanged,
    required this.selectedExchangeId,
    required this.onSelectedExchangeChanged,
    required this.onCreateTrade,
    required this.isCreateDisabled,
    required this.exchanges,
  });

  final double totalPnl;
  final String selectedView;
  final ValueChanged<String> onSelectedViewChanged;
  final int? selectedExchangeId;
  final ValueChanged<int?> onSelectedExchangeChanged;
  final VoidCallback onCreateTrade;
  final bool isCreateDisabled;
  final List<Exchange> exchanges;

  static const views = ['标准视图', '紧凑视图'];
  static const double _controlHeight = 40;
  static const double _controlFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountOptions = _buildAccountOptions();
    final selectedAccountOption = accountOptions.firstWhere(
      (option) => option.id == selectedExchangeId,
      orElse: () => accountOptions.first,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '交易记录',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '净盈亏：${_formatCurrency(totalPnl)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: totalPnl >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: isCreateDisabled ? null : onCreateTrade,
                icon: const Icon(Icons.add),
                label: const Text('新增交易'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(120, _controlHeight),
                  textStyle: const TextStyle(fontSize: _controlFontSize),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const compactBreakpoint = 840.0;
              final isCompact = constraints.maxWidth < compactBreakpoint;

              final filterControls = Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildAccountPicker(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    selected: selectedAccountOption,
                    options: accountOptions,
                    onSelected: onSelectedExchangeChanged,
                  ),
                  _buildPickerPill(
                    context,
                    icon: Icons.view_week_outlined,
                    label: selectedView,
                    isActive: selectedView != views.first,
                    options: views,
                    onSelected: onSelectedViewChanged,
                  ),
                ],
              );

              final searchField = SizedBox(
                width: isCompact ? double.infinity : 280,
                child: SizedBox(
                  height: _controlHeight,
                  child: _buildSearchField(context),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    filterControls,
                    const SizedBox(height: 16),
                    searchField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: filterControls),
                  const SizedBox(width: 16),
                  searchField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPicker(
    BuildContext context, {
    required IconData icon,
    required _AccountOption selected,
    required List<_AccountOption> options,
    required ValueChanged<int?> onSelected,
  }) {
    final theme = Theme.of(context);
    final isActive = selected.id != null;
    final borderColor = isActive
        ? theme.colorScheme.primary
        : Colors.grey.shade300;
    final foregroundColor = isActive
        ? theme.colorScheme.primary
        : Colors.grey.shade700;
    final backgroundColor = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : Colors.grey.shade100;

    return SizedBox(
      height: _controlHeight,
      child: PopupMenuButton<_AccountOption>(
        position: PopupMenuPosition.under,
        onSelected: (option) => onSelected(option.id),
        itemBuilder: (context) => options
            .map(
              (option) => PopupMenuItem<_AccountOption>(
                value: option,
                child: Text(
                  option.label,
                  style: const TextStyle(fontSize: _controlFontSize),
                ),
              ),
            )
            .toList(),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                selected.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: _controlFontSize,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 18, color: foregroundColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<String> options,
    required ValueChanged<String> onSelected,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final borderColor = isActive
        ? theme.colorScheme.primary
        : Colors.grey.shade300;
    final foregroundColor = isActive
        ? theme.colorScheme.primary
        : Colors.grey.shade700;
    final backgroundColor = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : Colors.grey.shade100;

    return SizedBox(
      height: _controlHeight,
      child: PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: (context) => options
            .map(
              (option) => PopupMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(fontSize: _controlFontSize),
                ),
              ),
            )
            .toList(),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: _controlFontSize,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 18, color: foregroundColor),
            ],
          ),
        ),
      ),
    );
  }

  List<_AccountOption> _buildAccountOptions() {
    final options = <_AccountOption>[
      const _AccountOption(id: null, label: '全部账户'),
    ];
    for (final exchange in exchanges) {
      if (exchange.id == null) {
        continue;
      }
      options.add(_AccountOption(id: exchange.id!, label: exchange.name));
    }
    return options;
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索交易、交易所或备注',
        prefixIcon: const Icon(Icons.search, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      style: const TextStyle(fontSize: _controlFontSize),
    );
  }

  String _formatCurrency(double value) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(2)}';
  }
}

class _AccountOption {
  const _AccountOption({required this.id, required this.label});

  final int? id;
  final String label;

  @override
  String toString() => 'AccountOption(id: $id, label: $label)';
}

String _tradeIdentifier(Trade trade) {
  return trade.id?.toString() ??
      '${trade.exchangeId}-${trade.symbol}-${trade.openTimestamp}-${trade.closeTimestamp}';
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
