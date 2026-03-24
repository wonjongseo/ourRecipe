import 'package:flutter/material.dart';
import 'package:our_recipe/core/common/app_scale.dart';

class CustomBottomButton extends StatelessWidget {
  const CustomBottomButton({
    super.key,
    this.onPressed,
    required this.label,
    this.icon,
  });
  final String label;
  final IconData? icon;
  final Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: SizedBox(
          width: double.infinity,
          height: AppScale.size(50),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon == null ? null : Icon(icon),
            label: Text(label),
            iconAlignment: IconAlignment.end,
          ),
        ),
      ),
    );
  }
}
