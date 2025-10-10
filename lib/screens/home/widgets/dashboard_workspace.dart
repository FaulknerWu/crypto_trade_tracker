import 'package:flutter/material.dart';

import '../../../models/exchange.dart';
import '../../../models/trade.dart';

class DashboardWorkspace extends StatelessWidget {
  const DashboardWorkspace({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.totalPnl,
    required this.trades,
    required this.exchanges,
    required this.onCreateTrade,
  });

  final bool isLoading;
  final String? errorMessage;
  final double totalPnl;
  final List<Trade> trades;
  final List<Exchange> exchanges;
  final VoidCallback onCreateTrade;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return _ErrorView(message: errorMessage!);
    }

    final metrics = _DashboardMetrics.fromData(trades, exchanges, totalPnl);

    return Container(
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '仪表盘',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCreateTrade,
                  icon: const Icon(Icons.add),
                  label: const Text('快速添加一笔交易信息'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MetricsGrid(metrics: metrics),
            const SizedBox(height: 24),
            _RecentTradesCard(metrics: metrics),
            const SizedBox(height: 24),
            _ExchangePerformanceCard(metrics: metrics),
          ],
        ),
      ),
    );
  }
}

class _DashboardMetrics {
  _DashboardMetrics({
    required this.totalPnl,
    required this.realizedPnl,
    required this.totalTrades,
    required this.closedTrades,
    required this.totalExchanges,
    required this.recentTrades,
    required this.exchangeSummaries,
  });

  final double totalPnl;
  final double realizedPnl;
  final int totalTrades;
  final int closedTrades;
  final int totalExchanges;
  final List<Trade> recentTrades;
  final List<_ExchangeSummary> exchangeSummaries;

  static _DashboardMetrics fromData(
    List<Trade> trades,
    List<Exchange> exchanges,
    double totalPnl,
  ) {
    final trimmedTrades = trades;
    final closed = trimmedTrades
        .where((trade) => trade.closeTimestamp.trim().isNotEmpty)
        .toList();
    final realizedPnl = closed.fold<double>(0, (sum, trade) => sum + trade.pnl);
    final sortedTrades = List<Trade>.of(trimmedTrades)
      ..sort(
        (a, b) => _parseTimestamp(
          b.openTimestamp,
        ).compareTo(_parseTimestamp(a.openTimestamp)),
      );
    final recentTrades = sortedTrades.take(5).toList();

    final exchangeById = {
      for (final exchange in exchanges)
        if (exchange.id != null) exchange.id!: exchange,
    };

    final exchangeMap = <int, _ExchangeSummary>{};
    for (final trade in trimmedTrades) {
      final exchange = exchangeById[trade.exchangeId];
      if (exchange == null) {
        continue;
      }
      final summary = exchangeMap.putIfAbsent(
        trade.exchangeId,
        () => _ExchangeSummary(
          exchangeName: exchange.name,
          tradeCount: 0,
          pnl: 0,
        ),
      );
      exchangeMap[trade.exchangeId] = summary.copyWith(
        tradeCount: summary.tradeCount + 1,
        pnl: summary.pnl + trade.pnl,
      );
    }

    final exchangeSummaries = exchangeMap.values.toList()
      ..sort((a, b) => b.pnl.compareTo(a.pnl));

    return _DashboardMetrics(
      totalPnl: totalPnl,
      realizedPnl: realizedPnl,
      totalTrades: trimmedTrades.length,
      closedTrades: closed.length,
      totalExchanges: exchanges.length,
      recentTrades: recentTrades,
      exchangeSummaries: exchangeSummaries,
    );
  }
}

class _ExchangeSummary {
  const _ExchangeSummary({
    required this.exchangeName,
    required this.tradeCount,
    required this.pnl,
  });

  final String exchangeName;
  final int tradeCount;
  final double pnl;

  _ExchangeSummary copyWith({int? tradeCount, double? pnl}) {
    return _ExchangeSummary(
      exchangeName: exchangeName,
      tradeCount: tradeCount ?? this.tradeCount,
      pnl: pnl ?? this.pnl,
    );
  }
}

const double _metricCardMinHeight = 188;

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        title: '净盈亏',
        value: _formatCurrency(metrics.totalPnl),
        trendColor: metrics.totalPnl >= 0 ? Colors.green : Colors.red,
        icon: Icons.ssid_chart,
      ),
      _MetricCard(
        title: '已结算交易',
        value: metrics.closedTrades.toString(),
        subtitle: '累计收益 ${_formatCurrency(metrics.realizedPnl)}',
        icon: Icons.check_circle_outline,
      ),
      _MetricCard(
        title: '关联账户',
        value: metrics.totalExchanges.toString(),
        subtitle: '总交易 ${metrics.totalTrades}',
        icon: Icons.account_balance_wallet,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 260.0;
        const gap = 16.0;
        final rawColumns = (constraints.maxWidth / minWidth).floor();
        final columnCount = rawColumns.clamp(1, cards.length);

        if (columnCount >= cards.length) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i != cards.length - 1) const SizedBox(width: gap),
                ],
              ],
            ),
          );
        }

        final isNarrow = constraints.maxWidth < minWidth * 1.2;
        final itemWidth = isNarrow
            ? constraints.maxWidth
            : (constraints.maxWidth - (columnCount - 1) * gap) / columnCount;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.trendColor,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? trendColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _metricCardMinHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(icon, color: theme.colorScheme.primary),
                    ),
                  ),
                  const Spacer(),
                  if (trendColor != null)
                    Icon(
                      trendColor == Colors.green
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: trendColor,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: trendColor ?? theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTradesCard extends StatelessWidget {
  const _RecentTradesCard({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final trades = metrics.recentTrades;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: '最近交易',
              trailing: Text('共 ${metrics.totalTrades} 条记录'),
            ),
            const SizedBox(height: 16),
            if (trades.isEmpty)
              Text(
                '暂无交易数据，前往“交易记录”页面添加新交易。',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Column(
                children: [
                  const _RecentTradesHeaderRow(),
                  const SizedBox(height: 12),
                  for (var i = 0; i < trades.length; i++) ...[
                    _RecentTradeRow(trade: trades[i]),
                    if (i != trades.length - 1)
                      Divider(height: 16, color: Colors.grey.shade200),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTradesHeaderRow extends StatelessWidget {
  const _RecentTradesHeaderRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _TradeTableCell(flex: 3, child: Text('交易对', style: headerStyle)),
          _TradeTableCell(flex: 1, child: Text('方向', style: headerStyle)),
          _TradeTableCell(
            flex: 1,
            alignment: Alignment.centerRight,
            child: Text('数量', style: headerStyle),
          ),
          _TradeTableCell(
            flex: 1,
            alignment: Alignment.centerRight,
            child: Text('杠杆', style: headerStyle),
          ),
          _TradeTableCell(
            flex: 2,
            alignment: Alignment.centerRight,
            child: Text('开仓时间', style: headerStyle),
          ),
          _TradeTableCell(
            flex: 2,
            alignment: Alignment.centerRight,
            child: Text('平仓时间', style: headerStyle),
          ),
          _TradeTableCell(
            flex: 1,
            alignment: Alignment.centerRight,
            child: Text('盈亏', style: headerStyle),
          ),
        ],
      ),
    );
  }
}

class _RecentTradeRow extends StatelessWidget {
  const _RecentTradeRow({required this.trade});

  final Trade trade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLong = trade.direction.toUpperCase() == 'LONG';
    final pnlColor = trade.pnl >= 0 ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _TradeTableCell(
            flex: 3,
            child: Text(
              trade.symbol,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _TradeTableCell(
            flex: 1,
            child: Text(
              isLong ? '做多' : '做空',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isLong ? Colors.green : Colors.red,
              ),
            ),
          ),
          _TradeTableCell(
            flex: 1,
            alignment: Alignment.centerRight,
            child: Text(
              trade.quantity.toStringAsFixed(2),
              style: theme.textTheme.bodySmall,
            ),
          ),
          _TradeTableCell(
            flex: 1,
            alignment: Alignment.centerRight,
            child: Text(
              trade.leverage.toString(),
              style: theme.textTheme.bodySmall,
            ),
          ),
          _TradeTableCell(
            flex: 2,
            alignment: Alignment.centerRight,
            child: Text(
              trade.openTimestamp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          _TradeTableCell(
            flex: 2,
            alignment: Alignment.centerRight,
            child: Text(
              trade.closeTimestamp.isEmpty ? '--' : trade.closeTimestamp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          _TradeTableCell(
            flex: 1,
            alignment: Alignment.centerRight,
            child: Text(
              _formatCurrency(trade.pnl),
              style: theme.textTheme.bodySmall?.copyWith(color: pnlColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeTableCell extends StatelessWidget {
  const _TradeTableCell({
    required this.flex,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  final int flex;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(alignment: alignment, child: child),
    );
  }
}

class _ExchangePerformanceCard extends StatelessWidget {
  const _ExchangePerformanceCard({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final summaries = metrics.exchangeSummaries;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: '交易所表现'),
            const SizedBox(height: 16),
            if (summaries.isEmpty)
              Text('暂无交易所数据。', style: Theme.of(context).textTheme.bodyMedium)
            else
              Column(
                children: summaries
                    .map((summary) => _ExchangeSummaryRow(summary: summary))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeSummaryRow extends StatelessWidget {
  const _ExchangeSummaryRow({required this.summary});

  final _ExchangeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pnlColor = summary.pnl >= 0 ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary.exchangeName,
              style: theme.textTheme.titleSmall,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              '交易 ${summary.tradeCount}',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              _formatCurrency(summary.pnl),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(color: pnlColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

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
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}';
}

DateTime _parseTimestamp(String raw) {
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
