import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../models/exchange.dart';
import '../../../models/trade.dart';

class TradeTable extends StatelessWidget {
  const TradeTable({
    super.key,
    required this.trades,
    required this.exchangeById,
  });

  final List<Trade> trades;
  final Map<int, Exchange> exchangeById;

  @override
  Widget build(BuildContext context) {
    final columns = _buildTradeColumns();
    final rows = _buildTradeRows(trades);
    return PlutoGrid(
      columns: columns,
      rows: rows,
      configuration: PlutoGridConfiguration(
        style: _buildStyle(),
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
    );
  }

  PlutoGridStyleConfig _buildStyle() {
    return PlutoGridStyleConfig(
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
  }

  List<PlutoColumn> _buildTradeColumns() {
    return _tradeColumnConfigs.map(_buildTradeColumn).toList();
  }

  PlutoColumn _buildTradeColumn(_TradeColumnConfig config) {
    final renderer = _columnRendererFor(config.rendererType);
    switch (config.type) {
      case _TradeColumnType.text:
        return _buildTextColumn(
          title: config.title,
          field: config.field,
          widthIndex: config.widthIndex,
          textAlign: config.textAlign,
          minWidth: config.minWidth ?? 0,
          renderer: renderer,
        );
      case _TradeColumnType.number:
        return _buildNumberColumn(
          title: config.title,
          field: config.field,
          widthIndex: config.widthIndex,
          format: config.format!,
          textAlign: config.textAlign,
          minWidth: config.minWidth ?? 0,
          renderer: renderer,
        );
    }
  }

  PlutoColumnRenderer? _columnRendererFor(
    _TradeColumnRendererType rendererType,
  ) {
    switch (rendererType) {
      case _TradeColumnRendererType.none:
        return null;
      case _TradeColumnRendererType.pnl:
        return (context) {
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
        };
      case _TradeColumnRendererType.notes:
        return (context) {
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
        };
    }
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
    PlutoColumnTextAlign textAlign = PlutoColumnTextAlign.right,
    double minWidth = 0,
    PlutoColumnRenderer? renderer,
  }) {
    return _buildColumn(
      title: title,
      field: field,
      type: PlutoColumnType.number(format: format),
      width: _columnWidth(widthIndex),
      textAlign: textAlign,
      minWidth: minWidth,
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

  List<PlutoRow> _buildTradeRows(List<Trade> trades) {
    return trades.map((trade) {
      final exchangeName =
          exchangeById[trade.exchangeId]?.name ?? '交易所 ${trade.exchangeId}';
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

  double _columnWidth(int index) => _tradeTableColumnWidths[index];

  String _formatNumber(double value) => value.toStringAsFixed(2);

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    final local = parsed.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

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

enum _TradeColumnType { text, number }

enum _TradeColumnRendererType { none, pnl, notes }

class _TradeColumnConfig {
  const _TradeColumnConfig.text({
    required this.title,
    required this.field,
    required this.widthIndex,
    this.textAlign = PlutoColumnTextAlign.start,
    this.minWidth,
    this.rendererType = _TradeColumnRendererType.none,
  }) : type = _TradeColumnType.text,
       format = null;

  const _TradeColumnConfig.number({
    required this.title,
    required this.field,
    required this.widthIndex,
    required this.format,
    this.rendererType = _TradeColumnRendererType.none,
  }) : type = _TradeColumnType.number,
       textAlign = PlutoColumnTextAlign.right,
       minWidth = null;

  final _TradeColumnType type;
  final String title;
  final String field;
  final int widthIndex;
  final String? format;
  final PlutoColumnTextAlign textAlign;
  final double? minWidth;
  final _TradeColumnRendererType rendererType;
}

const _tradeColumnConfigs = <_TradeColumnConfig>[
  _TradeColumnConfig.text(
    title: '交易所',
    field: 'exchange',
    widthIndex: 0,
    minWidth: 120,
  ),
  _TradeColumnConfig.text(title: '交易对', field: 'symbol', widthIndex: 1),
  _TradeColumnConfig.text(
    title: '方向',
    field: 'direction',
    widthIndex: 2,
    textAlign: PlutoColumnTextAlign.center,
  ),
  _TradeColumnConfig.text(
    title: '角色',
    field: 'role',
    widthIndex: 3,
    textAlign: PlutoColumnTextAlign.center,
  ),
  _TradeColumnConfig.number(
    title: '数量',
    field: 'quantity',
    widthIndex: 4,
    format: '#,##0.00',
  ),
  _TradeColumnConfig.number(
    title: '杠杆',
    field: 'leverage',
    widthIndex: 5,
    format: '#,##0',
  ),
  _TradeColumnConfig.number(
    title: '开仓价',
    field: 'openPrice',
    widthIndex: 6,
    format: '#,##0.00',
  ),
  _TradeColumnConfig.number(
    title: '平仓价',
    field: 'closePrice',
    widthIndex: 7,
    format: '#,##0.00',
  ),
  _TradeColumnConfig.number(
    title: '起始保证金',
    field: 'initialMargin',
    widthIndex: 8,
    format: '#,##0.00',
  ),
  _TradeColumnConfig.number(
    title: '手续费',
    field: 'fee',
    widthIndex: 9,
    format: '#,##0.00',
  ),
  _TradeColumnConfig.number(
    title: '净盈亏',
    field: 'pnl',
    widthIndex: 10,
    format: '#,##0.00',
    rendererType: _TradeColumnRendererType.pnl,
  ),
  _TradeColumnConfig.text(title: '开仓时间', field: 'openTime', widthIndex: 11),
  _TradeColumnConfig.text(title: '平仓时间', field: 'closeTime', widthIndex: 12),
  _TradeColumnConfig.text(
    title: '备注',
    field: 'notes',
    widthIndex: 13,
    minWidth: 160,
    rendererType: _TradeColumnRendererType.notes,
  ),
];
