# iCloud Usage Guide

이 폴더는 `로컬 SQLite + CloudKit 동기화` 구조를 다른 프로젝트에서도 재사용할 수 있게 정리한 공용 코드입니다.

## 구성

- `app_data_path_service.dart`
  - 로컬 Documents 경로 / CloudKit 상태 조회
- `icloud_sync_settings_service.dart`
  - iCloud 공유 ON/OFF 설정 저장
- `icloud_sync_service.dart`
  - 로컬 SQLite <-> CloudKit 스냅샷 동기화 facade
- `icloud.dart`
  - 공용 export 파일
- `icloud_usage_example.dart`
  - 실제 사용 예제

## 구조

1. 앱은 항상 로컬 SQLite와 로컬 이미지 파일만 읽고 쓴다.
2. iCloud 공유가 ON이면 현재 로컬 상태 전체를 CloudKit에 업로드한다.
3. 다른 기기는 CloudKit 스냅샷을 내려받아 자기 로컬 SQLite와 이미지 폴더에 반영한다.
4. 화면과 Repository는 끝까지 로컬 SQLite만 사용한다.

즉:
- `local SQLite` = 실제 앱 런타임 저장소
- `CloudKit` = 기기 간 공유 백엔드

## 사용 흐름

1. 화면 진입 시 `pullIfEnabled()`
2. 로컬 DB 저장
3. 저장 직후 `schedulePushIfEnabled()` 또는 `pushIfEnabled()`
4. 새로고침 시 다시 `pullIfEnabled()`

## 최소 사용 예

```dart
import 'package:my_app/core/services/icloud/icloud.dart';

final ICloudSyncService sync = ICloudSyncService();

Future<void> load() async {
  await sync.pullIfEnabled();
  await repository.fetchItems();
}

Future<void> save() async {
  await repository.saveItem(item);
  sync.schedulePushIfEnabled();
}
```

## 사진 공유

- 스냅샷 JSON과 별도로 이미지 파일도 CloudKit에 업로드한다.
- 다운로드 시 로컬 이미지 폴더를 CloudKit 기준으로 다시 맞춘다.

## RefreshIndicator

공통 새로고침 위젯은 `AppRefreshIndicator`를 사용합니다.

```dart
AppRefreshIndicator(
  onRefresh: controller.load,
  child: ListView(...),
)
```
