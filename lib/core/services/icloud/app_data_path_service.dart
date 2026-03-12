import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppDataPathService {
  AppDataPathService._();

  /// iOS 네이티브(CloudKit 상태 조회)와 통신하는 채널.
  static const MethodChannel _channel = MethodChannel('our_recipe/icloud_path');

  /// 앱 로컬 Documents 경로.
  static Future<String> getLocalDocumentsPath() async {
    final localDocs = await getApplicationDocumentsDirectory();
    return localDocs.path;
  }

  /// 앱은 항상 이 경로의 로컬 SQLite와 로컬 이미지 파일만 직접 읽고 쓴다.
  ///
  /// iCloud 공유가 ON이어도 앱이 CloudKit 안의 데이터를 직접 읽는 구조는 아니다.
  /// CloudKit에서 내려받은 스냅샷을 다시 이 로컬 경로에 반영한 뒤,
  /// 화면/Repository는 평소처럼 로컬 SQLite만 사용한다.
  static Future<String> getAppDataDirectoryPath() async {
    final localDocs = Directory(await getLocalDocumentsPath());
    return localDocs.path;
  }

  /// 레시피 이미지 전용 로컬 폴더 경로.
  static Future<String> getRecipeImagesDirectoryPath() async {
    final localDocs = Directory(await getLocalDocumentsPath());
    final imageDir = Directory('${localDocs.path}/recipe_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir.path;
  }

  /// iOS CloudKit 사용 가능 여부를 반환한다.
  static Future<Map<String, dynamic>?> getICloudStatus() async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMapMethod<String, dynamic>('getICloudStatus');
    } on PlatformException {
      return null;
    }
  }
}
