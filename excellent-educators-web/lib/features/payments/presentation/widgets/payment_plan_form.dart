import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/settings/data/dto/app_settings_dto.dart';
import 'package:excellent_educators_web/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a reference to [PaymentPlanFormFieldsState] without a [GlobalKey].
///
/// Avoids relocating keyed elements in the tree (which triggers Flutter's
/// `_dependents.isEmpty` assertion when siblings are inserted above the form).
class PaymentPlanFormController {
  PaymentPlanFormFieldsState? _state;

  Map<String, dynamic>? toPayload() => _state?.toPayload();
}

/// Shared payment plan fields for student create / plan setup.
///
/// [lockedTotalAmount] is used when editing an existing student plan so a later
/// Admin Settings change does not overwrite that student's locked total.
class PaymentPlanFormFields extends ConsumerStatefulWidget {
  const PaymentPlanFormFields({
    super.key,
    this.controller,
    this.initialType,
    this.initialMode,
    this.lockedTotalAmount,
    this.enabled = true,
  });

  final PaymentPlanFormController? controller;
  final String? initialType;
  final String? initialMode;
  final double? lockedTotalAmount;
  final bool enabled;

  @override
  ConsumerState<PaymentPlanFormFields> createState() =>
      PaymentPlanFormFieldsState();
}

class PaymentPlanFormFieldsState extends ConsumerState<PaymentPlanFormFields> {
  String? _paymentType;
  String? _paymentMode;
  late final TextEditingController _total;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  var _defaultsApplied = false;
  double _settingsFull = 6000;
  double _settingsPartial = 6500;

  bool get _hasLockedTotal =>
      widget.lockedTotalAmount != null && widget.lockedTotalAmount! > 0;

  double get _effectiveFullTotal =>
      _hasLockedTotal ? widget.lockedTotalAmount! : _settingsFull;

  double get _effectivePartialTotal =>
      _hasLockedTotal ? widget.lockedTotalAmount! : _settingsPartial;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _paymentType = widget.initialType;
    _paymentMode = widget.initialMode ?? 'offline';
    _total = TextEditingController(
      text: widget.lockedTotalAmount != null
          ? widget.lockedTotalAmount!.round().toString()
          : '',
    );
    _amount = TextEditingController(
      text: widget.initialType == 'full' && widget.lockedTotalAmount != null
          ? widget.lockedTotalAmount!.round().toString()
          : widget.lockedTotalAmount != null
              ? '0'
              : '',
    );
    _notes = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant PaymentPlanFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller!._state = null;
      }
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller!._state = null;
    }
    _total.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _applySettingsDefaults(double full, double partial) {
    _settingsFull = full;
    _settingsPartial = partial;
    if (_defaultsApplied) {
      return;
    }
    _defaultsApplied = true;

    if (_paymentType == 'full') {
      _total.text = _effectiveFullTotal.round().toString();
      _amount.text = _effectiveFullTotal.round().toString();
    } else if (_paymentType == 'partial') {
      _total.text = _effectivePartialTotal.round().toString();
      if (_hasLockedTotal) {
        _amount.text = '0';
      }
    }
  }

  void _maybeApplySettings(AppSettingsDto data) {
    if (_defaultsApplied) {
      return;
    }
    _applySettingsDefaults(
      _readAmount(data.items, 'payment_full_amount', 6000),
      _readAmount(data.items, 'payment_partial_total', 6500),
    );
  }

  Map<String, dynamic>? toPayload() {
    if (_paymentType == null) {
      return null;
    }

    if (_paymentType == 'full') {
      final total = _effectiveFullTotal;
      return {
        'payment_type': 'full',
        'preferred_mode': _paymentMode,
        'total_amount': total,
        if (!_hasLockedTotal) 'payment_amount': total,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      };
    }

    final total = _effectivePartialTotal;
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    return {
      'payment_type': 'partial',
      'preferred_mode': _paymentMode,
      'total_amount': total,
      if (!_hasLockedTotal) 'initial_amount': amount,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };
  }

  double _readAmount(
    List<AppSettingItemDto> items,
    String key,
    double fallback,
  ) {
    for (final item in items) {
      if (item.key == key) {
        final v = item.value;
        if (v is num) {
          return v.toDouble();
        }
        return double.tryParse('$v') ?? fallback;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(adminSettingsProvider);

    ref.listen(adminSettingsProvider, (previous, next) {
      next.whenData((data) {
        if (!mounted || _defaultsApplied) {
          return;
        }
        setState(() => _maybeApplySettings(data));
      });
    });

    final paid = double.tryParse(_amount.text.trim()) ?? 0;
    final settingsLoading = settings.isLoading && !settings.hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.paymentDetails,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Brand.navy,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          AppStrings.paymentPlanAndModeHelp,
          style: TextStyle(color: Brand.muted, height: 1.4),
        ),
        if (settingsLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 2),
        ],
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _paymentType,
          decoration: const InputDecoration(
            labelText: AppStrings.paymentPlan,
          ),
          items: const [
            DropdownMenuItem(
              value: 'full',
              child: Text(AppStrings.fullPayment),
            ),
            DropdownMenuItem(
              value: 'partial',
              child: Text(AppStrings.partialPayment),
            ),
          ],
          onChanged: widget.enabled
              ? (value) {
                  final data = settings.asData?.value;
                  if (data != null) {
                    _maybeApplySettings(data);
                  }
                  setState(() {
                    _paymentType = value;
                    if (value == 'full') {
                      _total.text = _effectiveFullTotal.round().toString();
                      _amount.text = _effectiveFullTotal.round().toString();
                    } else if (value == 'partial') {
                      _total.text = _effectivePartialTotal.round().toString();
                      _amount.text = _hasLockedTotal ? '0' : '';
                    }
                  });
                }
              : null,
        ),
        if (_paymentType != null) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(
              labelText: AppStrings.paymentMode,
            ),
            items: const [
              DropdownMenuItem(
                value: 'online',
                child: Text(AppStrings.online),
              ),
              DropdownMenuItem(
                value: 'offline',
                child: Text(AppStrings.offline),
              ),
            ],
            onChanged: widget.enabled
                ? (value) => setState(() => _paymentMode = value)
                : null,
          ),
          if (_paymentType == 'full') ...[
            const SizedBox(height: 12),
            Text(
              '${AppStrings.totalAmount}: ₹${_effectiveFullTotal.round()}',
              style: const TextStyle(
                color: Brand.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_paymentType == 'partial') ...[
            const SizedBox(height: 12),
            Text(
              '${AppStrings.totalPayableAmount}: ₹${_effectivePartialTotal.round()}',
              style: const TextStyle(
                color: Brand.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!_hasLockedTotal) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: AppStrings.initialPaymentAmount,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0) {
                    return AppStrings.enterAValidAmount;
                  }
                  final max = _effectivePartialTotal;
                  if (parsed > max && max > 0) {
                    return AppStrings.amountCannotExceedTotal;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              if (_effectivePartialTotal > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${AppStrings.paidAmount}: ₹${paid.round()}  ·  ${AppStrings.pendingAmount}: ₹${(_effectivePartialTotal - paid).clamp(0, double.infinity).round()}',
                  style: const TextStyle(
                    color: Brand.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            enabled: widget.enabled,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: AppStrings.notesOptional,
            ),
          ),
        ],
      ],
    );
  }
}
