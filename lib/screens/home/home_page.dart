import 'package:flutter/material.dart';

import '../../models/exchange.dart';
import '../../models/trade.dart';
import '../../repositories/exchange_repository.dart';
import '../../repositories/trade_repository.dart';
import '../trade_records/widgets/trade_form_dialog.dart';
import '../trade_records/widgets/trade_records_workspace.dart';
import 'widgets/dashboard_workspace.dart';
import 'widgets/home_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ExchangeRepository _exchangeRepository;
  late final TradeRepository _tradeRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<Exchange> _exchanges = const [];
  List<Trade> _trades = const [];
  double _totalPnl = 0;
  String _selectedView = '标准视图';
  String _selectedAccount = '全部账户';
  bool _showOnlyOpenTrades = false;
  String _activeNavigationItem = '仪表盘';

  @override
  void initState() {
    super.initState();
    _exchangeRepository = ExchangeRepository();
    _tradeRepository = TradeRepository(exchangeRepository: _exchangeRepository);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final exchanges = await _exchangeRepository.getAllExchanges();
      final trades = await _tradeRepository.getAllTrades();
      final totalPnl = await _tradeRepository.getTotalPnl();
      if (!mounted) {
        return;
      }
      setState(() {
        _exchanges = exchanges;
        _trades = trades;
        _totalPnl = totalPnl;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Map<int, Exchange> get _exchangeById => {
    for (final exchange in _exchanges)
      if (exchange.id != null) exchange.id!: exchange,
  };

  List<Trade> get _visibleTrades {
    Iterable<Trade> trades = _trades;
    if (_showOnlyOpenTrades) {
      trades = trades.where((trade) => trade.closeTimestamp.trim().isEmpty);
    }
    if (_selectedAccount != '全部账户') {
      int? selectedExchangeId;
      for (final entry in _exchangeById.entries) {
        if (entry.value.name == _selectedAccount) {
          selectedExchangeId = entry.key;
          break;
        }
      }
      if (selectedExchangeId != null) {
        trades = trades.where(
          (trade) => trade.exchangeId == selectedExchangeId,
        );
      }
    }
    return trades.toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildActiveContent();
    return HomeView(
      isRefreshing: _isLoading,
      onRefresh: _loadData,
      activeItem: _activeNavigationItem,
      onNavigationChanged: _handleNavigationChanged,
      content: content,
    );
  }

  void _updateSelectedView(String value) {
    setState(() => _selectedView = value);
  }

  void _updateSelectedAccount(String value) {
    setState(() => _selectedAccount = value);
  }

  void _updateShowOnlyOpenTrades(bool value) {
    setState(() => _showOnlyOpenTrades = value);
  }

  void _handleNavigationChanged(String value) {
    if (!mounted) {
      return;
    }
    setState(() => _activeNavigationItem = value);
  }

  Widget _buildActiveContent() {
    switch (_activeNavigationItem) {
      case '仪表盘':
        return DashboardWorkspace(
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          totalPnl: _totalPnl,
          trades: _trades,
          exchanges: _exchanges,
        );
      case '交易记录':
        return TradeRecordsWorkspace(
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          totalPnl: _totalPnl,
          selectedView: _selectedView,
          onSelectedViewChanged: _updateSelectedView,
          selectedAccount: _selectedAccount,
          onSelectedAccountChanged: _updateSelectedAccount,
          showOnlyOpenTrades: _showOnlyOpenTrades,
          onShowOnlyOpenTradesChanged: _updateShowOnlyOpenTrades,
          onCreateTrade: _openCreateTradeDialog,
          onRefresh: _loadData,
          trades: _visibleTrades,
          exchanges: _exchanges,
          exchangeById: _exchangeById,
        );
      default:
        return _ComingSoonPlaceholder(label: _activeNavigationItem);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

  Future<void> _openCreateTradeDialog() async {
    if (_exchanges.isEmpty) {
      _showSnackBar('请先添加交易所信息。');
      return;
    }

    final input = await showDialog<TradeInput>(
      context: context,
      builder: (context) => TradeFormDialog(exchanges: _exchanges),
    );
    if (input == null) {
      return;
    }
    try {
      await _tradeRepository.createTrade(input);
      await _loadData();
      _showSnackBar('交易记录已保存。');
    } catch (error) {
      _showSnackBar('保存失败：$error', isError: true);
    }
  }
}

class _ComingSoonPlaceholder extends StatelessWidget {
  const _ComingSoonPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_work_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            '“$label” 页面尚未实现',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '请先使用仪表盘或交易记录功能。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
