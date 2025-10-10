import 'package:flutter/material.dart';

import '../../../models/exchange.dart';
import '../../../models/trade.dart';
import '../../../services/profit_report_service.dart';

class ProfitReportWorkspace extends StatelessWidget {
  const ProfitReportWorkspace({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.trades,
    required this.exchanges,
    required this.onRefresh,
    required this.onCreateTrade,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Trade> trades;
  final List<Exchange> exchanges;
  final VoidCallback onRefresh;
  final VoidCallback onCreateTrade;

  static const _service = ProfitReportService();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return _ErrorView(message: errorMessage!, onRetry: onRefresh);
    }
    if (trades.isEmpty) {
      return _EmptyView(onCreate: onCreateTrade);
    }

    final report = _service.buildReport(trades: trades, exchanges: exchanges);

    return Container(
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportHeader(overview: report.overview, onRefresh: onRefresh),
            const SizedBox(height: 20),
            _OverviewGrid(overview: report.overview),
            if (report.overview.bestTrade != null ||
                report.overview.worstTrade != null) ...[
              const SizedBox(height: 24),
              _HighlightsRow(overview: report.overview),
            ],
            if (report.directionSummaries.isNotEmpty) ...[
              const SizedBox(height: 24),
              _DirectionCard(summaries: report.directionSummaries),
            ],
            if (report.exchangeSummaries.isNotEmpty) ...[
              const SizedBox(height: 24),
              _ExchangeSummaryCard(summaries: report.exchangeSummaries),
            ],
            if (report.symbolSummaries.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SymbolSummaryCard(summaries: report.symbolSummaries),
            ],
            if (report.monthlySummaries.isNotEmpty) ...[
              const SizedBox(height: 24),
              _MonthlySummaryCard(summaries: report.monthlySummaries),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.overview, required this.onRefresh});

  final ProfitReportOverview overview;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netColor = overview.netPnl >= 0 ? Colors.green : Colors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '收益报表',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '净收益：${_formatCurrency(overview.netPnl)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: netColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '共记录 ${overview.totalTrades} 笔 | 胜率 ${_formatPercentage(overview.winRate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('重新统计'),
        ),
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.overview});

  final ProfitReportOverview overview;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _OverviewMetric(
        title: '累计盈利',
        value: _formatCurrency(overview.grossProfit),
        subtitle: '亏损 ${_formatCurrency(-overview.grossLoss)}',
      ),
      _OverviewMetric(
        title: '平均单笔盈亏',
        value: _formatCurrency(overview.averagePnl),
        subtitle: '手续费 ${_formatCurrency(-overview.totalFees)}',
      ),
      _OverviewMetric(
        title: '利润因子',
        value: overview.profitFactor == null
            ? '--'
            : overview.profitFactor!.toStringAsFixed(2),
        subtitle: '胜/负 ${overview.winningTrades}/${overview.losingTrades}',
      ),
      _OverviewMetric(
        title: '平均持仓 (小时)',
        value: overview.averageHoldingHours.toStringAsFixed(2),
        subtitle: '平均杠杆 ${overview.averageLeverage.toStringAsFixed(1)} 倍',
      ),
      _OverviewMetric(
        title: '平均初始保证金',
        value: _formatCurrency(overview.averageInitialMargin),
        subtitle: '走平 ${overview.breakevenTrades} 笔',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        const spacing = 16.0;
        var columns = 1;
        if (maxWidth >= 960) {
          columns = 3;
        } else if (maxWidth >= 640) {
          columns = 2;
        }
        final itemWidth = columns == 1
            ? maxWidth
            : (maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: columns == 1 ? maxWidth : itemWidth,
                child: _OverviewMetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _OverviewMetric {
  const _OverviewMetric({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({required this.metric});

  final _OverviewMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            metric.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (metric.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              metric.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightsRow extends StatelessWidget {
  const _HighlightsRow({required this.overview});

  final ProfitReportOverview overview;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];
    if (overview.bestTrade != null) {
      cards.add(
        _TradeHighlightCard(
          label: '最佳交易',
          highlight: overview.bestTrade!,
          color: Colors.green,
        ),
      );
    }
    if (overview.worstTrade != null) {
      cards.add(
        _TradeHighlightCard(
          label: '最大回撤',
          highlight: overview.worstTrade!,
          color: Colors.red,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (cards.length == 2 && constraints.maxWidth > 680) {
          return Row(
            children: [
              Expanded(child: cards.first),
              const SizedBox(width: 16),
              Expanded(child: cards.last),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _TradeHighlightCard extends StatelessWidget {
  const _TradeHighlightCard({
    required this.label,
    required this.highlight,
    required this.color,
  });

  final String label;
  final ProfitReportTradeHighlight highlight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directionLabel = highlight.direction == 'LONG' ? '多头' : '空头';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  label == '最佳交易' ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(highlight.pnl),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildInfoChip('品种', highlight.symbol),
              _buildInfoChip('账户', highlight.exchangeName),
              _buildInfoChip('方向', directionLabel),
              _buildInfoChip('数量', highlight.quantity.toStringAsFixed(4)),
              _buildInfoChip('杠杆', '${highlight.leverage}x'),
              _buildInfoChip(
                '持仓',
                highlight.holdingHours == null
                    ? '--'
                    : '${highlight.holdingHours!.toStringAsFixed(2)} 小时',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '开仓：${_formatTimestamp(highlight.openTimestamp)}  |  平仓：${_formatTimestamp(highlight.closeTimestamp)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label $value'),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({required this.summaries});

  final List<ProfitReportDirectionSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '方向表现',
      subtitle: '区分多空方向的盈亏和胜率',
      child: Column(
        children: [
          for (final summary in summaries) ...[
            _DirectionTile(summary: summary),
            if (summary != summaries.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _DirectionTile extends StatelessWidget {
  const _DirectionTile({required this.summary});

  final ProfitReportDirectionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = summary.direction == 'LONG' ? '多头' : '空头';
    final color = summary.pnl >= 0 ? Colors.green : Colors.red;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(
          summary.direction == 'LONG' ? Icons.trending_up : Icons.trending_down,
          color: color,
          size: 18,
        ),
      ),
      title: Text(
        '$label ${summary.tradeCount} 笔',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        '胜率 ${_formatPercentage(summary.winRate)} · 持仓 ${summary.averageHoldingHours.toStringAsFixed(2)} 小时 · 杠杆 ${summary.averageLeverage.toStringAsFixed(1)}x',
      ),
      trailing: Text(
        _formatCurrency(summary.pnl),
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ExchangeSummaryCard extends StatelessWidget {
  const _ExchangeSummaryCard({required this.summaries});

  final List<ProfitReportExchangeSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final top = summaries.take(6).toList();
    return _SectionCard(
      title: '账户表现',
      subtitle: '按交易所统计盈亏、胜率与手续费',
      child: Column(
        children: [
          for (final summary in top) ...[
            _ExchangeTile(summary: summary),
            if (summary != top.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ExchangeTile extends StatelessWidget {
  const _ExchangeTile({required this.summary});

  final ProfitReportExchangeSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = summary.pnl >= 0 ? Colors.green : Colors.red;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(summary.exchangeName, style: theme.textTheme.titleSmall),
      subtitle: Text(
        '${summary.tradeCount} 笔 · 胜率 ${_formatPercentage(summary.winRate)} · 手续费 ${_formatCurrency(-summary.totalFees)}',
      ),
      trailing: Text(
        _formatCurrency(summary.pnl),
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _SymbolSummaryCard extends StatelessWidget {
  const _SymbolSummaryCard({required this.summaries});

  final List<ProfitReportSymbolSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final top = summaries.take(8).toList();
    return _SectionCard(
      title: '品种排行',
      subtitle: '按交易品种统计盈亏与胜率',
      child: Column(
        children: [
          for (final summary in top) ...[
            _SymbolTile(summary: summary),
            if (summary != top.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SymbolTile extends StatelessWidget {
  const _SymbolTile({required this.summary});

  final ProfitReportSymbolSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = summary.pnl >= 0 ? Colors.green : Colors.red;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey.shade100,
        child: Text(
          _symbolPrefix(summary.symbol),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(summary.symbol, style: theme.textTheme.titleSmall),
      subtitle: Text(
        '${summary.tradeCount} 笔 · 胜率 ${_formatPercentage(summary.winRate)} · 持仓 ${summary.averageHoldingHours.toStringAsFixed(2)} 小时',
      ),
      trailing: Text(
        _formatCurrency(summary.pnl),
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.summaries});

  final List<ProfitReportPeriodSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: '月度盈亏趋势',
      subtitle: '按结算月份统计盈亏与胜率',
      child: Column(
        children: [
          for (final summary in summaries) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(summary.label, style: theme.textTheme.titleSmall),
              subtitle: Text(
                '${summary.tradeCount} 笔 · 胜率 ${_formatPercentage(summary.winRate)}',
              ),
              trailing: Text(
                _formatCurrency(summary.pnl),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: summary.pnl >= 0 ? Colors.green : Colors.red,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (summary != summaries.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text('数据加载失败', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text('暂无交易数据', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '添加交易记录后即可查看收益统计。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onCreate, child: const Text('录入一笔交易')),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}';
}

String _formatPercentage(double value) {
  final percent = (value * 100).clamp(-9999, 9999);
  return '${percent.toStringAsFixed(1)}%';
}

String _formatTimestamp(String raw) {
  final dateTime = DateTime.tryParse(raw);
  if (dateTime == null) {
    return raw;
  }
  final date =
      '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  final time =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _symbolPrefix(String symbol) {
  final trimmed = symbol.trim();
  if (trimmed.isEmpty) {
    return '--';
  }
  final upper = trimmed.toUpperCase();
  final length = upper.length < 3 ? upper.length : 3;
  return upper.substring(0, length);
}
