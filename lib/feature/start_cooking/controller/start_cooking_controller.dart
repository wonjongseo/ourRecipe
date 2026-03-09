import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/models/recipe_step_model.dart';

class StartCookingController extends GetxController {
  final RecipeModel recipeModel;
  StartCookingController(this.recipeModel);

  final pageController = PageController();
  final currentIndex = 0.obs;
  final remainingSec = RxnInt();
  final isTimerRunning = false.obs;

  Timer? _timer;

  List<CookingStepModel> get steps => recipeModel.steps;
  int get totalSteps => steps.length;
  CookingStepModel? get currentStepOrNull {
    if (steps.isEmpty) return null;
    final idx = currentIndex.value.clamp(0, steps.length - 1);
    return steps[idx];
  }

  CookingStepModel get currentStep => currentStepOrNull!;
  bool get canGoPrev => currentIndex.value > 0;
  bool get canGoNext => currentIndex.value < totalSteps - 1;
  bool get hasTimerOnCurrentStep => (currentStepOrNull?.timerSec ?? 0) > 0;

  String get remainingMinuteText {
    final sec = remainingSec.value;
    if (sec == null) return '--';
    final minute = (sec / 60).ceil();
    return '$minute';
  }

  String get remainingClockText {
    final sec = remainingSec.value;
    if (sec == null) return '--:--';
    final mm = (sec ~/ 60).toString().padLeft(2, '0');
    final ss = (sec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void onInit() {
    super.onInit();
    if (steps.isEmpty) return;
    _resetTimerForCurrentStep();
  }

  @override
  void onClose() {
    _timer?.cancel();
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    if (steps.isEmpty) return;
    if (index == currentIndex.value) return;
    currentIndex.value = index;
    _resetTimerForCurrentStep();
  }

  void onTapPrev() {
    if (steps.isEmpty) return;
    if (!canGoPrev) return;
    pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
    );
  }

  void onTapNext() {
    if (steps.isEmpty) return;
    if (!canGoNext) return;
    pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
    );
  }

  void onTapTimer() {
    if (steps.isEmpty) return;
    if (!hasTimerOnCurrentStep) return;
    if (isTimerRunning.value) {
      _stopTimer();
      return;
    }
    final current = remainingSec.value ?? (currentStep.timerSec! * 60);
    if (current <= 0) {
      _resetTimerForCurrentStep();
    }
    _startTimer();
  }

  void _resetTimerForCurrentStep() {
    _stopTimer();
    if (steps.isEmpty) {
      remainingSec.value = null;
      return;
    }
    remainingSec.value =
        hasTimerOnCurrentStep ? (currentStep.timerSec! * 60) : null;
  }

  void _startTimer() {
    if (!hasTimerOnCurrentStep) return;
    if ((remainingSec.value ?? 0) <= 0) {
      remainingSec.value = currentStep.timerSec! * 60;
    }
    isTimerRunning.value = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = remainingSec.value;
      if (now == null) {
        _stopTimer();
        return;
      }
      if (now <= 1) {
        remainingSec.value = 0;
        _stopTimer();
        _notifyTimerFinished();
        return;
      }
      remainingSec.value = now - 1;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    isTimerRunning.value = false;
  }

  void _notifyTimerFinished() {
    SystemSound.play(SystemSoundType.alert);
  }
}
