import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/controller/edit_recipe_controller.dart';
import 'package:our_recipe/feature/recipes/screens/widgets/dialog/set_timer_dialog.dart';

class EditableCookingStepListTile extends StatelessWidget {
  const EditableCookingStepListTile({
    super.key,
    required this.inputCookingStep,
    required this.index,
    this.onDelete,
    required this.pickImage,
    required this.cropImage,
    required this.removeImage,
    required this.setTimer,
  });

  final int index;
  final InputCookingStep inputCookingStep;
  final Function(int)? onDelete;
  final Function(int) pickImage;
  final Function(int) cropImage;
  final Function(int) removeImage;
  final Function(int, int, String) setTimer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.10),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.secondartColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showTimerDialog(context, index),
                    icon: Icon(FontAwesomeIcons.clock),
                    label:
                        inputCookingStep.timerValue == 0
                            ? Text(AppStrings.timer.tr)
                            : Text(
                              '${inputCookingStep.timerValue}${_timerUnitLabel(inputCookingStep.timerUnit)}',
                            ),
                  ),
                  IconButton(
                    onPressed: onDelete == null ? null : () => onDelete!(index),
                    icon: Icon(
                      FontAwesomeIcons.circleMinus,
                      size: 20,
                      color: onDelete == null ? Colors.grey : Colors.pinkAccent,
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),
          CustomTextFormField(
            label: AppStrings.description.tr,
            maxLine: 3,
            controller: inputCookingStep.descriptionTeCtrl,
          ),
          SizedBox(height: 24),

          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            child:
                inputCookingStep.image == null
                    ? InkWell(
                      onTap: () => pickImage(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.image),
                            SizedBox(width: 10),
                            Text(AppStrings.addPhoto.tr),
                          ],
                        ),
                      ),
                    )
                    : Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 120,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: FileImage(inputCookingStep.image!),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 44,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => cropImage(index),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.crop_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => removeImage(index),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  FontAwesomeIcons.xmark,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _showTimerDialog(BuildContext context, int index) async {
    final result = await Get.dialog(
      SetTimerDialog(
        initialValue: inputCookingStep.timerValue,
        initialUnit: inputCookingStep.timerUnit,
      ),
    );

    if (result == null) return;
    final value = result['value'] as int?;
    final unit = result['unit'] as String?;
    if (value == null || unit == null) return;
    setTimer(index, value, unit);
  }

  String _timerUnitLabel(String unit) {
    switch (unit) {
      case 'second':
        return AppStrings.second.tr;
      case 'hour':
        return AppStrings.hour.tr;
      case 'minute':
      default:
        return AppStrings.minute.tr;
    }
  }
}
