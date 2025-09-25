import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../models/exchange.dart';
import '../models/trade.dart';
import '../repositories/exchange_repository.dart';
import '../repositories/trade_repository.dart';

const _tradeTableColumnWidths = <double>[
  160, // 交易所
  120, // 交易对
  80, // 方向
  100, // 角色
  100, // 数量
  80, // 杠杆
  120, // 开仓价
  120, // 平仓价
  140, // 起始保证金
  100, // 手续费
  120, // 净盈亏
  160, // 开仓时间
  160, // 平仓时间
  200, // 备注
];

class _NavigationGroupConfig {
  const _NavigationGroupConfig({required this.title, required this.items});

  final String title;
  final List<String> items;
}

const _navigationGroups = <_NavigationGroupConfig>[
  _NavigationGroupConfig(
    title: '账户',
    items: ['仪表盘', '交易账户', '资金流动'],
  ),
  _NavigationGroupConfig(
    title: '报表',
    items: ['资产净值', '仓位分析', '收益报表', '交易记录', '图表面板'],
  ),
  _NavigationGroupConfig(
    title: '类别',
    items: ['标签管理', '策略类型'],
  ),
  _NavigationGroupConfig(
    title: '常规数据',
    items: ['货币', '设置'],
  ),
];

const _formFieldGap = SizedBox(height: 12);

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
    for (final exchange in _exchanges) exchange.id!: exchange,
  };

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildTopToolbar() {
    final menuItems = const ['文件', '视图', '账户', '数据', '帮助'];
    final theme = Theme.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '合约交易管理台',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 32),
          for (final item in menuItems)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                item,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: '刷新',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '偏好设置',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildTopToolbar(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: Row(
              children: [
                _buildNavigationPane(),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildWorkspace()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPane() {
    const activeItem = '交易记录';
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
            ...group.items.map((item) => _buildNavigationItem(theme, item,
                isActive: item == activeItem)),
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
          onTap: () {},
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
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('数据加载失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWorkspaceHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildTradesSection(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceHeader() {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '交易记录',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const compactBreakpoint = 920.0;
              final isCompact = constraints.maxWidth < compactBreakpoint;

              final viewSelector = _buildViewSelector();
              final accountSelector = _buildAccountSelector();
              final createButton = FilledButton.icon(
                onPressed: _isLoading ? null : _openCreateTradeDialog,
                icon: const Icon(Icons.add),
                label: const Text('新增交易'),
              );
              final viewOptions = _buildViewOptions();
              final pnlText = Text(
                '净盈亏: ${_formatCurrency(_totalPnl)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: _totalPnl >= 0 ? Colors.green : Colors.red,
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
                    children: [
                      viewSelector,
                      accountSelector,
                      createButton,
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      viewOptions,
                      pnlText,
                      searchField,
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    const views = ['标准视图', '紧凑视图'];
    return _buildDropdown(
      label: '视图',
      value: _selectedView,
      options: views,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedView = value);
      },
    );
  }

  Widget _buildAccountSelector() {
    final accountNames = ['全部账户', ..._exchanges.map((exchange) => exchange.name)];
    return _buildDropdown(
      label: '账户',
      value: _selectedAccount,
      options: accountNames,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedAccount = value);
      },
    );
  }

  Widget _buildViewOptions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _showOnlyOpenTrades,
          onChanged: (checked) {
            setState(() => _showOnlyOpenTrades = checked ?? false);
          },
        ),
        const Text('仅显示未平仓'),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    ValueChanged<String?>? onChanged,
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
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTradesSection() {
    final trades = _showOnlyOpenTrades
        ? _trades
            .where((trade) => trade.closeTimestamp.trim().isEmpty)
            .toList()
        : _trades;

    if (trades.isEmpty) {
      return Center(
        child: Text(
          '尚未记录任何交易。点击上方“新增交易”开始记录。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final columns = _buildTradeColumns();
    final rows = _buildTradeRows(trades);

    final style = PlutoGridStyleConfig(
      enableGridBorderShadow: false,
      gridBackgroundColor: Colors.white,
      rowColor: Colors.white,
      oddRowColor: Colors.grey.shade50,
      evenRowColor: Colors.white,
      gridBorderColor: Colors.grey.shade300,
      borderColor: Colors.grey.shade200,
      enableCellBorderHorizontal: true,
      enableCellBorderVertical: true,
      rowHeight: 32,
      columnHeight: 36,
      columnFilterHeight: 34,
      defaultCellPadding: const EdgeInsets.symmetric(horizontal: 8),
      defaultColumnTitlePadding: const EdgeInsets.symmetric(horizontal: 8),
      defaultColumnFilterPadding: const EdgeInsets.symmetric(horizontal: 8),
      columnTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
      cellTextStyle: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      activatedColor: Colors.blue.shade50,
      checkedColor: Colors.blue.shade50.withValues(alpha: 0.3),
      iconColor: Colors.grey.shade500,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: PlutoGrid(
        columns: columns,
        rows: rows,
        configuration: PlutoGridConfiguration(
          style: style,
          columnSize: const PlutoGridColumnSizeConfig(
            autoSizeMode: PlutoAutoSizeMode.none,
            resizeMode: PlutoResizeMode.normal,
          ),
          scrollbar: PlutoGridScrollbarConfig(
            draggableScrollbar: true,
            onlyDraggingThumb: true,
            isAlwaysShown: true,
            scrollbarRadius: const Radius.circular(4),
            scrollbarThickness: 10,
            scrollbarThicknessWhileDragging: 12,
          ),
        ),
        onLoaded: (event) {
          event.stateManager
            ..setShowColumnFilter(true)
            ..setKeepFocus(true);
        },
      ),
    );
  }

  List<PlutoColumn> _buildTradeColumns() {
    return [
      _buildTextColumn(
        title: '交易所',
        field: 'exchange',
        widthIndex: 0,
        textAlign: PlutoColumnTextAlign.start,
        minWidth: 120,
      ),
      _buildTextColumn(
        title: '交易对',
        field: 'symbol',
        widthIndex: 1,
      ),
      _buildTextColumn(
        title: '方向',
        field: 'direction',
        widthIndex: 2,
        textAlign: PlutoColumnTextAlign.center,
      ),
      _buildTextColumn(
        title: '角色',
        field: 'role',
        widthIndex: 3,
        textAlign: PlutoColumnTextAlign.center,
      ),
      _buildNumberColumn(
        title: '数量',
        field: 'quantity',
        widthIndex: 4,
        format: '#,##0.00',
      ),
      _buildNumberColumn(
        title: '杠杆',
        field: 'leverage',
        widthIndex: 5,
        format: '#,##0',
      ),
      _buildNumberColumn(
        title: '开仓价',
        field: 'openPrice',
        widthIndex: 6,
        format: '#,##0.00',
      ),
      _buildNumberColumn(
        title: '平仓价',
        field: 'closePrice',
        widthIndex: 7,
        format: '#,##0.00',
      ),
      _buildNumberColumn(
        title: '起始保证金',
        field: 'initialMargin',
        widthIndex: 8,
        format: '#,##0.00',
      ),
      _buildNumberColumn(
        title: '手续费',
        field: 'fee',
        widthIndex: 9,
        format: '#,##0.00',
      ),
      _buildNumberColumn(
        title: '净盈亏',
        field: 'pnl',
        widthIndex: 10,
        format: '#,##0.00',
        renderer: (context) {
          final value = context.cell.value is num
              ? (context.cell.value as num).toDouble()
              : double.tryParse('${context.cell.value}') ?? 0;
          final color = value >= 0 ? Colors.green : Colors.red;
          return Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatNumber(value),
              style: TextStyle(
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
      _buildTextColumn(
        title: '开仓时间',
        field: 'openTime',
        widthIndex: 11,
      ),
      _buildTextColumn(
        title: '平仓时间',
        field: 'closeTime',
        widthIndex: 12,
      ),
      _buildTextColumn(
        title: '备注',
        field: 'notes',
        widthIndex: 13,
      minWidth: 160,
      renderer: (context) {
          final raw = context.cell.value?.toString().trim();
          final display = (raw == null || raw.isEmpty) ? '-' : raw;
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              display,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    ];
  }

  PlutoColumn _buildTextColumn({
    required String title,
    required String field,
    required int widthIndex,
    PlutoColumnTextAlign textAlign = PlutoColumnTextAlign.start,
    double minWidth = 0,
    PlutoColumnRenderer? renderer,
  }) {
    return _buildColumn(
      title: title,
      field: field,
      type: PlutoColumnType.text(),
      width: _columnWidth(widthIndex),
      textAlign: textAlign,
      minWidth: minWidth,
      renderer: renderer,
    );
  }

  PlutoColumn _buildNumberColumn({
    required String title,
    required String field,
    required int widthIndex,
    required String format,
    PlutoColumnRenderer? renderer,
  }) {
    return _buildColumn(
      title: title,
      field: field,
      type: PlutoColumnType.number(format: format),
      width: _columnWidth(widthIndex),
      textAlign: PlutoColumnTextAlign.right,
      renderer: renderer,
    );
  }

  PlutoColumn _buildColumn({
    required String title,
    required String field,
    required PlutoColumnType type,
    required double width,
    PlutoColumnTextAlign textAlign = PlutoColumnTextAlign.start,
    PlutoColumnTextAlign titleTextAlign = PlutoColumnTextAlign.center,
    double minWidth = 0,
    PlutoColumnRenderer? renderer,
  }) {
    return PlutoColumn(
      title: title,
      field: field,
      type: type,
      width: width,
      minWidth: minWidth,
      readOnly: true,
      titleTextAlign: titleTextAlign,
      textAlign: textAlign,
      renderer: renderer,
    );
  }

  double _columnWidth(int index) => _tradeTableColumnWidths[index];

  List<PlutoRow> _buildTradeRows(List<Trade> trades) {
    return trades.map((trade) {
      final exchangeName =
          _exchangeById[trade.exchangeId]?.name ?? '交易所 ${trade.exchangeId}';
      return PlutoRow(
        cells: {
          'exchange': PlutoCell(value: exchangeName),
          'symbol': PlutoCell(value: trade.symbol),
          'direction': PlutoCell(value: trade.direction),
          'role': PlutoCell(value: trade.role),
          'quantity': PlutoCell(value: trade.quantity),
          'leverage': PlutoCell(value: trade.leverage),
          'openPrice': PlutoCell(value: trade.openPrice),
          'closePrice': PlutoCell(value: trade.closePrice),
          'initialMargin': PlutoCell(value: trade.initialMargin),
          'fee': PlutoCell(value: trade.fee),
          'pnl': PlutoCell(value: trade.pnl),
          'openTime': PlutoCell(value: _formatDate(trade.openTimestamp)),
          'closeTime': PlutoCell(value: _formatDate(trade.closeTimestamp)),
          'notes': PlutoCell(value: trade.notes ?? ''),
        },
      );
    }).toList();
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(2)}';
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    final local = parsed.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Future<void> _openCreateTradeDialog() async {
    if (_exchanges.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加交易所信息。')));
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('交易记录已保存。')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }
}

class TradeFormDialog extends StatefulWidget {
  const TradeFormDialog({super.key, required this.exchanges});

  final List<Exchange> exchanges;

  @override
  State<TradeFormDialog> createState() => _TradeFormDialogState();
}

class _TradeFormDialogState extends State<TradeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late int _selectedExchangeId;
  String _direction = 'LONG';
  String _role = 'TAKER';

  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _leverageController = TextEditingController(text: '1');
  final _openPriceController = TextEditingController(text: '100');
  final _closePriceController = TextEditingController(text: '100');
  late final TextEditingController _openTimestampController;
  late final TextEditingController _closeTimestampController;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedExchangeId = widget.exchanges.first.id!;
    final now = DateTime.now().toUtc();
    _openTimestampController = TextEditingController(
      text: now.toIso8601String(),
    );
    _closeTimestampController = TextEditingController(
      text: now.toIso8601String(),
    );
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _leverageController.dispose();
    _openPriceController.dispose();
    _closePriceController.dispose();
    _openTimestampController.dispose();
    _closeTimestampController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增交易记录'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdownField<int>(
                  label: '交易所',
                  value: _selectedExchangeId,
                  items: widget.exchanges
                      .map(
                        (exchange) => DropdownMenuItem<int>(
                          value: exchange.id,
                          child: Text(exchange.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedExchangeId = value);
                    }
                  },
                ),
                _formFieldGap,
                _buildFormTextField(
                  controller: _symbolController,
                  label: '交易对 (例如 BTCUSDT)',
                  validator: _requiredValidator,
                ),
                _formFieldGap,
                _buildDualFieldRow(
                  _buildDropdownField<String>(
                    label: '方向',
                    value: _direction,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'LONG',
                        child: Text('多头 (LONG)'),
                      ),
                      DropdownMenuItem(
                        value: 'SHORT',
                        child: Text('空头 (SHORT)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _direction = value);
                      }
                    },
                  ),
                  _buildDropdownField<String>(
                    label: '角色',
                    value: _role,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'MAKER',
                        child: Text('挂单 (MAKER)'),
                      ),
                      DropdownMenuItem(
                        value: 'TAKER',
                        child: Text('吃单 (TAKER)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _role = value);
                      }
                    },
                  ),
                ),
                _formFieldGap,
                _buildDualFieldRow(
                  _buildNumberField(
                    controller: _quantityController,
                    label: '数量',
                  ),
                  _buildNumberField(
                    controller: _leverageController,
                    label: '杠杆',
                    isInteger: true,
                  ),
                ),
                _formFieldGap,
                _buildDualFieldRow(
                  _buildNumberField(
                    controller: _openPriceController,
                    label: '开仓价',
                  ),
                  _buildNumberField(
                    controller: _closePriceController,
                    label: '平仓价',
                  ),
                ),
                _formFieldGap,
                _buildIsoField(
                  controller: _openTimestampController,
                  label: '开仓时间 (ISO 8601)',
                ),
                _formFieldGap,
                _buildIsoField(
                  controller: _closeTimestampController,
                  label: '平仓时间 (ISO 8601)',
                ),
                _formFieldGap,
                _buildFormTextField(
                  controller: _notesController,
                  label: '备注 (可选)',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    bool isInteger = false,
  }) {
    return _buildFormTextField(
      controller: controller,
      label: label,
      keyboardType: isInteger
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      validator: (value) =>
          _positiveNumberValidator(value, isInteger: isInteger),
    );
  }

  Widget _buildIsoField({
    required TextEditingController controller,
    required String label,
  }) {
    return _buildFormTextField(
      controller: controller,
      label: label,
      validator: _isoValidator,
    );
  }

  Widget _buildDualFieldRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '该字段不能为空';
    }
    return null;
  }

  String? _positiveNumberValidator(String? value, {required bool isInteger}) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return '请输入数值';
    }
    final parsed = isInteger ? int.tryParse(raw) : double.tryParse(raw);
    if (parsed == null) {
      return '格式无效';
    }
    if (parsed <= 0) {
      return '必须大于 0';
    }
    return null;
  }

  String? _isoValidator(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return '请输入时间';
    }
    try {
      DateTime.parse(raw);
      return null;
    } catch (_) {
      return '必须是有效的 ISO 8601 时间字符串';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final quantity = double.parse(_quantityController.text.trim());
    final leverage = int.parse(_leverageController.text.trim());
    final openPrice = double.parse(_openPriceController.text.trim());
    final closePrice = double.parse(_closePriceController.text.trim());

    Navigator.of(context).pop(
      TradeInput(
        exchangeId: _selectedExchangeId,
        symbol: _symbolController.text.trim(),
        direction: _direction,
        role: _role,
        quantity: quantity,
        leverage: leverage,
        openPrice: openPrice,
        closePrice: closePrice,
        openTimestamp: _openTimestampController.text.trim(),
        closeTimestamp: _closeTimestampController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }
}
