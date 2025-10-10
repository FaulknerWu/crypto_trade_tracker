import '../models/exchange.dart';
import '../models/trade.dart';

class ProfitReportService {
  const ProfitReportService();

  ProfitReportData buildReport({
    required List<Trade> trades,
    required List<Exchange> exchanges,
  }) {
    if (trades.isEmpty) {
      return const ProfitReportData.empty();
    }

    final exchangeById = <int, Exchange>{
      for (final exchange in exchanges)
        if (exchange.id != null) exchange.id!: exchange,
    };

    final overview = _buildOverview(trades, exchangeById);
    final directionSummaries = _buildDirectionSummaries(trades);
    final exchangeSummaries = _buildExchangeSummaries(trades, exchangeById);
    final symbolSummaries = _buildSymbolSummaries(trades);
    final monthlySummaries = _buildMonthlySummaries(trades);

    return ProfitReportData(
      overview: overview,
      directionSummaries: directionSummaries,
      exchangeSummaries: exchangeSummaries,
      symbolSummaries: symbolSummaries,
      monthlySummaries: monthlySummaries,
    );
  }

  ProfitReportOverview _buildOverview(
    List<Trade> trades,
    Map<int, Exchange> exchangeById,
  ) {
    var netPnl = 0.0;
    var grossProfit = 0.0;
    var grossLoss = 0.0;
    var totalFees = 0.0;
    var winningTrades = 0;
    var losingTrades = 0;
    var breakevenTrades = 0;
    var totalHoldingHours = 0.0;
    var holdingSamples = 0;
    var totalLeverage = 0.0;
    var totalInitialMargin = 0.0;

    Trade? bestTrade;
    Trade? worstTrade;

    for (final trade in trades) {
      netPnl += trade.pnl;
      totalFees += trade.fee;
      totalLeverage += trade.leverage;
      totalInitialMargin += trade.initialMargin;

      if (trade.pnl > 0) {
        grossProfit += trade.pnl;
        winningTrades += 1;
      } else if (trade.pnl < 0) {
        grossLoss += trade.pnl.abs();
        losingTrades += 1;
      } else {
        breakevenTrades += 1;
      }

      if (bestTrade == null || trade.pnl > bestTrade.pnl) {
        bestTrade = trade;
      }
      if (worstTrade == null || trade.pnl < worstTrade.pnl) {
        worstTrade = trade;
      }

      final holdingHours = _holdingHoursFor(trade);
      if (holdingHours != null) {
        totalHoldingHours += holdingHours;
        holdingSamples += 1;
      }
    }

    final totalTrades = trades.length;
    final winRate = totalTrades == 0 ? 0.0 : winningTrades / totalTrades;
    final averagePnl = totalTrades == 0 ? 0.0 : netPnl / totalTrades;
    final averageLeverage = totalTrades == 0
        ? 0.0
        : totalLeverage / totalTrades;
    final averageInitialMargin = totalTrades == 0
        ? 0.0
        : totalInitialMargin / totalTrades;
    final averageHoldingHours = holdingSamples == 0
        ? 0.0
        : totalHoldingHours / holdingSamples;
    final profitFactor = grossLoss == 0 ? null : grossProfit / grossLoss;

    return ProfitReportOverview(
      netPnl: netPnl,
      grossProfit: grossProfit,
      grossLoss: grossLoss,
      totalFees: totalFees,
      totalTrades: totalTrades,
      winningTrades: winningTrades,
      losingTrades: losingTrades,
      breakevenTrades: breakevenTrades,
      winRate: winRate,
      averagePnl: averagePnl,
      profitFactor: profitFactor,
      averageHoldingHours: averageHoldingHours,
      averageLeverage: averageLeverage,
      averageInitialMargin: averageInitialMargin,
      bestTrade: bestTrade == null
          ? null
          : _buildHighlight(bestTrade, exchangeById),
      worstTrade: worstTrade == null
          ? null
          : _buildHighlight(worstTrade, exchangeById),
    );
  }

  ProfitReportTradeHighlight _buildHighlight(
    Trade trade,
    Map<int, Exchange> exchangeById,
  ) {
    final holdingHours = _holdingHoursFor(trade);
    final exchange = exchangeById[trade.exchangeId];
    return ProfitReportTradeHighlight(
      tradeId: trade.id,
      symbol: trade.symbol,
      exchangeName: exchange?.name ?? '未命名账户',
      direction: trade.direction,
      pnl: trade.pnl,
      quantity: trade.quantity,
      leverage: trade.leverage,
      openTimestamp: trade.openTimestamp,
      closeTimestamp: trade.closeTimestamp,
      holdingHours: holdingHours,
    );
  }

  List<ProfitReportDirectionSummary> _buildDirectionSummaries(
    List<Trade> trades,
  ) {
    final accumulator = <String, _StatsAccumulator>{};
    for (final trade in trades) {
      final key = trade.direction.toUpperCase();
      final stats = accumulator.putIfAbsent(key, _StatsAccumulator.new);
      stats.addTrade(trade);
    }

    final entries = accumulator.entries.toList()
      ..sort((a, b) => b.value.netPnl.compareTo(a.value.netPnl));

    return [
      for (final entry in entries)
        ProfitReportDirectionSummary(
          direction: entry.key,
          tradeCount: entry.value.count,
          pnl: entry.value.netPnl,
          winRate: entry.value.winRate,
          averageHoldingHours: entry.value.averageHoldingHours,
          averageLeverage: entry.value.averageLeverage,
        ),
    ];
  }

  List<ProfitReportExchangeSummary> _buildExchangeSummaries(
    List<Trade> trades,
    Map<int, Exchange> exchangeById,
  ) {
    final accumulator = <int, _StatsAccumulator>{};
    for (final trade in trades) {
      final stats = accumulator.putIfAbsent(
        trade.exchangeId,
        _StatsAccumulator.new,
      );
      stats.addTrade(trade);
    }

    final entries = accumulator.entries.toList()
      ..sort((a, b) => b.value.netPnl.compareTo(a.value.netPnl));

    return [
      for (final entry in entries)
        ProfitReportExchangeSummary(
          exchangeId: entry.key,
          exchangeName: exchangeById[entry.key]?.name ?? '账户 ${entry.key}',
          tradeCount: entry.value.count,
          pnl: entry.value.netPnl,
          winRate: entry.value.winRate,
          totalFees: entry.value.totalFees,
          averageHoldingHours: entry.value.averageHoldingHours,
        ),
    ];
  }

  List<ProfitReportSymbolSummary> _buildSymbolSummaries(List<Trade> trades) {
    final accumulator = <String, _StatsAccumulator>{};
    for (final trade in trades) {
      final key = trade.symbol.toUpperCase();
      final stats = accumulator.putIfAbsent(key, _StatsAccumulator.new);
      stats.addTrade(trade);
    }

    final entries = accumulator.entries.toList()
      ..sort((a, b) => b.value.netPnl.compareTo(a.value.netPnl));

    return [
      for (final entry in entries)
        ProfitReportSymbolSummary(
          symbol: entry.key,
          tradeCount: entry.value.count,
          pnl: entry.value.netPnl,
          winRate: entry.value.winRate,
          averageHoldingHours: entry.value.averageHoldingHours,
        ),
    ];
  }

  List<ProfitReportPeriodSummary> _buildMonthlySummaries(List<Trade> trades) {
    final accumulator = <String, _StatsAccumulator>{};
    for (final trade in trades) {
      final closeTime =
          _parseTimestamp(trade.closeTimestamp) ??
          _parseTimestamp(trade.openTimestamp);
      final label = closeTime == null
          ? '未知日期'
          : '${closeTime.year.toString().padLeft(4, '0')}-${closeTime.month.toString().padLeft(2, '0')}';
      final stats = accumulator.putIfAbsent(label, _StatsAccumulator.new);
      stats.addTrade(trade);
    }

    final entries = accumulator.entries.toList()
      ..sort((a, b) => _comparePeriodLabels(b.key, a.key));

    return [
      for (final entry in entries)
        ProfitReportPeriodSummary(
          label: entry.key,
          tradeCount: entry.value.count,
          pnl: entry.value.netPnl,
          winRate: entry.value.winRate,
        ),
    ];
  }
}

class ProfitReportData {
  const ProfitReportData({
    required this.overview,
    required this.directionSummaries,
    required this.exchangeSummaries,
    required this.symbolSummaries,
    required this.monthlySummaries,
  });

  const ProfitReportData.empty()
    : overview = const ProfitReportOverview.empty(),
      directionSummaries = const [],
      exchangeSummaries = const [],
      symbolSummaries = const [],
      monthlySummaries = const [];

  final ProfitReportOverview overview;
  final List<ProfitReportDirectionSummary> directionSummaries;
  final List<ProfitReportExchangeSummary> exchangeSummaries;
  final List<ProfitReportSymbolSummary> symbolSummaries;
  final List<ProfitReportPeriodSummary> monthlySummaries;
}

class ProfitReportOverview {
  const ProfitReportOverview({
    required this.netPnl,
    required this.grossProfit,
    required this.grossLoss,
    required this.totalFees,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.breakevenTrades,
    required this.winRate,
    required this.averagePnl,
    required this.profitFactor,
    required this.averageHoldingHours,
    required this.averageLeverage,
    required this.averageInitialMargin,
    this.bestTrade,
    this.worstTrade,
  });

  const ProfitReportOverview.empty()
    : netPnl = 0,
      grossProfit = 0,
      grossLoss = 0,
      totalFees = 0,
      totalTrades = 0,
      winningTrades = 0,
      losingTrades = 0,
      breakevenTrades = 0,
      winRate = 0,
      averagePnl = 0,
      profitFactor = null,
      averageHoldingHours = 0,
      averageLeverage = 0,
      averageInitialMargin = 0,
      bestTrade = null,
      worstTrade = null;

  final double netPnl;
  final double grossProfit;
  final double grossLoss;
  final double totalFees;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final int breakevenTrades;
  final double winRate;
  final double averagePnl;
  final double? profitFactor;
  final double averageHoldingHours;
  final double averageLeverage;
  final double averageInitialMargin;
  final ProfitReportTradeHighlight? bestTrade;
  final ProfitReportTradeHighlight? worstTrade;
}

class ProfitReportTradeHighlight {
  const ProfitReportTradeHighlight({
    required this.tradeId,
    required this.symbol,
    required this.exchangeName,
    required this.direction,
    required this.pnl,
    required this.quantity,
    required this.leverage,
    required this.openTimestamp,
    required this.closeTimestamp,
    this.holdingHours,
  });

  final int? tradeId;
  final String symbol;
  final String exchangeName;
  final String direction;
  final double pnl;
  final double quantity;
  final int leverage;
  final String openTimestamp;
  final String closeTimestamp;
  final double? holdingHours;
}

class ProfitReportDirectionSummary {
  const ProfitReportDirectionSummary({
    required this.direction,
    required this.tradeCount,
    required this.pnl,
    required this.winRate,
    required this.averageHoldingHours,
    required this.averageLeverage,
  });

  final String direction;
  final int tradeCount;
  final double pnl;
  final double winRate;
  final double averageHoldingHours;
  final double averageLeverage;
}

class ProfitReportExchangeSummary {
  const ProfitReportExchangeSummary({
    required this.exchangeId,
    required this.exchangeName,
    required this.tradeCount,
    required this.pnl,
    required this.winRate,
    required this.totalFees,
    required this.averageHoldingHours,
  });

  final int exchangeId;
  final String exchangeName;
  final int tradeCount;
  final double pnl;
  final double winRate;
  final double totalFees;
  final double averageHoldingHours;
}

class ProfitReportSymbolSummary {
  const ProfitReportSymbolSummary({
    required this.symbol,
    required this.tradeCount,
    required this.pnl,
    required this.winRate,
    required this.averageHoldingHours,
  });

  final String symbol;
  final int tradeCount;
  final double pnl;
  final double winRate;
  final double averageHoldingHours;
}

class ProfitReportPeriodSummary {
  const ProfitReportPeriodSummary({
    required this.label,
    required this.tradeCount,
    required this.pnl,
    required this.winRate,
  });

  final String label;
  final int tradeCount;
  final double pnl;
  final double winRate;
}

class _StatsAccumulator {
  _StatsAccumulator()
    : count = 0,
      netPnl = 0,
      winCount = 0,
      totalFees = 0,
      leverageTotal = 0,
      holdingSamples = 0,
      holdingTotal = 0;

  int count;
  double netPnl;
  int winCount;
  double totalFees;
  double leverageTotal;
  int holdingSamples;
  double holdingTotal;

  bool get hasTrades => count > 0;

  double get winRate => count == 0 ? 0 : winCount / count;

  double get averageHoldingHours =>
      holdingSamples == 0 ? 0 : holdingTotal / holdingSamples;

  double get averageLeverage => count == 0 ? 0 : leverageTotal / count;

  void addTrade(Trade trade) {
    count += 1;
    netPnl += trade.pnl;
    if (trade.pnl > 0) {
      winCount += 1;
    }
    totalFees += trade.fee;
    leverageTotal += trade.leverage;

    final holdingHours = _holdingHoursFor(trade);
    if (holdingHours != null) {
      holdingSamples += 1;
      holdingTotal += holdingHours;
    }
  }
}

double? _holdingHoursFor(Trade trade) {
  final openTime = _parseTimestamp(trade.openTimestamp);
  final closeTime = _parseTimestamp(trade.closeTimestamp);
  if (openTime == null || closeTime == null) {
    return null;
  }
  final duration = closeTime.difference(openTime);
  if (duration.isNegative) {
    return null;
  }
  return duration.inMinutes / 60;
}

DateTime? _parseTimestamp(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  try {
    return DateTime.parse(value);
  } catch (_) {
    return null;
  }
}

int _comparePeriodLabels(String a, String b) {
  final aParts = _parsePeriodLabel(a);
  final bParts = _parsePeriodLabel(b);
  if (aParts == null || bParts == null) {
    return a.compareTo(b);
  }
  final yearCompare = aParts.$1.compareTo(bParts.$1);
  if (yearCompare != 0) {
    return yearCompare;
  }
  return aParts.$2.compareTo(bParts.$2);
}

(int, int)? _parsePeriodLabel(String label) {
  final parts = label.split('-');
  if (parts.length != 2) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) {
    return null;
  }
  return (year, month);
}
