class Trade {
  Trade({
    this.id,
    required this.exchangeId,
    required this.symbol,
    required this.direction,
    required this.role,
    required this.quantity,
    required this.leverage,
    required this.openPrice,
    required this.closePrice,
    required this.initialMargin,
    required this.fee,
    required this.pnl,
    required this.openTimestamp,
    required this.closeTimestamp,
    this.notes,
  });

  final int? id;
  final int exchangeId;
  final String symbol;
  final String direction;
  final String role;
  final double quantity;
  final int leverage;
  final double openPrice;
  final double closePrice;
  final double initialMargin;
  final double fee;
  final double pnl;
  final String openTimestamp;
  final String closeTimestamp;
  final String? notes;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'exchange_id': exchangeId,
      'symbol': symbol,
      'direction': direction,
      'role': role,
      'quantity': quantity,
      'leverage': leverage,
      'open_price': openPrice,
      'close_price': closePrice,
      'initial_margin': initialMargin,
      'fee': fee,
      'pnl': pnl,
      'open_timestamp': openTimestamp,
      'close_timestamp': closeTimestamp,
      'notes': notes,
    };
  }

  factory Trade.fromMap(Map<String, Object?> map) {
    return Trade(
      id: map['id'] as int?,
      exchangeId: map['exchange_id'] as int,
      symbol: map['symbol'] as String,
      direction: map['direction'] as String,
      role: map['role'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      leverage: map['leverage'] as int,
      openPrice: (map['open_price'] as num).toDouble(),
      closePrice: (map['close_price'] as num).toDouble(),
      initialMargin: (map['initial_margin'] as num).toDouble(),
      fee: (map['fee'] as num).toDouble(),
      pnl: (map['pnl'] as num).toDouble(),
      openTimestamp: map['open_timestamp'] as String,
      closeTimestamp: map['close_timestamp'] as String,
      notes: map['notes'] as String?,
    );
  }
}

class TradeInput {
  TradeInput({
    required this.exchangeId,
    required this.symbol,
    required this.direction,
    required this.role,
    required this.quantity,
    required this.leverage,
    required this.openPrice,
    required this.closePrice,
    required this.openTimestamp,
    required this.closeTimestamp,
    this.notes,
  });

  final int exchangeId;
  final String symbol;
  final String direction;
  final String role;
  final double quantity;
  final int leverage;
  final double openPrice;
  final double closePrice;
  final String openTimestamp;
  final String closeTimestamp;
  final String? notes;
}
