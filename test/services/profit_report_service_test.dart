import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_trade_tracker/models/exchange.dart';
import 'package:crypto_trade_tracker/models/trade.dart';
import 'package:crypto_trade_tracker/services/profit_report_service.dart';

void main() {
  group('ProfitReportService', () {
    const service = ProfitReportService();

    test('returns empty report when trades list is empty', () {
      final report = service.buildReport(trades: const [], exchanges: const []);
      expect(report.overview.totalTrades, 0);
      expect(report.directionSummaries, isEmpty);
      expect(report.exchangeSummaries, isEmpty);
      expect(report.symbolSummaries, isEmpty);
      expect(report.monthlySummaries, isEmpty);
    });

    test('aggregates core metrics and breakdowns', () {
      final exchanges = [
        Exchange(
          id: 1,
          name: 'Alpha Exchange',
          makerFeeRate: 0.001,
          takerFeeRate: 0.0015,
        ),
        Exchange(
          id: 2,
          name: 'Beta Exchange',
          makerFeeRate: 0.0012,
          takerFeeRate: 0.0018,
        ),
      ];
      final trades = [
        Trade(
          id: 1,
          exchangeId: 1,
          symbol: 'BTCUSDT',
          direction: 'LONG',
          role: 'MAKER',
          quantity: 1,
          leverage: 5,
          openPrice: 100,
          closePrice: 120,
          initialMargin: 20,
          fee: 4,
          pnl: 16,
          openTimestamp: '2024-01-01T00:00:00Z',
          closeTimestamp: '2024-01-02T00:00:00Z',
          notes: null,
        ),
        Trade(
          id: 2,
          exchangeId: 2,
          symbol: 'ETHUSDT',
          direction: 'SHORT',
          role: 'TAKER',
          quantity: 2,
          leverage: 3,
          openPrice: 100,
          closePrice: 105,
          initialMargin: 66.67,
          fee: 2,
          pnl: -12,
          openTimestamp: '2024-01-03T00:00:00Z',
          closeTimestamp: '2024-01-03T06:00:00Z',
          notes: null,
        ),
        Trade(
          id: 3,
          exchangeId: 1,
          symbol: 'ETHUSDT',
          direction: 'LONG',
          role: 'MAKER',
          quantity: 1.5,
          leverage: 4,
          openPrice: 50,
          closePrice: 70,
          initialMargin: 18.75,
          fee: 3,
          pnl: 27,
          openTimestamp: '2024-02-01T00:00:00Z',
          closeTimestamp: '2024-02-05T00:00:00Z',
          notes: null,
        ),
        Trade(
          id: 4,
          exchangeId: 2,
          symbol: 'BTCUSDT',
          direction: 'SHORT',
          role: 'TAKER',
          quantity: 0.5,
          leverage: 3,
          openPrice: 150,
          closePrice: 150,
          initialMargin: 25,
          fee: 0,
          pnl: 0,
          openTimestamp: '2024-02-10T00:00:00Z',
          closeTimestamp: '2024-02-10T04:00:00Z',
          notes: null,
        ),
      ];

      final report = service.buildReport(trades: trades, exchanges: exchanges);

      expect(report.overview.totalTrades, 4);
      expect(report.overview.netPnl, closeTo(31, 0.0001));
      expect(report.overview.grossProfit, closeTo(43, 0.0001));
      expect(report.overview.grossLoss, closeTo(12, 0.0001));
      expect(report.overview.totalFees, closeTo(9, 0.0001));
      expect(report.overview.winningTrades, 2);
      expect(report.overview.losingTrades, 1);
      expect(report.overview.breakevenTrades, 1);
      expect(report.overview.winRate, closeTo(0.5, 0.0001));
      expect(report.overview.averagePnl, closeTo(7.75, 0.0001));
      expect(report.overview.profitFactor, isNotNull);
      expect(report.overview.profitFactor!, closeTo(3.58, 0.01));
      expect(report.overview.averageHoldingHours, closeTo(32.5, 0.001));
      expect(report.overview.averageLeverage, closeTo(3.75, 0.0001));
      expect(report.overview.averageInitialMargin, closeTo(32.605, 0.001));

      final best = report.overview.bestTrade;
      expect(best, isNotNull);
      expect(best!.symbol, 'ETHUSDT');
      expect(best.exchangeName, 'Alpha Exchange');
      expect(best.holdingHours, closeTo(96, 0.0001));

      final worst = report.overview.worstTrade;
      expect(worst, isNotNull);
      expect(worst!.symbol, 'ETHUSDT');
      expect(worst.exchangeName, 'Beta Exchange');
      expect(worst.holdingHours, closeTo(6, 0.0001));

      expect(report.directionSummaries, hasLength(2));
      final longSummary = report.directionSummaries.firstWhere(
        (summary) => summary.direction == 'LONG',
      );
      expect(longSummary.tradeCount, 2);
      expect(longSummary.pnl, closeTo(43, 0.0001));
      expect(longSummary.winRate, closeTo(1, 0.0001));
      expect(longSummary.averageHoldingHours, closeTo(60, 0.0001));

      final shortSummary = report.directionSummaries.firstWhere(
        (summary) => summary.direction == 'SHORT',
      );
      expect(shortSummary.tradeCount, 2);
      expect(shortSummary.pnl, closeTo(-12, 0.0001));
      expect(shortSummary.winRate, 0);

      expect(report.exchangeSummaries, hasLength(2));
      final alpha = report.exchangeSummaries.firstWhere(
        (summary) => summary.exchangeId == 1,
      );
      expect(alpha.tradeCount, 2);
      expect(alpha.pnl, closeTo(43, 0.0001));
      expect(alpha.winRate, closeTo(1, 0.0001));
      expect(alpha.totalFees, closeTo(7, 0.0001));

      final beta = report.exchangeSummaries.firstWhere(
        (summary) => summary.exchangeId == 2,
      );
      expect(beta.tradeCount, 2);
      expect(beta.pnl, closeTo(-12, 0.0001));
      expect(beta.totalFees, closeTo(2, 0.0001));

      expect(report.symbolSummaries, hasLength(2));
      final btc = report.symbolSummaries.firstWhere(
        (summary) => summary.symbol == 'BTCUSDT',
      );
      expect(btc.tradeCount, 2);
      expect(btc.pnl, closeTo(16, 0.0001));

      final eth = report.symbolSummaries.firstWhere(
        (summary) => summary.symbol == 'ETHUSDT',
      );
      expect(eth.tradeCount, 2);
      expect(eth.pnl, closeTo(15, 0.0001));

      expect(report.monthlySummaries, hasLength(2));
      expect(report.monthlySummaries.first.label, '2024-02');
      expect(report.monthlySummaries.first.pnl, closeTo(27, 0.0001));
      expect(report.monthlySummaries.last.label, '2024-01');
      expect(report.monthlySummaries.last.pnl, closeTo(4, 0.0001));
    });
  });
}
