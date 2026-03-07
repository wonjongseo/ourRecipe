/// 레시피 조리 단계 모델.

class CookingStepModel {
  /// 단계 고유 ID.
  final String id;

  /// 단계 순서(1, 2, 3...).
  final int order;

  /// 조리 지시 문구.
  final String instruction;

  /// 단계 타이머(초). 없으면 null.
  final int? timerSec;

  /// 단계 이미지 경로(없을 수 있음).
  final String? imagePath;

  const CookingStepModel({
    required this.id,
    required this.order,
    required this.instruction,
    this.timerSec,
    this.imagePath,
  });

  CookingStepModel copyWith({
    String? id,
    int? order,
    String? instruction,
    int? timerSec,
    String? imagePath,
  }) {
    return CookingStepModel(
      id: id ?? this.id,
      order: order ?? this.order,
      instruction: instruction ?? this.instruction,
      timerSec: timerSec ?? this.timerSec,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'instruction': instruction,
      'timerSec': timerSec,
      'imagePath': imagePath,
    };
  }

  factory CookingStepModel.fromJson(Map<String, dynamic> json) {
    return CookingStepModel(
      id: json['id'] as String,
      order: json['order'] as int,
      instruction: json['instruction'] as String,
      timerSec: json['timerSec'] as int?,
      imagePath: json['imagePath'] as String?,
    );
  }
}
