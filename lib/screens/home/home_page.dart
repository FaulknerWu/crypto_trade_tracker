import 'package:flutter/material.dart';

import '../../models/exchange.dart';
import '../../models/trade.dart';
import '../../repositories/exchange_repository.dart';
import '../../repositories/trade_repository.dart';
import 'widgets/home_view.dart';
import 'widgets/trade_form_dialog.dart';

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
    if (!_showOnlyOpenTrades) {
      return _trades;
    }
    return _trades
        .where((trade) => trade.closeTimestamp.trim().isEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return HomeView(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      totalPnl: _totalPnl,
      selectedView: _selectedView,
      onSelectedViewChanged: _updateSelectedView,
      selectedAccount: _selectedAccount,
      onSelectedAccountChanged: _updateSelectedAccount,
      showOnlyOpenTrades: _showOnlyOpenTrades,
      onShowOnlyOpenTradesChanged: _updateShowOnlyOpenTrades,
      onRefresh: _loadData,
      onCreateTrade: _openCreateTradeDialog,
      trades: _visibleTrades,
      exchanges: _exchanges,
      exchangeById: _exchangeById,
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
