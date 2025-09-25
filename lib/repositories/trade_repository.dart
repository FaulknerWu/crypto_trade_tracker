import '../models/exchange.dart';
import '../models/trade.dart';
import '../services/database_service.dart';
import 'exchange_repository.dart';

class TradeRepository {
  TradeRepository({
    DatabaseService? databaseService,
    ExchangeRepository? exchangeRepository,
  }) : _databaseService = databaseService ?? DatabaseService.instance,
       _exchangeRepository =
           exchangeRepository ??
           ExchangeRepository(databaseService: databaseService);

  final DatabaseService _databaseService;
  final ExchangeRepository _exchangeRepository;

  Future<int> createTrade(TradeInput input) async {
    final trade = await _buildTradeFromInput(input);
    final db = await _databaseService.database;
    final data = trade.toMap()..remove('id');
    return db.insert('trades', data);
  }

  Future<int> updateTrade(int id, TradeInput input) async {
    final trade = await _buildTradeFromInput(input, id: id);
    final db = await _databaseService.database;
    final data = trade.toMap()..remove('id');
    return db.update('trades', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTrade(int id) async {
    final db = await _databaseService.database;
    return db.delete('trades', where: 'id = ?', whereArgs: [id]);
  }

  Future<Trade?> getTradeById(int id) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'trades',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Trade.fromMap(rows.first);
  }

  Future<List<Trade>> getAllTrades() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'trades',
      orderBy: 'close_timestamp DESC, id DESC',
    );
    return rows.map(Trade.fromMap).toList();
  }

  Future<double> getTotalPnl() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(pnl) AS total_pnl FROM trades',
    );
    final value = result.first['total_pnl'] as num?;
    return value?.toDouble() ?? 0;
  }

  Future<Map<int, double>> getTotalPnlByExchange() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT exchange_id, SUM(pnl) AS total_pnl FROM trades GROUP BY exchange_id',
    );
    return {
      for (final row in result)
        row['exchange_id'] as int: (row['total_pnl'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<Trade> _buildTradeFromInput(TradeInput input, {int? id}) async {
    if (input.leverage <= 0) {
      throw ArgumentError('Leverage must be greater than zero');
    }
    if (input.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero');
    }
    if (input.openPrice <= 0 || input.closePrice <= 0) {
      throw ArgumentError('Prices must be greater than zero');
    }

    final exchange = await _requireExchange(input.exchangeId);
    final direction = input.direction.trim().toUpperCase();
    const allowedDirections = {'LONG', 'SHORT'};
    if (!allowedDirections.contains(direction)) {
      throw ArgumentError('Direction must be either LONG or SHORT');
    }

    final role = input.role.trim().toUpperCase();
    const allowedRoles = {'MAKER', 'TAKER'};
    if (!allowedRoles.contains(role)) {
      throw ArgumentError('Role must be either MAKER or TAKER');
    }

    final initialMargin = (input.quantity * input.openPrice) / input.leverage;
    final feeRate = role == 'MAKER'
        ? exchange.makerFeeRate
        : exchange.takerFeeRate;
    final fee = input.quantity * input.openPrice * feeRate;

    final priceDiff = direction == 'LONG'
        ? input.closePrice - input.openPrice
        : input.openPrice - input.closePrice;
    final pnl = priceDiff * input.quantity - fee;

    final openTimestamp = _validateIso8601Timestamp(
      input.openTimestamp,
      fieldName: 'openTimestamp',
    );
    final closeTimestamp = _validateIso8601Timestamp(
      input.closeTimestamp,
      fieldName: 'closeTimestamp',
    );
    final trimmedNotes = input.notes?.trim();
    return Trade(
      id: id,
      exchangeId: input.exchangeId,
      symbol: input.symbol.trim(),
      direction: direction,
      role: role,
      quantity: input.quantity,
      leverage: input.leverage,
      openPrice: input.openPrice,
      closePrice: input.closePrice,
      initialMargin: initialMargin,
      fee: fee,
      pnl: pnl,
      openTimestamp: openTimestamp,
      closeTimestamp: closeTimestamp,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty)
          ? null
          : trimmedNotes,
    );
  }

  Future<Exchange> _requireExchange(int exchangeId) async {
    final exchange = await _exchangeRepository.getExchangeById(exchangeId);
    if (exchange == null) {
      throw ArgumentError('Exchange with id $exchangeId not found');
    }
    return exchange;
  }

  String _validateIso8601Timestamp(String raw, {required String fieldName}) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw ArgumentError('$fieldName cannot be empty');
    }
    try {
      DateTime.parse(value);
      return value;
    } on FormatException {
      throw ArgumentError(
        '$fieldName must be a valid ISO 8601 date or date-time string',
      );
    }
  }
}
