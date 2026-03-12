import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';

class SetTimerDialog extends StatefulWidget {
  const SetTimerDialog({
    super.key,
    required this.initialValue,
    required this.initialUnit,
  });

  final int initialValue;
  final String initialUnit;

  @override
  State<SetTimerDialog> createState() => _SetTimerDialogState();
}

class _SetTimerDialogState extends State<SetTimerDialog> {
  late final TextEditingController timerTextController;
  late String selectedUnit;

  @override
  void initState() {
    super.initState();
    timerTextController = TextEditingController(
      text: widget.initialValue > 0 ? widget.initialValue.toString() : '',
    );
    selectedUnit = widget.initialUnit;
  }

  @override
  void dispose() {
    timerTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _unitButton('second', AppStrings.second.tr)),
              const SizedBox(width: 8),
              Expanded(child: _unitButton('minute', AppStrings.minute.tr)),
              const SizedBox(width: 8),
              Expanded(child: _unitButton('hour', AppStrings.hour.tr)),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextFormField(
            label: AppStrings.timer.tr,
            hintText: AppStrings.exampleFive.tr,
            controller: timerTextController,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(AppStrings.cancel.tr),
              ),
              TextButton(
                onPressed:
                    () => Get.back(result: {'value': 0, 'unit': 'minute'}),
                child: Text(AppStrings.remove.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = int.tryParse(timerTextController.text.trim());
                  if (value == null) return;
                  Get.back(result: {'value': value, 'unit': selectedUnit});
                },
                child: Text(AppStrings.confirm.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitButton(String unit, String label) {
    final selected = selectedUnit == unit;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          selectedUnit = unit;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Get.theme.colorScheme.primary : null,
        foregroundColor:
            selected ? Colors.white : Get.theme.colorScheme.onSurface,
      ),
      child: Text(label),
    );
  }
}
