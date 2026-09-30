import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneWhatsappAddressFields extends StatelessWidget {
  const PhoneWhatsappAddressFields({
    super.key,
    required this.phone,
    required this.whatsapp,
    this.address,
    this.requirePhone = true,
    this.showAddress = true,
    this.phoneLabel = AppStrings.phoneNumber,
    this.whatsappLabel = AppStrings.whatsappNumberOptional,
    this.addressLabel = AppStrings.address,
    this.addressHint,
    this.fieldSpacing = 14,
  });

  final TextEditingController phone;
  final TextEditingController whatsapp;
  final TextEditingController? address;
  final bool requirePhone;
  final bool showAddress;
  final String phoneLabel;
  final String whatsappLabel;
  final String addressLabel;
  final String? addressHint;
  final double fieldSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: phoneLabel,
            prefixText: '+91  ',
          ),
          validator: requirePhone ? validateRequiredPhone : validateOptionalPhone,
        ),
        SizedBox(height: fieldSpacing),
        TextFormField(
          controller: whatsapp,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: whatsappLabel,
            prefixText: '+91  ',
          ),
          validator: validateOptionalPhone,
        ),
        if (showAddress && address != null) ...[
          SizedBox(height: fieldSpacing),
          TextFormField(
            controller: address,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: addressLabel,
              hintText: addressHint,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ],
    );
  }
}
