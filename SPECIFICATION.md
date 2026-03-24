# Our Recipe Specification

## 1. Document Info

- Project name: `our_recipe`
- App name: `우리의 레시피`
- Document type: Product / Functional Specification
- 기준일: 2026-03-19
- 기준 버전: `1.0.0+2026031501`
- Target platforms: iOS, Android

## 2. Product Overview

`our_recipe`는 사용자가 직접 레시피를 등록하고, 재료 가격과 영양 정보를 관리하며, 조리 단계 진행과 장보기 체크까지 할 수 있는 개인 레시피 관리 앱이다.

앱은 다음 목표를 가진다.

- 개인 레시피를 손쉽게 등록, 수정, 삭제할 수 있어야 한다.
- 재료 단가를 기반으로 레시피 총 재료비를 계산할 수 있어야 한다.
- 북마크한 레시피를 장보기 목록으로 활용할 수 있어야 한다.
- 다국어 환경에서 자연스럽게 사용할 수 있어야 한다.
- 프리미엄 구매 시 광고 제거가 가능해야 한다.
- iOS에서는 프리미엄 구매 시 iCloud 동기화를 사용할 수 있어야 한다.

## 3. Target Users

- 직접 요리를 하며 레시피를 기록하고 싶은 사용자
- 재료 구매 비용까지 관리하고 싶은 사용자
- 자주 만드는 레시피를 북마크하고 장보기 체크리스트로 활용하고 싶은 사용자
- 여러 Apple 기기에서 레시피와 사진을 이어서 쓰고 싶은 iOS 사용자

## 4. Supported Platforms and Environment

### 4.1 Platforms

- iOS
- Android

### 4.2 Runtime / Framework

- Flutter
- Dart 3.x

### 4.3 Main Packages

- State management / routing: `get`
- Local DB: `sqflite`
- Preferences: `shared_preferences`
- Image input/editing: `image_picker`, `image_cropper`
- Ads: `google_mobile_ads`
- In-app purchase: `in_app_purchase`, `in_app_purchase_storekit`
- Review: `in_app_review`
- Notifications: `flutter_local_notifications`
- Share: `share_plus`
- Analytics: `firebase_analytics`
- App info: `package_info_plus`

## 5. App Structure

### 5.1 Main Navigation

앱은 하단 탭 구조를 사용한다.

1. 레시피
2. 장보기
3. 마이페이지

### 5.2 Initial Flow

1. 앱 실행
2. 스플래시 화면 진입
3. 초기 서비스 준비
4. 홈 화면 진입

### 5.3 Main Routes

- `/` Home
- `/splash`
- `/edit_recipe`
- `/detail_recipe`
- `/category_management`
- `/ingredient_management`
- `/ingredient_edit`
- `/ingredient_category_management`
- `/start_cooking`
- `/icloud_sync_settings`
- `/premium_purchase`

## 6. Functional Specification

### 6.1 Recipe Management

사용자는 레시피를 생성, 조회, 수정, 삭제할 수 있어야 한다.

기능:

- 레시피 목록 조회
- 레시피 검색
- 카테고리 필터링
- 북마크 필터링
- 레시피 상세 화면 조회
- 레시피 생성
- 레시피 수정
- 레시피 삭제
- 레시피 북마크 토글
- 조리 단계 등록
- 대표 이미지 등록
- 단계별 이미지 등록
- 인분 수 입력
- 총 재료비 계산
- 영양정보 연동

비고:

- 레시피 리스트 정렬은 생성일 기준 유지
- 레시피 수정 또는 북마크 변경 시 리스트 순서가 바뀌지 않도록 설계
- 가격이 0인 경우 일부 화면에서는 가격을 비표시

### 6.2 Recipe Category Management

사용자는 레시피 카테고리를 관리할 수 있어야 한다.

기능:

- 카테고리 추가
- 카테고리 삭제
- 카테고리 이름 변경

처리 규칙:

- 카테고리 이름 변경 시 해당 카테고리를 사용하는 기존 레시피의 카테고리 값도 함께 변경

### 6.3 Ingredient Product Management

사용자는 재료 상품 정보를 등록하고 관리할 수 있어야 한다.

기능:

- 재료 상품 목록 조회
- 앱 기본 재료 / 사용자 추가 재료 구분
- 재료 검색
- 재료 상품 추가
- 재료 상품 수정
- 재료 상품 삭제
- 재료 카테고리 관리

입력 항목:

- 재료명
- 제조사명
- 기준 중량
- 가격
- 영양성분
- 재료 카테고리

### 6.4 Ingredient Category Management

사용자는 재료 카테고리를 추가, 수정, 삭제할 수 있어야 한다.

### 6.5 Nutrition Management

앱은 재료 기준 영양정보를 저장하고, 레시피 단위 영양정보 계산에 활용해야 한다.

기능:

- 재료별 영양정보 저장
- 레시피 영양 합산값 계산
- 영양정보 상세 보기

### 6.6 Cooking Flow

사용자는 레시피 조리 단계를 따라가며 요리를 진행할 수 있어야 한다.

기능:

- 조리 단계 순차 진행
- 단계별 타이머 설정
- 타이머 완료 알림
- 조리 완료 처리

### 6.7 Shopping Checklist

북마크한 레시피를 기반으로 장보기 체크리스트를 제공해야 한다.

기능:

- 북마크된 레시피 목록 기반 장보기 카드 생성
- 레시피별 재료 체크
- 체크 상태 저장
- 새로고침

처리 규칙:

- 체크 상태는 로컬 저장

### 6.8 Settings / My Page

사용자는 마이페이지에서 앱 설정 및 관리 기능을 이용할 수 있어야 한다.

기능:

- 레시피 카테고리 관리 진입
- 재료 관리 진입
- 언어 변경
- 테마 모드 변경
- 컬러 프리셋 변경
- 폰트 변경
- 폰트 미리보기
- 글자 크기 조절
- 앱 버전 확인
- 리뷰 남기기
- 문의 / 버그 제보 메일 연동

### 6.9 Language Support

지원 언어:

- 일본어 `ja_JP`
- 한국어 `ko_KR`
- 영어 `en_US`

처리 규칙:

- 화면 문자열은 `AppStrings`를 통해 관리
- 앱 첫 실행 시 저장 언어가 없으면 기기 언어를 기준으로 초기 언어 결정

### 6.10 Theme / Appearance

기능:

- 시스템 / 라이트 / 다크 모드
- 컬러 프리셋 선택
- 언어별 폰트 선택
- 텍스트 크기 조절

처리 규칙:

- 선택한 테마, 색상, 폰트, 텍스트 크기는 로컬에 저장

### 6.11 Image Handling

기능:

- 대표 이미지 선택
- 조리 단계 이미지 선택
- 이미지 크롭
- 저장된 이미지 파일 정리

처리 규칙:

- 레시피 삭제 시 관련 이미지 파일도 함께 정리

### 6.12 Share / External Action

기능:

- 메일 앱 열기
- 앱 리뷰 페이지 열기
- 향후 공유 기능 사용 가능 구조 포함

### 6.13 Notifications

기능:

- 조리 타이머 완료 알림
- 타이머 완료 사운드 재생

## 7. Advertisement Specification

앱은 광고 수익화를 지원한다.

광고 유형:

- 배너 광고
- 리스트 중간 네이티브 광고
- 전면 광고

노출 위치:

- 레시피 관련 주요 화면 하단 배너
- 레시피 리스트 내 네이티브 광고
- 특정 사용자 액션 누적 후 전면 광고

제한:

- Web에서는 광고 비활성
- Debug 환경에서는 일부 광고 비활성
- 프리미엄 구매 사용자는 광고 미노출

## 8. Premium Purchase Specification

### 8.1 Product Type

- 상품 ID: `our_recipe_premium`
- 구매 방식: 비소모성 1회 구매

### 8.2 Unlock Rules

Android:

- 광고 제거

iOS:

- 광고 제거
- iCloud 동기화 기능 사용 가능

### 8.3 Purchase Screen

프리미엄 구매 화면은 다음을 제공해야 한다.

- 기능 안내
- 가격 표시
- 구매 버튼
- 복원 버튼
- 구매 진행 상태 표시
- 구매 성공 / 실패 / 복원 결과 표시

구매 처리 규칙:

- 구매 중에는 버튼 내부에 스피너와 진행 문구 표시
- 실패 메시지는 화면 내 메시지로 표시
- 사용자가 구매를 취소한 경우 에러로 취급하지 않음

### 8.4 Entitlement Rules

프리미엄 상태는 로컬 캐시만으로 판단하지 않고 스토어 이력을 기준으로 판단해야 한다.

Android:

- 과거 구매 이력 조회 기반

iOS:

- StoreKit 트랜잭션 조회 기반

## 9. iCloud Sync Specification

### 9.1 Scope

- iOS 전용
- 프리미엄 구매 사용자만 사용 가능

### 9.2 Features

- iCloud 동기화 on/off
- 로컬 데이터를 iCloud에 업로드
- iCloud 데이터를 로컬에 가져오기
- iCloud 데이터 삭제

### 9.3 Behavior Rules

- Android에서는 iCloud 기능 미지원
- iOS에서 프리미엄 미구매 시 iCloud 기능 잠금
- 프리미엄 구매 후에만 마이페이지에 iCloud 항목 표시
- iCloud 활성화 여부 설정값은 로컬에 저장
- 삭제된 레시피 tombstone 정보 관리

## 10. Data Specification

### 10.1 Main Models

#### RecipeModel

주요 속성:

- id
- name
- description
- category
- ingredients
- steps
- coverImagePath
- isLiked
- createdAt
- updatedAt
- servings
- ingredientCostTotal

#### IngredientProductModel

주요 속성:

- id
- name
- manufacturer
- price
- baseGram
- nutrition data
- category
- app-provided 여부

#### IngredientModel

주요 속성:

- id
- name
- amount
- unit
- memo
- 단가 계산용 참조 정보

#### RecipeStepModel

주요 속성:

- description
- imagePath
- timer

### 10.2 Storage

업무 데이터:

- SQLite 저장

저장 대상 예:

- 레시피
- 레시피 카테고리
- 재료 상품
- 재료 카테고리
- 조리 관련 기록

설정 / 환경값:

- SharedPreferences 저장

저장 대상 예:

- 언어
- 테마 모드
- 컬러 프리셋
- 폰트
- 텍스트 크기
- 장보기 체크 상태
- iCloud on/off 설정

## 11. UI / Screen Specification

### 11.1 Splash Screen

- 앱 초기화 수행
- 초기 라우팅 전환

### 11.2 Home Screen

- 하단 NavigationBar 제공
- 탭 전환

### 11.3 Recipes Screen

- 검색 바
- 필터 칩
- 레시피 리스트
- 광고 포함 가능
- 레시피 추가 FAB

### 11.4 Edit Recipe Screen

- 기본 정보 입력
- 카테고리 선택
- 인분 입력
- 재료 추가
- 조리 단계 추가
- 이미지 등록
- 저장

### 11.5 Detail Recipe Screen

- 레시피 상세 정보
- 영양 정보 진입
- 수정 / 삭제 / 요리 시작 관련 액션

### 11.6 Ingredient Management Screen

- 사용자 재료 / 앱 기본 재료 구분
- 재료 추가 FAB
- 그룹형 목록 표시

### 11.7 Shopping Screen

- 북마크 레시피 기반 체크리스트
- 체크 저장

### 11.8 My Page Screen

- 일반 설정
- 화면 설정
- 관리 기능
- 앱 정보 / 지원 기능
- 프리미엄 및 iCloud 관련 메뉴

### 11.9 Premium Purchase Screen

- 프리미엄 기능 설명
- 가격 표시
- 구매
- 복원
- 상태 메시지 표시

### 11.10 iCloud Sync Settings Screen

- iCloud 사용 가능 상태 표시
- 동기화 스위치
- 업로드 / 다운로드 / 삭제 버튼
- 진행 중 상태 표시

## 12. External Integration Specification

### 12.1 Firebase

- Firebase Core
- Firebase Analytics

수집 예:

- 레시피 생성
- 레시피 수정
- 레시피 삭제
- 장보기 체크 액션

### 12.2 AdMob

- 배너 광고
- 네이티브 광고
- 전면 광고

### 12.3 App Store / Play Billing

- 비소모성 인앱결제 상품 사용
- 스토어 구매 이력 기반 entitlement 판단

### 12.4 App Review / Store Review

- 앱 리뷰 페이지 열기 지원

### 12.5 Mail App

- 문의 / 버그 제보용 메일 작성 진입
- 메일 앱 미지원 시 이메일 복사 다이얼로그

## 13. Non-Functional Requirements

- 모바일 기기에서 안정적으로 동작해야 한다.
- 오프라인 상태에서도 로컬 데이터 기반 사용이 가능해야 한다.
- 다국어 UI가 정상 동작해야 한다.
- 프리미엄 구매 상태는 앱 재실행 후에도 올바르게 반영되어야 한다.
- iOS 전용 기능은 Android에서 노출 또는 동작 충돌이 없어야 한다.
- 삭제 시 관련 로컬 파일 및 DB 데이터 정합성이 유지되어야 한다.

## 14. Error Handling Policy

- DB 로드 실패 시 사용자 안내 필요
- DB 저장 실패 시 사용자 안내 필요
- 스토어 연결 불가 시 구매 화면 내 메시지 표시
- 구매 실패 시 화면 내 오류 메시지 표시
- 구매 취소는 오류로 간주하지 않음
- iCloud 미사용 가능 상태에서는 기능을 제한하고 안내 문구를 제공

## 15. Test Data / Development Utility

앱은 개발용 테스트 데이터 생성 서비스를 포함한다.

기능:

- 한국 샘플 레시피 생성
- 일본 샘플 레시피 생성
- 미국 샘플 레시피 생성

사용 목적:

- 개발 / QA 시 빠른 데이터 구성

## 16. Known Business Rules

- 북마크는 장보기 기능의 입력 소스로 사용된다.
- Android는 iCloud 미지원이다.
- iOS의 iCloud는 프리미엄 구매 후에만 사용 가능하다.
- 프리미엄 구매 전 iCloud 메뉴는 마이페이지에 표시하지 않는다.
- 프리미엄 구매 후에는 프리미엄 구매 메뉴를 마이페이지에서 숨긴다.
- 레시피 가격은 재료 가격 기반 계산값을 사용한다.

## 17. Future Expansion Candidates

- 사용자 계정 / 클라우드 계정 연동
- 레시피 공유
- 다중 디바이스 동기화 강화
- 카테고리/재료 추천
- 분석 대시보드
- 서버 기반 백업

