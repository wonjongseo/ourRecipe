import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AppDataPathService {
  AppDataPathService._();

  /// iOS 네이티브(iCloud 컨테이너 경로 조회)와 통신하는 채널.
  static const MethodChannel _channel = MethodChannel('our_recipe/icloud_path');

  /// 앱 로컬 Documents 경로.
  static Future<String> getLocalDocumentsPath() async {
    final localDocs = await getApplicationDocumentsDirectory();
    return localDocs.path;
  }

  /// 앱 데이터 저장 루트 경로를 반환한다.
  /// - 모든 플랫폼에서 로컬 Documents 경로를 사용한다.
  /// - 즉, 앱은 항상 "내 기기 로컬 DB"를 먼저 읽고 쓴다.
  /// - iCloud 안의 DB 파일은 다른 기기와 데이터를 맞추기 위한 복사/병합 대상이다.
  ///
  /// 왜 이렇게 하냐면, SQLite 파일을 여러 기기가 동시에 직접 열어버리면
  /// 파일 잠금, 쓰기 타이밍 차이, WAL 보조 파일 누락 같은 문제가 쉽게 생긴다.
  /// 그래서 "실사용 DB는 로컬", "iCloud는 동기화용 저장소"로 분리했다.
  static Future<String> getAppDataDirectoryPath() async {
    final localDocs = Directory(await getLocalDocumentsPath());
    return localDocs.path;
  }

  /// 토글 상태와 관계없이 iCloud Documents 경로를 조회한다.
  /// migration/진단 용도로 사용.
  static Future<String?> getICloudDirectoryPathIfAvailable() async {
    if (!Platform.isIOS) return null;
    try {
      return await _resolveICloudDocumentsPath();
    } on PlatformException {
      return null;
    }
  }

  static Future<String?> _resolveICloudDocumentsPath() async {
    return _channel.invokeMethod<String>('getICloudDocumentsPath');
  }

  /// iOS iCloud 상태(token/container) 진단 정보를 반환한다.
  static Future<Map<String, dynamic>?> getICloudStatus() async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMapMethod<String, dynamic>('getICloudStatus');
    } on PlatformException {
      return null;
    }
  }
}
