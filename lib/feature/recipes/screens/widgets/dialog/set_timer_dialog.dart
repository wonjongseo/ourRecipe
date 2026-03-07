import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';

class SetTimerDialog extends StatelessWidget {
  const SetTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final timerTextController = TextEditingController();
    return AlertDialog(
      contentPadding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextFormField(
            label: AppStrings.timeMinute.tr,
            hintText: AppStrings.exampleFive.tr,
            controller: timerTextController,
            suffixText: AppStrings.minute.tr,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(AppStrings.cancel.tr),
              ),
              TextButton(
                onPressed: () => Get.back(result: '0'),
                child: Text(AppStrings.remove.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back(result: timerTextController.text);
                },
                child: Text(AppStrings.confirm.tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
