class Exchange {
  Exchange({
    this.id,
    required this.name,
    required this.makerFeeRate,
    required this.takerFeeRate,
  });

  final int? id;
  final String name;
  final double makerFeeRate;
  final double takerFeeRate;

  Exchange copyWith({
    int? id,
    String? name,
    double? makerFeeRate,
    double? takerFeeRate,
  }) {
    return Exchange(
      id: id ?? this.id,
      name: name ?? this.name,
      makerFeeRate: makerFeeRate ?? this.makerFeeRate,
      takerFeeRate: takerFeeRate ?? this.takerFeeRate,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'maker_fee_rate': makerFeeRate,
      'taker_fee_rate': takerFeeRate,
    };
  }

  factory Exchange.fromMap(Map<String, Object?> map) {
    return Exchange(
      id: map['id'] as int?,
      name: map['name'] as String,
      makerFeeRate: (map['maker_fee_rate'] as num).toDouble(),
      takerFeeRate: (map['taker_fee_rate'] as num).toDouble(),
    );
  }
}
