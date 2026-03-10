# iCloud Usage Guide

이 폴더는 "로컬 SQLite + iCloud 동기화" 구조를 다른 프로젝트에서도 재사용할 수 있게 정리한 공용 코드입니다.

## 구성

- `icloud_sync_settings_service.dart`
  - iCloud ON/OFF 설정 저장
- `icloud_sync_migration_service.dart`
  - local <-> iCloud 병합, 삭제 이벤트, 파일 정리
- `icloud_sync_service.dart`
  - 화면/컨트롤러에서 바로 쓰는 facade
- `icloud_usage_example.dart`
  - 실제 사용 예제

## 기본 흐름

1. 앱은 항상 로컬 SQLite를 읽고 쓴다.
2. iCloud는 직접 여는 DB가 아니라 동기화용 저장소다.
3. 화면 진입 시 `pullIfEnabled()`
4. 저장 후 `pushPullIfEnabled()`
5. 삭제는 merge만으로 부족할 수 있으니 전용 delete 흐름을 둔다.

## 최소 사용 예

```dart
final ICloudSyncService sync = ICloudSyncService();

Future<void> load() async {
  await sync.pullIfEnabled();
  await repository.fetchItems();
}

Future<void> save() async {
  await repository.saveItem(item);
  await sync.pushPullIfEnabled();
}
```

## RefreshIndicator

공통 새로고침 위젯은 `AppRefreshIndicator`를 사용합니다.

```dart
AppRefreshIndicator(
  onRefresh: controller.load,
  child: ListView(...),
)
```
