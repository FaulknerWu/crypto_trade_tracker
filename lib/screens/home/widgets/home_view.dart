import 'package:flutter/material.dart';

import '../../../models/exchange.dart';
import '../../../models/trade.dart';
import 'home_top_toolbar.dart';
import 'home_workspace.dart';
import 'navigation_pane.dart';

class HomeView extends StatelessWidget {
  const HomeView({
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
    required this.onRefresh,
    required this.onCreateTrade,
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
  final VoidCallback onRefresh;
  final VoidCallback onCreateTrade;
  final List<Trade> trades;
  final List<Exchange> exchanges;
  final Map<int, Exchange> exchangeById;

  static const _activeNavigationItem = '交易记录';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          HomeTopToolbar(isRefreshing: isLoading, onRefresh: onRefresh),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: Row(
              children: [
                HomeNavigationPane(activeItem: _activeNavigationItem),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: HomeWorkspace(
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    totalPnl: totalPnl,
                    selectedView: selectedView,
                    onSelectedViewChanged: onSelectedViewChanged,
                    selectedAccount: selectedAccount,
                    onSelectedAccountChanged: onSelectedAccountChanged,
                    showOnlyOpenTrades: showOnlyOpenTrades,
                    onShowOnlyOpenTradesChanged: onShowOnlyOpenTradesChanged,
                    onCreateTrade: onCreateTrade,
                    onRefresh: onRefresh,
                    trades: trades,
                    exchanges: exchanges,
                    exchangeById: exchangeById,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
