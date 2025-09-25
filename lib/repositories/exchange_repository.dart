import '../models/exchange.dart';
import '../services/database_service.dart';

class ExchangeRepository {
  ExchangeRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<int> createExchange(Exchange exchange) async {
    final db = await _databaseService.database;
    return db.insert('exchanges', _exchangeDataWithoutId(exchange));
  }

  Future<List<Exchange>> getAllExchanges() async {
    final db = await _databaseService.database;
    final rows = await db.query('exchanges', orderBy: 'name ASC');
    return rows.map(Exchange.fromMap).toList();
  }

  Future<Exchange?> getExchangeById(int id) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'exchanges',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Exchange.fromMap(rows.first);
  }

  Future<int> updateExchange(Exchange exchange) async {
    if (exchange.id == null) {
      throw ArgumentError('Exchange id cannot be null for update');
    }
    final db = await _databaseService.database;
    final data = _exchangeDataWithoutId(exchange);
    return db.update(
      'exchanges',
      data,
      where: 'id = ?',
      whereArgs: [exchange.id],
    );
  }

  Future<int> deleteExchange(int id) async {
    final db = await _databaseService.database;
    return db.delete('exchanges', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _exchangeDataWithoutId(Exchange exchange) {
    final data = exchange.toMap();
    data.remove('id');
    return data;
  }
}
