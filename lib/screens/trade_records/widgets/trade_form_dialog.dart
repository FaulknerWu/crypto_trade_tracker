import 'package:flutter/material.dart';

import '../../../models/exchange.dart';
import '../../../models/trade.dart';
import '../../../utils/string_utils.dart';

const _formFieldGap = SizedBox(height: 12);

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
  final _openTimestampController = TextEditingController(
    text: DateTime.now().toIso8601String(),
  );
  final _closeTimestampController = TextEditingController(
    text: DateTime.now().toIso8601String(),
  );
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedExchangeId = widget.exchanges.first.id!;
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
      title: const Text('新增交易'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdownField<int>(
                  label: '交易所',
                  value: _selectedExchangeId,
                  items: widget.exchanges
                      .map(
                        (exchange) => DropdownMenuItem(
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
                  label: '交易对',
                  validator: _requiredValidator,
                ),
                _formFieldGap,
                _buildDualFieldRow(
                  _buildDropdownField<String>(
                    label: '方向',
                    value: _direction,
                    items: const [
                      DropdownMenuItem(value: 'LONG', child: Text('多头')),
                      DropdownMenuItem(value: 'SHORT', child: Text('空头')),
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
                    items: const [
                      DropdownMenuItem(value: 'MAKER', child: Text('挂单')),
                      DropdownMenuItem(value: 'TAKER', child: Text('吃单')),
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
                _buildDualFieldRow(
                  _buildIsoField(
                    controller: _openTimestampController,
                    label: '开仓时间 (ISO 8601)',
                  ),
                  _buildIsoField(
                    controller: _closeTimestampController,
                    label: '平仓时间 (ISO 8601)',
                  ),
                ),
                _formFieldGap,
                _buildFormTextField(
                  controller: _notesController,
                  label: '备注',
                  maxLines: 3,
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
    final quantity = double.parse(_valueOf(_quantityController));
    final leverage = int.parse(_valueOf(_leverageController));
    final openPrice = double.parse(_valueOf(_openPriceController));
    final closePrice = double.parse(_valueOf(_closePriceController));

    Navigator.of(context).pop(
      TradeInput(
        exchangeId: _selectedExchangeId,
        symbol: _valueOf(_symbolController),
        direction: _direction,
        role: _role,
        quantity: quantity,
        leverage: leverage,
        openPrice: openPrice,
        closePrice: closePrice,
        openTimestamp: _valueOf(_openTimestampController),
        closeTimestamp: _valueOf(_closeTimestampController),
        notes: trimToNull(_notesController.text),
      ),
    );
  }

  String _valueOf(TextEditingController controller) => controller.text.trim();
}
