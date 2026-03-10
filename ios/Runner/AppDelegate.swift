import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Flutter <-> iOS iCloud 경로/상태 조회 채널.
  private let iCloudChannelName = "our_recipe/icloud_path"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: iCloudChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      // Flutter에서 요청한 iCloud 관련 메서드 분기 처리.
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }
        if call.method == "getICloudDocumentsPath" {
          // 실제 파일 저장에 사용할 iCloud Documents 절대경로 반환.
          result(self.resolveICloudDocumentsPath())
          return
        }
        if call.method == "getICloudStatus" {
          // 설정 진단용 상태(token/container) 반환.
          result(self.resolveICloudStatus())
          return
        }
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// iCloud Documents 경로를 계산한다.
  /// 컨테이너를 찾지 못하면 nil을 반환해 Dart 쪽에서 로컬 폴백하도록 한다.
  private func resolveICloudDocumentsPath() -> String? {
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let explicitContainerId = bundleId.isEmpty ? nil : "iCloud.\(bundleId)"
    let containerURL =
      FileManager.default.url(forUbiquityContainerIdentifier: explicitContainerId)
      ?? FileManager.default.url(forUbiquityContainerIdentifier: nil)
    guard let containerURL else {
      return nil
    }

    let docsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
    do {
      try FileManager.default.createDirectory(
        at: docsURL,
        withIntermediateDirectories: true
      )
      return docsURL.path
    } catch {
      return nil
    }
  }

  /// iCloud 상태 진단용 값.
  /// - tokenPresent: Apple ID iCloud 식별 토큰 존재 여부
  /// - containerAvailable: 앱 iCloud 컨테이너 접근 가능 여부
  private func resolveICloudStatus() -> [String: Bool] {
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let explicitContainerId = bundleId.isEmpty ? nil : "iCloud.\(bundleId)"
    let tokenPresent = FileManager.default.ubiquityIdentityToken != nil
    let hasContainer =
      FileManager.default.url(forUbiquityContainerIdentifier: explicitContainerId) != nil
      || FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    return [
      "tokenPresent": tokenPresent,
      "containerAvailable": hasContainer
    ]
  }
}
