import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  DatabaseService._internal()
    : _databaseFactory = kIsWeb ? databaseFactoryFfiWeb : databaseFactoryFfi {
    if (!kIsWeb) {
      sqfliteFfiInit();
    }
  }

  static final DatabaseService instance = DatabaseService._internal();

  final DatabaseFactory _databaseFactory;
  Database? _database;

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }
    final path = await _resolveDatabasePath();
    _database = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE exchanges (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              maker_fee_rate REAL NOT NULL,
              taker_fee_rate REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE trades (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              exchange_id INTEGER NOT NULL,
              symbol TEXT NOT NULL,
              direction TEXT NOT NULL CHECK(direction IN ('LONG', 'SHORT')),
              role TEXT NOT NULL CHECK(role IN ('MAKER', 'TAKER')),
              quantity REAL NOT NULL,
              leverage INTEGER NOT NULL,
              open_price REAL NOT NULL,
              close_price REAL NOT NULL,
              initial_margin REAL NOT NULL,
              fee REAL NOT NULL,
              pnl REAL NOT NULL,
              open_timestamp TEXT NOT NULL,
              close_timestamp TEXT NOT NULL,
              notes TEXT,
              FOREIGN KEY(exchange_id) REFERENCES exchanges(id) ON DELETE CASCADE
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_trades_exchange_id ON trades(exchange_id)',
          );
          await _seedInitialData(db);
        },
      ),
    );
  }

  Future<Database> get database async {
    if (_database == null) {
      await initialize();
    }
    return _database!;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<String> _resolveDatabasePath() async {
    if (kIsWeb) {
      return 'crypto_trade_tracker.db';
    }
    final basePath = await _databaseFactory.getDatabasesPath();
    return p.join(basePath, 'crypto_trade_tracker.db');
  }

  Future<void> _seedInitialData(Database db) async {
    final exchanges = <Map<String, Object?>>[
      {
        'name': 'Binance Futures',
        'maker_fee_rate': 0.0002,
        'taker_fee_rate': 0.0004,
      },
      {
        'name': 'OKX Futures',
        'maker_fee_rate': 0.0002,
        'taker_fee_rate': 0.0005,
      },
      {
        'name': 'Bybit USDT Perpetual',
        'maker_fee_rate': 0.0003,
        'taker_fee_rate': 0.00055,
      },
    ];

    final exchangeIds = <String, int>{};
    for (final exchange in exchanges) {
      final id = await db.insert('exchanges', exchange);
      exchangeIds[exchange['name'] as String] = id;
    }

    final trades = <Map<String, Object?>>[
      {
        'exchange_name': 'Binance Futures',
        'symbol': 'BTCUSDT',
        'direction': 'LONG',
        'role': 'TAKER',
        'quantity': 0.5,
        'leverage': 10,
        'open_price': 42000.0,
        'close_price': 43500.0,
        'initial_margin': 2100.0,
        'fee': 8.4,
        'pnl': 741.6,
        'open_timestamp': '2024-02-15T08:30:00Z',
        'close_timestamp': '2024-02-16T12:45:00Z',
        'notes': 'Rebound breakout test trade',
      },
      {
        'exchange_name': 'OKX Futures',
        'symbol': 'ETHUSDT',
        'direction': 'SHORT',
        'role': 'MAKER',
        'quantity': 5.0,
        'leverage': 5,
        'open_price': 2500.0,
        'close_price': 2350.0,
        'initial_margin': 2500.0,
        'fee': 2.5,
        'pnl': 747.5,
        'open_timestamp': '2024-03-01T02:15:00Z',
        'close_timestamp': '2024-03-02T09:20:00Z',
        'notes': 'Shorted local top during news fade',
      },
      {
        'exchange_name': 'Bybit USDT Perpetual',
        'symbol': 'LTCUSDT',
        'direction': 'LONG',
        'role': 'TAKER',
        'quantity': 80.0,
        'leverage': 4,
        'open_price': 150.0,
        'close_price': 163.0,
        'initial_margin': 3000.0,
        'fee': 6.6,
        'pnl': 1033.4,
        'open_timestamp': '2024-03-10T13:00:00Z',
        'close_timestamp': '2024-03-10T22:30:00Z',
        'notes': 'Breakout retest continuation',
      },
    ];

    for (final trade in trades) {
      final data = Map<String, Object?>.from(trade);
      final exchangeName = data.remove('exchange_name') as String;
      final exchangeId = exchangeIds[exchangeName];
      if (exchangeId == null) {
        continue;
      }
      data['exchange_id'] = exchangeId;
      await db.insert('trades', data);
    }
  }
}
